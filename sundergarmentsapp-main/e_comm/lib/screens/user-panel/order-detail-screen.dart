// ignore_for_file: file_names, prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, sized_box_for_whitespace

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order-model.dart';
import '../../models/order-status.dart';
import '../../models/transporter-details-model.dart';
import '../../repositories/order-repository.dart';
import '../../utils/app-constant.dart';

/// Read-only order detail view for the customer's own order - the one
/// screen that was missing entirely before this. The admin app has
/// always been able to add transporter/tracking details to an order,
/// but there was never anywhere in the customer-facing app to actually
/// see them, or even to see anything beyond the order list's one-line
/// summary. This shows: item breakdown, delivery address, current
/// status against the full order lifecycle, and transporter/tracking
/// info once the admin has added it.
class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  late OrderModel order;
  bool _isMarkingReceived = false;

  @override
  void initState() {
    super.initState();
    order = widget.order;
  }

  Future<void> _markAsReceived() async {
    setState(() => _isMarkingReceived = true);
    try {
      await _orderRepository.markAsReceived(order.orderId);
      setState(() {
        order = order.copyWith(status: OrderStatus.delivered);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for confirming!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingReceived = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppConstant.appMainColor,
        iconTheme: IconThemeData(color: AppConstant.appTextColor),
        title: Text(
          order.orderNumber.isNotEmpty ? 'Order ${order.orderNumber}' : 'Order details',
          style: TextStyle(color: AppConstant.appTextColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          _StatusProgressCard(order: order),
          if (order.status == OrderStatus.shipped) ...[
            const SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isMarkingReceived ? null : _markAsReceived,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                icon: _isMarkingReceived
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isMarkingReceived ? 'Updating...' : "I've received this order"),
              ),
            ),
          ],
          const SizedBox(height: 12.0),
          _ItemsCard(order: order),
          const SizedBox(height: 12.0),
          _DeliveryAddressCard(order: order),
          if (order.transporterDetails != null) ...[
            const SizedBox(height: 12.0),
            _TransporterCard(transporter: order.transporterDetails!),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12.0),
          ...children,
        ],
      ),
    );
  }
}

class _StatusProgressCard extends StatelessWidget {
  final OrderModel order;
  const _StatusProgressCard({required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red.shade400),
            const SizedBox(width: 10.0),
            const Text(
              'This order was cancelled',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // Same simplified 5-stage view as the admin app - New and Dispatched
    // still exist as stored values for old orders, but aren't shown as
    // their own step anymore. A leftover "Dispatched" order displays as
    // if it's sitting right after Packed.
    const visibleStages = [
      OrderStatus.confirmed,
      OrderStatus.processing,
      OrderStatus.packed,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];
    int currentPosition = visibleStages.indexOf(order.status);
    if (currentPosition == -1) {
      currentPosition = order.status == OrderStatus.dispatched
          ? visibleStages.indexOf(OrderStatus.packed)
          : -1;
    }
    final steps = visibleStages;

    return _SectionCard(
      title: 'Order status',
      children: [
        ...steps.asMap().entries.map((entry) {
          final s = entry.value;
          final isDone = entry.key <= currentPosition;
          final isCurrent = s == order.status;
          final isLast = s == steps.last;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    isDone ? Icons.check_circle : Icons.circle_outlined,
                    size: 20.0,
                    color: isDone ? Colors.green.shade600 : Colors.grey.shade400,
                  ),
                  if (!isLast)
                    Container(
                      width: 2.0,
                      height: 28.0,
                      color: isDone ? Colors.green.shade200 : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12.0),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    color: isDone ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final OrderModel order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Items',
      children: [
        ...order.items.map((item) {
          final imageUrl = item.productImages.isNotEmpty
              ? item.productImages.first.toString()
              : null;
          final variantParts = <String>[
            if ((item.size ?? '').isNotEmpty) item.size!,
            if ((item.color ?? '').isNotEmpty) item.color!,
          ];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 48.0,
                          height: 48.0,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 48.0,
                            height: 48.0,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_outlined, size: 18.0),
                          ),
                        )
                      : Container(
                          width: 48.0,
                          height: 48.0,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.checkroom_outlined, size: 20.0),
                        ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
                      ),
                      if (variantParts.isNotEmpty)
                        Text(
                          variantParts.join(' / '),
                          style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
                        ),
                      Text(
                        'Qty: ${item.quantity}',
                        style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\u20b9${item.lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '\u20b9${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  final OrderModel order;
  const _DeliveryAddressCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Delivery details',
      children: [
        Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2.0),
        Text(order.customerPhone, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 2.0),
        Text(order.customerAddress, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }
}

class _TransporterCard extends StatelessWidget {
  final TransporterDetailsModel transporter;
  const _TransporterCard({required this.transporter});

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.0,
            child: Text(label, style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = transporter;
    return _SectionCard(
      title: 'Shipment tracking',
      children: [
        _row('Transporter', t.transporterName),
        _row('Company', t.transportCompany),
        _row('AWB Number', t.awbNumber),
        _row('Consignment No.', t.consignmentNumber),
        if (t.remarks != null && t.remarks!.isNotEmpty)
          _row('Remarks', t.remarks),
        if (t.trackingUrl != null && t.trackingUrl!.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(t.trackingUrl!);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.local_shipping_outlined, size: 18.0),
              label: const Text('Track shipment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstant.appMainColor,
                side: BorderSide(color: AppConstant.appMainColor),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
