// ignore_for_file: must_be_immutable, file_names, prefer_const_literals_to_create_immutables, prefer_const_constructors, prefer_interpolation_to_compose_strings

import 'package:e_comm_admin/models/order-model.dart';
import 'package:e_comm_admin/utils/constant.dart';
import 'package:flutter/material.dart';

class CheckSingleOrderScreen extends StatelessWidget {
  String docId;
  OrderModel orderModel;
  CheckSingleOrderScreen({
    super.key,
    required this.docId,
    required this.orderModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppConstant.appTextColor,
        ),
        backgroundColor: AppConstant.appMainColor,
        title: Text(
          'Order',
          style: TextStyle(color: AppConstant.appTextColor),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(orderModel.productName),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Rs. ${orderModel.productTotalPrice.toStringAsFixed(2)}'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('x' + orderModel.productQuantity.toString()),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(orderModel.productDescription),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50.0,
                backgroundColor: AppConstant.appScendoryColor,
                backgroundImage: _getProductImage(orderModel.productImages),
                child: !orderModel.hasImages
                    ? Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 40,
                      )
                    : null,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(orderModel.customerName),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(orderModel.customerPhone),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(orderModel.customerAddress),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(orderModel.customerId),
          ),
        ],
      ),
    );
  }

  /// Safely gets the first product image with proper error handling
  /// Returns null if no images are available or if there's an error
  ImageProvider? _getProductImage(List<String> productImages) {
    try {
      final firstImageUrl = productImages.isNotEmpty ? productImages[0] : null;
      if (firstImageUrl != null && firstImageUrl.isNotEmpty) {
        return NetworkImage(firstImageUrl);
      }
    } catch (e) {
      print('Error accessing product image: $e');
    }
    return null;
  }
}
