// ignore_for_file: file_names, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, prefer_const_constructors, must_be_immutable, sized_box_for_whitespace, prefer_is_empty, avoid_print, await_only_futures

import 'dart:io';
import 'package:e_comm_admin/models/product-model.dart';
import 'package:e_comm_admin/utils/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../controllers/category-dropdown_controller.dart';
import '../controllers/is-sale-controller.dart';
import '../controllers/products-images-controller.dart';
import '../services/generate-ids-service.dart';
import '../widgets/dropdown-categories-widget.dart';

class AddProductScreen extends StatefulWidget {
  AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {

  AddProductImagesController addProductImagesController =
      Get.put(AddProductImagesController());

  CategoryDropDownController categoryDropDownController =
      Get.put(CategoryDropDownController());

  IsSaleController isSaleController = Get.put(IsSaleController());

  TextEditingController productNameController = TextEditingController();
  TextEditingController salePriceController = TextEditingController();
  TextEditingController fullPriceController = TextEditingController();
  // Dynamic description lines
  List<String> descriptionLines = [''];

  void addDescriptionLine() {
    setState(() {
      descriptionLines.add('');
    });
  }

  void removeDescriptionLine(int index) {
    if (descriptionLines.length > 1) {
      setState(() {
        descriptionLines.removeAt(index);
      });
    }
  }

  String getFormattedDescription() {
    return descriptionLines
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppConstant.appTextColor,
        ),
        backgroundColor: AppConstant.appMainColor,
        title: Text(
          'Add Products',
          style: TextStyle(color: AppConstant.appTextColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Select Images"),
                      ElevatedButton(
                        onPressed: () {
                          addProductImagesController.showImagesPickerDialog();
                        },
                        child: Text("Select Images"),
                      )
                    ],
                  ),
                ),

                //show Images
                GetBuilder<AddProductImagesController>(
                  init: AddProductImagesController(),
                  builder: (imageController) {
                    return imageController.selectedIamges.length > 0
                        ? Container(
                            width: MediaQuery.of(context).size.width - 20,
                            height: Get.height / 2.5,
                            child: GridView.builder(
                              itemCount: imageController.selectedIamges.length,
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.0,
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(addProductImagesController
                                            .selectedIamges[index].path),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          imageController.removeImages(index);
                                        },
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
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
                                );
                              },
                            ),
                          )
                        : SizedBox.shrink();
                  },
                ),

                //show categories drop down
                DropDownCategoriesWiidget(),

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
                SizedBox(height: 10.0),

                Obx(() {
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
                }),

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
                            onPressed: addDescriptionLine,
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
                      Column(
                        children: descriptionLines.asMap().entries.map((entry) {
                          final index = entry.key;
                          final line = entry.value;
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
                                        descriptionLines[index] = value;
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
                                if (descriptionLines.length > 1)
                                  Container(
                                    margin: EdgeInsets.only(left: 8),
                                    child: GestureDetector(
                                      onTap: () => removeDescriptionLine(index),
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
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (addProductImagesController.selectedIamges.isEmpty) {
                      Get.snackbar(
                        'Validation Error',
                        'Please select at least one image.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppConstant.appScendoryColor,
                        colorText: AppConstant.appTextColor,
                      );
                      return;
                    }
                    if (productNameController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Validation Error',
                        'Please enter a product name.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppConstant.appScendoryColor,
                        colorText: AppConstant.appTextColor,
                      );
                      return;
                    }
                    if (fullPriceController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Validation Error',
                        'Please enter product price.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppConstant.appScendoryColor,
                        colorText: AppConstant.appTextColor,
                      );
                      return;
                    }
                    if (getFormattedDescription().isEmpty) {
                      Get.snackbar(
                        'Validation Error',
                        'Please enter product description.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppConstant.appScendoryColor,
                        colorText: AppConstant.appTextColor,
                      );
                      return;
                    }
                    if (categoryDropDownController.selectedCategoryId?.value == null) {
                      Get.snackbar(
                        'Validation Error',
                        'Please select category.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppConstant.appScendoryColor,
                        colorText: AppConstant.appTextColor,
                      );
                      return;
                    }
                    try {
                      EasyLoading.show();
                      await addProductImagesController.uploadFunction(
                          addProductImagesController.selectedIamges);
                      print(addProductImagesController.arrImagesUrl);

                      String productId =
                          await GenerateIds().generateProductId();

                      ProductModel productModel = ProductModel(
                        productId: productId,
                        categoryId: categoryDropDownController
                            .selectedCategoryId?.value ?? '',
                        productName: productNameController.text.trim(),
                        categoryName: categoryDropDownController
                            .selectedCategoryName?.value ?? '',
                        salePrice: isSaleController.isSale.value
                            ? salePriceController.text.trim()
                            : '',
                        fullPrice: fullPriceController.text.trim(),
                        productImages: addProductImagesController.arrImagesUrl,
                        deliveryTime: '',
                        isSale: isSaleController.isSale.value,
                        productDescription: getFormattedDescription(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      await FirebaseFirestore.instance
                          .collection('products')
                          .doc(productId)
                          .set(productModel.toMap());
                      EasyLoading.dismiss();

                      Get.back();
                      //await Get.offAll(() => AllProductsScreen());
                    } catch (e) {
                      print("error : $e");
                    }
                  },
                  child: Text("Upload"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
