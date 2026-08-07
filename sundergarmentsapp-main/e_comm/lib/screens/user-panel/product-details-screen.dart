// ignore_for_file: file_names, must_be_immutable, prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, prefer_interpolation_to_compose_strings, unused_local_variable, avoid_print, prefer_const_declarations, deprecated_member_use, sized_box_for_whitespace

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
  // Resolved from the product's first real photo once loaded - the
  // carousel_slider package needs one fixed aspect ratio for its
  // whole viewport (a real constraint, it can't resize per-slide
  // while swiping), so this uses the first image's own real shape
  // instead of a guessed constant. Falls back to a sensible portrait
  // default while it's still loading.
  double _carouselAspectRatio = 0.8;
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
  Widget _buildSpecsTable() {
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

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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

    _resolveCarouselAspectRatio();
    
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

  void _resolveCarouselAspectRatio() {
    if (widget.productModel.productImages.isEmpty) return;
    final firstImageUrl = widget.productModel.productImages[0].toString();
    final provider = CachedNetworkImageProvider(firstImageUrl);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, synchronousCall) {
      if (mounted && info.image.height > 0) {
        setState(() {
          _carouselAspectRatio = info.image.width / info.image.height;
        });
      }
      stream.removeListener(listener);
    }, onError: (error, stackTrace) {
      // Keep the default aspect ratio - the placeholder/errorWidget in
      // the carousel itself already handles a genuinely broken image.
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
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
              Text(
                'Qty: ',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
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
                        width: 32,
                        height: 32,
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
                      height: 32,
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
                        width: 32,
                        height: 32,
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

  Widget _buildLotCaption() {
    final moq = widget.productModel.moq > 0 ? widget.productModel.moq : 1;
    final qty = _selectedQuantity ?? 0;
    if (moq <= 1 || qty <= 0) return const SizedBox.shrink();

    final isExactLots = qty % moq == 0;
    final String caption = isExactLots
        ? '${qty ~/ moq} lot${qty ~/ moq == 1 ? '' : 's'} of $moq pcs each'
        : 'Custom quantity (MOQ is $moq pcs per lot)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
      child: Text(
        caption,
        style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CalculateProductRatingController calculateProductRatingController = Get.put(
        CalculateProductRatingController(widget.productModel.productId));
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: [
          const CartIconWithBadge(),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(bottom: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //product images
              SizedBox(
                height: Get.height / 8,
              ),
              CarouselSlider(
                items: widget.productModel.productImages.map((imageUrl) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.black,
                          child: InteractiveViewer(
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Center(
                                child: CupertinoActivityIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.error,
                                color: AppColors.dangerFg,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        // FIX: was BoxFit.contain inside a fixed 0.8
                        // aspect ratio box - solved the earlier
                        // cropping problem, but any photo that didn't
                        // happen to match that exact ratio now showed
                        // large wasted empty bars around it instead.
                        // The carousel viewport now sizes itself to
                        // the product's own first real photo
                        // (resolved once in initState, same caching
                        // as everywhere else - see
                        // _resolveCarouselAspectRatio), so cover and
                        // contain become the same thing once the box
                        // actually matches the image - no crop, no
                        // wasted space.
                        color: AppColors.surfaceMuted,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: Get.width - 20,
                          placeholder: (context, url) => const ColoredBox(
                            color: AppColors.surfaceMuted,
                            child: Center(
                              child: CupertinoActivityIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                options: CarouselOptions(
                  scrollDirection: Axis.horizontal,
                  autoPlay: true,
                  aspectRatio: _carouselAspectRatio,
                  viewportFraction: 0.9,
                  enlargeCenterPage: true,
                ),
              ),
              SizedBox(
                height: Get.height / 20,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: Container(
                          alignment: Alignment.topLeft,
                          child: Text(
                            widget.productModel.productName,
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      // GUARD: same as the list tile - only show this
                      // for products that actually have tracked
                      // variants, otherwise a product with no
                      // inventory data set up yet would wrongly show
                      // as Out of Stock.
                      if (widget.productModel.variants.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: StockIndicator(
                              status: widget.productModel.stockStatus,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 4.0),
                        child: Container(
                          alignment: Alignment.topLeft,
                          child: widget.productModel.isSale == true &&
                                  widget.productModel.salePrice != ''
                              ? Row(
                                  children: [
                                    Text(
                                      "₹${widget.productModel.salePrice}",
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.successFg,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      "₹${widget.productModel.fullPrice}",
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: AppColors.textSecondary,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  "₹${widget.productModel.fullPrice}",
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.successFg,
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Category: " + _getCategoryName(
                                    widget.productModel.categoryId, 
                                    widget.productModel.categoryName
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            _buildQuantitySelector(),
                          ],
                        ),
                      ),
                      _buildLotCaption(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 4.0),
                        child: _buildSpecsTable(),
                      ),
                      // Product details (Quantity, Size, Description)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 4.0),
                        child: Container(
                          alignment: Alignment.topLeft,
                          child: _buildProductDetails(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              final isOutOfStock = widget.productModel.variants.isNotEmpty &&
                                  widget.productModel.stockStatus == StockStatus.outOfStock;
                              return Transform.translate(
                                offset: Offset(_shakeAnimation.value * 
                                    ((_shakeController.value * 4).round() % 2 == 0 ? 1 : -1), 0),
                                child: Material(
                                  child: Container(
                                    width: Get.width * 0.7,
                                    height: Get.height / 16,
                                    decoration: BoxDecoration(
                                      color: isOutOfStock ? AppColors.surfaceMuted : AppColors.brand,
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                    ),
                                    child: TextButton(
                                      child: isOutOfStock
                                        ? const Text(
                                            "Out of stock",
                                            style: TextStyle(color: AppColors.textSecondary),
                                          )
                                        : _isAddingToCart
                                        ? const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    AppColors.textOnBrand,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "Adding...",
                                                style: TextStyle(
                                                  color: AppColors.textOnBrand,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Text(
                                            "Add to cart",
                                            style: TextStyle(
                                              color: AppColors.textOnBrand,
                                            ),
                                          ),
                                      onPressed: isOutOfStock ? null : (_isAddingToCart ? null : () async {
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
                                            quantityIncrement: _selectedQuantity!
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
                                      }),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

      print("product exists");
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

      print("product added");
    }
  }
}
