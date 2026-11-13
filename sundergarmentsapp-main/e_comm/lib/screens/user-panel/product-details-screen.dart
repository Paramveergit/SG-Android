// ignore_for_file: file_names, must_be_immutable, prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, prefer_interpolation_to_compose_strings, unused_local_variable, prefer_const_declarations, deprecated_member_use, sized_box_for_whitespace

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm/models/product-model.dart';
import 'package:e_comm/screens/user-panel/cart-screen.dart' as cart_screen;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/rating-controller.dart';
import '../../models/cart-model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../widgets/cart_icon_badge.dart';
import '../../widgets/fullscreen_image_viewer.dart';
import '../../widgets/stock_indicator.dart';
import '../../models/stock-status.dart';

class ProductDetailsScreen extends StatefulWidget {
  ProductModel productModel;
  ProductDetailsScreen({super.key, required this.productModel});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> with TickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  
  // Loading state management to prevent multiple taps
  bool _isAddingToCart = false;
  
  // Quantity management
  int? _selectedQuantity;
  // FIX: this used to resolve the product's real photo aspect ratio
  // and feed it to CarouselOptions.aspectRatio, which sizes the
  // carousel's height off the full screen width regardless of any
  // surrounding constraint - so a tall/portrait photo blew the box up
  // to take over almost the whole screen, pushing price/specs/
  // add-to-cart below the fold. A fixed height (see _carouselHeight,
  // used directly as CarouselOptions.height below) keeps every
  // product's details card reachable without excess scrolling no
  // matter what shape its photos are; BoxFit.cover inside that fixed
  // box still shows the photo cleanly.
  static const double _carouselHeight = 260.0;
  // Current gallery page, kept in a notifier so swiping photos only
  // repaints the dots, not the whole screen.
  final ValueNotifier<int> _imageIndex = ValueNotifier<int>(0);
  bool _quantityError = false;
  late TextEditingController _quantityController;
  
  // Animation controllers
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;
  
  // Category mapping system (same as used in filtering)
  String _getCategoryName(String categoryId, String categoryName) {
    final categoryIdToName = {
      'SG-d33996c': 'Boy\'s Bottomwear',
      'SG-c9dbc04': 'Boy\'s Topwear', 
      'SG-b4ca53f': 'Girl\'s BottomWear',
      'SG-a6a6a05': 'Girl\'s TopWear',
      'SG-5c2a4db': 'Infant\'s Wear',
      'SG-e2f8f74': 'Men\'s Innerwear',
      'SG-e3e41cb': 'Men\'s Bottomwear',
      'SG-bbb90f2': 'Men\'s TopWear',
      'SG-3ad974f': 'Women\'s Bottomwear',
      'SG-4fe40f2': 'Women\'s Top',
    };
    
    // Return mapped name if available, otherwise return original name or fallback
    return categoryIdToName[categoryId] ?? 
           (categoryName.isNotEmpty ? categoryName : 'Uncategorized');
  }
  
  // Parse product description to extract quantity and size information
  Map<String, String> _parseProductDescription(String description) {
    String quantity = '';
    String size = '';
    String otherInfo = '';
    
    if (description.isNotEmpty) {
      // Split by pipe separator if it exists
      if (description.contains('|')) {
        List<String> parts = description.split('|');
        if (parts.length >= 2) {
          quantity = parts[0].trim();
          size = parts[1].trim();
        }
      } else {
        // If no pipe separator, try to extract QTY and SIZE patterns
        RegExp qtyRegex = RegExp(r'QTY:\s*([^|]+)', caseSensitive: false);
        RegExp sizeRegex = RegExp(r'SIZE:\s*([^|]+)', caseSensitive: false);
        
        Match? qtyMatch = qtyRegex.firstMatch(description);
        Match? sizeMatch = sizeRegex.firstMatch(description);
        
        if (qtyMatch != null) {
          quantity = 'QTY: ${qtyMatch.group(1)?.trim() ?? ''}';
        }
        if (sizeMatch != null) {
          size = 'SIZE: ${sizeMatch.group(1)?.trim() ?? ''}';
        }
        
        // If no patterns found, use the whole description as other info
        if (quantity.isEmpty && size.isEmpty) {
          otherInfo = description;
        }
      }
    }
    
    return {
      'quantity': quantity,
      'size': size,
      'otherInfo': otherInfo,
    };
  }
  
