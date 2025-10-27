// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm_admin/utils/constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'specific-customer-orders-screen.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  String selectedFilter = 'All'; // Default filter
  List<String> filterOptions = ['All', 'Pending', 'In Process', 'Delivered', 'Cancelled'];
  Map<String, int> customerStatusCache = {}; // Cache for customer statuses

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppConstant.appTextColor,
        ),
        backgroundColor: AppConstant.appMainColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Orders',
              style: TextStyle(color: AppConstant.appTextColor),
            ),
            if (selectedFilter != 'All')
              Text(
                'Filter: $selectedFilter',
                style: TextStyle(
                  color: AppConstant.appTextColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: AppConstant.appTextColor,
            ),
            onSelected: (String value) {
              setState(() {
                selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return filterOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _getFilterIcon(option),
                        color: _getFilterColor(option),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(option),
                      if (selectedFilter == option) ...[
                        SizedBox(width: 8),
                        Icon(Icons.check, color: Colors.green, size: 16),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Container(
              child: Center(
                child: Text('Error occurred while fetching orders!'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          }
          if (snapshot.data!.docs.isEmpty) {
            return Container(
              child: Center(
                child: Text('No orders found!'),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(data['uId'])
                    .collection('confirmOrders')
                    .orderBy('createdAt', descending: true)
                    .limit(1)
                    .get(),
                builder: (context, orderSnapshot) {
                  if (orderSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      elevation: 5,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppConstant.appScendoryColor,
                          child: Text(
                            data['customerName'].isNotEmpty 
                                ? data['customerName'][0].toUpperCase()
                                : 'U',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(data['customerName']),
                        subtitle: Text(data['customerPhone']),
                        trailing: CupertinoActivityIndicator(),
                      ),
                    );
                  }

                  int orderStatus = -1; // Default to pending
                  if (orderSnapshot.hasData && orderSnapshot.data!.docs.isNotEmpty) {
                    orderStatus = orderSnapshot.data!.docs.first['status'] ?? -1;
                  }

                  // Apply filter - hide orders that don't match
                  if (selectedFilter != 'All' && _getFilterStatus(selectedFilter) != orderStatus) {
                    return SizedBox.shrink();
                  }

                  return Card(
                    elevation: 5,
                    child: ListTile(
                      onTap: () => Get.to(
                        () => SpecificCustomerOrderScreen(
                          docId: data['uId'],
                          customerName: data['customerName'],
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppConstant.appScendoryColor,
                        child: Text(
                          data['customerName'].isNotEmpty 
                              ? data['customerName'][0].toUpperCase()
                              : 'U',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(data['customerName']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['customerPhone']),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(orderStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(orderStatus),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusText(orderStatus),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(orderStatus),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Helper method to get filter icon
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'All':
        return Icons.list;
      case 'Pending':
        return Icons.schedule;
      case 'In Process':
        return Icons.hourglass_empty;
      case 'Delivered':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.list;
    }
  }

  /// Helper method to get filter color
  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'All':
        return Colors.grey;
      case 'Pending':
        return Colors.orange;
      case 'In Process':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Helper method to get filter status number
  int _getFilterStatus(String filter) {
    switch (filter) {
      case 'Pending':
        return -1;
      case 'In Process':
        return 0;
      case 'Delivered':
        return 1;
      case 'Cancelled':
        return 2;
      default:
        return -1;
    }
  }

  /// Helper method to get status text
  String _getStatusText(int status) {
    switch (status) {
      case -1:
        return 'Pending';
      case 0:
        return 'In Process';
      case 1:
        return 'Delivered';
      case 2:
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  /// Helper method to get status color
  Color _getStatusColor(int status) {
    switch (status) {
      case -1:
        return Colors.orange;
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
