// Fallback Banner Widget
// Shows when main banner system fails or no banners are available

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app-constant.dart';

class FallbackBannerWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final String? title;
  final String? subtitle;
  final IconData? icon;

  const FallbackBannerWidget({
    super.key,
    this.onTap,
    this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.25,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstant.appMainColor.withOpacity(0.8),
                  AppConstant.appMainColor.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstant.appMainColor.withOpacity(0.3),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          icon ?? Icons.local_offer_outlined,
                          size: 32.0,
                          color: AppConstant.appTextColor,
                        ),
                      ),
                      
                      const SizedBox(width: 20.0),
                      
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title ?? 'Special Offers',
                              style: const TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: AppConstant.appTextColor,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              subtitle ?? 'Discover amazing deals on premium garments',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: AppConstant.appTextColor.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 6.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: const Text(
                                'Explore Now',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstant.appTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




