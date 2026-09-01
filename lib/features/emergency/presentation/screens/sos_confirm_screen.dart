import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/error/failures.dart';
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
        final message = error is Failure ? error.message : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Emergency SOS'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.3,
            colors: [Color(0xFF3A0A0A), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Press and hold the button below for 3 seconds to alert the '
                  'nearest available hospital and start emergency tracking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildTypeSelector(),
              const Spacer(),
              _buildHoldButton(),
              const SizedBox(height: 12),
              Text(
                _submitting ? 'Alerting nearest hospital…' : 'Hold for 3s or Tap Below to Send Alert',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (!_submitting)
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  label: const Text(
                    'TAP TO SEND SOS NOW',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmergencyHospitalsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.local_hospital_outlined, size: 18, color: Colors.white70),
                label: const Text(
                  'Not urgent? Browse hospitals manually',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(EmergencyType type) {
    switch (type) {
      case EmergencyType.cardiac:
        return Icons.favorite_border;
      case EmergencyType.accident:
        return Icons.car_crash_outlined;
      case EmergencyType.breathing:
        return Icons.air;
      case EmergencyType.unspecified:
        return Icons.help_outline;
    }
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: EmergencyType.values.map((type) {
        final selected = type == _selectedType;
        return ChoiceChip(
          avatar: Icon(
            _iconFor(type),
            size: 16,
            color: selected ? Colors.white : Colors.white70,
          ),
          label: Text(type.label),
          selected: selected,
          onSelected: _submitting ? null : (_) => setState(() => _selectedType = type),
          selectedColor: AppColors.error,
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
          backgroundColor: Colors.white12,
          side: BorderSide(color: selected ? AppColors.error : Colors.white24),
          shape: const StadiumBorder(),
        );
      }).toList(),
    );
  }

  Widget _buildHoldButton() {
    return GestureDetector(
      onTap: _submit,
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
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.25 + 0.35 * _holdController.value),
                      blurRadius: 24 + 20 * _holdController.value,
                      spreadRadius: 4 * _holdController.value,
                    ),
                  ],
                ),
              ),
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
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
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
