// ignore_for_file: file_names

import 'product-variant-model.dart';

class ProductModel {
  final String productId;
  final String categoryId;
  final String productName;
  final String categoryName;
  final String salePrice;
  final String fullPrice;
  final List productImages;
  final String deliveryTime;
  final bool isSale;
  final String productDescription;
  final dynamic createdAt;
  final dynamic updatedAt;
  // FIX: these three were never read here at all, even though the Admin
  // App has written them to every product document for a while now -
  // this model just silently ignored them. Optional with safe defaults
  // so nothing that already constructs a ProductModel elsewhere breaks.
  final String fabric;
  final int moq;
  final List<ProductVariantModel> variants;

  ProductModel({
    required this.productId,
    required this.categoryId,
    required this.productName,
    required this.categoryName,
    required this.salePrice,
    required this.fullPrice,
    required this.productImages,
    required this.deliveryTime,
    required this.isSale,
    required this.productDescription,
    required this.createdAt,
    required this.updatedAt,
    this.fabric = '',
    this.moq = 0,
    this.variants = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'categoryId': categoryId,
      'productName': productName,
      'categoryName': categoryName,
      'salePrice': salePrice,
      'fullPrice': fullPrice,
      'productImages': productImages,
      'deliveryTime': deliveryTime,
      'isSale': isSale,
      'productDescription': productDescription,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'fabric': fabric,
      'moq': moq,
      'variants': variants.map((v) => v.toMap()).toList(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'],
      categoryId: json['categoryId'],
      productName: json['productName'],
      categoryName: json['categoryName'],
      salePrice: json['salePrice'],
      fullPrice: json['fullPrice'],
      productImages: json['productImages'],
      deliveryTime: json['deliveryTime'],
      isSale: json['isSale'],
      productDescription: json['productDescription'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      // Safe fallbacks - older product documents (or ones created before
      // this fix) may not have these fields at all.
      fabric: json['fabric']?.toString() ?? '',
      moq: (json['moq'] as num?)?.toInt() ?? 0,
      variants: json['variants'] is List
          ? (json['variants'] as List)
              .whereType<Map>()
              .map((v) => ProductVariantModel.fromMap(Map<String, dynamic>.from(v)))
              .toList()
          : const [],
    );
  }
}

