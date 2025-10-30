// Welcome Popup Widget
// Beautiful popup that appears once when the app is opened

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app-constant.dart';
import '../controllers/welcome-popup-controller.dart';

class WelcomePopupWidget extends StatelessWidget {
  const WelcomePopupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final WelcomePopupController controller = Get.find<WelcomePopupController>();
    
    return Obx(() {
      if (!controller.isShowingWelcome.value) {
        return const SizedBox.shrink();
      }
      
      return _buildWelcomePopup(context, controller);
    });
  }

  Widget _buildWelcomePopup(BuildContext context, WelcomePopupController controller) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => controller.markWelcomeAsShown(),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20.0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppConstant.appMainColor,
                          AppConstant.appScendoryColor,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10.0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36.0,
                            backgroundColor: Colors.white,
                            backgroundImage: controller.userPhotoURL != null 
                              ? NetworkImage(controller.userPhotoURL!) 
                              : null,
                            child: controller.userPhotoURL == null 
                              ? Icon(
                                  Icons.person,
                                  color: AppConstant.appMainColor,
                                  size: 40.0,
                                )
                              : null,
                          ),
                        ),
                        
                        const SizedBox(height: 16.0),
                        
                        // Welcome Text
                        Text(
                          'Welcome back!',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 8.0),
                        
                        Text(
                          controller.userDisplayName,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                        Text(
                          'We\'re excited to have you back!',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 12.0),
                        
                        Text(
                          'Discover our latest collection of premium garments crafted just for you.',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey.shade600,
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
                            onPressed: () => controller.markWelcomeAsShown(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstant.appMainColor,
                              foregroundColor: AppConstant.appTextColor,
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 2.0,
                            ),
                            child: const Text(
                              'Start Shopping',
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
                          onPressed: () => controller.markWelcomeAsShown(),
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              color: Colors.grey.shade600,
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
            color: AppConstant.appMainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            icon,
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
                title,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}




