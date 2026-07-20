// ignore_for_file: file_names

/// Canonical order lifecycle, matching the admin app's schema exactly
/// since both apps read/write the same Firestore data. Stored as the
/// integer index.
enum OrderStatus {
  newOrder,     // 0 - just placed, not yet reviewed
  confirmed,    // 1 - admin has reviewed and accepted
  processing,   // 2 - being prepared / picked
  packed,       // 3 - packed and ready for pickup
  dispatched,   // 4 - handed to transporter
  shipped,      // 5 - in transit
  delivered,    // 6 - reached customer
  cancelled,    // 7 - cancelled at any stage
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.newOrder:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromInt(int? value) {
    if (value == null || value < 0 || value >= OrderStatus.values.length) {
      return OrderStatus.newOrder;
    }
    return OrderStatus.values[value];
  }
}
