// ignore_for_file: file_names, prefer_const_constructors, sized_box_for_whitespace, avoid_unnecessary_containers

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_comm/screens/user-panel/single-category-products-screen.dart';
import 'package:e_comm/utils/app-constant.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_card/image_card.dart';

import '../../models/categories-model.dart';

class CategoryWidget extends StatelessWidget {
  const CategoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height / 6.0,
      child: FutureBuilder(
        future: FirebaseFirestore.instance.collection('categories').orderBy('createdAt', descending: true).limit(10).get(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error"),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: Get.height / 5,
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No category found!"),
            );
          }

          if (snapshot.data != null) {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              cacheExtent: 200.0, // Optimize cache for better performance
              itemBuilder: (context, index) {
                return RepaintBoundary(
                  child: _buildCategoryItem(context, index, snapshot.data!.docs),
                );
              },
            );
          }

          return Container();
        },
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, int index, List<QueryDocumentSnapshot> docs) {
    final categoryData = docs[index].data() as Map<String, dynamic>;
    String categoryName = categoryData['categoryName'] as String;
    
    // Apply category name mapping for Innerwear
    if (categoryData['categoryId'] == 'SG-e2f8f74') {
      categoryName = 'Men\'s Innerwear';
    }
    
    CategoriesModel categoriesModel = CategoriesModel(
      categoryId: categoryData['categoryId'],
      categoryImg: categoryData['categoryImg'],
      categoryName: categoryName, // Use the mapped name
      createdAt: categoryData['createdAt'],
      updatedAt: categoryData['updatedAt'],
    );
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.to(() => AllSingleCategoryProductsScreen(
              categoryId: categoriesModel.categoryId)),
          child: Padding(
            padding: EdgeInsets.all(5.0),
            child: Container(
              child: FillImageCard(
                borderRadius: 20.0,
                width: Get.width / 3.5,
                heightImage: Get.height / 12,
                imageProvider: CachedNetworkImageProvider(
                  categoriesModel.categoryImg,
                ),
                title: Center(
                  child: Text(
                    categoriesModel.categoryName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 12.0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
