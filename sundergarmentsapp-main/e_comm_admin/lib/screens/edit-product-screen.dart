// ignore_for_file: file_names, must_be_immutable, avoid_unnecessary_containers, prefer_const_constructors, sized_box_for_whitespace, unused_import

import 'dart:io';
import 'package:e_comm_admin/controllers/edit-product-controller.dart';
import 'package:e_comm_admin/models/product-model.dart';
import 'package:e_comm_admin/utils/constant.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../controllers/category-dropdown_controller.dart';
import '../controllers/is-sale-controller.dart';

class EditProductScreen extends StatefulWidget {
  ProductModel productModel;
  EditProductScreen({super.key, required this.productModel});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  IsSaleController isSaleController = Get.put(IsSaleController());
  CategoryDropDownController categoryDropDownController =
      Get.put(CategoryDropDownController());
  TextEditingController productNameController = TextEditingController();
  TextEditingController salePriceController = TextEditingController();
  TextEditingController fullPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    productNameController.text = widget.productModel.productName;
    salePriceController.text = widget.productModel.salePrice;
    fullPriceController.text = widget.productModel.fullPrice;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EditProductController>(
      init: EditProductController(productModel: widget.productModel),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(
              color: AppConstant.appTextColor,
            ),
            backgroundColor: AppConstant.appMainColor,
            title: Text(
              "Edit Product ${widget.productModel.productName}",
              style: TextStyle(color: AppConstant.appTextColor),
            ),
          ),
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  // Image Management Section
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Product Images",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                controller.showImagesPickerDialog();
                              },
                              icon: Icon(Icons.add_photo_alternate, size: 18),
                              label: Text("Add Images"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstant.appMainColor,
                                foregroundColor: AppConstant.appTextColor,
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Obx(() {
                          return controller.images.isNotEmpty
                              ? Container(
                                  width: MediaQuery.of(context).size.width - 20,
                                  height: Get.height / 2.5,
                                  child: GridView.builder(
                                    itemCount: controller.images.length,
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 1.0, // Perfect square
                                    ),
                                    itemBuilder: (BuildContext context, int index) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                child: CachedNetworkImage(
                                                  imageUrl: controller.images[index],
                                                  fit: BoxFit.cover, // Ensures even coverage
                                                  placeholder: (context, url) =>
                                                      Container(
                                                        color: Colors.grey[100],
                                                        child: Center(
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                      ),
                                                  errorWidget: (context, url, error) =>
                                                      Container(
                                                        color: Colors.grey[200],
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.error,
                                                            size: 30,
                                                            color: Colors.grey[400],
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 6,
                                              top: 6,
                                              child: GestureDetector(
                                                onTap: () async {
                                                  EasyLoading.show();
                                                  await controller.deleteImagesFromStorage(
                                                      controller.images[index].toString());
                                                  await controller.deleteImageFromFireStore(
                                                      controller.images[index].toString(),
                                                      widget.productModel.productId);
                                                  EasyLoading.dismiss();
                                                },
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.3),
                                                        spreadRadius: 1,
                                                        blurRadius: 2,
                                                        offset: Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!, width: 1),
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[50],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image, size: 40, color: Colors.grey[400]),
                                        SizedBox(height: 5),
                                        Text(
                                          "No images added yet",
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                        }),
                      ],
                    ),
                  ),

                  //drop down
                  GetBuilder<CategoryDropDownController>(
                    init: CategoryDropDownController(),
                    builder: (categoriesDropDownController) {
                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0.0),
                            child: Card(
                              elevation: 10,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: DropdownButton<String>(
                                  value: categoriesDropDownController
                                      .selectedCategoryId?.value,
                                  items: categoriesDropDownController.categories
                                      .map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category['categoryId'],
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              category['categoryImg']
                                                  .toString(),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Text(category['categoryName']),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? selectedValue) async {
                                    categoriesDropDownController
                                        .setSelectedCategory(selectedValue);
                                    String? categoryName =
                                        await categoriesDropDownController
                                            .getCategoryName(selectedValue);
                                    categoriesDropDownController
                                        .setSelectedCategoryName(categoryName);
                                  },
                                  hint: const Text(
                                    'Select a category',
                                  ),
                                  isExpanded: true,
                                  elevation: 10,
                                  underline: const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  //isSale
                  GetBuilder<IsSaleController>(
                    init: IsSaleController(),
                    builder: (isSaleController) {
                      return Card(
                        elevation: 10,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Flash Sale"),
                              Switch(
                                value: isSaleController.isSale.value,
                                activeColor: AppConstant.appMainColor,
                                onChanged: (value) {
                                  isSaleController.toggleIsSale(value);
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  //form
                  SizedBox(height: 10.0),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Product Name",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          height: 65,
                    child: TextFormField(
                      cursorColor: AppConstant.appMainColor,
                      textInputAction: TextInputAction.next,
                      controller: productNameController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.0,
                        ),
                              hintText: "Enter product name",
                        hintStyle: TextStyle(fontSize: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                      ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  GetBuilder<IsSaleController>(
                    init: IsSaleController(),
                    builder: (isSaleController) {
                      return isSaleController.isSale.value
                          ? Container(
                              margin: EdgeInsets.symmetric(horizontal: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Flash Price",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Container(
                                    height: 65,
                              child: TextFormField(
                                cursorColor: AppConstant.appMainColor,
                                textInputAction: TextInputAction.next,
                                controller: salePriceController,
                                      keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                  ),
                                        hintText: "Enter flash sale price",
                                  hintStyle: TextStyle(fontSize: 12.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink();
                    },
                  ),

                  // Obx(() {
                  //   return isSaleController.isSale.value
                  //       ? Container(
                  //           height: 65,
                  //           margin: EdgeInsets.symmetric(horizontal: 10.0),
                  //           child: TextFormField(
                  //             cursorColor: AppConstant.appMainColor,
                  //             textInputAction: TextInputAction.next,
                  //             controller: salePriceController
                  //               ..text = productModel.salePrice,
                  //             decoration: InputDecoration(
                  //               contentPadding: EdgeInsets.symmetric(
                  //                 horizontal: 10.0,
                  //               ),
                  //               hintText: "Sale Price",
                  //               hintStyle: TextStyle(fontSize: 12.0),
                  //               border: OutlineInputBorder(
                  //                 borderRadius: BorderRadius.all(
                  //                   Radius.circular(10.0),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         )
                  //       : SizedBox.shrink();
                  // }),

                  SizedBox(height: 10.0),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          height: 65,
                    child: TextFormField(
                      cursorColor: AppConstant.appMainColor,
                      textInputAction: TextInputAction.next,
                      controller: fullPriceController,
                            keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.0,
                        ),
                              hintText: "Enter regular price",
                        hintStyle: TextStyle(fontSize: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                      ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SizedBox(height: 10.0),
                  // Container(
                  //   height: 65,
                  //   margin: EdgeInsets.symmetric(horizontal: 10.0),
                  //   child: TextFormField(
                  //     cursorColor: AppConstant.appMainColor,
                  //     textInputAction: TextInputAction.next,
                  //     controller: deliveryTimeController,
                  //     decoration: InputDecoration(
                  //       contentPadding: EdgeInsets.symmetric(
                  //         horizontal: 10.0,
                  //       ),
                  //       hintText: "Delivery Time",
                  //       hintStyle: TextStyle(fontSize: 12.0),
                  //       border: OutlineInputBorder(
                  //         borderRadius: BorderRadius.all(
                  //           Radius.circular(10.0),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  SizedBox(height: 10.0),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Description",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                controller.addDescriptionLine();
                              },
                              icon: Icon(Icons.add, size: 16),
                              label: Text("Add Line"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstant.appMainColor,
                                foregroundColor: AppConstant.appTextColor,
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size(0, 32),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Obx(() {
                          return Column(
                            children: controller.descriptionLines.asMap().entries.map((entry) {
                              int index = entry.key;
                              String line = entry.value;
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 50,
                    child: TextFormField(
                      cursorColor: AppConstant.appMainColor,
                                          textInputAction: TextInputAction.next,
                                          initialValue: line,
                                          onChanged: (value) {
                                            controller.updateDescriptionLine(index, value);
                                          },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.0,
                                              vertical: 10.0,
                        ),
                                            hintText: "Enter description line ${index + 1}",
                        hintStyle: TextStyle(fontSize: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                      ),
                                        ),
                                      ),
                                    ),
                                    if (controller.descriptionLines.length > 1)
                                      Container(
                                        margin: EdgeInsets.only(left: 8),
                                        child: GestureDetector(
                                          onTap: () {
                                            controller.removeDescriptionLine(index);
                                          },
                                          child: Container(
                                            width: 40,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.red[200]!),
                                            ),
                                            child: Icon(
                                              Icons.remove,
                                              color: Colors.red[600],
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      //product Model

                      EasyLoading.show();
                      ProductModel newProductModel = ProductModel(
                        productId: widget.productModel.productId,
                        categoryId: categoryDropDownController
                            .selectedCategoryId?.value ?? widget.productModel.categoryId,
                        productName: productNameController.text.trim(),
                        categoryName: categoryDropDownController
                            .selectedCategoryName?.value ?? widget.productModel.categoryName,
                        salePrice: isSaleController.isSale.value
                            ? salePriceController.text.trim()
                            : '',
                        fullPrice: fullPriceController.text.trim(),
                        productImages: widget.productModel.productImages,
                        deliveryTime: '',
                        isSale: isSaleController.isSale.value,
                        productDescription:
                            controller.getFormattedDescription(),
                        createdAt: widget.productModel.createdAt,
                        updatedAt: DateTime.now(),
                      );

                      await FirebaseFirestore.instance
                          .collection('products')
                          .doc(widget.productModel.productId)
                          .update(newProductModel.toMap());

                      EasyLoading.dismiss();

                      Get.back();
                      //await Get.offAll(() => AllProductsScreen());
                    },
                    child: Text("Update"),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
