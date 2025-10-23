// Enhanced Banner Widget with Modern Indicators & Animations
// Replaces basic CarouselSlider with more engaging banner experience

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../controllers/banners-controller.dart';
import 'loading_states.dart';

class EnhancedBannerWidget extends StatefulWidget {
  final double? height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showIndicators;
  final bool showGradientOverlay;
  final VoidCallback? onBannerTap;

  const EnhancedBannerWidget({
    super.key,
    this.height,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.showIndicators = true,
    this.showGradientOverlay = false,
    this.onBannerTap,
  });

  @override
  State<EnhancedBannerWidget> createState() => _EnhancedBannerWidgetState();
}

class _EnhancedBannerWidgetState extends State<EnhancedBannerWidget>
    with TickerProviderStateMixin {
  final bannerController _bannerController = Get.put(bannerController());
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppTheme.durationMedium,
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: AppTheme.durationSlow,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _scaleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<bannerController>(
      id: 'banners',
      builder: (controller) {
        if (controller.bannerUrls.isEmpty) {
          return _buildLoadingState();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
            child: Column(
              children: [
                _buildCarousel(controller.bannerUrls),
                if (widget.showIndicators && controller.bannerUrls.length > 1)
                  _buildIndicators(controller.bannerUrls.length),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: ModernLoadingStates.bannerSkeleton(
        height: widget.height ?? Get.height * 0.25,
      ),
    );
  }

  Widget _buildCarousel(List<String> bannerUrls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: CarouselSlider(
        items: bannerUrls.asMap().entries.map((entry) {
          final index = entry.key;
          final imageUrl = entry.value;
          return _buildBannerItem(imageUrl, index);
        }).toList(),
        options: CarouselOptions(
          height: widget.height ?? Get.height * 0.25,
          aspectRatio: 16 / 9,
          viewportFraction: 1.0,
          initialPage: 0,
          enableInfiniteScroll: bannerUrls.length > 1,
          reverse: false,
          autoPlay: widget.autoPlay && bannerUrls.length > 1,
          autoPlayInterval: widget.autoPlayInterval,
          autoPlayAnimationDuration: AppTheme.durationSlow,
          autoPlayCurve: Curves.easeInOutCubic,
          enlargeCenterPage: false,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index, reason) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildBannerItem(String imageUrl, int index) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onBannerTap,
          child: Stack(
            children: [
              // Background with subtle animation
              Transform.scale(
                scale: _currentIndex == index ? _scaleAnimation.value : 1.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildImagePlaceholder(),
                  errorWidget: (context, url, error) => _buildImageError(),
                  fadeInDuration: AppTheme.durationMedium,
                  fadeOutDuration: AppTheme.durationFast,
                  memCacheHeight: 800,
                  memCacheWidth: 1200,
                  maxWidthDiskCache: 1080,
                ),
              ),
              
              // Gradient Overlay (if enabled)
              if (widget.showGradientOverlay)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.onSurface.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              
              // Subtle border highlight
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Stack(
        children: [
          // Shimmer effect
          ModernLoadingStates.shimmerCard(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          // Loading indicator
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: AppTheme.onSurfaceVariant,
                ),
                SizedBox(height: AppTheme.spaceSm),
                Text(
                  'Loading banner...',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppTheme.error,
            ),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              'Failed to load banner',
              style: TextStyle(
                color: AppTheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators(int itemCount) {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spaceMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          itemCount,
          (index) => _buildIndicatorDot(index),
        ),
      ),
    );
  }

  Widget _buildIndicatorDot(int index) {
    final bool isActive = index == _currentIndex;
    
    return AnimatedContainer(
      duration: AppTheme.durationMedium,
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXs / 2),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive 
          ? AppTheme.primary 
          : AppTheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: isActive
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withOpacity(0.8),
                ],
              ),
            ),
          )
        : null,
    );
  }
}

// Enhanced Banner with Call-to-Action
class PromotionalBanner extends StatelessWidget {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonTap;
  final Color? overlayColor;
  final double? height;

  const PromotionalBanner({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonTap,
    this.overlayColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 200,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Stack(
          children: [
            // Background Image
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => ModernLoadingStates.shimmerCard(
                width: double.infinity,
                height: double.infinity,
              ),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.surfaceVariant,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            
            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    overlayColor?.withOpacity(0.8) ?? 
                      AppTheme.onSurface.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Content
            Positioned(
              left: AppTheme.spaceLg,
              top: AppTheme.spaceLg,
              bottom: AppTheme.spaceLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppTheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                  ],
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.onPrimary.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                  ],
                  if (buttonText != null && onButtonTap != null)
                    ElevatedButton(
                      onPressed: onButtonTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
                      ),
                      child: Text(buttonText!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
