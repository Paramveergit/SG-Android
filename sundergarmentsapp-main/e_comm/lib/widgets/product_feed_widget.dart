// Enhanced All Products Screen with Category Filters
// Replaces the categories section with a modern filter system

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/product-model.dart';
import '../models/cart-model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'app_product_list_tile.dart';
import 'app_empty_state.dart';
import 'app_error_state.dart';
import 'skeleton_box.dart';
import '../screens/user-panel/product-details-screen.dart';

class ProductFeedWidget extends StatefulWidget {
  const ProductFeedWidget({super.key});

  @override
  State<ProductFeedWidget> createState() => _ProductFeedWidgetState();
}

class _ProductFeedWidgetState extends State<ProductFeedWidget> {
  String? selectedCategoryId;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Loading state management to prevent multiple taps
  final Set<String> _addingToCartProducts = <String>{};
  
  
  // Stable category order to prevent position shifting
  static const List<String> _stableCategoryOrder = [
    'SG-5c2a4db', // Infant's Wear
    'SG-d33996c', // Boy's Bottomwear
    'SG-c9dbc04', // Boy's Topwear
    'SG-b4ca53f', // Girl's BottomWear
    'SG-a6a6a05', // Girl's TopWear
    'SG-e2f8f74', // Men's Innerwear
    'SG-e3e41cb', // Men's Bottomwear
    'SG-bbb90f2', // Men's TopWear
    'SG-3ad974f', // Women's Bottomwear
    'SG-4fe40f2', // Women's Top
  ];

