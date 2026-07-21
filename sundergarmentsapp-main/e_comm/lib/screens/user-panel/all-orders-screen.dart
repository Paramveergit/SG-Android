// ignore_for_file: file_names, prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, sized_box_for_whitespace, avoid_print
import 'package:e_comm/models/order-model.dart';
import 'package:e_comm/models/order-status.dart';
import 'package:e_comm/repositories/order-repository.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final OrderRepository orderRepository = OrderRepository();

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.shipped:
      case OrderStatus.dispatched:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppConstant.appTextColor,
        ),
        backgroundColor: AppConstant.appMainColor,
        title: Text(
          'All Orders',
          style: TextStyle(color: AppConstant.appTextColor),
        ),
      ),
      body: user == null
          ? Center(child: Text('Please sign in to view your orders'))
          : StreamBuilder<List<OrderModel>>(
              stream: orderRepository.streamOrdersForCustomer(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Could not load your orders:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: MediaQuery.of(context).size.height / 5,
                    child: Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return Center(
                    child: Text("No orders found!"),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final firstItem =
                        order.items.isNotEmpty ? order.items.first : null;
                    final itemSummary = firstItem == null
                        ? 'No items'
                        : (order.items.length > 1
                            ? '${firstItem.productName} +${order.items.length - 1} more'
                            : firstItem.productName);

                    return Card(
                      elevation: 5,
                      color: AppConstant.appTextColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppConstant.appMainColor,
                          backgroundImage: (firstItem != null &&
                                  firstItem.productImages.isNotEmpty)
                              ? NetworkImage(firstItem.productImages[0])
                              : null,
                        ),
                        title: Text(itemSummary),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Rs. ${order.total.toStringAsFixed(2)}'),
                            SizedBox(width: 10.0),
                            Text(
                              order.status.label,
                              style: TextStyle(
                                  color: _statusColor(order.status)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
