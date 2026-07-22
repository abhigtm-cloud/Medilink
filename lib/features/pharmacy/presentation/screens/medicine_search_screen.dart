import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';
import 'package:medilink/features/pharmacy/domain/entities/pharmacy.dart';
import 'package:medilink/features/pharmacy/presentation/providers/pharmacy_providers.dart';
import 'package:medilink/features/pharmacy/presentation/screens/order_tracking_screen.dart';

/// Browse `medicine_inventory` across every hospital + a "My Orders" tab.
/// Deliberately a single-item "Buy Now" flow rather than a persistent
/// multi-item cart — keeps this feature's scope to what's asked (search,
/// order, track) without introducing new cross-screen cart state. See
/// architecture doc §13.
class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Pharmacy'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Search Medicines'), Tab(text: 'My Orders')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_MedicineSearchTab(), _MyOrdersTab()],
      ),
    );
  }
}

class _MedicineSearchTab extends ConsumerStatefulWidget {
  const _MedicineSearchTab();

  @override
  ConsumerState<_MedicineSearchTab> createState() => _MedicineSearchTabState();
}

class _MedicineSearchTabState extends ConsumerState<_MedicineSearchTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(allActiveMedicinesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search medicines...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: medicinesAsync.when(
            data: (medicines) {
              final filtered = _query.isEmpty
                  ? medicines
                  : medicines
                      .where((m) =>
                          m.name.toLowerCase().contains(_query) ||
                          (m.genericName?.toLowerCase().contains(_query) ?? false))
                      .toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('No medicines found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _MedicineCard(medicine: filtered[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Unable to load: $error')),
          ),
        ),
      ],
    );
  }
}

class _MedicineCard extends ConsumerWidget {
  const _MedicineCard({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalAsync = ref.watch(getHospitalByIdProvider(medicine.hospitalId));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.medication)),
        title: Text(medicine.name),
        subtitle: hospitalAsync.when(
          data: (hospital) => Text(
            '${hospital?.name ?? 'Unknown hospital'} · Stock: ${medicine.stockQuantity}'
            '${medicine.requiresPrescription ? ' · Rx required' : ''}',
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text(''),
        ),
        trailing: Text(medicine.unitPrice.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: medicine.stockQuantity > 0 ? () => _showBuyDialog(context, ref) : null,
      ),
    );
  }

  Future<void> _showBuyDialog(BuildContext context, WidgetRef ref) async {
    final addressController = TextEditingController();
    int quantity = 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(medicine.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Quantity:'),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                  ),
                  Text('$quantity'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: quantity < medicine.stockQuantity ? () => setState(() => quantity++) : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Delivery Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text('Total: ${(medicine.unitPrice * quantity).toStringAsFixed(0)}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Place Order')),
          ],
        ),
      ),
    );

    if (confirmed != true || addressController.text.trim().isEmpty) return;
    if (!context.mounted) return;

    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    final orderId = await ref.read(pharmacyRepositoryProvider).placeOrder(
          patientUid: uid,
          hospitalId: medicine.hospitalId,
          items: [
            PharmacyOrderItem(
              medicineId: medicine.id,
              name: medicine.name,
              quantity: quantity,
              unitPrice: medicine.unitPrice,
            ),
          ],
          deliveryAddress: addressController.text.trim(),
        );

    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
  }
}

class _MyOrdersTab extends ConsumerWidget {
  const _MyOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return const Center(child: Text('Sign in required'));

    final ordersAsync = ref.watch(myOrdersProvider(uid));

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) return const Center(child: Text('No orders yet.'));
        final sorted = [...orders]..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final order = sorted[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text('${order.items.length} item(s) · ${order.totalAmount.toStringAsFixed(0)}'),
                subtitle: Text(order.status.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load: $error')),
    );
  }
}
