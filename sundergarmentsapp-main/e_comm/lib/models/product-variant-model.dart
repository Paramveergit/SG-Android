// ignore_for_file: file_names

/// One buyable combination of a product - e.g. "M / Red". Mirrors the
/// admin app's ProductVariantModel (same field names/shape) since both
/// apps read/write the same Firestore documents.
class ProductVariantModel {
  final String size;
  final String color;
  final int stock;

  ProductVariantModel({
    required this.size,
    required this.color,
    required this.stock,
  });

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'color': color,
      'stock': stock,
    };
  }

  factory ProductVariantModel.fromMap(Map<String, dynamic> json) {
    return ProductVariantModel(
      size: json['size']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}
