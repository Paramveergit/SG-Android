// ignore_for_file: file_names

class OrderItemModel {
  final String productId;
  final String productName;
  final String? sku;
  final String? size;
  final String? color;
  final String categoryId;
  final String categoryName;
  final List productImages;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  OrderItemModel({
    required this.productId,
    required this.productName,
    this.sku,
    this.size,
    this.color,
    required this.categoryId,
    required this.categoryName,
    required this.productImages,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'size': size,
      'color': color,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'productImages': productImages,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'lineTotal': lineTotal,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString(),
      size: json['size']?.toString(),
      color: json['color']?.toString(),
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      productImages: json['productImages'] ?? [],
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
