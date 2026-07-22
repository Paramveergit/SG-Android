// Profile Screen with Orders and User Information
// Fixed to properly query orders and show only order count

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../utils/app-constant.dart';
import '../../models/order-model.dart';
import '../../models/order-status.dart';
import '../../repositories/order-repository.dart';
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: AppConstant.appTextColor),
        ),
        backgroundColor: AppConstant.appMainColor,
        iconTheme: const IconThemeData(color: AppConstant.appTextColor),
        elevation: 2.0,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstant.appMainColor,
                width: 3.0,
              ),
            ),
            child: CircleAvatar(
              radius: 36.0,
              backgroundColor: AppConstant.appMainColor,
              backgroundImage: user?.photoURL != null 
                ? NetworkImage(user!.photoURL!) 
                : null,
              child: user?.photoURL == null 
                ? const Icon(
                    Icons.person,
                    color: AppConstant.appTextColor,
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
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 4.0),
          
          // User Email
          if (user?.email != null)
            Text(
              user!.email!,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey.shade600,
              ),
            ),
          
          const SizedBox(height: 4.0),

          // TEMPORARY DIAGNOSTIC - remove once the missing-orders issue
          // is confirmed fixed. Shows the exact live session UID being
          // used for the orders query, so it can be compared byte-for-
          // byte against a specific order's customerId field instead of
          // relying on a visual check.
          if (user != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: SelectableText(
                'Session UID: ${user!.uid}',
                style: TextStyle(fontSize: 11.0, color: Colors.grey.shade800),
              ),
            ),

          const SizedBox(height: 12.0),
          
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
          color: AppConstant.appMainColor,
          size: 24.0,
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppConstant.appMainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppConstant.appMainColor,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 12.0),
              const Text(
                'Order History',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstant.appMainColor),
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
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48.0,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Could not load your orders',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),
          // Shown deliberately, not logged-only: this text is what lets
          // us actually diagnose the real cause instead of guessing.
          // Screenshot/copy this if you're reporting the bug.
          SelectableText(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrderState() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 48.0,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'No orders found!',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    final displayNumber = order.orderNumber.isNotEmpty
        ? order.orderNumber
        : (order.orderId.length >= 8
            ? order.orderId.substring(0, 8)
            : order.orderId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppConstant.appMainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppConstant.appMainColor,
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Status: ${order.status.label}',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${order.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: AppConstant.appMainColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Actions',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16.0),
          
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
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isDestructive ? Colors.red.shade200 : Colors.grey.shade200,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isDestructive 
                  ? Colors.red.withValues(alpha: 0.1)
                  : AppConstant.appMainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppConstant.appMainColor,
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
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDestructive ? Colors.red : Colors.grey.shade400,
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
