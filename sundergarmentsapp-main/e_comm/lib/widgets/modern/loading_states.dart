// Modern Loading States & Shimmer Effects
// Replaces basic CupertinoActivityIndicator with engaging loading experiences

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ModernLoadingStates {
  // Enhanced Loading Indicator with brand colors
  static Widget brandSpinner({
    double size = 24,
    Color? color,
    double strokeWidth = 3.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.primary,
        ),
        backgroundColor: AppTheme.primary.withOpacity(0.2),
      ),
    );
  }
  
  // Shimmer Loading Effect for Cards
  static Widget shimmerCard({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return AnimatedContainer(
      duration: AppTheme.durationMedium,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusMd),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceVariant,
            AppTheme.outline.withOpacity(0.3),
            AppTheme.surfaceVariant,
          ],
          stops: const [0.1, 0.3, 0.4],
        ),
      ),
      child: const _ShimmerAnimation(),
    );
  }
  
  // Product Card Skeleton Loader
  static Widget productCardSkeleton({
    double? width,
    double? height,
  }) {
    return Card(
      elevation: AppTheme.elevation2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            shimmerCard(
              width: width,
              height: height ?? 120,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            // Title placeholder
            shimmerCard(
              width: (width ?? 200) * 0.8,
              height: 16,
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
            const SizedBox(height: AppTheme.spaceXs),
            // Price placeholder
            shimmerCard(
              width: (width ?? 200) * 0.4,
              height: 14,
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
          ],
        ),
      ),
    );
  }
  
  // List Item Skeleton
  static Widget listItemSkeleton() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.surfaceVariant,
          child: shimmerCard(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
        ),
        title: shimmerCard(
          width: 150,
          height: 16,
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        ),
        subtitle: shimmerCard(
          width: 100,
          height: 14,
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        ),
        trailing: shimmerCard(
          width: 60,
          height: 32,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
    );
  }
  
  // Banner Skeleton
  static Widget bannerSkeleton({
    double? width,
    double? height,
  }) {
    return shimmerCard(
      width: width,
      height: height ?? 200,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
    );
  }
  
  // Grid Loading State
  static Widget gridLoadingState({
    required int itemCount,
    required int crossAxisCount,
    double? itemWidth,
    double? itemHeight,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppTheme.spaceSm,
        mainAxisSpacing: AppTheme.spaceSm,
        childAspectRatio: 0.8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => productCardSkeleton(
        width: itemWidth,
        height: itemHeight,
      ),
    );
  }
  
  // List Loading State
  static Widget listLoadingState({
    required int itemCount,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => listItemSkeleton(),
    );
  }
  
  // Full Page Loading with Brand Logo
  static Widget fullPageLoading({
    String? message,
    bool showLogo = true,
  }) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLogo) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Icon(
                  Icons.store,
                  size: 40,
                  color: AppTheme.onPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
            ],
            brandSpinner(size: 40),
            if (message != null) ...[
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                message,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Simple Shimmer Animation Widget
class _ShimmerAnimation extends StatefulWidget {
  const _ShimmerAnimation();

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceVariant,
                AppTheme.surface.withOpacity(0.5 + (_animation.value * 0.5)),
                AppTheme.surfaceVariant,
              ],
            ),
          ),
        );
      },
    );
  }
}

// Error State Widget
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorStateWidget({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 40,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              title,
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                message!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spaceLg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? icon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.onAction,
    this.actionLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Icon(
                icon ?? Icons.inventory_2_outlined,
                size: 50,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              title,
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                message!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppTheme.spaceLg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