  // Category name mapping for display
  final Map<String, String> categoryNameMapping = {
    'SG-e2f8f74': 'Men\'s Innerwear', // Rename Innerwear to Men's Innerwear
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold/AppBar of its own - this widget is embedded inside
    // whichever screen uses it (Browsing screen's own Scaffold, or
    // Home's), each of which provides its own AppBar/branding around it.
    return Column(
      children: [
        // Search bar (always visible)
        _buildSearchBar(),

        // Category grid - hidden while actively searching, so search
        // results get the full remaining space instead of fighting
        // the grid for room. Reappears the moment the search is
        // cleared.
        if (searchQuery.isEmpty) _buildCategoryFilters(),

        // Products List
        Expanded(
          child: _buildProductsGrid(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
              )
            : null,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('categoryName')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Category stream error: ${snapshot.error}');
          return const SizedBox(height: 40.0);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 40.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: SkeletonBox(width: 80, height: 32, borderRadius: 20),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(height: 40.0);
        }

        return Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: CategoryGridSelector(
            key: const ValueKey('category_grid_selector'),
            categories: snapshot.data!.docs,
            selectedCategoryId: selectedCategoryId,
            onCategorySelected: (categoryId) {
              setState(() {
                selectedCategoryId = categoryId;
              });
            },
            categoryNameMapping: categoryNameMapping,
            stableCategoryOrder: _stableCategoryOrder,
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const AppErrorState(
            title: 'Could not load products',
            message: 'Please check your connection and try again.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (context, index) => const ProductListTileSkeleton(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.storefront_outlined,
            title: 'No products available',
            message: 'Please check back again soon.',
          );
        }

        final products = _filterProducts(snapshot.data!.docs);

        if (products.isEmpty) {
          // Distinct, more specific copy depending on why nothing
          // matched - a mistyped search and an empty category are
          // different situations and deserve different guidance.
          if (searchQuery.isNotEmpty) {
            return AppEmptyState(
              icon: Icons.search_off,
              title: 'No matching products found',
              message: 'Please check your spelling, or try a different search term.',
              actionLabel: 'Clear search',
              onAction: () {
                setState(() {
                  searchQuery = '';
                  _searchController.clear();
                });
              },
            );
          }
          return _buildComingSoonState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final productData = products[index].data() as Map<String, dynamic>;
            
            // Switched to fromMap so this picks up fabric/moq/variants
            // like every other product list screen now does - preserving
            // the same null-safety this screen had by pre-sanitizing the
            // map before handing it to fromMap.
            final safeProductData = <String, dynamic>{
              ...productData,
              'productId': productData['productId'] ?? '',
              'categoryId': productData['categoryId'] ?? '',
              'productName': productData['productName'] ?? '',
              'categoryName': productData['categoryName'] ?? '',
              'salePrice': productData['salePrice'] ?? '',
              'fullPrice': productData['fullPrice'] ?? '',
              'productImages': List<String>.from(productData['productImages'] ?? []),
              'deliveryTime': productData['deliveryTime'] ?? '',
              'isSale': productData['isSale'] ?? false,
              'productDescription': productData['productDescription'] ?? '',
            };
            final productModel = ProductModel.fromMap(safeProductData);

            return AppProductListTile(
              product: productModel,
              onTap: () => Get.to(() => ProductDetailsScreen(productModel: productModel)),
              onAddToCart: () => _handleAddToCart(productModel),
              isAddingToCart: _addingToCartProducts.contains(productModel.productId),
            );
          },
        );
      },
    );
  }

  Widget _buildComingSoonState() {
    return AppEmptyState(
      icon: Icons.storefront_outlined,
      title: 'Products coming soon',
      message: "We're working hard to bring you amazing products.\nStay tuned for updates!",
      actionLabel: 'Browse all products',
      onAction: () {
        setState(() {
          selectedCategoryId = null;
        });
      },
    );
  }

  List<QueryDocumentSnapshot> _filterProducts(List<QueryDocumentSnapshot> products) {
    List<QueryDocumentSnapshot> filteredProducts = products;

    // Category filter: exact categoryId match only. This used to run
    // through ~125 lines of "smart" pattern-matching (checking if the
    // category name string contained words like "bottom"/"pants"/
    // "shorts") as a workaround for some historical bad data. The
    // problem: those patterns were never actually gender-specific -
    // selecting "Men's Bottomwear" matched anything containing
    // "bottom" or "pants" regardless of which gender/age section it
    // actually belonged to, which is exactly why Boy's/Girl's/Women's
    // items were showing up under Men's Bottomwear. categoryId is a
    // precise identifier - there's no good reason to fuzzy-match it.
    // Any product with a genuinely correct categoryId is matched
    // correctly by this alone. A product that still doesn't show up
    // under its real category has bad data at the source (re-saving
    // it via the admin app fixes it), which is a data problem to
    // solve there, not something to paper over with more guessing here.
    if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
      filteredProducts = filteredProducts.where((doc) {
        final productData = doc.data() as Map<String, dynamic>;
        final productCategoryId = productData['categoryId']?.toString() ?? '';
        return productCategoryId == selectedCategoryId;
      }).toList();
    }

    // Apply search filter if query exists
    if (searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((doc) {
        final productData = doc.data() as Map<String, dynamic>;
        final productName = (productData['productName']?.toString() ?? '').toLowerCase();
        final categoryName = (productData['categoryName']?.toString() ?? '').toLowerCase();
        final description = (productData['productDescription']?.toString() ?? '').toLowerCase();
        
        return productName.contains(searchQuery) ||
               categoryName.contains(searchQuery) ||
               description.contains(searchQuery);
      }).toList();
    }
    
    return filteredProducts;
  }



  void _handleAddToCart(ProductModel product) async {
    // Prevent multiple taps for the same product
    if (_addingToCartProducts.contains(product.productId)) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'Please sign in to add items to cart',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Add to loading set
      setState(() {
        _addingToCartProducts.add(product.productId);
      });

      await _addToCart(product, user.uid);
      Get.snackbar(
        'Success',
        '${product.productName} added to cart',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add item to cart',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      // Remove from loading set
      if (mounted) {
        setState(() {
          _addingToCartProducts.remove(product.productId);
        });
      }
    }
  }

  Future<void> _addToCart(ProductModel product, String userId) async {
    final DocumentReference documentReference = FirebaseFirestore.instance
        .collection('cart')
        .doc(userId)
        .collection('cartOrders')
        .doc(product.productId.toString());

    DocumentSnapshot snapshot = await documentReference.get();

    if (snapshot.exists) {
      int currentQuantity = snapshot['productQuantity'];
      int updatedQuantity = currentQuantity + 1;
      double totalPrice = double.parse(product.isSale
              ? product.salePrice
              : product.fullPrice) *
          updatedQuantity;

      await documentReference.update({
        'productQuantity': updatedQuantity,
        'productTotalPrice': totalPrice
      });
    } else {
      await FirebaseFirestore.instance.collection('cart').doc(userId).set(
        {
          'uId': userId,
          'createdAt': DateTime.now(),
        },
      );

      CartModel cartModel = CartModel(
        productId: product.productId,
        categoryId: product.categoryId,
        productName: product.productName,
        categoryName: product.categoryName,
        salePrice: product.salePrice,
        fullPrice: product.fullPrice,
        productImages: product.productImages,
        deliveryTime: product.deliveryTime,
        isSale: product.isSale,
        productDescription: product.productDescription,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        productQuantity: 1,
        productTotalPrice: double.parse(product.isSale
            ? product.salePrice
            : product.fullPrice),
      );

      await documentReference.set(cartModel.toMap());
    }
  }
}

