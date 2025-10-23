// ignore_for_file: file_names

import 'package:flutter/material.dart';

class AppConstant {
  static String appMainName = 'Sunder Garments';
  static String appPoweredBy = 'Powered By SG';
  static const appMainColor = Color(0xFFbf1b08);
  static const appScendoryColor = Color(0xFF981206);
  static const appTextColor = Color(0xFFFBF5F4);
  static const appStatusBarColor = Color(0xFFFBF5F4);

  // Modern theme compatibility - these reference the new AppTheme
  static Color get modernPrimary => appMainColor;
  static Color get modernSecondary => appScendoryColor;
  static Color get modernOnPrimary => appTextColor;
  static Color get modernBackground => const Color(0xFFFAFAFA);
  static Color get modernSurface => const Color(0xFFFFFFFF);
  static Color get modernError => const Color(0xFFD32F2F);
  static Color get modernSuccess => const Color(0xFF4CAF50);
  static Color get modernWarning => const Color(0xFFFF9800);
  static Color get modernInfo => const Color(0xFF2196F3);
}
