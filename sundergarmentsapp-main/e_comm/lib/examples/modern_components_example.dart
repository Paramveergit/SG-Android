// Example implementation of modern components
// This file demonstrates how to use the new components in your app

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/product-model.dart';
import '../utils/app-constant.dart';
import '../widgets/modern/simple_loading_states.dart';
import '../widgets/modern/simple_product_card.dart';

/// Example screen showing how to use modern components
class ModernComponentsExample extends StatelessWidget {
  const ModernComponentsExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Components'),
        backgroundColor: AppConstant.appMainColor,
        foregroundColor: AppConstant.appTextColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Modern Loading States'),
            _buildLoadingStatesExample(),
            
            _buildSectionHeader('Modern Product Cards'),
            _buildProductCardsExample(),
            
            _buildSectionHeader('Error & Empty States'),
            _buildErrorStatesExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingStatesExample() {
    return Column(
      children: [
        // Brand Spinner
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Brand Spinner:'),
              const SizedBox(width: 16.0),
              SimpleLoadingStates.brandSpinner(),
              const SizedBox(width: 16.0),
              SimpleLoadingStates.brandSpinner(size: 36.0),
            ],
          ),
        ),
        
        // Skeleton Cards
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              SimpleLoadingStates.skeletonCard(width: 100, height: 50),
              const SizedBox(width: 16.0),
              SimpleLoadingStates.skeletonCard(width: 150, height: 50),
            ],
          ),
        ),
        
        // Product Card Skeleton
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              SimpleLoadingStates.productCardSkeleton(width: 150),
              const SizedBox(width: 16.0),
              SimpleLoadingStates.productCardSkeleton(width: 150),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCardsExample() {
    return FutureBuilder(
      // This is just an example - replace with your actual data source
      future: FirebaseFirestore.instance
          .collection('products')
          .limit(4)
          .get(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return SimpleLoadingStates.errorState(
            title: 'Error Loading Products',
            message: 'Please try again later',
            onRetry: () => Get.back(),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SimpleLoadingStates.gridLoadingState(
            itemCount: 4,
            crossAxisCount: 2,
          );
        }
        
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return SimpleLoadingStates.emptyState(
            title: 'No Products Found',
            message: 'Try searching for something else',
          );
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final productData = snapshot.data!.docs[index];
            
            ProductModel productModel = ProductModel(
              productId: productData['productId'],
              categoryId: productData['categoryId'],
              productName: productData['productName'],
              categoryName: productData['categoryName'],
              salePrice: productData['salePrice'],
              fullPrice: productData['fullPrice'],
              productImages: productData['productImages'],
              deliveryTime: productData['deliveryTime'],
              isSale: productData['isSale'],
              productDescription: productData['productDescription'],
              createdAt: productData['createdAt'],
              updatedAt: productData['updatedAt'],
            );
            
            return SimpleProductCard(
              product: productModel,
              onTap: () {},
              onFavorite: () {},
              onAddToCart: () {},
              showFavorite: true,
            );
          },
        );
      },
    );
  }

  Widget _buildErrorStatesExample() {
    return Column(
      children: [
        // Error State
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SimpleLoadingStates.errorState(
            title: 'Network Error',
            message: 'Please check your internet connection and try again',
            onRetry: () {},
          ),
        ),
        
        // Empty State
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SimpleLoadingStates.emptyState(
            title: 'No Items in Cart',
            message: 'Add some products to your cart to see them here',
            icon: Icons.shopping_cart_outlined,
          ),
        ),
      ],
    );
  }
}




