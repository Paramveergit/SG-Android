// Simple Loading States - Compatible with all Flutter versions
// Provides modern loading experiences without complex animations

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../utils/app-constant.dart';

/// Simple loading states that work on all Flutter versions
class SimpleLoadingStates {
  /// Brand-colored spinner (drop-in replacement for CupertinoActivityIndicator)
  static Widget brandSpinner({
    double size = 24,
    Color? color,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppConstant.appMainColor,
        ),
      ),
    );
  }
  
  /// Simple skeleton card for loading states
  static Widget skeletonCard({
    double? width,
    double? height,
    double borderRadius = 8.0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.grey.shade200,
      ),
      child: const SizedBox(),
    );
  }
  
  /// Product card skeleton
  static Widget productCardSkeleton({
    double? width,
    double? height,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            skeletonCard(
              width: width,
              height: height ?? 120,
              borderRadius: 4.0,
            ),
            const SizedBox(height: 8.0),
            // Title placeholder
            skeletonCard(
              width: (width ?? 200) * 0.8,
              height: 16,
              borderRadius: 4.0,
            ),
            const SizedBox(height: 4.0),
            // Price placeholder
            skeletonCard(
              width: (width ?? 200) * 0.4,
              height: 14,
              borderRadius: 4.0,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Grid loading state
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
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => productCardSkeleton(
        width: itemWidth,
        height: itemHeight,
      ),
    );
  }
  
  /// Error state widget
  static Widget errorState({
    String title = 'Error',
    String? message,
    VoidCallback? onRetry,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 48,
              color: AppConstant.appMainColor,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8.0),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstant.appMainColor,
                  foregroundColor: AppConstant.appTextColor,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Loading state widget
  static Widget loadingState({
    String title = 'Loading',
    String? message,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            brandSpinner(size: 48),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Empty state widget
  static Widget emptyState({
    String title = 'No Items Found',
    String? message,
    IconData icon = Icons.inbox_outlined,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

