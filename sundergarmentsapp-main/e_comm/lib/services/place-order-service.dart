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
  final number = "+919830464031";
  
  String message = "ORDER CONFIRMATION!\n\n";
  message += "Hi, $customerName just placed an order!\n";
  message += "Order details:\n";
  
  double grandTotal = 0;
  
  for (int i = 0; i < orderItems.length; i++) {
    var item = orderItems[i];
    double itemTotal = double.parse(item['salePrice']) * item['productQuantity'];
    grandTotal += itemTotal;
    
    message += "• Product: ${item['productName']}\n";
    message += "• ID: ${item['productId']}\n";
    message += "• Price: ₹${item['salePrice']}\n";
    message += "• Quantity: ${item['productQuantity']}\n";
    message += "• Total: ₹$itemTotal\n\n";
  }
  
  message += "GRAND TOTAL: ₹$grandTotal";
  
  final url = 'https://wa.me/$number?text=${Uri.encodeComponent(message)}';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
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
  EasyLoading.show(status: "Please Wait..");
  if (user != null) {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .doc(user.uid)
          .collection('cartOrders')
          .get();

      List<QueryDocumentSnapshot> documents = querySnapshot.docs;
      List<Map<String, dynamic>> orderItems = [];

      // Collect all order items first
      for (var doc in documents) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>;
        orderItems.add(data);
      }

      // Process each order item
      for (var doc in documents) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>;

        String orderId = generateOrderId();

        OrderModel cartModel = OrderModel(
          productId: data['productId'],
          categoryId: data['categoryId'],
          productName: data['productName'],
          categoryName: data['categoryName'],
          salePrice: data['salePrice'],
          fullPrice: data['fullPrice'],
          productImages: data['productImages'],
          deliveryTime: data['deliveryTime'],
          isSale: data['isSale'],
          productDescription: data['productDescription'],
          createdAt: DateTime.now(),
          updatedAt: data['updatedAt'],
          productQuantity: data['productQuantity'],
          productTotalPrice: double.parse(data['productTotalPrice'].toString()),
          customerId: user.uid,
          status: 0,
          customerName: customerName,
          customerPhone: customerPhone,
          customerAddress: customerAddress,
          customerDeviceToken: customerDeviceToken,
        );

        // Save order to Firebase
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
        );

        //upload orders
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(user.uid)
            .collection('confirmOrders')
            .doc(orderId)
            .set(cartModel.toMap());

        //delete cart products
        await FirebaseFirestore.instance
            .collection('cart')
            .doc(user.uid)
            .collection('cartOrders')
            .doc(cartModel.productId.toString())
            .delete()
            .then((value) {
          print('Delete cart Products $cartModel.productId.toString()');
        });
      }

      // Send consolidated WhatsApp message for all products
      if (orderItems.isNotEmpty) {
        await openConsolidatedWhatsApp(orderItems, customerName, customerPhone);
      }
      print("Order Confirmed");
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
      print("error $e");
    }
  }
}
