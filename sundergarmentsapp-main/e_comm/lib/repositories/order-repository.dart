// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order-model.dart';
import '../models/order-item-model.dart';
import '../models/order-status.dart';
import '../models/order-status-history-entry.dart';

/// Single place responsible for reading and writing orders from the
/// retailer app. Mirrors the admin app's OrderRepository so both apps
/// treat the same Firestore data the same way - this is the fix for
/// the old bug where every cart item became its own disconnected
/// document instead of one real order per checkout.
class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  /// Live stream of every order placed by one customer, most recent
  /// first - used for "My Orders" and the profile screen's order
  /// history.
  Stream<List<OrderModel>> streamOrdersForCustomer(String customerId,
      {int? limit}) {
    Query<Map<String, dynamic>> query = _ordersRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => OrderModel.fromMap(d.data())).toList());
  }

  /// Creates one order document from a full cart checkout - every item
  /// from the cart goes into a single order's `items` array instead of
  /// becoming its own disconnected document.
  Future<String> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? customerDeviceToken,
    required List<OrderItemModel> items,
  }) async {
    final orderRef = _ordersRef.doc();
    final subtotal =
        items.fold<double>(0.0, (sum, item) => sum + item.lineTotal);

    final order = OrderModel(
      orderId: orderRef.id,
      orderNumber: await _generateOrderNumber(),
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerDeviceToken: customerDeviceToken,
      items: items,
      subtotal: subtotal,
      total: subtotal,
      status: OrderStatus.newOrder,
      statusHistory: [
        OrderStatusHistoryEntry(
          status: OrderStatus.newOrder,
          timestamp: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await orderRef.set(order.toMap());
    return orderRef.id;
  }

  /// Same sequential order number scheme as the admin app - shares the
  /// same counter document, so numbers stay sequential regardless of
  /// which app created the order.
  Future<String> _generateOrderNumber() async {
    final counterRef = _firestore.collection('counters').doc('orders');
    final newCount = await _firestore.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);
      final current = (snap.data()?['count'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      tx.set(counterRef, {'count': next});
      return next;
    });
    return 'SG-${newCount.toString().padLeft(6, '0')}';
  }
}
