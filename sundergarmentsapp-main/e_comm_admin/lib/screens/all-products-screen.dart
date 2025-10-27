// ignore_for_file: file_names, prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, avoid_print

import 'package:e_comm_admin/models/product-model.dart';
import 'package:e_comm_admin/utils/constant.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:get/get.dart';
import '../controllers/category-dropdown_controller.dart';
import '../controllers/is-sale-controller.dart';
import 'add-products-screen.dart';
import 'edit-product-screen.dart';
import 'product-detail-screen.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  String selectedCategoryFilter = 'All'; // Default filter
  List<Map<String, dynamic>> availableCategories = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Loads categories from Firestore for filtering
  Future<void> _loadCategories() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      List<Map<String, dynamic>> categoriesList = [];

      for (var doc in querySnapshot.docs) {
        categoriesList.add({
          'categoryId': doc.id,
          'categoryName': doc['categoryName'] ?? '',
          'categoryImg': doc['categoryImg'] ?? '',
        });
      }

      setState(() {
        availableCategories = categoriesList;
        isLoadingCategories = false;
      });
    } catch (e) {
      print("Error loading categories: $e");
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppConstant.appTextColor,
        ),
        backgroundColor: AppConstant.appMainColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Products',
              style: TextStyle(color: AppConstant.appTextColor),
            ),
            if (selectedCategoryFilter != 'All')
              Text(
                'Category: $selectedCategoryFilter',
                style: TextStyle(
                  color: AppConstant.appTextColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          // Category Filter Button
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: AppConstant.appTextColor,
            ),
            onSelected: (String value) {
              setState(() {
                selectedCategoryFilter = value;
              });
            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<String>> items = [
                PopupMenuItem<String>(
                  value: 'All',
                  child: Row(
                    children: [
                      Icon(
                        Icons.list,
                        color: Colors.grey,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text('All Categories'),
                      if (selectedCategoryFilter == 'All') ...[
                        SizedBox(width: 8),
                        Icon(Icons.check, color: Colors.green, size: 16),
                      ],
                    ],
                  ),
                ),
                PopupMenuDivider(),
              ];

              // Add category items
              for (var category in availableCategories) {
                items.add(
                  PopupMenuItem<String>(
                    value: category['categoryName'],
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundImage: category['categoryImg'] != null && category['categoryImg'].isNotEmpty
                              ? CachedNetworkImageProvider(category['categoryImg'])
                              : null,
                          child: category['categoryImg'] == null || category['categoryImg'].isEmpty
                              ? Icon(Icons.category, size: 12, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category['categoryName'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selectedCategoryFilter == category['categoryName']) ...[
                          SizedBox(width: 8),
                          Icon(Icons.check, color: Colors.green, size: 16),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return items;
            },
          ),
          // Add Product Button
          GestureDetector(
            onTap: () => Get.to(() => AddProductScreen()),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Container(
              child: Center(
                child: Text('Error occurred while fetching products!'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          }
          if (snapshot.data!.docs.isEmpty) {
            return Container(
              child: Center(
                child: Text('No products found!'),
              ),
            );
          }
          if (snapshot.data != null) {
            // Filter products based on selected category
            List<QueryDocumentSnapshot> filteredProducts = snapshot.data!.docs.where((doc) {
              if (selectedCategoryFilter == 'All') return true;
              
              final data = doc.data() as Map<String, dynamic>;
              final productCategoryName = data['categoryName'] ?? '';
              
              return productCategoryName == selectedCategoryFilter;
            }).toList();

            if (filteredProducts.isEmpty && selectedCategoryFilter != 'All') {
              return Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No products found in "$selectedCategoryFilter"',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try selecting a different category',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final data = filteredProducts[index].data() as Map<String, dynamic>;
                ProductModel productModel = ProductModel.fromMap(data);
                
                return SwipeActionCell(
                  key: ObjectKey(productModel.productId),
                  trailingActions: <SwipeAction>[
                    SwipeAction(
                        title: "Delete",
                        onTap: (CompletionHandler handler) async {
                          await Get.defaultDialog(
                            title: "Delete Product",
                            content: Text(
                                "Are you sure you want to delete this product?"),
                            textCancel: "Cancel",
                            textConfirm: "Delete",
                            contentPadding: EdgeInsets.all(10.0),
                            confirmTextColor: Colors.white,
                            onCancel: () {},
                            onConfirm: () async {
                              Get.back(); // Close the dialog
                              EasyLoading.show(status: 'Please wait..');
                              await deleteImagesFromFirebase(
                                productModel.productImages,
                              );
                              await FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(productModel.productId)
                                  .delete();
                              EasyLoading.dismiss();
                            },
                            buttonColor: Colors.red,
                            cancelTextColor: Colors.black,
                          );
                        },
                        color: Colors.red),
                  ],
                  child: Card(
                    elevation: 5,
                    child: ListTile(
                      onTap: () {
                        Get.to(() => SingleProductDetailScreen(
                            productModel: productModel));
                      },
                      leading: CircleAvatar(
                        backgroundColor: AppConstant.appScendoryColor,
                        backgroundImage: _getProductImage(productModel.productImages),
                        child: !productModel.hasImages
                            ? Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 30,
                              )
                            : null,
                      ),
                      title: Text(productModel.productName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productModel.productId),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              productModel.categoryName.isNotEmpty 
                                  ? productModel.categoryName 
                                  : 'Uncategorized',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: GestureDetector(
                          onTap: () {
                            final editProdouctCategory =
                                Get.put(CategoryDropDownController());
                            final isSaleController =
                                Get.put(IsSaleController());
                            editProdouctCategory
                                .setOldValue(productModel.categoryId);
                            isSaleController
                                .setIsSaleOldValue(productModel.isSale);
                            Get.to(() =>
                                EditProductScreen(productModel: productModel));
                          },
                          child: Icon(Icons.edit)),
                    ),
                  ),
                );
              },
            );
          }

          return Container();
        },
      ),
    );
  }

  /// Safely gets the first product image with proper error handling
  /// Returns null if no images are available or if there's an error
  ImageProvider? _getProductImage(List<String> productImages) {
    try {
      final firstImageUrl = productImages.isNotEmpty ? productImages[0] : null;
      if (firstImageUrl != null && firstImageUrl.isNotEmpty) {
        return CachedNetworkImageProvider(
          firstImageUrl,
          errorListener: (err) {
            print('Error loading image: $err');
          },
        );
      }
    } catch (e) {
      print('Error accessing product image: $e');
    }
    return null;
  }

  Future deleteImagesFromFirebase(List<String> imagesUrls) async {
    final FirebaseStorage storage = FirebaseStorage.instance;

    for (String imageUrl in imagesUrls) {
      try {
        Reference reference = storage.refFromURL(imageUrl);
        await reference.delete();
      } catch (e) {
        print("Error deleting image $imageUrl: $e");
      }
    }
  }
}
