// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../models/stock-status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class StockIndicator extends StatelessWidget {
  final StockStatus status;
  final double fontSize;

  const StockIndicator({super.key, required this.status, this.fontSize = 11});

  Color get _dotColor {
    switch (status) {
      case StockStatus.inStock:
        return AppColors.successFg;
      case StockStatus.lowStock:
        return AppColors.warningFg;
      case StockStatus.outOfStock:
        return AppColors.dangerFg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: _dotColor, borderRadius: BorderRadius.circular(AppRadius.full)),
        ),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: _dotColor),
        ),
      ],
    );
  }
}
