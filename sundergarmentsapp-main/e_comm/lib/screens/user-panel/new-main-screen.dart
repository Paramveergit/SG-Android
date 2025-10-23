// New Main Screen with Navigation Cards - No Sidebar
// Implements modern card-based navigation as requested

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app-constant.dart';
import '../../widgets/banner-widget.dart';
import '../../widgets/welcome-popup-widget.dart';
import '../../controllers/welcome-popup-controller.dart';
import '../user-panel/enhanced-all-products-screen.dart';
import '../user-panel/cart-screen.dart' as cart_screen;
import '../user-panel/profile-screen.dart';
import '../auth-ui/welcome-screen.dart';

class NewMainScreen extends StatefulWidget {
  const NewMainScreen({super.key});

  @override
  State<NewMainScreen> createState() => _NewMainScreenState();
}

class _NewMainScreenState extends State<NewMainScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  late WelcomePopupController _welcomeController;

  @override
  void initState() {
    super.initState();
    _welcomeController = Get.put(WelcomePopupController());
    
    // Show welcome popup after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _welcomeController.showWelcomePopup();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove hamburger menu
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppConstant.appScendoryColor,
          statusBarIconBrightness: Brightness.light,
        ),
        backgroundColor: AppConstant.appMainColor,
        elevation: 2.0,
        toolbarHeight: 80.0, // Increased height for logo
        title: _buildHeaderWithLogo(),
        centerTitle: true,

      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 16.0),
                        
                        // Banner Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: BannerWidget(),
                        ),
                        
                        const SizedBox(height: 32.0),
                        
                        // Navigation Cards Section
                        _buildNavigationCards(),
                        
                        const SizedBox(height: 32.0),
                      ],
                    ),
                  ),
                ),
                
                // Logout Section (Fixed at bottom with safe area)
                _buildLogoutSection(),
              ],
            ),
            
            // Welcome Popup (overlay)
            const WelcomePopupWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWithLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              'assets/images/SG_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.store,
                  color: AppConstant.appTextColor,
                  size: 24.0,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        // Title and GST Number
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sunder Garments',
              style: TextStyle(
                color: AppConstant.appTextColor,
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'GST: 19AIQPD5899L1Z8',
              style: TextStyle(
                color: AppConstant.appTextColor.withOpacity(0.8),
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Explore',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        
        const SizedBox(height: 16.0),
        
        // Navigation Cards Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.3,
            children: [
              _buildNavigationCard(
                icon: Icons.inventory_2_outlined,
                title: 'All Products',
                subtitle: 'Browse our collection',
                color: Colors.blue.shade50,
                iconColor: Colors.blue,
                onTap: () => Get.to(() => const EnhancedAllProductsScreen()),
              ),
              _buildNavigationCard(
                icon: Icons.person_outline,
                title: 'My Profile',
                subtitle: 'Orders & settings',
                color: Colors.green.shade50,
                iconColor: Colors.green,
                onTap: () => Get.to(() => const ProfileScreen()),
              ),
              _buildNavigationCard(
                icon: Icons.shopping_cart_outlined,
                title: 'My Cart',
                subtitle: 'Review your items',
                color: Colors.orange.shade50,
                iconColor: Colors.orange,
                onTap: () => Get.to(() => const cart_screen.CartScreen()),
              ),
              _buildNavigationCard(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get assistance',
                color: Colors.purple.shade50,
                iconColor: Colors.purple,
                onTap: () => _showSupportOptions(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: iconColor.withOpacity(0.2),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.1),
                blurRadius: 8.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24.0,
                ),
              ),
              
              const SizedBox(height: 8.0),
              
              // Title
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 2.0),
              
              // Subtitle
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.0,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 16.0 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
                side: BorderSide(color: Colors.red.shade200),
              ),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Copyright Text
          Text(
            '© 2024 Sunder Garments. All rights reserved.',
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => WelcomeScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSupportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12.0),
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            
            const SizedBox(height: 20.0),
            
            // Title
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20.0),
            
            // Support Options
            _buildSupportOption(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: '+91 9830464031',
              onTap: () {
                Get.back();
                // Add phone call functionality
              },
            ),
            
            _buildSupportOption(
              icon: Icons.message,
              title: 'WhatsApp',
              subtitle: 'Chat with us',
              onTap: () {
                Get.back();
                // Add WhatsApp functionality
              },
            ),
            
            _buildSupportOption(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'support@sundergarments.com',
              onTap: () {
                Get.back();
                // Add email functionality
              },
            ),
            
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: AppConstant.appMainColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          icon,
          color: AppConstant.appMainColor,
          size: 20.0,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
