// ignore_for_file: file_names, avoid_print, unused_local_variable, prefer_const_constructors, deprecated_member_use, prefer_const_declarations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm/models/order-item-model.dart';
import 'package:e_comm/models/order-model.dart';
import 'package:e_comm/repositories/order-repository.dart';
import 'package:e_comm/screens/auth-ui/home-router.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Redirects to WhatsApp with a pre-filled order-summary message
/// addressed to the business's own number - the customer just taps
/// Send, and the full order (number, every item, quantities, total,
/// delivery address) lands straight in the business's WhatsApp. Per
/// direct decision: not a silent, fully-automated send (that needs
/// the real WhatsApp Business API - Meta verification, pre-approved
/// templates, real setup time), this trades a one-tap customer action
/// for something that works today with no new accounts.
Future<void> _redirectToWhatsAppOrderSummary(OrderModel order) async {
  const businessNumber = '917850078100';

  final buffer = StringBuffer();
  buffer.writeln('New order placed!');
  buffer.writeln();
  buffer.writeln('Order: ${order.orderNumber}');
  buffer.writeln();
  buffer.writeln('Customer: ${order.customerName}');
  buffer.writeln('Phone: ${order.customerPhone}');
  buffer.writeln('Delivery address: ${order.customerAddress}');
  buffer.writeln();
  buffer.writeln('Items:');
  for (final item in order.items) {
    final variant = [item.size, item.color]
        .where((v) => v != null && v.isNotEmpty)
        .join(' / ');
    buffer.writeln(
      '\u2022 ${item.productName}${variant.isNotEmpty ? ' ($variant)' : ''} '
      '\u00d7 ${item.quantity} - \u20b9${item.lineTotal.toStringAsFixed(2)}',
    );
  }
  buffer.writeln();
  buffer.writeln('Total: \u20b9${order.total.toStringAsFixed(2)}');

  final uri = Uri.parse(
    'https://wa.me/$businessNumber?text=${Uri.encodeComponent(buffer.toString())}',
  );

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    print('WhatsApp order-summary redirect failed: $e');
    // A customer without WhatsApp installed (or who dismisses it)
    // shouldn't lose their already-successful order over this - the
    // order is already saved by the time this runs, this is a
    // secondary notification channel, not the order confirmation
    // itself.
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

    // Build the real order items (new schema) from the cart documents.
    List<OrderItemModel> orderItems = [];

    for (var doc in documents) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>;

      if (data['productId'] == null ||
          data['productName'] == null ||
          data['salePrice'] == null ||
          data['productQuantity'] == null) {
        throw 'Invalid product data in cart';
      }

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
    final createdOrder = await orderRepository.createOrder(
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

    // Redirect to WhatsApp with the full order summary pre-filled,
    // addressed to the business's own number - customer just taps
    // Send. Runs before the success snackbar/navigation so the
    // customer sees WhatsApp open right after their order is
    // confirmed, not after being routed back to Home first.
    await _redirectToWhatsAppOrderSummary(createdOrder);

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
