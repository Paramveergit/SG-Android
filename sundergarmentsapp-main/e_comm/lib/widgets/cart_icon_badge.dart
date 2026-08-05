// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/user-panel/cart-screen.dart' as cart_screen;
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Cart icon with a live item-count badge, backed by the same
/// cartOrders stream everywhere it's used - Home's AppBar, Home's
/// bottom nav, and Product Details all show the same number because
/// they all read the same source, instead of some screens having a
/// badge and others silently missing one.
class CartIconWithBadge extends StatelessWidget {
  final double iconSize;
  final EdgeInsets padding;
  // BottomNavigationBarItem already handles taps via the parent
  // BottomNavigationBar's own onTap - if this widget's internal
  // GestureDetector also navigated there, tapping would push two
  // CartScreens (one from each handler firing). Set false there and
  // let the parent handle the tap; true everywhere else (AppBar icon).
  final bool enableTap;

  const CartIconWithBadge({
    super.key,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(8.0),
    this.enableTap = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('cart')
              .doc(user.uid)
              .collection('cartOrders')
              .snapshots()
          : null,
      builder: (context, snapshot) {
        int cartItemCount = 0;
        if (snapshot.hasData && snapshot.data != null) {
          cartItemCount = snapshot.data!.docs.length;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: enableTap ? () => Get.to(() => cart_screen.CartScreen()) : null,
              child: Padding(
                padding: padding,
                child: Icon(Icons.shopping_cart_outlined, size: iconSize),
              ),
            ),
            if (cartItemCount > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    cartItemCount.toString(),
                    style: const TextStyle(
                      color: AppColors.textOnBrand,
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
}
