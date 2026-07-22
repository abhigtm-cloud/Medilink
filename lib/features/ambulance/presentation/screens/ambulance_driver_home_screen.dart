import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/ambulance/domain/entities/ambulance.dart';
import 'package:medilink/features/ambulance/presentation/providers/ambulance_providers.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart' as domain;

/// Gated to role == ambulance_driver. Streams the driver's live location to
/// their ambulance doc every ~8s while dispatched — the narrow direct
/// Firestore write carved out in firestore.rules, not a Cloud Function (no
/// server-side validation needed for a location ping). See architecture
/// doc §12.
class AmbulanceDriverHomeScreen extends ConsumerStatefulWidget {
  const AmbulanceDriverHomeScreen({super.key});

  @override
  ConsumerState<AmbulanceDriverHomeScreen> createState() => _AmbulanceDriverHomeScreenState();
}

class _AmbulanceDriverHomeScreenState extends ConsumerState<AmbulanceDriverHomeScreen> {
  StreamSubscription<Position>? _positionSub;
  String? _trackedAmbulanceId;

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  void _syncLocationStream(Ambulance? ambulance) {
    final shouldTrack = ambulance != null && ambulance.status == AmbulanceStatus.dispatched;

    if (!shouldTrack) {
      _positionSub?.cancel();
      _positionSub = null;
      _trackedAmbulanceId = null;
      return;
    }
    if (_trackedAmbulanceId == ambulance.id) return; // already tracking this one

    _positionSub?.cancel();
    _trackedAmbulanceId = ambulance.id;
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen((position) {
      ref.read(ambulanceRepositoryProvider).updateAmbulanceLocation(
            ambulance.id,
            domain.GeoPointValue(latitude: position.latitude, longitude: position.longitude),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).valueOrNull;

    if (user != null) {
      ref.listen<AsyncValue<Ambulance?>>(
        driverAmbulanceProvider(user.uid),
        (previous, next) => next.whenData(_syncLocationStream),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('Ambulance Driver')),
      body: user == null
          ? const Center(child: Text('Sign in required'))
          : _DriverBody(driverUid: user.uid),
    );
  }
}

class _DriverBody extends ConsumerWidget {
  const _DriverBody({required this.driverUid});

  final String driverUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambulanceAsync = ref.watch(driverAmbulanceProvider(driverUid));

    return ambulanceAsync.when(
      data: (ambulance) {
        if (ambulance == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No ambulance is linked to your account yet. Ask your hospital '
                'admin to register you as a driver.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusCard(ambulance: ambulance),
              const SizedBox(height: 16),
              if (ambulance.status == AmbulanceStatus.dispatched && ambulance.activeTripId != null)
                _ActiveTripCard(tripId: ambulance.activeTripId!),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load: $error')),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.ambulance});

  final Ambulance ambulance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ambulance.vehicleNumber,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Status: ${ambulance.status.label}'),
            if (ambulance.status == AmbulanceStatus.dispatched)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Sharing your live location with the hospital and patient.',
                  style: TextStyle(color: AppColors.success),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTripCard extends ConsumerWidget {
  const _ActiveTripCard({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Active Trip',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.task_alt),
                label: const Text('Mark Trip Completed'),
                onPressed: () async {
                  final result = await ref.read(ambulanceRepositoryProvider).completeTrip(tripId);
                  if (!context.mounted) return;
                  result.match(
                    (failure) => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(failure.message))),
                    (_) => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Trip completed'))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