/// Category picker (Option C, per direct feedback): a full 2-column
/// grid of category cards while nothing is selected, collapsing to a
/// small "< Category name" strip once one is picked - so the grid
/// doesn't permanently eat scroll space above the product list, only
/// while the person is actually choosing.
///
/// Each card shows the category's real photo (categoryImg) once one
/// exists in Firestore - the data model already had this field, it
/// was just never populated or used. Until real photos are uploaded
/// via the admin app, falls back to a brand-tinted icon tile so it
/// never looks broken - the switch to real photos needs no further
/// code changes once they exist.
class CategoryGridSelector extends StatelessWidget {
  final List<QueryDocumentSnapshot> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final Map<String, String> categoryNameMapping;
  final List<String> stableCategoryOrder;

  const CategoryGridSelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.categoryNameMapping,
    required this.stableCategoryOrder,
  });

  IconData _fallbackIcon(String nameLower) {
    if (nameLower.contains('infant') || nameLower.contains('baby')) {
      return Icons.child_friendly;
    }
    if (nameLower.contains('boy') || nameLower.contains('men')) {
      return Icons.man;
    }
    if (nameLower.contains('girl') || nameLower.contains('women')) {
      return Icons.woman;
    }
    return Icons.checkroom;
  }

  @override
  Widget build(BuildContext context) {
    if (selectedCategoryId != null) {
      String selectedName = selectedCategoryId!;
      for (final doc in categories) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['categoryId'] == selectedCategoryId) {
          final rawName = data['categoryName'] as String? ?? selectedCategoryId!;
          selectedName = categoryNameMapping[selectedCategoryId] ?? rawName;
          break;
        }
      }
      return GestureDetector(
        onTap: () => onCategorySelected(null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.arrow_back, size: 16, color: AppColors.brand),
              const SizedBox(width: AppSpacing.sm),
              Text(
                selectedName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedCategories = categories.toList()
      ..sort((a, b) {
        final aId = (a.data() as Map<String, dynamic>)['categoryId'] as String;
        final bId = (b.data() as Map<String, dynamic>)['categoryId'] as String;
        final aIndex = stableCategoryOrder.indexOf(aId);
        final bIndex = stableCategoryOrder.indexOf(bId);
        if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
        if (aIndex != -1) return -1;
        if (bIndex != -1) return 1;
        final aName = (a.data() as Map<String, dynamic>)['categoryName'] as String;
        final bName = (b.data() as Map<String, dynamic>)['categoryName'] as String;
        return aName.compareTo(bName);
      });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.7,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final data = sortedCategories[index].data() as Map<String, dynamic>;
        final categoryId = data['categoryId'] as String;
        String categoryName = data['categoryName'] as String? ?? '';
        categoryName = categoryNameMapping[categoryId] ?? categoryName;
        final categoryImg = (data['categoryImg'] as String?)?.trim() ?? '';
        final hasRealImage = categoryImg.isNotEmpty && categoryImg.toLowerCase() != 'null';

        return GestureDetector(
          onTap: () => onCategorySelected(categoryId),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasRealImage)
                  // FIX: raw Image.network re-fetches from network on
                  // every rebuild once its widget is disposed and
                  // recreated (e.g. navigating away from Home and back)
                  // - Flutter's own image cache is keyed to the widget
                  // lifecycle, not truly persistent across navigation.
                  // CachedNetworkImage keeps a real disk/memory cache
                  // keyed by URL, so the second-and-later loads are
                  // instant instead of re-downloading every time.
                  CachedNetworkImage(
                    imageUrl: categoryImg,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.surfaceMuted),
                    errorWidget: (_, __, ___) => Container(color: AppColors.brandTintBg),
                  )
                else
                  Container(color: AppColors.brandTintBg),
                if (hasRealImage)
                  Container(color: Colors.black.withOpacity(0.28)),
                if (!hasRealImage)
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      _fallbackIcon(categoryName.toLowerCase()),
                      color: AppColors.brand,
                      size: 26,
                    ),
                  ),
                Positioned(
                  left: 10,
                  bottom: hasRealImage ? 8 : 6,
                  right: 10,
                  child: Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasRealImage ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
