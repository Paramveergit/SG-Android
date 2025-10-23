import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CacheManager {
  static void clearCache() {
    // Clear image cache
    imageCache.clear();
    imageCache.clearLiveImages();
    
    Get.snackbar(
      'Cache Cleared',
      'App cache has been cleared successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.7),
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
  }

  static void limitCacheSize() {
    // Set maximum cache size (100MB) for better performance
    PaintingBinding.instance.imageCache.maximumSize = 100;
    // Set maximum image count for better memory management
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB
  }
}
