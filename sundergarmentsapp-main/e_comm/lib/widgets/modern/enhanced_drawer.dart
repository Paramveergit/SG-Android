// Enhanced Drawer Widget with Modern Design & Animations
// Replaces basic custom-drawer-widget with more engaging navigation

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/app_theme.dart';
import '../../screens/auth-ui/welcome-screen.dart';
import '../../screens/user-panel/all-orders-screen.dart';
import '../../screens/user-panel/main-screen.dart';
import '../../screens/auth-ui/home-router.dart';
import '../../screens/user-panel/all-products-screen.dart';

class EnhancedDrawerWidget extends StatefulWidget {
  const EnhancedDrawerWidget({super.key});

  @override
  State<EnhancedDrawerWidget> createState() => _EnhancedDrawerWidgetState();
}

class _EnhancedDrawerWidgetState extends State<EnhancedDrawerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.durationMedium,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 100, 0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Drawer(
              backgroundColor: AppTheme.primaryDark,
              elevation: AppTheme.elevation4,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(AppTheme.radiusLg),
                  bottomRight: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header Section
                    _buildDrawerHeader(),
                    
                    // Navigation Items
                    Expanded(
                      child: _buildNavigationItems(),
                    ),
                    
                    // Footer Section
                    _buildDrawerFooter(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
        ),
      ),
      child: Column(
        children: [
          // Logo and Brand
          Row(
            children: [
              Hero(
                tag: 'app_logo',
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.onPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: AppTheme.onPrimary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/SG_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.store,
                          size: 30,
                          color: AppTheme.onPrimary,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sunder Garments',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppTheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version 1.0.1',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMd),
          
          // User Info (if logged in)
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.onPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.onPrimary,
                    backgroundImage: user.photoURL != null 
                      ? NetworkImage(user.photoURL!) 
                      : null,
                    child: user.photoURL == null 
                      ? Icon(
                          Icons.person,
                          color: AppTheme.primary,
                          size: 20,
                        )
                      : null,
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: AppTheme.titleSmall.copyWith(
                            color: AppTheme.onPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.email != null)
                          Text(
                            user.email!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.onPrimary.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationItems() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
      children: [
        _buildNavigationItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
          onTap: () {
            Get.back();
            // Navigate via centralized home router to keep UI consistent
            Get.to(() => HomeRouter());
          },
        ),
        _buildNavigationItem(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          label: 'Products',
          onTap: () {
            Get.back();
            Get.to(() => const AllProductsScreen());
          },
        ),
        _buildNavigationItem(
          icon: Icons.shopping_bag_outlined,
          activeIcon: Icons.shopping_bag,
          label: 'Orders',
          onTap: () {
            Get.back();
            Get.to(() => const AllOrdersScreen());
          },
        ),
        _buildNavigationItem(
          icon: Icons.favorite_outline,
          activeIcon: Icons.favorite,
          label: 'Wishlist',
          onTap: () {
            // TODO: Navigate to wishlist screen
            Get.back();
            Get.snackbar(
              'Coming Soon',
              'Wishlist feature will be available soon!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.info,
              colorText: AppTheme.onPrimary,
            );
          },
        ),
        const Divider(
          color: AppTheme.onPrimary,
          thickness: 0.5,
          indent: AppTheme.spaceLg,
          endIndent: AppTheme.spaceLg,
        ),
        _buildNavigationItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          onTap: () {
            // TODO: Navigate to profile screen
            Get.back();
            Get.snackbar(
              'Coming Soon',
              'Profile feature will be available soon!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.info,
              colorText: AppTheme.onPrimary,
            );
          },
        ),
        _buildNavigationItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          label: 'Settings',
          onTap: () {
            // TODO: Navigate to settings screen
            Get.back();
            Get.snackbar(
              'Coming Soon',
              'Settings feature will be available soon!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.info,
              colorText: AppTheme.onPrimary,
            );
          },
        ),
        _buildNavigationItem(
          icon: Icons.help_outline,
          activeIcon: Icons.help,
          label: 'Help & Support',
          onTap: () {
            // TODO: Navigate to help screen
            Get.back();
            Get.snackbar(
              'Coming Soon',
              'Help & Support feature will be available soon!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.info,
              colorText: AppTheme.onPrimary,
            );
          },
        ),
      ],
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceXs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMd,
              vertical: AppTheme.spaceMd,
            ),
            decoration: BoxDecoration(
              color: isActive 
                ? AppTheme.onPrimary.withOpacity(0.1)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: AppTheme.onPrimary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.onPrimary,
                      fontWeight: isActive 
                        ? FontWeight.w600 
                        : FontWeight.w400,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.onPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        children: [
          const Divider(
            color: AppTheme.onPrimary,
            thickness: 0.5,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.onPrimary,
                side: const BorderSide(
                  color: AppTheme.onPrimary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spaceMd,
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceSm),
          
          // Powered By
          Text(
            'Powered By SG',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.onPrimary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool shouldLogout = await _showLogoutDialog();
    
    if (shouldLogout) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final FirebaseAuth auth = FirebaseAuth.instance;
        
        // Sign out from both Firebase and Google
        await auth.signOut();
        await googleSignIn.signOut();
        
        // Navigate to welcome screen
        Get.offAll(() => WelcomeScreen());
        
        Get.snackbar(
          'Success',
          'Logged out successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.success,
          colorText: AppTheme.onPrimary,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to logout. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.error,
          colorText: AppTheme.onPrimary,
        );
      }
    }
  }

  Future<bool> _showLogoutDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.onPrimary,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;
  }
}




