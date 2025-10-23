// Simple Product Card - Compatible with all Flutter versions
// Provides modern product card without complex animations

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../utils/app-constant.dart';
import '../../models/product-model.dart';

/// Simple product card that works on all Flutter versions
class SimpleProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToCart;
  final bool isFavorite;
  final bool showFavorite;
  final bool isLoading; // Add loading state
  final double? width;
  final double? height;

  const SimpleProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.onAddToCart,
    this.isFavorite = false,
    this.showFavorite = false,
    this.isLoading = false, // Default to false
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = product.isSale && 
                           product.salePrice.isNotEmpty &&
                           product.salePrice != product.fullPrice;
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Overlay
            Stack(
              children: [
                // Main Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    topRight: Radius.circular(12.0),
                  ),
                  child: Builder(
                    builder: (context) {
                      final imageUrl = product.productImages.isNotEmpty 
                        ? product.productImages[0].toString().trim()
                        : '';
                      
                      print('Product ${product.productName} image URL: $imageUrl');
                      print('Product ${product.productName} image URL length: ${imageUrl.length}');
                      
                      if (imageUrl.isEmpty) {
                        return Container(
                          width: width ?? double.infinity,
                          height: height ?? 120,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: width ?? double.infinity,
                        height: height ?? 120,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        maxWidthDiskCache: 600,
                        fadeInDuration: const Duration(milliseconds: 300),
                        httpHeaders: const {
                          'Cache-Control': 'max-age=3600',
                        },
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          print('Error loading image for ${product.productName}: $error');
                          print('Failed URL: $url');
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Discount Badge
                if (hasDiscount)
                  Positioned(
                    top: 8.0,
                    left: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        'SALE',
                        style: TextStyle(
                          color: AppConstant.appTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                
                // Favorite Button
                if (showFavorite)
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 20.0,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Product Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4.0),
                  
                  // Category
                  Text(
                    product.categoryName,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8.0),
                  
                  // Price Row
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        // Sale Price
                        Text(
                          '₹${product.salePrice}',
                          style: TextStyle(
                            color: AppConstant.appMainColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        // Original Price (crossed out)
                        Text(
                          '₹${product.fullPrice}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12.0,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '₹${product.fullPrice}',
                          style: TextStyle(
                            color: AppConstant.appMainColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                      
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
