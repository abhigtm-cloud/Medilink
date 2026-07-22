import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/ambulance/domain/entities/ambulance.dart';
import 'package:medilink/features/ambulance/presentation/providers/ambulance_providers.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';

/// Hospital-side fleet management: register ambulances, toggle
/// available/offline. Dispatch itself happens from the Command Center's
/// EmergencyDetailScreen, not here. See architecture doc §12.
class AmbulanceManagementScreen extends ConsumerWidget {
  const AmbulanceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalIdAsync = ref.watch(currentHospitalIdProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('Ambulance Fleet')),
      floatingActionButton: hospitalIdAsync.maybeWhen(
        data: (hospitalId) => hospitalId == null
            ? null
            : FloatingActionButton(
                onPressed: () => _showRegisterDialog(context, ref),
                child: const Icon(Icons.add),
              ),
        orElse: () => null,
      ),
      body: hospitalIdAsync.when(
        data: (hospitalId) {
          if (hospitalId == null) {
            return const Center(child: Text('No hospital linked to your account yet.'));
          }
          return _FleetList(hospitalId: hospitalId);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load: $error')),
      ),
    );
  }

  Future<void> _showRegisterDialog(BuildContext context, WidgetRef ref) async {
    final vehicleController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register Ambulance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: vehicleController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Driver Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Driver Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Driver Email (optional)',
                  helperText: 'Links live-location sharing if they have the '
                      'ambulance_driver role',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Register')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (vehicleController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      return;
    }

    final result = await ref.read(ambulanceRepositoryProvider).registerAmbulance(
          vehicleNumber: vehicleController.text.trim(),
          driverName: nameController.text.trim(),
          driverPhone: phoneController.text.trim(),
          driverEmail: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        );

    if (!context.mounted) return;
    result.match(
      (failure) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ambulance registered'))),
    );
  }
}

class _FleetList extends ConsumerWidget {
  const _FleetList({required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetAsync = ref.watch(hospitalFleetProvider(hospitalId));

    return fleetAsync.when(
      data: (fleet) {
        if (fleet.isEmpty) {
          return const Center(child: Text('No ambulances registered yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: fleet.length,
          itemBuilder: (context, index) => _AmbulanceCard(ambulance: fleet[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load fleet: $error')),
    );
  }
}

class _AmbulanceCard extends ConsumerWidget {
  const _AmbulanceCard({required this.ambulance});

  final Ambulance ambulance;

  Color _statusColor() {
    switch (ambulance.status) {
      case AmbulanceStatus.available:
        return AppColors.success;
      case AmbulanceStatus.dispatched:
        return AppColors.warning;
      case AmbulanceStatus.offline:
      case AmbulanceStatus.maintenance:
        return AppColors.textTertiaryLight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canToggle = ambulance.status == AmbulanceStatus.available ||
        ambulance.status == AmbulanceStatus.offline;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor().withOpacity(0.15),
          child: Icon(Icons.local_shipping, color: _statusColor()),
        ),
        title: Text(ambulance.vehicleNumber),
        subtitle: Text('${ambulance.driverName} · ${ambulance.driverPhone}\n'
            '${ambulance.status.label}'),
        isThreeLine: true,
        trailing: canToggle
            ? Switch(
                value: ambulance.status == AmbulanceStatus.available,
                onChanged: (value) async {
                  final result = await ref.read(ambulanceRepositoryProvider).setAvailability(
                        ambulance.id,
                        value ? AmbulanceStatus.available : AmbulanceStatus.offline,
                      );
                  if (!context.mounted) return;
                  result.match(
                    (failure) => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(failure.message))),
                    (_) {},
                  );
                },
              )
            : null,
      ),
    );
  }
}
