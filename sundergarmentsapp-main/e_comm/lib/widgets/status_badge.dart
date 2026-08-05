// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../models/order-status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Pill-shaped status label for an order. Maps all 8 OrderStatus values
/// onto the 4 status color pairs - the two pre-processing states share
/// "pending" styling, the three in-motion states share "shipped", etc.
/// - so a customer sees a small, meaningful set of colors instead of
/// 8 different ones.
class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  (Color, Color) get _colors {
    switch (status) {
      case OrderStatus.newOrder:
        return (AppColors.pendingBg, AppColors.pendingFg);
      case OrderStatus.confirmed:
      case OrderStatus.processing:
      case OrderStatus.packed:
        return (AppColors.processingBg, AppColors.processingFg);
      case OrderStatus.dispatched:
      case OrderStatus.shipped:
        return (AppColors.shippedBg, AppColors.shippedFg);
      case OrderStatus.delivered:
        return (AppColors.deliveredBg, AppColors.deliveredFg);
      case OrderStatus.cancelled:
        return (AppColors.cancelledBg, AppColors.cancelledFg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
