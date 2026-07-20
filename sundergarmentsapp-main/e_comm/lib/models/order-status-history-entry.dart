// ignore_for_file: file_names

import 'order-status.dart';

class OrderStatusHistoryEntry {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;
  final String? updatedByStaffId;

  OrderStatusHistoryEntry({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedByStaffId,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status.index,
      'timestamp': timestamp,
      'note': note,
      'updatedByStaffId': updatedByStaffId,
    };
  }

  factory OrderStatusHistoryEntry.fromMap(Map<String, dynamic> json) {
    return OrderStatusHistoryEntry(
      status: OrderStatusX.fromInt(json['status'] as int?),
      timestamp: _toDateTime(json['timestamp']) ?? DateTime.now(),
      note: json['note']?.toString(),
      updatedByStaffId: json['updatedByStaffId']?.toString(),
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
