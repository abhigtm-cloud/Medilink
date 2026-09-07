import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/pharmacy/domain/entities/pharmacy.dart';
import 'package:medilink/features/pharmacy/presentation/providers/pharmacy_providers.dart';

/// Hospital-staff side pharmacy management — inventory CRUD, prescription
/// review, and order fulfillment, consolidated into one screen (tabs)
/// rather than three separate ones, since all three are straightforward
/// direct-Firestore-write CRUD guarded by rules (no state machine). A
/// separate menu entry from the Emergency Command Center per architecture
/// doc §13.
class PharmacyInventoryScreen extends ConsumerStatefulWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  ConsumerState<PharmacyInventoryScreen> createState() => _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends ConsumerState<PharmacyInventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hospitalIdAsync = ref.watch(currentHospitalIdProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Pharmacy'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Inventory'), Tab(text: 'Prescriptions'), Tab(text: 'Orders')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final hId = hospitalIdAsync.valueOrNull ?? 'general';
          _showMedicineDialog(context, hId);
        },
        child: const Icon(Icons.add),
      ),
      body: hospitalIdAsync.when(
        data: (hospitalId) {
          final targetHospitalId = (hospitalId != null && hospitalId.isNotEmpty) ? hospitalId : 'general';
          return TabBarView(
            controller: _tabController,
            children: [
              _InventoryTab(hospitalId: targetHospitalId, onAdd: () => _showMedicineDialog(context, targetHospitalId)),
              _PrescriptionsTab(hospitalId: targetHospitalId),
              _OrdersTab(hospitalId: targetHospitalId),
            ],
          );
        },
        loading: () => TabBarView(
          controller: _tabController,
          children: [
            _InventoryTab(hospitalId: 'general', onAdd: () => _showMedicineDialog(context, 'general')),
            const _PrescriptionsTab(hospitalId: 'general'),
            const _OrdersTab(hospitalId: 'general'),
          ],
        ),
        error: (_, __) => TabBarView(
          controller: _tabController,
          children: [
            _InventoryTab(hospitalId: 'general', onAdd: () => _showMedicineDialog(context, 'general')),
            const _PrescriptionsTab(hospitalId: 'general'),
            const _OrdersTab(hospitalId: 'general'),
          ],
        ),
      ),
    );
  }

  Future<void> _showMedicineDialog(BuildContext context, String hospitalId) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    bool requiresPrescription = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Unit Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text('Requires Prescription'),
                  value: requiresPrescription,
                  onChanged: (value) => setState(() => requiresPrescription = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty) return;

    await ref.read(pharmacyRepositoryProvider).upsertMedicine(
          hospitalId,
          null,
          Medicine(
            id: '',
            hospitalId: hospitalId,
            name: nameController.text.trim(),
            unitPrice: double.tryParse(priceController.text) ?? 0,
            stockQuantity: int.tryParse(stockController.text) ?? 0,
            requiresPrescription: requiresPrescription,
          ),
        );
  }
}

class _InventoryTab extends ConsumerWidget {
  const _InventoryTab({required this.hospitalId, required this.onAdd});

  final String hospitalId;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(hospitalInventoryProvider(hospitalId));

    return inventoryAsync.when(
      data: (medicines) {
        if (medicines.isEmpty) {
          return const Center(child: Text('No medicines yet. Tap + to add one.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            final medicine = medicines[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(medicine.name),
                subtitle: Text('Stock: ${medicine.stockQuantity} · ${medicine.unitPrice.toStringAsFixed(0)}'),
                trailing: Switch(
                  value: medicine.isActive,
                  onChanged: (value) => ref
                      .read(pharmacyRepositoryProvider)
                      .setMedicineActive(hospitalId, medicine.id, value),
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

class _PrescriptionsTab extends ConsumerWidget {
  const _PrescriptionsTab({required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(hospitalPrescriptionsProvider(hospitalId));

    return prescriptionsAsync.when(
      data: (prescriptions) {
        final pending =
            prescriptions.where((p) => p.status == PrescriptionStatus.pendingReview).toList();
        if (pending.isEmpty) return const Center(child: Text('No prescriptions awaiting review.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final prescription = pending[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  prescription.imageUrl.isNotEmpty
                      ? Image.network(prescription.imageUrl, height: 160, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                          const SizedBox(height: 160, child: Icon(Icons.broken_image)))
                      : const SizedBox(height: 160, child: Icon(Icons.description, size: 64, color: AppColors.primary)),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                            onPressed: () => ref
                                .read(pharmacyRepositoryProvider)
                                .reviewPrescription(prescription.id, approve: true),
                            child: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ref
                                .read(pharmacyRepositoryProvider)
                                .reviewPrescription(prescription.id, approve: false, note: 'Unclear image'),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(hospitalOrdersProvider(hospitalId));

    return ordersAsync.when(
      data: (orders) {
        final active = orders.where((o) => !o.status.isTerminal).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        if (active.isEmpty) return const Center(child: Text('No active orders.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: active.length,
          itemBuilder: (context, index) {
            final order = active[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text('${order.items.length} item(s) · ${order.totalAmount.toStringAsFixed(0)}'),
                subtitle: Text(order.deliveryAddress),
                trailing: DropdownButton<PharmacyOrderStatus>(
                  value: order.status,
                  items: PharmacyOrderStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (status) {
                    if (status != null) {
                      ref.read(pharmacyRepositoryProvider).updateOrderStatus(order.id, status);
                    }
                  },
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
