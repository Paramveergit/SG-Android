// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Shimmering placeholder box for loading states - replaces bare
/// CircularProgressIndicator/CupertinoActivityIndicator spinners with
/// a shape that previews the content's layout while it loads.
/// Self-contained animation, no external shimmer package needed.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppRadius.sm,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 3.0 * t, 0),
              end: Alignment(1.0 + 3.0 * t, 0),
              colors: const [
                AppColors.surfaceMuted,
                AppColors.surfaceBorder,
                AppColors.surfaceMuted,
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built skeleton matching the product card layout, for use in
/// product grids while data loads.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 1,
            child: SkeletonBox(borderRadius: AppRadius.sm),
          ),
          const SizedBox(height: 10),
          const SkeletonBox(height: 14, width: 120),
          const SizedBox(height: 6),
          const SkeletonBox(height: 12, width: 70),
        ],
      ),
    );
  }
}
