// Enhanced Product Card with Modern Design & Animations
// Replaces basic image_card with custom, more engaging product cards

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../models/product-model.dart';
import 'loading_states.dart';

class EnhancedProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToCart;
  final bool isFavorite;
  final bool showFavorite;
  final bool showAddToCart;
  final bool showDiscount;
  final double? width;
  final double? height;

  const EnhancedProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.onAddToCart,
    this.isFavorite = false,
    this.showFavorite = true,
    this.showAddToCart = true,
    this.showDiscount = true,
    this.width,
    this.height,
  });

  @override
  State<EnhancedProductCard> createState() => _EnhancedProductCardState();
}

class _EnhancedProductCardState extends State<EnhancedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = widget.product.isSale && 
                            widget.product.salePrice.isNotEmpty &&
                            widget.product.salePrice != widget.product.fullPrice;
    
    final double? discountPercentage = hasDiscount ? 
      _calculateDiscountPercentage() : null;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _onHover(true),
            onExit: (_) => _onHover(false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: widget.width,
                height: widget.height,
                margin: const EdgeInsets.all(AppTheme.spaceXs),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowLight,
                      offset: const Offset(0, 2),
                      blurRadius: _isHovered ? 12 : 6,
                      spreadRadius: _isHovered ? 2 : 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image with Overlay
                      Expanded(
                        flex: 3,
                        child: _buildProductImage(hasDiscount, discountPercentage),
                      ),
                      
                      // Product Details
                      Expanded(
                        flex: 2,
                        child: _buildProductDetails(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(bool hasDiscount, double? discountPercentage) {
    return Stack(
      children: [
        // Main Image
        Hero(
          tag: 'product_${widget.product.productId}',
          child: CachedNetworkImage(
            imageUrl: widget.product.productImages.isNotEmpty 
              ? widget.product.productImages[0] 
              : '',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => ModernLoadingStates.shimmerCard(
              width: double.infinity,
              height: double.infinity,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                topRight: Radius.circular(AppTheme.radiusMd),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppTheme.surfaceVariant,
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            fadeInDuration: AppTheme.durationMedium,
            fadeOutDuration: AppTheme.durationFast,
          ),
        ),
        
        // Gradient Overlay
        if (_isHovered)
          AnimatedOpacity(
            opacity: _opacityAnimation.value * 0.3,
            duration: AppTheme.durationFast,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.onSurface.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
        
        // Discount Badge
        if (hasDiscount && widget.showDiscount && discountPercentage != null)
          Positioned(
            top: AppTheme.spaceSm,
            left: AppTheme.spaceSm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceSm,
                vertical: AppTheme.spaceXs,
              ),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                '${discountPercentage.toInt()}% OFF',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Favorite Button
        if (widget.showFavorite)
          Positioned(
            top: AppTheme.spaceSm,
            right: AppTheme.spaceSm,
            child: AnimatedScale(
              scale: _isHovered ? 1.1 : 1.0,
              duration: AppTheme.durationFast,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowLight,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: widget.onFavorite,
                  icon: Icon(
                    widget.isFavorite 
                      ? Icons.favorite 
                      : Icons.favorite_border,
                    color: widget.isFavorite 
                      ? AppTheme.error 
                      : AppTheme.onSurfaceVariant,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        
      ],
    );
  }

  Widget _buildProductDetails() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Expanded(
            child: Text(
              widget.product.productName,
              style: AppTheme.titleSmall.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceXs),
          
          // Category
          Text(
            widget.product.categoryName,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: AppTheme.spaceSm),
          
          // Price Row
          _buildPriceRow(),
        ],
      ),
    );
  }

  Widget _buildPriceRow() {
    final bool hasDiscount = widget.product.isSale && 
                            widget.product.salePrice.isNotEmpty &&
                            widget.product.salePrice != widget.product.fullPrice;

    if (hasDiscount) {
      return Row(
        children: [
          // Sale Price
          Text(
            '₹${widget.product.salePrice}',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppTheme.spaceXs),
          // Original Price (crossed out)
          Text(
            '₹${widget.product.fullPrice}',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    } else {
      return Text(
        '₹${widget.product.fullPrice}',
        style: AppTheme.titleMedium.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  double? _calculateDiscountPercentage() {
    try {
      final double fullPrice = double.parse(widget.product.fullPrice);
      final double salePrice = double.parse(widget.product.salePrice);
      if (fullPrice > 0 && salePrice < fullPrice) {
        return ((fullPrice - salePrice) / fullPrice) * 100;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

// Horizontal Product Card for lists
class HorizontalProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onRemove;
  final int? quantity;
  final bool showQuantityControls;

  const HorizontalProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onRemove,
    this.quantity,
    this.showQuantityControls = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceXs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: product.productImages.isNotEmpty 
                    ? product.productImages[0] 
                    : '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => ModernLoadingStates.shimmerCard(
                    width: 80,
                    height: 80,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.surfaceVariant,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: AppTheme.spaceMd),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                    Text(
                      product.categoryName,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildPriceAndActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceAndActions() {
    final bool hasDiscount = product.isSale && 
                            product.salePrice.isNotEmpty &&
                            product.salePrice != product.fullPrice;

    return Row(
      children: [
        // Price
        Expanded(
          child: hasDiscount
            ? Row(
                children: [
                  Text(
                    '₹${product.salePrice}',
                    style: AppTheme.titleSmall.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceXs),
                  Text(
                    '₹${product.fullPrice}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              )
            : Text(
                '₹${product.fullPrice}',
                style: AppTheme.titleSmall.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
        
        // Actions
        if (showQuantityControls && quantity != null)
          _buildQuantityControls(),
      ],
    );
  }

  Widget _buildQuantityControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: quantity! > 1 ? onRemove : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppTheme.primary,
        ),
        Text(
          quantity.toString(),
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: onAddToCart,
          icon: const Icon(Icons.add_circle_outline),
          color: AppTheme.primary,
        ),
      ],
    );
  }
}





