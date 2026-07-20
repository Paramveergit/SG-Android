// ignore_for_file: file_names, avoid_print, unused_local_variable, prefer_const_constructors, deprecated_member_use, prefer_const_declarations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm/models/order-item-model.dart';
import 'package:e_comm/repositories/order-repository.dart';
import 'package:e_comm/screens/auth-ui/home-router.dart';
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
      double itemTotal =
          double.parse(item['salePrice'].toString()) * item['productQuantity'];
      grandTotal += itemTotal;

      message += "• Product: ${item['productName']}\n";
      message += "• ID: ${item['productId']}\n";
      message += "• Price: ₹${item['salePrice']}\n";
      message += "• Quantity: ${item['productQuantity']}\n";
      message += "• Total: ₹$itemTotal\n\n";
    }

    message += "GRAND TOTAL: ₹$grandTotal";

    final url = 'https://wa.me/$number?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      final webUrl =
          'https://web.whatsapp.com/send?phone=$number&text=${Uri.encodeComponent(message)}';
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
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('cart')
        .doc(user.uid)
        .collection('cartOrders')
        .get()
        .timeout(Duration(seconds: 30));

    List<QueryDocumentSnapshot> documents = querySnapshot.docs;

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

    // Build the WhatsApp-message data (kept in the original simple map
    // shape) and the real order items (in the new schema) from the
    // same cart documents, in one pass.
    List<Map<String, dynamic>> orderItemsForWhatsApp = [];
    List<OrderItemModel> orderItems = [];

    for (var doc in documents) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>;

      if (data['productId'] == null ||
          data['productName'] == null ||
          data['salePrice'] == null ||
          data['productQuantity'] == null) {
        throw 'Invalid product data in cart';
      }

      orderItemsForWhatsApp.add(data);

      final unitPrice = double.tryParse(data['salePrice'].toString()) ?? 0.0;
      final quantity = (data['productQuantity'] as num?)?.toInt() ?? 1;
      final lineTotal = data['productTotalPrice'] != null
          ? (double.tryParse(data['productTotalPrice'].toString()) ??
              (unitPrice * quantity))
          : (unitPrice * quantity);

      orderItems.add(OrderItemModel(
        productId: data['productId'].toString(),
        productName: data['productName'].toString(),
        categoryId: data['categoryId']?.toString() ?? '',
        categoryName: data['categoryName']?.toString() ?? '',
        productImages: data['productImages'] ?? [],
        unitPrice: unitPrice,
        quantity: quantity,
        lineTotal: lineTotal,
      ));
    }

    // Create ONE real order for the whole cart - this is the actual
    // fix: previously every cart item became its own disconnected
    // document, and the customer's top-level order record got
    // overwritten on every single checkout.
    final orderRepository = OrderRepository();
    await orderRepository.createOrder(
      customerId: user.uid,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerDeviceToken: customerDeviceToken,
      items: orderItems,
    );

    // Only clear the cart after the order has been successfully
    // created, not interleaved with per-item writes as before.
    for (var doc in documents) {
      try {
        await FirebaseFirestore.instance
            .collection('cart')
            .doc(user.uid)
            .collection('cartOrders')
            .doc(doc.id)
            .delete()
            .timeout(Duration(seconds: 30));
      } catch (e) {
        print('Error deleting cart item ${doc.id}: $e');
        // Don't fail the whole checkout just because cart cleanup had
        // an issue - the order itself already succeeded.
      }
    }

    if (orderItemsForWhatsApp.isNotEmpty) {
      try {
        await openConsolidatedWhatsApp(
            orderItemsForWhatsApp, customerName, customerPhone);
      } catch (e) {
        print('WhatsApp notification failed: $e');
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
    Get.offAll(() => HomeRouter());
  } catch (e) {
    print("Order placement error: $e");
    EasyLoading.dismiss();

    String errorMessage = "Failed to place order. Please try again.";

    if (e.toString().contains('timeout')) {
      errorMessage =
          "Request timed out. Please check your internet connection and try again.";
    } else if (e.toString().contains('permission')) {
      errorMessage = "Permission denied. Please check your account status.";
    } else if (e.toString().contains('network')) {
      errorMessage = "Network error. Please check your internet connection.";
    } else if (e.toString().contains('Invalid cart data') ||
        e.toString().contains('Invalid product data')) {
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
