import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/ambulance/presentation/providers/ambulance_providers.dart';

/// Embedded card on EmergencyTrackingScreen once an ambulance has been
/// dispatched (`emergency_requests.assignedAmbulanceId` set). See
/// architecture doc §12.
class AmbulanceTrackingCard extends ConsumerWidget {
  const AmbulanceTrackingCard({super.key, required this.ambulanceId});

  final String ambulanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambulanceAsync = ref.watch(ambulanceByIdProvider(ambulanceId));

    return ambulanceAsync.when(
      data: (ambulance) {
        if (ambulance == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      ambulance.vehicleNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Driver: ${ambulance.driverName}'),
                Text('Status: ${ambulance.status.label}'),
                if (ambulance.currentLocation != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Live location sharing active',
                        style: TextStyle(color: AppColors.success, fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.call),
                  label: Text('Call Driver: ${ambulance.driverPhone}'),
                  onPressed: () => launchUrl(Uri.parse('tel:${ambulance.driverPhone}')),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