  // Build a proper specs section from the actual structured fields the
  // admin app saves (fabric, moq, and size/color living per-variant) -
  // this used to only ever try to parse "QTY:...|SIZE:..." patterns out
  // of the free-text description, which never matched how products are
  // actually entered via the current Admin App. That's why nothing but
  // possibly a stray sentence ever showed here, even for products with
  // fabric/size/color/MOQ correctly saved.
  List<MapEntry<String, String>> _specRows() {
    final product = widget.productModel;
    final variants = product.variants;
    final sizes = variants.map((v) => v.size).where((s) => s.isNotEmpty).toSet().toList();
    final colors = variants.map((v) => v.color).where((c) => c.isNotEmpty).toSet().toList();

    final rows = <MapEntry<String, String>>[];
    if (sizes.isNotEmpty) rows.add(MapEntry('Size', sizes.join(', ')));
    if (product.fabric.isNotEmpty) rows.add(MapEntry('Fabric', product.fabric));
    if (colors.isNotEmpty) rows.add(MapEntry('Color', colors.join(', ')));
    if (product.moq > 0) rows.add(MapEntry('MOQ', '${product.moq} pcs'));
    if (product.deliveryTime.isNotEmpty) {
      rows.add(MapEntry('Delivery Time', product.deliveryTime));
    }
    return rows;
  }

