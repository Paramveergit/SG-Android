// ignore_for_file: file_names, prefer_const_constructors, no_leading_underscores_for_local_identifiers, avoid_unnecessary_containers

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_comm/screens/user-panel/all-categories-screen.dart';
import 'package:e_comm/screens/user-panel/all-flash-sale-products.dart';
import 'package:e_comm/screens/user-panel/all-products-screen.dart';
import 'package:e_comm/screens/user-panel/cart-screen.dart' as cart_screen;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../utils/app-constant.dart';
import '../../widgets/all-products-widget.dart';
import '../../widgets/banner-widget.dart';
import '../../widgets/fallback-banner-widget.dart';
import '../../widgets/category-widget.dart';
import '../../widgets/custom-drawer-widget.dart';
import '../../widgets/flash-sale-widget.dart';
import '../../widgets/heading-widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  
  @override
  void initState() {
    super.initState();
  }
  
  Widget _buildCartIconWithBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: user != null 
          ? FirebaseFirestore.instance
              .collection('cart')
              .doc(user!.uid)
              .collection('cartOrders')
              .snapshots()
          : null,
      builder: (context, snapshot) {
        int cartItemCount = 0;
        if (snapshot.hasData && snapshot.data != null) {
          cartItemCount = snapshot.data!.docs.length;
        }
        
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Get.to(() => cart_screen.CartScreen()),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.shopping_cart,
                  color: AppConstant.appTextColor,
                ),
              ),
            ),
            if (cartItemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    cartItemCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppConstant.appTextColor),
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppConstant.appScendoryColor,
            statusBarIconBrightness: Brightness.light),
        backgroundColor: AppConstant.appMainColor,
        title: Text(
          AppConstant.appMainName, 
          style: TextStyle(color: AppConstant.appTextColor),
        ),
        centerTitle: true,
        actions: [
          _buildCartIconWithBadge(),
        ],
      ),
      drawer: DrawerWidget(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: Get.height / 90.0),
            // Banners section with fallback
            _buildBannerSection(),
            // Categories section
            HeadingWidget(
              headingTitle: "Categories",
              headingSubTitle: "According to your budget",
              onTap: () => Get.to(() => AllCategoriesScreen()),
              buttonText: "See More >>",
            ),
            CategoryWidget(),
            // Flash Sale section
            HeadingWidget(
              headingTitle: "Flash Sale",
              headingSubTitle: "According to your budget",
              onTap: () => Get.to(() => AllFlashSaleProductScreen()),
              buttonText: "See More >>",
            ),
            FlashSaleWidget(),
            // All Products section
            HeadingWidget(
              headingTitle: "All Products",
              headingSubTitle: "According to your budget",
              onTap: () => Get.to(() => AllProductsScreen()),
              buttonText: "See More >>",
            ),
            AllProductsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return BannerWidget();
  }
}
