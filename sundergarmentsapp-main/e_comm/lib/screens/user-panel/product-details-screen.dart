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
    
    // Initialize quantity controller with empty text
    _quantityController = TextEditingController();
    
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
  
  Widget _buildCartIconWithBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: user != null 
          ? FirebaseFirestore.instance
              .collection('cart')
              .doc(user!.uid)
              .collection('cartOrders')
              .snapshots()
          : null,
      builder: (context, snapshot) {
        int cartItemCount = 0;
        if (snapshot.hasData && snapshot.data != null) {
          cartItemCount = snapshot.data!.docs.length;
        }
        
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Get.to(() => cart_screen.CartScreen()),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.shopping_cart),
              ),
            ),
            if (cartItemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    cartItemCount.toString(),
                    style: const TextStyle(
                      color: AppColors.textOnBrand,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
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
                    // Minus button
                    GestureDetector(
                      onTap: () {
                        if (_selectedQuantity != null && _selectedQuantity! > 1) {
                          setState(() {
                            _selectedQuantity = _selectedQuantity! - 1;
                            _quantityController.text = _selectedQuantity.toString();
                            _quantityError = false;
                          });
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (_selectedQuantity != null && _selectedQuantity! > 1)
                              ? AppColors.textPrimary 
                              : AppColors.surfaceMuted,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            bottomLeft: Radius.circular(3),
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: (_selectedQuantity != null && _selectedQuantity! > 1)
                              ? AppColors.textOnBrand 
                              : AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                    // Quantity input field
                    Container(
                      width: 50,
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
                    // Plus button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedQuantity = (_selectedQuantity ?? 0) + 1;
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

  @override
  Widget build(BuildContext context) {
    CalculateProductRatingController calculateProductRatingController = Get.put(
        CalculateProductRatingController(widget.productModel.productId));
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: [
          _buildCartIconWithBadge(),
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
                  );
                }).toList(),
                options: CarouselOptions(
                  scrollDirection: Axis.horizontal,
                  autoPlay: true,
                  aspectRatio: 1.5,
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
                              return Transform.translate(
                                offset: Offset(_shakeAnimation.value * 
                                    ((_shakeController.value * 4).round() % 2 == 0 ? 1 : -1), 0),
                                child: Material(
                                  child: Container(
                                    width: Get.width * 0.7,
                                    height: Get.height / 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.brand,
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                    ),
                                    child: TextButton(
                                      child: _isAddingToCart
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
                                      onPressed: _isAddingToCart ? null : () async {
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
                                      },
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
    final number = "+919830464031";
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
      );

      await documentReference.set(cartModel.toMap());

      print("product added");
    }
  }
}
