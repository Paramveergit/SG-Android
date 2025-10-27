// ignore_for_file: file_names

class OrderModel {
  final String categoryId;
  final String categoryName;
  final dynamic createdAt;
  final String customerAddress;
  final String customerDeviceToken;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryTime;
  final String fullPrice;
  final bool isSale;
  final String productDescription;
  final String productId;
  final List<String> productImages;
  final String productName;
  final int productQuantity;
  final double productTotalPrice;
  final String salePrice;
  final int status;
  final dynamic updatedAt;

  OrderModel({
    required this.categoryId,
    required this.categoryName,
    required this.createdAt,
    required this.customerAddress,
    required this.customerDeviceToken,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryTime,
    required this.fullPrice,
    required this.isSale,
    required this.productDescription,
    required this.productId,
    required this.productImages,
    required this.productName,
    required this.productQuantity,
    required this.productTotalPrice,
    required this.salePrice,
    required this.status,
    required this.updatedAt,
  });

// Convert the object to a map
  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'createdAt': createdAt,
      'customerAddress': customerAddress,
      'customerDeviceToken': customerDeviceToken,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryTime': deliveryTime,
      'fullPrice': fullPrice,
      'isSale': isSale,
      'productDescription': productDescription,
      'productId': productId,
      'productImages': productImages,
      'productName': productName,
      'productQuantity': productQuantity,
      'productTotalPrice': productTotalPrice,
      'salePrice': salePrice,
      'status': status,
      'updatedAt': updatedAt,
    };
  }

  // Create an instance of the class from a map
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      createdAt: json['createdAt'],
      customerAddress: json['customerAddress'] ?? '',
      customerDeviceToken: json['customerDeviceToken'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      deliveryTime: json['deliveryTime'] ?? '',
      fullPrice: json['fullPrice'] ?? '',
      isSale: json['isSale'] ?? false,
      productDescription: json['productDescription'] ?? '',
      productId: json['productId'] ?? '',
      productImages: _parseProductImages(json['productImages']),
      productName: json['productName'] ?? '',
      productQuantity: json['productQuantity'] ?? 0,
      productTotalPrice: (json['productTotalPrice'] ?? 0.0).toDouble(),
      salePrice: json['salePrice'] ?? '',
      status: json['status'] ?? 0,
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
