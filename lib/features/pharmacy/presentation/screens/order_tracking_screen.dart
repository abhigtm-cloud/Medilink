import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/pharmacy/presentation/providers/pharmacy_providers.dart';

/// Same append-only-subcollection pattern as the emergency timeline —
/// `orders/{orderId}/tracking` is populated by `onOrderStatusChange`. See
/// architecture doc §4.10/§13.
class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync = ref.watch(orderTrackingProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('Order Tracking')),
      body: trackingAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No tracking updates yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(
                        isLast ? Icons.radio_button_checked : Icons.check_circle,
                        color: isLast ? AppColors.primary : AppColors.success,
                        size: 20,
                      ),
                      if (index != events.length - 1)
                        Container(width: 2, height: 40, color: AppColors.borderLight),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.note, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (event.timestamp != null)
                            Text(
                              event.timestamp!.toLocal().toString(),
                              style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load: $error')),
      ),
    );
  }
}
