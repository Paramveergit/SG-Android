// ignore_for_file: file_names, must_be_immutable, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:e_comm_admin/utils/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/order-model.dart';
import 'check-single-order-screen.dart';

class SpecificCustomerOrderScreen extends StatelessWidget {
  String docId;
  String customerName;
  SpecificCustomerOrderScreen({
    super.key,
    required this.docId,
    required this.customerName,
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
          customerName,
          style: TextStyle(color: AppConstant.appTextColor),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(docId)
            .collection('confirmOrders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Container(
              child: const Center(
                child: Text('Error occurred while fetching orders!'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          }
          if (snapshot.data!.docs.isEmpty) {
            return Container(
              child: const Center(
                child: Text('No orders found!'),
              ),
            );
          }

          if (snapshot.data != null) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data = snapshot.data!.docs[index];
                String orderDocId = data.id;
                OrderModel orderModel = OrderModel.fromJson(data.data() as Map<String, dynamic>);

                return Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Info Section
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppConstant.appScendoryColor,
                              child: Text(
                                orderModel.customerName.isNotEmpty 
                                    ? orderModel.customerName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    orderModel.customerName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    orderModel.productName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Status: ',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: orderModel.status == -1
                                              ? Colors.orange.withOpacity(0.1)
                                              : orderModel.status == 0
                                                  ? Colors.blue.withOpacity(0.1)
                                                  : orderModel.status == 1
                                                      ? Colors.green.withOpacity(0.1)
                                                      : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: orderModel.status == -1
                                                ? Colors.orange
                                                : orderModel.status == 0
                                                    ? Colors.blue
                                                    : orderModel.status == 1
                                                        ? Colors.green
                                                        : Colors.red,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          orderModel.status == -1
                                              ? "Pending"
                                              : orderModel.status == 0
                                                  ? "In Process"
                                                  : orderModel.status == 1
                                                      ? "Delivered"
                                                      : "Cancelled",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: orderModel.status == -1
                                                ? Colors.orange
                                                : orderModel.status == 0
                                                    ? Colors.blue
                                                    : orderModel.status == 1
                                                        ? Colors.green
                                                        : Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // View Details Button
                            GestureDetector(
                              onTap: () => Get.to(
                                () => CheckSingleOrderScreen(
                                  docId: snapshot.data!.docs[index].id,
                                  orderModel: orderModel,
                                ),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppConstant.appMainColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'View',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Status Change Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await updateOrderStatus(userDocId: docId, orderDocId: orderDocId, status: -1);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orderModel.status == -1 ? Colors.orange : Colors.orange.withOpacity(0.3),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Pending',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await updateOrderStatus(userDocId: docId, orderDocId: orderDocId, status: 0);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orderModel.status == 0 ? Colors.blue : Colors.blue.withOpacity(0.3),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'In Process',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await updateOrderStatus(userDocId: docId, orderDocId: orderDocId, status: 1);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orderModel.status == 1 ? Colors.green : Colors.green.withOpacity(0.3),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Delivered',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await updateOrderStatus(userDocId: docId, orderDocId: orderDocId, status: 2);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orderModel.status == 2 ? Colors.red : Colors.red.withOpacity(0.3),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Cancelled',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return Container();
        },
      ),
    );
  }

  /// Updates the order status in Firestore
  Future<void> updateOrderStatus({
    required String userDocId,
    required String orderDocId,
    required int status,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(userDocId)
          .collection('confirmOrders')
          .doc(orderDocId)
          .update({
        'status': status,
      });
      
      // Show success message
      Get.snackbar(
        'Success',
        'Order status updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to update order status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
      );
    }
  }
}
