// ignore_for_file: file_names
import 'package:e_comm/models/order-model.dart';
import 'package:e_comm/models/order-status.dart';
import 'package:e_comm/repositories/order-repository.dart';
import 'package:e_comm/screens/user-panel/order-detail-screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/skeleton_box.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final OrderRepository orderRepository = OrderRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All orders'),
      ),
      body: user == null
          ? const AppEmptyState(
              icon: Icons.lock_outline,
              title: 'Please sign in to view your orders',
            )
          : StreamBuilder<List<OrderModel>>(
              stream: orderRepository.streamOrdersForCustomer(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AppErrorState(
                    title: 'Could not load your orders',
                    message: snapshot.error.toString(),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: 5,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: SkeletonBox(height: 72),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    message: 'Orders you place will show up here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: orders.length + 1,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Cancelled orders count toward "orders placed"
                      // (they genuinely were), but not toward the
                      // amount spent - that should reflect real
                      // business done, not orders that didn't
                      // actually go through. Matches how most
                      // lifetime-spend stats work.
                      final totalSpent = orders
                          .where((o) => o.status != OrderStatus.cancelled)
                          .fold(0.0, (sum, o) => sum + o.total);
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _OrderStatColumn(
                                label: 'Total orders',
                                value: '${orders.length}',
                              ),
                            ),
                            Container(width: 1, height: 36, color: AppColors.surfaceBorder),
                            Expanded(
                              child: _OrderStatColumn(
                                label: 'Total spent',
                                value: '\u20b9${totalSpent.toStringAsFixed(0)}',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final order = orders[index - 1];
                    final firstItem =
                        order.items.isNotEmpty ? order.items.first : null;
                    final itemSummary = firstItem == null
                        ? 'No items'
                        : (order.items.length > 1
                            ? '${firstItem.productName} +${order.items.length - 1} more'
                            : firstItem.productName);

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceMuted,
                          backgroundImage: (firstItem != null &&
                                  firstItem.productImages.isNotEmpty)
                              ? NetworkImage(firstItem.productImages[0])
                              : null,
                        ),
                        title: Text(itemSummary),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                '₹${order.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              StatusBadge(status: order.status),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _OrderStatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _OrderStatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
