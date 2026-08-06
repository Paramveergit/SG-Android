// Profile Screen with Orders and User Information
// Fixed to properly query orders and show only order count

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/order-model.dart';
import '../../repositories/order-repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/support_sheet.dart';
import 'order-detail-screen.dart';
import 'all-orders-screen.dart';
import '../auth-ui/welcome-screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final OrderRepository orderRepository = OrderRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            _buildProfileHeader(),
            
            const SizedBox(height: 24.0),
            
            // Order History Section
            _buildOrderHistorySection(),
            
            const SizedBox(height: 24.0),
            
            // Account Actions Section
            _buildAccountActions(),
            
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 80.0,
            height: 80.0,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(BorderSide(color: AppColors.brand, width: 3.0)),
            ),
            child: CircleAvatar(
              radius: 36.0,
              backgroundColor: AppColors.brand,
              backgroundImage: user?.photoURL != null 
                ? NetworkImage(user!.photoURL!) 
                : null,
              child: user?.photoURL == null 
                ? const Icon(
                    Icons.person,
                    color: AppColors.textOnBrand,
                    size: 40.0,
                  )
                : null,
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // User Name
          Text(
            user?.displayName ?? 'User',
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 4.0),
          
          // User Email
          if (user?.email != null)
            Text(
              user!.email!,
              style: const TextStyle(
                fontSize: 14.0,
                color: AppColors.textSecondary,
              ),
            ),
          
          const SizedBox(height: 16.0),
          
          // Order Count Only
          StreamBuilder<List<OrderModel>>(
            stream: user != null
              ? orderRepository.streamOrdersForCustomer(user!.uid)
              : null,
            builder: (context, snapshot) {
              // FIX: this used to only check hasData, so a genuine
              // Firestore error (permission, missing index, etc.) on
              // this account's orders query silently displayed as "0"
              // - indistinguishable from actually having zero orders.
              if (snapshot.hasError) {
                debugPrint('Order count stream error: ${snapshot.error}');
                return _buildStatItem(
                  icon: Icons.error_outline,
                  label: 'Orders',
                  value: '!',
                );
              }

              int orderCount = 0;
              
              if (snapshot.hasData && snapshot.data != null) {
                orderCount = snapshot.data!.length;
              }
              
              return _buildStatItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Orders',
                value: orderCount.toString(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.brand,
          size: 24.0,
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppColors.brandTintBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.brand,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Text(
                    'Order History',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // FIX: AllOrdersScreen existed in the codebase but had no
              // live entry point anywhere in the app - a customer with
              // more than 5 orders had no way to reach the rest. This
              // link is the fix.
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AllOrdersScreen()),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          
          const SizedBox(height: 20.0),
          
          // Orders List
          StreamBuilder<List<OrderModel>>(
            stream: user != null
              ? orderRepository.streamOrdersForCustomer(user!.uid, limit: 5)
              : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
                    ),
                  ),
                );
              }

              // FIX: this used to only check hasData, so a genuine
              // Firestore error on this account's orders query (missing
              // index, permission denial, etc.) silently rendered the
              // exact same "No orders found!" UI as a truly empty
              // account - indistinguishable to the user, and to us
              // debugging it. Show the real error instead.
              if (snapshot.hasError) {
                return _buildOrderErrorState(snapshot.error.toString());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyOrderState();
              }

              return Column(
                children: snapshot.data!.map((order) {
                  return _buildOrderItem(order);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderErrorState(String error) {
    // Message shown deliberately, not logged-only: this text is what
    // lets us actually diagnose the real cause instead of guessing.
    return AppErrorState(
      title: 'Could not load your orders',
      message: error,
    );
  }

  Widget _buildEmptyOrderState() {
    return const AppEmptyState(
      icon: Icons.shopping_bag_outlined,
      title: 'No orders yet',
      message: 'Your order history will appear here.',
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    final displayNumber = order.orderNumber.isNotEmpty
        ? order.orderNumber
        : (order.orderId.length >= 8
            ? order.orderId.substring(0, 8)
            : order.orderId);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.brandTintBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppColors.brand,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$displayNumber',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                StatusBadge(status: order.status),
              ],
            ),
          ),
          Text(
            '₹${order.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account actions',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Help & Support
          _buildActionButton(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Call, WhatsApp, or email us',
            onTap: () => showSupportOptionsSheet(context),
          ),
          
          const SizedBox(height: 12.0),
          
          // Sign Out Button
          _buildActionButton(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: () => _showSignOutDialog(),
          ),
          
          const SizedBox(height: 12.0),
          
          // Delete Account Button
          _buildActionButton(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            onTap: () => _showDeleteAccountDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.dangerBg : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDestructive ? AppColors.dangerFg.withOpacity(0.3) : AppColors.surfaceBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isDestructive 
                  ? AppColors.dangerBg
                  : AppColors.brandTintBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.dangerFg : AppColors.brand,
                size: 20.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: isDestructive ? AppColors.dangerFg : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDestructive ? AppColors.dangerFg : AppColors.textSecondary,
              size: 16.0,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.dangerFg),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      Get.offAll(() => WelcomeScreen());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign out: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        
        // Delete user account
        await user.delete();
        
        Get.offAll(() => WelcomeScreen());
        Get.snackbar(
          'Success',
          'Account deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete account: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
