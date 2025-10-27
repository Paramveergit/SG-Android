// ignore_for_file: file_names, prefer_const_constructors, sized_box_for_whitespace, avoid_unnecessary_containers

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm_admin/controllers/get-all-user-length-controller.dart';
import 'package:e_comm_admin/screens/all-users-screen.dart';
import 'package:e_comm_admin/screens/all-orders-screen.dart';
import 'package:e_comm_admin/screens/all-products-screen.dart';
import 'package:e_comm_admin/screens/all_categories_screen.dart';
import 'package:e_comm_admin/screens/add-products-screen.dart';
import 'package:e_comm_admin/screens/add_category_screen.dart';
import 'package:e_comm_admin/screens/sign-in-screen.dart';
import 'package:e_comm_admin/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GetUserLengthController _getUserLengthController = Get.put(GetUserLengthController());
  
  // Dashboard statistics
  int totalProducts = 0;
  int totalOrders = 0;
  int totalCategories = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  /// Loads dashboard statistics from Firestore with parallel execution
  Future<void> _loadDashboardStats() async {
    try {
      // Load all collections in parallel for faster performance
      final futures = await Future.wait([
        FirebaseFirestore.instance.collection('products').get(),
        FirebaseFirestore.instance.collection('orders').get(),
        FirebaseFirestore.instance.collection('categories').get(),
      ]);

      setState(() {
        totalProducts = futures[0].docs.length;
        totalOrders = futures[1].docs.length;
        totalCategories = futures[2].docs.length;
        isLoadingStats = false;
      });
    } catch (e) {
      print("Error loading dashboard stats: $e");
      setState(() {
        isLoadingStats = false;
      });
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
          'Admin Dashboard',
          style: TextStyle(color: AppConstant.appTextColor),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => SignInScreen());
            },
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.logout,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Section - Properly Centered
            if (isLoadingStats)
              Center(child: CupertinoActivityIndicator())
            else
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildSimpleStat('Products', totalProducts.toString(), Icons.inventory_2, Colors.blue)),
                    Expanded(child: _buildSimpleStat('Orders', totalOrders.toString(), Icons.shopping_bag, Colors.green)),
                    Expanded(child: _buildSimpleStat('Categories', totalCategories.toString(), Icons.category, Colors.orange)),
                    Expanded(child: Obx(() => _buildSimpleStat('Users', _getUserLengthController.userCollectionLength.value.toString(), Icons.people, Colors.purple))),
                  ],
                ),
              ),
            
            SizedBox(height: 32),
            
            // Navigation Cards
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            
            // Main Navigation Grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildNavigationCard(
                  'Users',
                  'Manage customers',
                  Icons.people,
                  Colors.blue,
                  () => Get.to(() => AllUsersScreen()),
                ),
                _buildNavigationCard(
                  'Orders',
                  'View all orders',
                  Icons.shopping_bag,
                  Colors.green,
                  () => Get.to(() => AllOrdersScreen()),
                ),
                _buildNavigationCard(
                  'Products',
                  'Manage catalog',
                  Icons.inventory_2,
                  Colors.orange,
                  () => Get.to(() => AllProductsScreen()),
                ),
                _buildNavigationCard(
                  'Categories',
                  'Organize categories',
                  Icons.category,
                  Colors.purple,
                  () => Get.to(() => AllCategoriesScreen()),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Quick Add Section
            Text(
              'Quick Add',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Add Product',
                    'Create a new product',
                    Icons.add_box,
                    Colors.blue,
                    () => Get.to(() => AddProductScreen()),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'Add Category',
                    'Create a new category',
                    Icons.add_circle,
                    Colors.green,
                    () => Get.to(() => AddCategoriesScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a simple statistic without card styling
  Widget _buildSimpleStat(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Builds a navigation card
  Widget _buildNavigationCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an action card for quick add
  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
