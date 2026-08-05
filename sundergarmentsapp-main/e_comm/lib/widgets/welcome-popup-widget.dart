// Welcome Popup Widget
// Beautiful popup that appears once when the app is opened

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/welcome-popup-controller.dart';
import '../theme/app_colors.dart';

class WelcomePopupWidget extends StatelessWidget {
  const WelcomePopupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final WelcomePopupController controller = Get.find<WelcomePopupController>();
    return _buildWelcomePopup(context, controller);
  }

  void _dismiss(WelcomePopupController controller) {
    controller.markWelcomeAsShown();
    Get.back();
  }

  Widget _buildWelcomePopup(BuildContext context, WelcomePopupController controller) {
    return Material(
      color: AppColors.textPrimary.withOpacity(0.5),
      child: Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _dismiss(controller),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          
          // Popup Content
          Center(
            child: Container(
              margin: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.0),
                        topRight: Radius.circular(24.0),
                      ),
                    ),
                    child: Column(
                      children: [
                        // User Avatar
                        Container(
                          width: 80.0,
                          height: 80.0,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.textOnBrand, width: 4.0),
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 36.0,
                            backgroundColor: AppColors.surface,
                            backgroundImage: controller.userPhotoURL != null 
                              ? NetworkImage(controller.userPhotoURL!) 
                              : null,
                            child: controller.userPhotoURL == null 
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.brand,
                                  size: 40.0,
                                )
                              : null,
                          ),
                        ),
                        
                        const SizedBox(height: 16.0),
                        
                        // Welcome Text
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnBrand,
                          ),
                        ),
                        
                        const SizedBox(height: 8.0),
                        
                        Text(
                          controller.userDisplayName,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnBrand,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Welcome Message
                        const Text(
                          'We\'re excited to have you back!',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 12.0),
                        
                        const Text(
                          'Discover our latest collection of premium garments crafted just for you.',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24.0),
                        
                        // Features List
                        _buildFeatureItem(
                          icon: Icons.local_offer_outlined,
                          title: 'Exclusive Offers',
                          subtitle: 'Get special discounts on premium products',
                        ),
                        
                        const SizedBox(height: 12.0),
                        
                        _buildFeatureItem(
                          icon: Icons.delivery_dining_outlined,
                          title: 'Fast Delivery',
                          subtitle: 'Quick and reliable shipping to your doorstep',
                        ),
                        
                        const SizedBox(height: 12.0),
                        
                        _buildFeatureItem(
                          icon: Icons.verified_outlined,
                          title: 'Quality Assured',
                          subtitle: 'Premium fabrics and expert craftsmanship',
                        ),
                        
                        const SizedBox(height: 32.0),
                        
                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _dismiss(controller),
                            child: const Text(
                              'Start shopping',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12.0),
                        
                        // Skip Button
                        TextButton(
                          onPressed: () => _dismiss(controller),
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: AppColors.brandTintBg,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            icon,
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
                title,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}




