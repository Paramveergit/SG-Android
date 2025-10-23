import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'cache_manager.dart';

class RefreshManager {
  static Future<void> refreshData({
    required Future<void> Function() onRefresh,
    bool clearCache = false,
  }) async {
    try {
      if (clearCache) {
        CacheManager.clearCache();
      }
      await onRefresh();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh data. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  }
}