  Widget _buildSpecsTable() {
    final rows = _specRows();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Container(
            color: i.isEven ? AppColors.surfaceMuted : AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    row.key,
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.value,
                    style: const TextStyle(fontSize: 13.0, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build product details widget with proper formatting
  Widget _buildProductDetails() {
    Map<String, String> parsedDetails = _parseProductDescription(widget.productModel.productDescription);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quantity information
        if (parsedDetails['quantity']!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              parsedDetails['quantity']!,
              style: const TextStyle(
                fontSize: 16.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        // Size information
        if (parsedDetails['size']!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              parsedDetails['size']!,
              style: const TextStyle(
                fontSize: 16.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        // Other description information
        if (parsedDetails['otherInfo']!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              parsedDetails['otherInfo']!,
              style: const TextStyle(
                fontSize: 14.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
  
  @override
  void initState() {
    super.initState();
    
    // Default quantity is one full lot (MOQ pieces), not one piece -
    // per direct clarification: the qty stepper represents lots, and
    // a fresh product view should start at "1 lot" rather than
    // "1 piece" (which would be a fraction of a lot for a wholesale
    // MOQ product and make no practical sense to actually order).
    final int startingQuantity = widget.productModel.moq > 0 ? widget.productModel.moq : 1;
    _selectedQuantity = startingQuantity;
    _quantityController = TextEditingController(text: startingQuantity.toString());

    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    // Initialize highlight animation
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _highlightAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppColors.dangerBg,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _imageIndex.dispose();
    _shakeController.dispose();
    _highlightController.dispose();
    super.dispose();
  }
  
  void _triggerShakeAnimation() {
    setState(() {
      _quantityError = true;
    });
    
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
    
    _highlightController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _highlightController.reverse();
          setState(() {
            _quantityError = false;
          });
        }
      });
    });
  }
  
  
  Widget _buildQuantitySelector() {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _highlightAnimation.value,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _quantityError ? AppColors.dangerFg : AppColors.surfaceBorder,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minus button - steps by one full lot (MOQ pieces)
                    // at a time, per direct clarification. Floors at
                    // one lot via the stepper - going below that is
                    // still possible by typing a custom number directly
                    // into the field below, which stays completely
                    // free-form for exactly that "partial/custom
                    // quantity" case.
                    GestureDetector(
                      onTap: () {
                        final moq = widget.productModel.moq > 0 ? widget.productModel.moq : 1;
                        if (_selectedQuantity != null && _selectedQuantity! > moq) {
                          setState(() {
                            _selectedQuantity = _selectedQuantity! - moq;
                            _quantityController.text = _selectedQuantity.toString();
                            _quantityError = false;
                          });
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (_selectedQuantity != null && _selectedQuantity! > (widget.productModel.moq > 0 ? widget.productModel.moq : 1))
                              ? AppColors.textPrimary 
                              : AppColors.surfaceMuted,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            bottomLeft: Radius.circular(3),
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: (_selectedQuantity != null && _selectedQuantity! > (widget.productModel.moq > 0 ? widget.productModel.moq : 1))
                              ? AppColors.textOnBrand 
                              : AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                    // Quantity input field - widened from 50 to 76:
                    // at 50px, a bold 16px 4-digit number (e.g. "2000",
                    // a completely normal MOQ-lot quantity now that
                    // qty represents lots) genuinely didn't fit and
                    // visibly clipped its last digit.
                    Container(
                      width: 76,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border.symmetric(
                          vertical: BorderSide(color: AppColors.surfaceBorder, width: 1.0),
                        ),
                      ),
                      child: Center(
                        child: TextFormField(
                          controller: _quantityController,
                        onTap: () {
                          if (_quantityController.text.isEmpty) {
                            _quantityController.text = '';
                          }
                        },
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintText: 'Qty',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand,
                            height: 1.0,
                          ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _selectedQuantity = null;
                              _quantityError = false;
                            });
                          } else {
                            int? newQuantity = int.tryParse(value);
                            if (newQuantity != null && newQuantity > 0) {
                              setState(() {
                                _selectedQuantity = newQuantity;
                                _quantityError = false;
                              });
                            }
                          }
                        },
                        ),
                      ),
                    ),
                    // Plus button - steps by one full lot (MOQ pieces)
                    GestureDetector(
                      onTap: () {
                        final moq = widget.productModel.moq > 0 ? widget.productModel.moq : 1;
                        setState(() {
                          _selectedQuantity = (_selectedQuantity ?? 0) + moq;
                          _quantityController.text = _selectedQuantity.toString();
                          _quantityError = false;
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(3),
                            bottomRight: Radius.circular(3),
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.textOnBrand,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // Layout helpers
  // ---------------------------------------------------------------

  // Indian digit grouping (12,34,567) with no trailing ".00".
  String _formatInr(double value) {
    final fixed = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final parts = fixed.split('.');
    var digits = parts[0];
    if (digits.length > 3) {
      final last3 = digits.substring(digits.length - 3);
      var rest = digits.substring(0, digits.length - 3);
      final groups = <String>[];
      while (rest.length > 2) {
        groups.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) groups.insert(0, rest);
      digits = '${groups.join(',')},$last3';
    }
    return parts.length > 1 ? '$digits.${parts[1]}' : digits;
  }

  bool get _onSale =>
      widget.productModel.isSale == true && widget.productModel.salePrice != '';

  double _unitPrice() {
    final raw = _onSale ? widget.productModel.salePrice : widget.productModel.fullPrice;
    return double.tryParse(raw.toString()) ?? 0;
  }

  String _lotCaptionText() {
    final moq = widget.productModel.moq > 0 ? widget.productModel.moq : 1;
    final qty = _selectedQuantity ?? 0;
    if (moq <= 1) return 'Enter the number of pieces';
    if (qty <= 0) return 'Minimum order: $moq pcs per lot';
    if (qty % moq == 0) {
      final lots = qty ~/ moq;
      return '$lots lot${lots == 1 ? '' : 's'} of $moq pcs each';
    }
    return 'Custom quantity (MOQ is $moq pcs per lot)';
  }

  Widget _buildImageGallery() {
    final images = List<String>.from(widget.productModel.productImages);

    if (images.isEmpty) {
      return Container(
        height: _carouselHeight,
        width: double.infinity,
        color: AppColors.surfaceMuted,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 40,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Container(
      height: _carouselHeight,
      width: double.infinity,
      color: AppColors.surfaceMuted,
      child: Stack(
        children: [
          CarouselSlider.builder(
            itemCount: images.length,
            itemBuilder: (context, index, realIndex) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FullscreenImageViewer.open(
                  context,
                  imageUrls: images,
                  initialIndex: index,
                ),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: _carouselHeight,
                  placeholder: (context, url) => const Center(
                    child: CupertinoActivityIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textSecondary,
                      size: 36,
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: _carouselHeight,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: false,
              enableInfiniteScroll: images.length > 1,
              onPageChanged: (index, reason) => _imageIndex.value = index,
            ),
          ),

          // Zoom affordance
          Positioned(
            right: 12,
            bottom: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.92),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Icon(
                  Icons.zoom_out_map,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Page dots
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: IgnorePointer(
                child: ValueListenableBuilder<int>(
                  valueListenable: _imageIndex,
                  builder: (context, current, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (i) {
                        final active = i == current;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.brand
                                : AppColors.textSecondary.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip() {
    final name = _getCategoryName(
      widget.productModel.categoryId,
      widget.productModel.categoryName,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandTintBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.brandTintFg,
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    final product = widget.productModel;
    final hasStock = product.variants.isNotEmpty;

    final priceWidgets = <Widget>[
      Text(
        '₹${_onSale ? product.salePrice : product.fullPrice}',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.1,
        ),
      ),
    ];

    if (_onSale) {
      priceWidgets.add(Text(
        '₹${product.fullPrice}',
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
          decoration: TextDecoration.lineThrough,
        ),
      ));
      final full = double.tryParse(product.fullPrice.toString()) ?? 0;
      final sale = double.tryParse(product.salePrice.toString()) ?? 0;
      if (full > sale && sale > 0) {
        final off = ((1 - sale / full) * 100).round();
        if (off > 0) {
          priceWidgets.add(Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '$off% off',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.successFg,
              ),
            ),
          ));
        }
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: priceWidgets,
              ),
              const SizedBox(height: 2),
              const Text(
                'per piece',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        // GUARD: only for products that actually have tracked variants,
        // otherwise a product with no inventory data yet would wrongly
        // show as Out of Stock.
        if (hasStock) ...[
          const SizedBox(width: AppSpacing.md),
          StockIndicator(status: product.stockStatus, fontSize: 13),
        ],
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _lotCaptionText(),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildQuantitySelector(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // Sticky footer: running total on the left, the one primary action on
  // the right - always on screen, so nothing about ordering depends on
  // how far down the page someone has scrolled.
  Widget _buildBottomBar() {
    final isOutOfStock = widget.productModel.variants.isNotEmpty &&
        widget.productModel.stockStatus == StockStatus.outOfStock;
    final qty = _selectedQuantity ?? 0;
    final total = _unitPrice() * qty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 10),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    qty > 0 && total > 0 ? '₹${_formatInr(total)}' : '—',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnimation.value *
                            ((_shakeController.value * 4).round() % 2 == 0 ? 1 : -1),
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor:
                            _isAddingToCart ? AppColors.brand : AppColors.surfaceMuted,
                        disabledForegroundColor:
                            _isAddingToCart ? AppColors.textOnBrand : AppColors.textSecondary,
                      ),
                      onPressed: (isOutOfStock || _isAddingToCart)
                          ? null
                          : _onAddToCartPressed,
                      child: isOutOfStock
                          ? const Text('Out of stock')
                          : _isAddingToCart
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textOnBrand,
                                    ),
                                  ),
                                )
                              : const Text('Add to cart'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAddToCartPressed() async {
    FocusScope.of(context).unfocus();

    // Check if quantity is valid (allow mass orders)
    if (_selectedQuantity == null || _selectedQuantity! < 1) {
      _triggerShakeAnimation();
      return;
    }

    // Prevent multiple taps
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      await checkProductExistence(
        uId: user!.uid,
        quantityIncrement: _selectedQuantity!,
      );

      // Show success message
      Get.snackbar(
        'Success',
        'Item added to cart',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navigate to cart immediately
      await Get.to(() => cart_screen.CartScreen());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add item to cart',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    CalculateProductRatingController calculateProductRatingController = Get.put(
        CalculateProductRatingController(widget.productModel.productId));

    final product = widget.productModel;
    final parsed = _parseProductDescription(product.productDescription);
    final hasDescription = parsed['quantity']!.isNotEmpty ||
        parsed['size']!.isNotEmpty ||
        parsed['otherInfo']!.isNotEmpty;
    final hasSpecs = _specRows().isNotEmpty;
    final displayName = product.productName.trim().replaceAll(RegExp(r'\s+'), ' ');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: [
          const CartIconWithBadge(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageGallery(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryChip(),
                        const SizedBox(height: 10),
                        Text(
                          displayName,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildPriceRow(),
                        const SizedBox(height: AppSpacing.md),
                        _buildQuantitySection(),
                        if (hasSpecs) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _sectionTitle('Product details'),
                          _buildSpecsTable(),
                        ],
                        if (hasDescription) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _sectionTitle('Description'),
                          _buildProductDetails(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  static Future<void> sendMessageOnWhatsApp({
    required ProductModel productModel,
  }) async {
    final number = "+917850078100";
    final message =
        // "Hello Sunder Garments \n I want to know about this product \n ${productModel.productName} \n ${productModel.productId}";
      "Hello Sunder Garments \n"
      "I want to know about this product \n"
      "Product Name: ${productModel.productName} \n"
      "Product ID: ${productModel.productId} \n"
      "Product Image: ${productModel.productImages[0]}";

    final url = 'https://wa.me/$number?text=${Uri.encodeComponent(message)}';

    // FIX: was using the deprecated canLaunch(String)/launch(String)
    // API while every other WhatsApp/URL call in the app already uses
    // canLaunchUrl(Uri)/launchUrl(Uri) - inconsistent, and the old API
    // is on its way out of the package entirely.
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  //check prooduct exist or not

  Future<void> checkProductExistence({
    required String uId,
    int quantityIncrement = 1,
  }) async {
    final DocumentReference documentReference = FirebaseFirestore.instance
        .collection('cart')
        .doc(uId)
        .collection('cartOrders')
        .doc(widget.productModel.productId.toString());

    DocumentSnapshot snapshot = await documentReference.get();

    if (snapshot.exists) {
      int currentQuantity = snapshot['productQuantity'];
      int updatedQuantity = currentQuantity + quantityIncrement;
      double totalPrice = double.parse(widget.productModel.isSale
              ? widget.productModel.salePrice
              : widget.productModel.fullPrice) *
          updatedQuantity;

      await documentReference.update({
        'productQuantity': updatedQuantity,
        'productTotalPrice': totalPrice
      });
    } else {
      await FirebaseFirestore.instance.collection('cart').doc(uId).set(
        {
          'uId': uId,
          'createdAt': DateTime.now(),
        },
      );

      CartModel cartModel = CartModel(
        productId: widget.productModel.productId,
        categoryId: widget.productModel.categoryId,
        productName: widget.productModel.productName,
        categoryName: widget.productModel.categoryName,
        salePrice: widget.productModel.salePrice,
        fullPrice: widget.productModel.fullPrice,
        productImages: widget.productModel.productImages,
        deliveryTime: widget.productModel.deliveryTime,
        isSale: widget.productModel.isSale,
        productDescription: widget.productModel.productDescription,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        productQuantity: quantityIncrement,
        productTotalPrice: double.parse(widget.productModel.isSale
            ? widget.productModel.salePrice
            : widget.productModel.fullPrice) * quantityIncrement,
        moq: widget.productModel.moq,
      );

      await documentReference.set(cartModel.toMap());
    }
  }
}
