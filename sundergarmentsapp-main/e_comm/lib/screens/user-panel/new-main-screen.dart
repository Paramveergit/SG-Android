// Home screen - Warehouse Ledger, Storefront design.
//
// Rebuilt per direct feedback: Home used to be just 4 static menu
// cards with no actual products visible. Now shows the same live
// product feed as the Browsing screen (shared via ProductFeedWidget,
// see lib/widgets/product_feed_widget.dart), with a bottom nav bar
// for Cart/Profile/Help since those are no longer reachable via nav
// cards. Sign-out moved to live only in Profile (it was duplicated
// here before) - Profile already has its own full sign-out flow.
//
// All functional logic (shipped-order popup listener, welcome popup)
// is unchanged from before.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order-model.dart';
import '../../models/order-status.dart';
import '../../repositories/order-repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/welcome-popup-widget.dart';
import '../../widgets/product_feed_widget.dart';
import '../../widgets/cart_icon_badge.dart';
import '../../controllers/welcome-popup-controller.dart';
import '../user-panel/cart-screen.dart' as cart_screen;
import '../user-panel/profile-screen.dart';
import '../user-panel/order-detail-screen.dart';

class NewMainScreen extends StatefulWidget {
  const NewMainScreen({super.key});

  @override
  State<NewMainScreen> createState() => _NewMainScreenState();
}

class _NewMainScreenState extends State<NewMainScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  late WelcomePopupController _welcomeController;
  StreamSubscription<List<OrderModel>>? _orderStatusSubscription;
  final Set<String> _shippedPopupShownFor = {};
  bool _isFirstOrderSnapshot = true;

  @override
  void initState() {
    super.initState();
    _welcomeController = Get.put(WelcomePopupController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_welcomeController.shouldShowWelcome.value) {
          _welcomeController.isShowingWelcome.value = true;
          Get.dialog(
            const WelcomePopupWidget(),
            barrierColor: Colors.transparent,
          );
        }
      });
    });

    _listenForShippedOrders();
  }

  void _listenForShippedOrders() {
    if (user == null) return;
    _orderStatusSubscription =
        OrderRepository().streamOrdersForCustomer(user!.uid).listen((orders) {
      if (_isFirstOrderSnapshot) {
        for (final order in orders) {
          if (order.status == OrderStatus.shipped) {
            _shippedPopupShownFor.add(order.orderId);
          }
        }
        _isFirstOrderSnapshot = false;
        return;
      }

      for (final order in orders) {
        if (order.status == OrderStatus.shipped &&
            !_shippedPopupShownFor.contains(order.orderId)) {
          _shippedPopupShownFor.add(order.orderId);
          _showShippedPopup(order);
        }
      }
    });
  }

  void _showShippedPopup(OrderModel order) {
    if (!mounted) return;
    final displayNumber =
        order.orderNumber.isNotEmpty ? order.orderNumber : order.orderId;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Your order has shipped! \u{1F69A}'),
          content: Text(
            "Hey! Your order having order number $displayNumber has been "
            "shipped and you can track the live update using the "
            "transporter details mentioned. Once the product gets "
            "delivered, please mark it as received.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(order: order),
                  ),
                );
              },
              child: const Text('View details'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _orderStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 72.0,
        title: _buildHeaderWithLogo(),
        centerTitle: false,
        actions: [
          const CartIconWithBadge(),
        ],
      ),
      body: const SafeArea(
        child: ProductFeedWidget(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 1:
            Get.to(() => cart_screen.CartScreen());
            break;
          case 2:
            Get.to(() => const ProfileScreen());
            break;
          case 3:
            _showSupportOptions();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Home'),
        BottomNavigationBarItem(
          icon: CartIconWithBadge(iconSize: 24, padding: EdgeInsets.zero, enableTap: false),
          label: 'Cart',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Help'),
      ],
    );
  }

  Widget _buildHeaderWithLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              'assets/images/SG_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.store,
                  color: AppColors.brand,
                  size: 24.0,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sunder Garments',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'GST: 19AIQPD5899L1Z8',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSupportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSupportOption(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: '+91 9830464031',
              onTap: () async {
                Get.back();
                final uri = Uri(scheme: 'tel', path: '+919830464031');
                if (!await launchUrl(uri)) {
                  Get.snackbar(
                    'Couldn\'t open dialer',
                    'You can reach us at +91 9830464031',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
            _buildSupportOption(
              icon: Icons.message,
              title: 'WhatsApp',
              subtitle: 'Chat with us',
              onTap: () async {
                Get.back();
                final message = Uri.encodeComponent(
                    "Hi, I need help with my Sunder Garments order.");
                final uri = Uri.parse(
                    'https://wa.me/919830464031?text=$message');
                if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                  Get.snackbar(
                    'Couldn\'t open WhatsApp',
                    'Message us directly at +91 9830464031',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
            _buildSupportOption(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'support@sundergarments.com',
              onTap: () async {
                Get.back();
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'support@sundergarments.com',
                  query: 'subject=${Uri.encodeComponent("Support request")}',
                );
                if (!await launchUrl(uri)) {
                  Get.snackbar(
                    'Couldn\'t open mail app',
                    'Email us at support@sundergarments.com',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
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
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.brandTintBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          icon,
          color: AppColors.brandTintFg,
          size: 20.0,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
