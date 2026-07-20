// ignore_for_file: file_names

import 'order-item-model.dart';
import 'order-status.dart';
import 'order-status-history-entry.dart';
import 'transporter-details-model.dart';

/// One real order document at orders/{orderId} - matches the admin
/// app's schema exactly, since both apps read/write the same Firestore
/// data. One checkout = one document here, with every product line in
/// `items`, one status for the whole order, and a full status timeline.
class OrderModel {
  final String orderId;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String? customerDeviceToken;
  final List<OrderItemModel> items;
  final double subtotal;
  final double total;
  final OrderStatus status;
  final List<OrderStatusHistoryEntry> statusHistory;
  final TransporterDetailsModel? transporterDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.customerDeviceToken,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.status,
    required this.statusHistory,
    this.transporterDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerDeviceToken': customerDeviceToken,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'total': total,
      'status': status.index,
      'isCancelled': status == OrderStatus.cancelled,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      'transporterDetails': transporterDetails?.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> json) {
    List<OrderItemModel> parsedItems;

    if (json['items'] is List && (json['items'] as List).isNotEmpty) {
      parsedItems = (json['items'] as List)
          .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } else if (json['productId'] != null) {
      // Legacy order (pre-rebuild): a single product stored directly on
      // the order document instead of an items array. Wrap it into a
      // single-item list so any old orders still display correctly.
      final legacyPrice =
          double.tryParse(json['salePrice']?.toString() ?? '') ?? 0.0;
      final legacyQuantity = (json['productQuantity'] as num?)?.toInt() ?? 0;
      parsedItems = [
        OrderItemModel(
          productId: json['productId']?.toString() ?? '',
          productName: json['productName']?.toString() ?? '',
          categoryId: json['categoryId']?.toString() ?? '',
          categoryName: json['categoryName']?.toString() ?? '',
          productImages: json['productImages'] ?? [],
          unitPrice: legacyPrice,
          quantity: legacyQuantity,
          lineTotal: (json['productTotalPrice'] as num?)?.toDouble() ??
              (legacyPrice * legacyQuantity),
        ),
      ];
    } else {
      parsedItems = [];
    }

    final legacyTotal =
        parsedItems.fold<double>(0.0, (sum, item) => sum + item.lineTotal);

    return OrderModel(
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerAddress: json['customerAddress']?.toString() ?? '',
      customerDeviceToken: json['customerDeviceToken']?.toString(),
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? legacyTotal,
      total: (json['total'] as num?)?.toDouble() ?? legacyTotal,
      status: OrderStatusX.fromInt(json['status'] as int?),
      statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
          .map((e) =>
              OrderStatusHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      transporterDetails: json['transporterDetails'] != null
          ? TransporterDetailsModel.fromMap(
              json['transporterDetails'] as Map<String, dynamic>)
          : null,
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }
}
