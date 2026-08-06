// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../models/product-model.dart';
import '../models/stock-status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'stock_indicator.dart';

/// List-row counterpart to AppProductCard. Used wherever products are
/// shown as a scrolling list rather than a grid - PV specifically asked
/// for list view over grid for browsing/home, since grid cards read as
/// cramped with a name + MOQ + price + button all packed into a small
/// square.
class AppProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final bool isAddingToCart;

  const AppProductListTile({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.isAddingToCart = false,
  });

  // FIX: some products have the literal 4-character string "null"
  // stored as their categoryName in Firestore (same footgun found and
  // fixed elsewhere tonight - an old ?.toString() call on an actually-
  // null value), instead of a genuinely empty value. Showed up on
  // every product card as "MOQ 2000 · null". Filters that out here so
  // it never renders, same as the checkout pre-fill fix.
  String _moqAndCategoryLabel(ProductModel product) {
    final category = product.categoryName.trim();
    final hasRealCategory = category.isNotEmpty && category.toLowerCase() != 'null';
    return hasRealCategory ? 'MOQ ${product.moq} \u00b7 $category' : 'MOQ ${product.moq}';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = product.productImages.isNotEmpty;
    final price = product.isSale ? product.salePrice : product.fullPrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 84,
                    height: 84,
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
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.brandTintBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Text(
                        'Sale',
                        style: TextStyle(
                          color: AppColors.brandTintFg,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // GUARD: only show a stock indicator when the product
                  // actually has variants with tracked stock. Most
                  // existing products predate the inventory system and
                  // have an empty variants list - totalStock would
                  // default to 0 for those, which would wrongly show
                  // "Out of Stock" on products that are perfectly
                  // available, just not using per-variant tracking yet.
                  if (product.variants.isNotEmpty) ...[
                    StockIndicator(status: product.stockStatus),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    _moqAndCategoryLabel(product),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\u20b9$price',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (onAddToCart != null)
                        Builder(builder: (context) {
                          final isOutOfStock = product.variants.isNotEmpty &&
                              product.stockStatus == StockStatus.outOfStock;
                          return SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: (isAddingToCart || isOutOfStock) ? null : onAddToCart,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                minimumSize: const Size(0, 32),
                                textStyle: const TextStyle(fontSize: 12),
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
                                  : Text(isOutOfStock ? 'Out of stock' : 'Add to cart'),
                            ),
                          );
                        }),
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
