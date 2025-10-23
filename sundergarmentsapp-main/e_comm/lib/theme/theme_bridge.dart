// Theme Bridge - Connects old AppConstant with new AppTheme system
// This ensures 100% backward compatibility while enabling new features

import 'package:flutter/material.dart';
import '../utils/app-constant.dart';
import 'app_theme.dart';

/// This class provides a bridge between the old AppConstant and new AppTheme
/// It ensures all existing code continues to work without any changes
class ThemeBridge {
  /// Initialize the theme bridge
  /// Call this in main.dart before runApp()
  static void init() {
    // Nothing to initialize yet
  }
  
  /// Get the theme data for the app
  /// This maintains the original look and feel while adding new capabilities
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: _createMaterialColor(AppConstant.appMainColor),
      primaryColor: AppConstant.appMainColor,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstant.appMainColor,
        foregroundColor: AppConstant.appTextColor,
        elevation: 2.0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppConstant.appTextColor,
        ),
        titleTextStyle: TextStyle(
          color: AppConstant.appTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: AppConstant.appMainColor,
        secondary: AppConstant.appScendoryColor,
        onPrimary: AppConstant.appTextColor,
        surface: Colors.white,
        background: Colors.white,
      ),
    );
  }
  
  /// Create a MaterialColor from a single Color
  static MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 0; i < 10; i++) {
      swatch[(strengths[i] * 1000).round()] = Color.fromRGBO(
        r,
        g,
        b,
        strengths[i],
      );
    }
    
    return MaterialColor(color.value, swatch);
  }
}




