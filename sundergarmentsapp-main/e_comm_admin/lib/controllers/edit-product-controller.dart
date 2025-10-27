// ignore_for_file: file_names, avoid_print

import 'dart:io';
import 'package:e_comm_admin/models/product-model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class EditProductController extends GetxController {
  ProductModel productModel;
  EditProductController({
    required this.productModel,
  });
  RxList<String> images = <String>[].obs;
  RxList<String> descriptionLines = <String>[].obs;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage storageRef = FirebaseStorage.instance;

  @override
  void onInit() {
    super.onInit();
    getRealTimeImages();
    initializeDescriptionLines();
  }

  // Initialize description lines from product description
  void initializeDescriptionLines() {
    if (productModel.productDescription.isNotEmpty) {
      // Split by common separators and filter out empty lines
      List<String> lines = productModel.productDescription
          .split(RegExp(r'[\n\r]+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      if (lines.isNotEmpty) {
        descriptionLines.value = lines;
      } else {
        descriptionLines.value = [''];
      }
    } else {
      descriptionLines.value = [''];
    }
  }

  // Add a new description line
  void addDescriptionLine() {
    descriptionLines.add('');
    update();
  }

  // Remove a description line
  void removeDescriptionLine(int index) {
    if (descriptionLines.length > 1) {
      descriptionLines.removeAt(index);
      update();
    }
  }

  // Update a specific description line
  void updateDescriptionLine(int index, String value) {
    if (index < descriptionLines.length) {
      descriptionLines[index] = value;
      update();
    }
  }

  // Get formatted description for saving
  String getFormattedDescription() {
    return descriptionLines
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }

  void getRealTimeImages() {
    FirebaseFirestore.instance
        .collection('products')
        .doc(productModel.productId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data['productImages'] != null) {
          // Safely convert List<dynamic> to List<String>
          final dynamic imagesData = data['productImages'];
          if (imagesData is List) {
            images.value = imagesData
                .where((item) => item != null && item.toString().isNotEmpty)
                .map((item) => item.toString())
                .toList();
          } else {
            images.value = <String>[];
          }
          update();
        }
      }
    });
  }

  //delete images
  Future deleteImagesFromStorage(String imageUrl) async {
    final FirebaseStorage storage = FirebaseStorage.instance;
    try {
      Reference reference = storage.refFromURL(imageUrl);
      await reference.delete();
    } catch (e) {
      print("Error $e");
    }
  }

  //collection
  Future<void> deleteImageFromFireStore(
      String imageUrl, String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
        'productImages': FieldValue.arrayRemove([imageUrl])
      });
      update();
    } catch (e) {
      print("Error $e");
    }
  }

  // Image picker dialog
  Future<void> showImagesPickerDialog() async {
    PermissionStatus status;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;

    if (androidDeviceInfo.version.sdkInt <= 32) {
      status = await Permission.storage.request();
    } else {
      status = await Permission.mediaLibrary.request();
    }

    if (status == PermissionStatus.granted) {
      Get.defaultDialog(
        title: "Choose Images",
        middleText: "Pick images from camera or gallery?",
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back();
              selectImages("camera");
            },
            child: Text('Camera'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              selectImages("gallery");
            },
            child: Text('Gallery'),
          ),
        ],
      );
    }
    if (status == PermissionStatus.denied) {
      print("Error please allow permission for further usage");
      openAppSettings();
    }
    if (status == PermissionStatus.permanentlyDenied) {
      print("Error please allow permission for further usage");
      openAppSettings();
    }
  }

  // Select images
  Future<void> selectImages(String type) async {
    List<XFile> imgs = [];
    if (type == 'gallery') {
      try {
        imgs = await _picker.pickMultiImage(imageQuality: 80);
        update();
      } catch (e) {
        print('Error $e');
      }
    } else {
      final img =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

      if (img != null) {
        imgs.add(img);
        update();
      }
    }

    if (imgs.isNotEmpty) {
      EasyLoading.show();
      await uploadAndAddImages(imgs);
      EasyLoading.dismiss();
    }
  }

  // Upload and add images to product
  Future<void> uploadAndAddImages(List<XFile> selectedImages) async {
    try {
      for (XFile image in selectedImages) {
        String imageUrl = await uploadFile(image);
        await addImageToFirestore(imageUrl);
      }
      update();
    } catch (e) {
      print("Error uploading images: $e");
    }
  }

  // Upload file to Firebase Storage
  Future<String> uploadFile(XFile image) async {
    TaskSnapshot reference = await storageRef
        .ref()
        .child("product-images")
        .child(image.name + DateTime.now().toString())
        .putFile(File(image.path));

    return await reference.ref.getDownloadURL();
  }

  // Add image to Firestore
  Future<void> addImageToFirestore(String imageUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productModel.productId)
          .update({
        'productImages': FieldValue.arrayUnion([imageUrl])
      });
    } catch (e) {
      print("Error adding image to Firestore: $e");
    }
  }
}
