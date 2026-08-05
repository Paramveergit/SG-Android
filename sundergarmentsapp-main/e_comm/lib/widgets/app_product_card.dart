// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../models/product-model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Standard product card for grids across Home/Browsing/Categories.
/// Built on the design tokens so every product listing looks the
/// same, instead of each screen styling its own card.
class AppProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  // Optional quick-add-to-cart, used by grid/browsing screens where
  // bulk-ordering customers benefit from adding without opening the
  // product page. Home screen and other simple listings can omit
  // these and get a plain tap-to-view card.
  final VoidCallback? onAddToCart;
  final bool isAddingToCart;

  const AppProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.isAddingToCart = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = product.productImages.isNotEmpty;
    final price = product.isSale ? product.salePrice : product.fullPrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: hasImage
                        ? Image.network(
                            product.productImages[0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceMuted,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceMuted,
                            child: const Icon(
                              Icons.checkroom_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
                if (product.isSale)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandTintBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Text(
                        'Sale',
                        style: TextStyle(
                          color: AppColors.brandTintFg,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              product.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'MOQ ${product.moq}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹$price',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (onAddToCart != null) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 30,
                child: ElevatedButton(
                  onPressed: isAddingToCart ? null : onAddToCart,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                  ),
                  child: isAddingToCart
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnBrand,
                          ),
                        )
                      : const Text('Add to cart', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
