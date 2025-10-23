// ignore_for_file: file_names, unused_field, avoid_unnecessary_containers, prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_comm/controllers/banners-controller.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  final bannerController _bannerController = Get.put(bannerController());

  @override
  void dispose() {
    // Clear image cache only when widget is disposed
    imageCache.clear();
    imageCache.clearLiveImages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<bannerController>(
      id: 'banners',
      builder: (controller) {
        // Show loading state
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }
        
        // Show error state
        if (controller.hasError.value) {
          return _buildErrorState(controller);
        }
        
        // Show empty state
        if (!controller.hasBanners) {
          return _buildEmptyState();
        }
        
        // Show banners
        return _buildBannerCarousel(controller);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: Get.height * 0.35,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 8.0),
            Text(
              'Loading banners...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bannerController controller) {
    return Container(
      height: Get.height * 0.35,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.0,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8.0),
            Text(
              controller.errorMessage.value,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12.0),
            ElevatedButton.icon(
              onPressed: () => controller.refreshBanners(),
              icon: const Icon(Icons.refresh, size: 16.0),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstant.appMainColor,
                foregroundColor: AppConstant.appTextColor,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: Get.height * 0.35,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48.0,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8.0),
            Text(
              'No banners available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(bannerController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: CarouselSlider(
        items: controller.bannerUrls
            .map(
              (imageUrl) => _buildBannerItem(imageUrl),
            )
            .toList(),
        options: CarouselOptions(
          scrollDirection: Axis.horizontal,
          autoPlay: controller.bannerCount > 1,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.easeInOut,
          aspectRatio: 2.0,
          viewportFraction: 1.0,
          enlargeCenterPage: false,
          enableInfiniteScroll: controller.bannerCount > 1,
        ),
      ),
    );
  }

  Widget _buildBannerItem(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: CachedNetworkImage(
        key: ValueKey(imageUrl),
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Optimized cache settings
        memCacheHeight: 600,
        memCacheWidth: 800,
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 600,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholderFadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) => _buildImageError(),
        // Add retry mechanism
        httpHeaders: const {
          'Cache-Control': 'max-age=3600',
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 8.0),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48.0,
              color: Colors.grey,
            ),
            SizedBox(height: 8.0),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}