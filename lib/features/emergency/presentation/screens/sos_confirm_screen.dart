import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:medilink/features/emergency/presentation/screens/emergency_tracking_screen.dart';
import 'package:medilink/features/home/screens/emergency_hospitals_screen.dart';

/// Patient-facing SOS trigger: hold-to-confirm (prevents accidental
/// triggers) + optional emergency-type quick-select. On success, pushes
/// straight into [EmergencyTrackingScreen]. See architecture doc §8.
class SosConfirmScreen extends ConsumerStatefulWidget {
  const SosConfirmScreen({super.key});

  @override
  ConsumerState<SosConfirmScreen> createState() => _SosConfirmScreenState();
}

class _SosConfirmScreenState extends ConsumerState<SosConfirmScreen>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(seconds: 3);

  EmergencyType _selectedType = EmergencyType.unspecified;
  late final AnimationController _holdController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _submit();
        }
      });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final position = await LocationService.getCurrentLocation();
    if (position == null) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _holdController.reset();
      _showLocationRequiredDialog();
      return;
    }

    await ref.read(sosControllerProvider.notifier).triggerSos(
          type: _selectedType,
          location: GeoPointValue(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );

    if (!mounted) return;

    final state = ref.read(sosControllerProvider);
    state.when(
      data: (requestId) {
        if (requestId == null) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmergencyTrackingScreen(requestId: requestId),
          ),
        );
      },
      loading: () {},
      error: (error, _) {
        setState(() => _submitting = false);
        _holdController.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      },
    );
  }

  void _showLocationRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location access is required for Emergency SOS'),
        content: const Text(
          'MediLink needs your location to find and notify the nearest hospital.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Emergency SOS'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Press and hold the button below for 3 seconds to alert the '
                'nearest available hospital and start emergency tracking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
              ),
            ),
            const SizedBox(height: 24),
            _buildTypeSelector(),
            const Spacer(),
            _buildHoldButton(),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyHospitalsScreen(),
                  ),
                );
              },
              child: const Text(
                'Not urgent? Browse hospitals manually',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: EmergencyType.values.map((type) {
        final selected = type == _selectedType;
        return ChoiceChip(
          label: Text(type.label),
          selected: selected,
          onSelected: _submitting ? null : (_) => setState(() => _selectedType = type),
          selectedColor: AppColors.error,
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
          backgroundColor: Colors.white12,
        );
      }).toList(),
    );
  }

  Widget _buildHoldButton() {
    return GestureDetector(
      onLongPressStart: _submitting ? null : (_) => _holdController.forward(),
      onLongPressEnd: (_) {
        if (_holdController.status != AnimationStatus.completed) {
          _holdController.reverse();
        }
      },
      onLongPressCancel: () {
        if (_holdController.status != AnimationStatus.completed) {
          _holdController.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: _holdController.value,
                  strokeWidth: 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emergency, color: Colors.white, size: 36),
                            SizedBox(height: 4),
                            Text(
                              'HOLD FOR\nSOS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
