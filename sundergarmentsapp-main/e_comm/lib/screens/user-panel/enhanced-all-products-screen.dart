// Enhanced All Products Screen with Category Filters
// Replaces the categories section with a modern filter system

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../utils/app-constant.dart';
import '../../models/product-model.dart';
import '../../models/cart-model.dart';
import '../../models/categories-model.dart';
import '../../widgets/modern/simple_product_card.dart';
import '../../widgets/modern/simple_loading_states.dart';
import 'cart-screen.dart';
import 'product-details-screen.dart';

class EnhancedAllProductsScreen extends StatefulWidget {
  const EnhancedAllProductsScreen({super.key});

  @override
  State<EnhancedAllProductsScreen> createState() => _EnhancedAllProductsScreenState();
}

class _EnhancedAllProductsScreenState extends State<EnhancedAllProductsScreen> {
  String? selectedCategoryId;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Loading state management to prevent multiple taps
  final Set<String> _addingToCartProducts = <String>{};
  
  // Scroll position preservation for filter section
  final ScrollController _filterScrollController = ScrollController();
  double _savedFilterScrollOffset = 0.0;
  
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

  // Categories that don't have products yet
  final Set<String> emptyCategories = {
    'SG-d33996c', // Boy's Bottomwear
    'SG-c9dbc04', // Boy's Topwear
    'SG-b4ca53f', // Girl's BottomWear
    'SG-a6a6a05', // Girl's TopWear
    // 'SG-5c2a4db', // Infant's Wear - REMOVED: This category has products!
    'SG-3ad974f', // Women's Bottomwear
    'SG-4fe40f2', // Women's Top
  };

  // Category name mapping for display
  final Map<String, String> categoryNameMapping = {
    'SG-e2f8f74': 'Men\'s Innerwear', // Rename Innerwear to Men's Innerwear
  };

