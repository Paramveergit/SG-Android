// ignore_for_file: file_names, avoid_print, unused_local_variable, prefer_const_constructors, deprecated_member_use, prefer_const_declarations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm/models/order-model.dart';
import 'package:e_comm/screens/user-panel/main-screen.dart';
import 'package:e_comm/screens/auth-ui/home-router.dart';
import 'package:e_comm/services/generate-order-id-service.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

// Consolidated WhatsApp function for multiple products
Future<void> openConsolidatedWhatsApp(List<Map<String, dynamic>> orderItems, 
                                    String customerName, String customerPhone) async {
  try {
    final number = "+919830464031";
    
    String message = "ORDER CONFIRMATION!\n\n";
    message += "Hi, $customerName just placed an order!\n";
    message += "Order details:\n";
    
    double grandTotal = 0;
    
    for (int i = 0; i < orderItems.length; i++) {
      var item = orderItems[i];
      double itemTotal = double.parse(item['salePrice'].toString()) * item['productQuantity'];
      grandTotal += itemTotal;
      
      message += "• Product: ${item['productName']}\n";
      message += "• ID: ${item['productId']}\n";
      message += "• Price: ₹${item['salePrice']}\n";
      message += "• Quantity: ${item['productQuantity']}\n";
      message += "• Total: ₹$itemTotal\n\n";
    }
    
    message += "GRAND TOTAL: ₹$grandTotal";
    
    final url = 'https://wa.me/$number?text=${Uri.encodeComponent(message)}';
    
    // Enhanced URL launching with proper error handling
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      // Fallback to browser if WhatsApp is not available
      final webUrl = 'https://web.whatsapp.com/send?phone=$number&text=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch WhatsApp. Please install WhatsApp or try again.';
      }
    }
  } catch (e) {
    print('WhatsApp launch error: $e');
    // Don't throw error - WhatsApp failure shouldn't prevent order completion
    // Just log the error and continue
  }
}

void placeOrder({
  required BuildContext context,
  required String customerName,
  required String customerPhone,
  required String customerAddress,
  required String customerDeviceToken,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  
  // Early validation
  if (user == null) {
    EasyLoading.dismiss();
    Get.snackbar(
      "Error",
      "User not authenticated. Please sign in again.",
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
    return;
  }

  EasyLoading.show(status: "Please Wait..");
  
  try {
    // Add timeout to Firebase operations
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('cart')
        .doc(user.uid)
        .collection('cartOrders')
        .get()
        .timeout(Duration(seconds: 30));

    List<QueryDocumentSnapshot> documents = querySnapshot.docs;
    
    // Validate cart is not empty
    if (documents.isEmpty) {
      EasyLoading.dismiss();
      Get.snackbar(
        "Empty Cart",
        "Your cart is empty. Please add items before placing an order.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      return;
    }

    List<Map<String, dynamic>> orderItems = [];

    // Collect all order items first with validation
    for (var doc in documents) {
      try {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>;
        
        // Validate required fields
        if (data['productId'] == null || 
            data['productName'] == null || 
            data['salePrice'] == null ||
            data['productQuantity'] == null) {
          throw 'Invalid product data in cart';
        }
        
        orderItems.add(data);
      } catch (e) {
        print('Error processing cart item: $e');
        throw 'Invalid cart data. Please refresh and try again.';
      }
    }

    // Process each order item with enhanced error handling
    for (var doc in documents) {
      try {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>;

        String orderId = generateOrderId();

        OrderModel cartModel = OrderModel(
          productId: data['productId'].toString(),
          categoryId: data['categoryId'].toString(),
          productName: data['productName'].toString(),
          categoryName: data['categoryName'].toString(),
          salePrice: data['salePrice'].toString(),
          fullPrice: data['fullPrice'].toString(),
          productImages: data['productImages'] ?? [],
          deliveryTime: data['deliveryTime'].toString(),
          isSale: data['isSale'] ?? false,
          productDescription: data['productDescription'].toString(),
          createdAt: DateTime.now(),
          updatedAt: data['updatedAt'] ?? DateTime.now(),
          productQuantity: data['productQuantity'] ?? 1,
          productTotalPrice: double.parse(data['productTotalPrice'].toString()),
          customerId: user.uid,
          status: 0,
          customerName: customerName,
          customerPhone: customerPhone,
          customerAddress: customerAddress,
          customerDeviceToken: customerDeviceToken,
        );

        // Save order to Firebase with timeout
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(user.uid)
            .set(
          {
            'uId': user.uid,
            'customerName': customerName,
            'customerPhone': customerPhone,
            'customerAddress': customerAddress,
            'customerDeviceToken': customerDeviceToken,
            'orderStatus': 0,
            'createdAt': DateTime.now()
          },
        ).timeout(Duration(seconds: 30));

        // Upload individual order with timeout
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(user.uid)
            .collection('confirmOrders')
            .doc(orderId)
            .set(cartModel.toMap())
            .timeout(Duration(seconds: 30));

        // Delete cart products with timeout
        await FirebaseFirestore.instance
            .collection('cart')
            .doc(user.uid)
            .collection('cartOrders')
            .doc(cartModel.productId.toString())
            .delete()
            .timeout(Duration(seconds: 30))
            .then((value) {
          print('Deleted cart product: ${cartModel.productId}');
        });
      } catch (e) {
        print('Error processing order item: $e');
        throw 'Failed to process order item. Please try again.';
      }
    }

    // Send consolidated WhatsApp message for all products (non-blocking)
    if (orderItems.isNotEmpty) {
      try {
        await openConsolidatedWhatsApp(orderItems, customerName, customerPhone);
      } catch (e) {
        print('WhatsApp notification failed: $e');
        // Don't fail the entire order for WhatsApp issues
      }
    }
    
    print("Order Confirmed Successfully");
    Get.snackbar(
      "Order Confirmed",
      "Thank you for your order!",
      backgroundColor: AppConstant.appMainColor,
      colorText: Colors.white,
      duration: Duration(seconds: 5),
    );
    
    EasyLoading.dismiss();
    // After placing an order, return via centralized router
    Get.offAll(() => HomeRouter());
    
  } catch (e) {
    print("Order placement error: $e");
    
    // CRITICAL FIX: Always dismiss loading in catch block
    EasyLoading.dismiss();
    
    // Enhanced error handling with user-friendly messages
    String errorMessage = "Failed to place order. Please try again.";
    
    if (e.toString().contains('timeout')) {
      errorMessage = "Request timed out. Please check your internet connection and try again.";
    } else if (e.toString().contains('permission')) {
      errorMessage = "Permission denied. Please check your account status.";
    } else if (e.toString().contains('network')) {
      errorMessage = "Network error. Please check your internet connection.";
    } else if (e.toString().contains('Invalid cart data')) {
      errorMessage = "Cart data is invalid. Please refresh and try again.";
    } else if (e.toString().contains('Empty Cart')) {
      errorMessage = "Your cart is empty. Please add items before placing an order.";
    }
    
    Get.snackbar(
      "Order Failed",
      errorMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
