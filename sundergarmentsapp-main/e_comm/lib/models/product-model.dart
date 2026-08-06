// ignore_for_file: file_names

import 'product-variant-model.dart';
import 'stock-status.dart';

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
  final String fabric;
  final int moq;
  final List<ProductVariantModel> variants;
  final int lowStockThreshold;

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
    this.lowStockThreshold = 5,
  });

  /// Total stock across every size/color combination - mirrors the
  /// admin app's identical getter, same underlying data.
  int get totalStock => variants.fold(0, (sum, v) => sum + v.stock);

  StockStatus get stockStatus =>
      StockStatusX.fromStock(totalStock, lowStockThreshold: lowStockThreshold);

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
      'lowStockThreshold': lowStockThreshold,
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
      fabric: json['fabric']?.toString() ?? '',
      moq: (json['moq'] as num?)?.toInt() ?? 0,
      variants: json['variants'] is List
          ? (json['variants'] as List)
              .whereType<Map>()
              .map((v) => ProductVariantModel.fromMap(Map<String, dynamic>.from(v)))
              .toList()
          : const [],
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 5,
    );
  }
}