  @override
  void dispose() {
    _searchController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'All Products',
          style: TextStyle(color: AppConstant.appTextColor),
        ),
        backgroundColor: AppConstant.appMainColor,
        iconTheme: const IconThemeData(color: AppConstant.appTextColor),
        elevation: 2.0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: IconButton(
              onPressed: () => Get.to(() => const CartScreen()),
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: AppConstant.appTextColor,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Section
            _buildSearchAndFilterSection(),
            
            // Products Grid
            Expanded(
              child: _buildProductsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade500,
                ),
                suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade500,
                      ),
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Category Filter Chips
          _buildCategoryFilters(),
        ],
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
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Chip(
                  label: Container(
                    width: 80,
                    height: 20,
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(height: 40.0);
        }

        return CategoryFilterList(
          key: const ValueKey('category_filter_list'),
          categories: snapshot.data!.docs,
          selectedCategoryId: selectedCategoryId,
          onCategorySelected: (categoryId) {
            // Save current scroll position before state change
            _savedFilterScrollOffset = _filterScrollController.offset;
            setState(() {
              selectedCategoryId = categoryId;
            });
          },
          categoryNameMapping: categoryNameMapping,
          stableCategoryOrder: _stableCategoryOrder,
          scrollController: _filterScrollController,
          savedScrollOffset: _savedFilterScrollOffset,
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    // Check if selected category is empty
    if (selectedCategoryId != null && emptyCategories.contains(selectedCategoryId)) {
      return _buildComingSoonState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Products stream error: ${snapshot.error}');
          return SimpleLoadingStates.errorState(
            title: 'Error Loading Products',
            message: 'Please try again later',
            icon: Icons.error_outline,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SimpleLoadingStates.loadingState(
            title: 'Loading Products',
            message: 'Please wait...',
            icon: Icons.shopping_bag_outlined,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SimpleLoadingStates.emptyState(
            title: 'No Products Found',
            message: 'Try adjusting your search or filter',
            icon: Icons.search_off,
          );
        }
        
        // Debug: Print all product categories when no filter is applied
        if (selectedCategoryId == null) {
          for (var doc in snapshot.data!.docs) {
            final productData = doc.data() as Map<String, dynamic>;
            print('Product: ${productData['productName']} - Category: ${productData['categoryId']}');
          }
        }
        
        final products = _filterProducts(snapshot.data!.docs);
        print('After filtering: ${products.length} products');

        if (products.isEmpty) {
          return SimpleLoadingStates.emptyState(
            title: 'No Products Found',
            message: 'Try adjusting your search or filter',
            icon: Icons.search_off,
          );
        }

        print('Building GridView with ${products.length} products');
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final productData = products[index].data() as Map<String, dynamic>;
            
            final productModel = ProductModel(
              productId: productData['productId'] ?? '',
              categoryId: productData['categoryId'] ?? '',
              productName: productData['productName'] ?? '',
              categoryName: productData['categoryName'] ?? '',
              salePrice: productData['salePrice'] ?? '',
              fullPrice: productData['fullPrice'] ?? '',
              productImages: List<String>.from(productData['productImages'] ?? []),
              deliveryTime: productData['deliveryTime'] ?? '',
              isSale: productData['isSale'] ?? false,
              productDescription: productData['productDescription'] ?? '',
              createdAt: productData['createdAt'],
              updatedAt: productData['updatedAt'],
            );

            return SimpleProductCard(
              product: productModel,
              onTap: () => Get.to(() => ProductDetailsScreen(productModel: productModel)),
              onAddToCart: () => _handleAddToCart(productModel),
              isLoading: _addingToCartProducts.contains(productModel.productId),
              showFavorite: false,
            );
          },
        );
      },
    );
  }

  Widget _buildComingSoonState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppConstant.appMainColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 60,
              color: AppConstant.appMainColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Products Coming Soon!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstant.appMainColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'re working hard to bring you amazing products.\nStay tuned for updates!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                selectedCategoryId = null; // Reset to all products
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Browse All Products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.appMainColor,
              foregroundColor: AppConstant.appTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Smart category matching function
  bool _isCategoryMatch(String selectedCategoryId, String productCategoryName, String productCategoryId) {
    // We need to get the selected category name, not just the ID
    // For now, let's use a simple approach based on the category ID patterns
    
    // Extract category name from the selected category ID
    String selectedCategoryName = '';
    
    // Map category IDs to their names (this should match your database)
    final categoryIdToName = {
      'SG-d33996c': 'Boy\'s Bottomwear',
      'SG-c9dbc04': 'Boy\'s Topwear', 
      'SG-b4ca53f': 'Girl\'s BottomWear',
      'SG-a6a6a05': 'Girl\'s TopWear',
      'SG-5c2a4db': 'Infant\'s Wear',
      'SG-e2f8f74': 'Men\'s Innerwear', // Updated name
      'SG-e3e41cb': 'Men\'s Bottomwear',
      'SG-bbb90f2': 'Men\'s TopWear',
      'SG-3ad974f': 'Women\'s Bottomwear',
      'SG-4fe40f2': 'Women\'s Top',
    };
    
    selectedCategoryName = categoryIdToName[selectedCategoryId] ?? selectedCategoryId;
    
    final selectedLower = selectedCategoryName?.toLowerCase() ?? '';
    final productNameLower = productCategoryName.toLowerCase();
    
    print('  🔍 Smart matching debug:');
    print('    Selected Category ID: $selectedCategoryId');
    print('    Selected Category Name: $selectedCategoryName');
    print('    Selected Lower: $selectedLower');
    print('    Product Category Name: $productCategoryName');
    print('    Product Name Lower: $productNameLower');
    
    // Map category patterns for smart matching
    final categoryPatterns = {
      'bottomwear': ['bottomwear', 'bottom', 'pants', 'shorts', 'trousers', 'jeans'],
      'topwear': ['topwear', 'top', 'shirt', 'tshirt', 'polo', 'vest'],
      'innerwear': ['innerwear', 'inner', 'brief', 'underwear', 'vest'],
      'boys': ['boy', 'boys', 'men', 'mens'],
      'girls': ['girl', 'girls', 'women', 'womens'],
      'mens': ['men', 'mens', 'boy', 'boys'],
      'womens': ['women', 'womens', 'girl', 'girls'],
      'infants': ['infant', 'infants', 'baby', 'babies'],
    };
    
    // Check for exact category name matches
    for (final entry in categoryPatterns.entries) {
      final categoryKey = entry.key;
      final patterns = entry.value;
      
      // If selected category contains this pattern
      if (selectedLower.contains(categoryKey)) {
        // Check if product category matches any of the patterns
        for (final pattern in patterns) {
          if (productNameLower.contains(pattern)) {
            print('  ✅ Smart category match: $categoryKey -> $pattern');
            return true;
          }
        }
      }
    }
    
    // Direct category ID mapping for Boy's/Girl's categories
    if (selectedCategoryId == 'SG-d33996c') { // Boy's Bottomwear
      if (productCategoryId == 'SG-e3e41cb') { // Men's Bottomwear
        print('  ✅ Direct ID match: Boy\'s Bottomwear -> Men\'s Bottomwear');
        return true;
      }
    }
    
    if (selectedCategoryId == 'SG-c9dbc04') { // Boy's Topwear
      if (productCategoryId == 'SG-bbb90f2') { // Men's TopWear
        print('  ✅ Direct ID match: Boy\'s Topwear -> Men\'s TopWear');
        return true;
      }
    }
    
    if (selectedCategoryId == 'SG-b4ca53f') { // Girl's BottomWear
      if (productCategoryId == 'SG-3ad974f') { // Women's Bottomwear
        print('  ✅ Direct ID match: Girl\'s BottomWear -> Women\'s Bottomwear');
        return true;
      }
    }
    
    if (selectedCategoryId == 'SG-a6a6a05') { // Girl's TopWear
      if (productCategoryId == 'SG-4fe40f2') { // Women's Top
        print('  ✅ Direct ID match: Girl\'s TopWear -> Women\'s Top');
        return true;
      }
    }
    
    // Special case: Boy's Bottomwear should match Men's Bottomwear
    if (selectedLower.contains('boy') && selectedLower.contains('bottomwear')) {
      if (productNameLower.contains('men') && productNameLower.contains('bottomwear')) {
        print('  ✅ Special match: Boy\'s Bottomwear -> Men\'s Bottomwear');
        return true;
      }
    }
    
    // Special case: Boy's Topwear should match Men's Topwear
    if (selectedLower.contains('boy') && selectedLower.contains('topwear')) {
      if (productNameLower.contains('men') && productNameLower.contains('topwear')) {
        print('  ✅ Special match: Boy\'s Topwear -> Men\'s Topwear');
        return true;
      }
    }
    
    // Special case: Girl's BottomWear should match Women's Bottomwear
    if (selectedLower.contains('girl') && selectedLower.contains('bottomwear')) {
      if (productNameLower.contains('women') && productNameLower.contains('bottomwear')) {
        print('  ✅ Special match: Girl\'s BottomWear -> Women\'s Bottomwear');
        return true;
      }
    }
    
    // Special case: Girl's TopWear should match Women's Top
    if (selectedLower.contains('girl') && selectedLower.contains('topwear')) {
      if (productNameLower.contains('women') && productNameLower.contains('top')) {
        print('  ✅ Special match: Girl\'s TopWear -> Women\'s Top');
        return true;
      }
    }
    
    print('  ❌ No match found');
    return false;
  }

  List<QueryDocumentSnapshot> _filterProducts(List<QueryDocumentSnapshot> products) {
    List<QueryDocumentSnapshot> filteredProducts = products;
    
        // Apply category filter if selected
        if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
          print('🔍 Applying category filter for: $selectedCategoryId');
          print('🔍 Total products before filtering: ${filteredProducts.length}');
      filteredProducts = filteredProducts.where((doc) {
        final productData = doc.data() as Map<String, dynamic>;
        final productCategoryId = productData['categoryId']?.toString() ?? '';
        final productCategoryName = productData['categoryName']?.toString() ?? '';
        final productName = productData['productName']?.toString() ?? '';
        
        print('Checking product: $productName');
        print('  Product categoryId: $productCategoryId');
        print('  Product categoryName: $productCategoryName');
        print('  Selected categoryId: $selectedCategoryId');
        
        // Check if categoryId matches (including old format)
        if (productCategoryId == selectedCategoryId || 
            productCategoryId == 'RxString: $selectedCategoryId') {
          print('  ✅ Direct categoryId match!');
          return true;
        }
        
        // Check for category name matching (case-insensitive)
        final productCategoryNameLower = productCategoryName.toLowerCase();
        final selectedCategoryName = categoryNameMapping[selectedCategoryId] ?? selectedCategoryId;
        final selectedCategoryNameLower = selectedCategoryName?.toLowerCase() ?? '';
        
        if (productCategoryNameLower.contains(selectedCategoryNameLower) ||
            selectedCategoryNameLower.contains(productCategoryNameLower)) {
          print('  ✅ Category name match: $productCategoryName -> $selectedCategoryName');
          return true;
        }
        
        // Special handling for Infant's Wear
        if (selectedCategoryId == 'SG-5c2a4db') { // Infant's Wear filter
          final productNameLower = productName.toLowerCase();
          if (productCategoryNameLower.contains('infant') || 
              productCategoryNameLower.contains('baby') ||
              productNameLower.contains('infant') ||
              productNameLower.contains('baby')) {
            print('  ✅ Infant\'s Wear match: $productCategoryName / $productName');
            return true;
          }
        }
        
        // Smart category matching for all filter categories
        final isMatch = _isCategoryMatch(selectedCategoryId!, productCategoryName, productCategoryId);
        if (isMatch) {
          print('  ✅ Smart category match!');
        } else {
          print('  ❌ No match');
        }
        return isMatch;
      }).toList();
      
      print('🔍 Products after filtering: ${filteredProducts.length}');
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

class CategoryFilterList extends StatefulWidget {
  final List<QueryDocumentSnapshot> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final Map<String, String> categoryNameMapping;
  final List<String> stableCategoryOrder;
  final ScrollController scrollController;
  final double savedScrollOffset;

  const CategoryFilterList({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.categoryNameMapping,
    required this.stableCategoryOrder,
    required this.scrollController,
    required this.savedScrollOffset,
  }) : super(key: key);

  @override
  State<CategoryFilterList> createState() => _CategoryFilterListState();
}

class _CategoryFilterListState extends State<CategoryFilterList> {
  @override
  void initState() {
    super.initState();
    // Restore saved scroll position after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.savedScrollOffset > 0 && widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(widget.savedScrollOffset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort categories by stable order
    final sortedCategories = widget.categories.toList()
      ..sort((a, b) {
        final aId = (a.data() as Map<String, dynamic>)['categoryId'] as String;
        final bId = (b.data() as Map<String, dynamic>)['categoryId'] as String;
        
        final aIndex = widget.stableCategoryOrder.indexOf(aId);
        final bIndex = widget.stableCategoryOrder.indexOf(bId);
        
        // If both are in stable order, sort by their position
        if (aIndex != -1 && bIndex != -1) {
          return aIndex.compareTo(bIndex);
        }
        // If only one is in stable order, prioritize it
        if (aIndex != -1) return -1;
        if (bIndex != -1) return 1;
        // If neither is in stable order, sort by category name for consistency
        final aName = (a.data() as Map<String, dynamic>)['categoryName'] as String;
        final bName = (b.data() as Map<String, dynamic>)['categoryName'] as String;
        return aName.compareTo(bName);
      });

    // Build category chips list
    final categoryChips = <Widget>[
      // "All Products" chip
      Padding(
        key: const ValueKey('all_products_chip'),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: FilterChip(
          label: const Text('All Products'),
          selected: widget.selectedCategoryId == null,
          onSelected: (selected) {
            if (selected) {
              widget.onCategorySelected(null);
            }
          },
          selectedColor: AppConstant.appMainColor.withOpacity(0.2),
          checkmarkColor: AppConstant.appMainColor,
          labelStyle: TextStyle(
            color: widget.selectedCategoryId == null 
              ? AppConstant.appMainColor 
              : Colors.grey.shade700,
            fontWeight: widget.selectedCategoryId == null 
              ? FontWeight.bold 
              : FontWeight.normal,
          ),
        ),
      ),
      
      // Category chips
      ...sortedCategories.map((doc) {
        final categoryData = doc.data() as Map<String, dynamic>;
        final categoryId = categoryData['categoryId'] as String;
        String categoryName = categoryData['categoryName'] as String;
        
        // Apply category name mapping
        categoryName = widget.categoryNameMapping[categoryId] ?? categoryName;
        
        final isSelected = widget.selectedCategoryId == categoryId;

        print('Category: $categoryName (ID: $categoryId, Selected: $isSelected)');

        return Padding(
          key: ValueKey('category_$categoryId'),
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: FilterChip(
            label: Text(
              categoryName,
              style: TextStyle(
                color: isSelected 
                  ? AppConstant.appMainColor 
                  : Colors.grey.shade700,
                fontWeight: isSelected 
                  ? FontWeight.bold 
                  : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              print('Category selected: $categoryName (ID: $categoryId, Selected: $selected)');
              widget.onCategorySelected(selected ? categoryId : null);
            },
            selectedColor: AppConstant.appMainColor.withOpacity(0.2),
            checkmarkColor: AppConstant.appMainColor,
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected 
                  ? AppConstant.appMainColor 
                  : Colors.transparent,
              ),
            ),
          ),
        );
      }).toList(),
    ];

    return SizedBox(
      height: 40.0,
      child: ListView(
        key: const ValueKey('category_filters'),
        controller: widget.scrollController,
        scrollDirection: Axis.horizontal,
        children: categoryChips,
      ),
    );
  }
}