// ignore_for_file: file_names

class ProductModel {
  final String productId;
  final String categoryId;
  final String productName;
  final String categoryName;
  final String salePrice;
  final String fullPrice;
  final List<String> productImages;
  final String deliveryTime;
  final bool isSale;
  final String productDescription;
  final dynamic createdAt;
  final dynamic updatedAt;

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
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      productName: json['productName'] ?? '',
      categoryName: json['categoryName'] ?? '',
      salePrice: json['salePrice'] ?? '',
      fullPrice: json['fullPrice'] ?? '',
      productImages: _parseProductImages(json['productImages']),
      deliveryTime: json['deliveryTime'] ?? '',
      isSale: json['isSale'] ?? false,
      productDescription: json['productDescription'] ?? '',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  /// Safely parses product images from various data types
  /// Handles null, empty lists, and ensures all items are strings
  static List<String> _parseProductImages(dynamic imagesData) {
    if (imagesData == null) return [];
    
    if (imagesData is List) {
      // Handle both List<dynamic> and List<String> from Firestore
      return imagesData
          .where((item) => item != null && item.toString().isNotEmpty)
          .map((item) => item.toString())
          .toList();
    }
    
    return [];
  }

  /// Gets the first product image URL safely
  /// Returns null if no images are available
  String? get firstImageUrl {
    return productImages.isNotEmpty ? productImages[0] : null;
  }

  /// Checks if the product has any images
  bool get hasImages {
    return productImages.isNotEmpty;
  }
}
