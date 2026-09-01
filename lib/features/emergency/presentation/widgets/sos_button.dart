import 'package:flutter/material.dart';
import 'package:medilink/features/emergency/presentation/screens/sos_confirm_screen.dart';

/// Persistent, always-reachable red FAB for triggering the real Emergency
/// SOS flow. Replaces the old FAB that just jumped to a manual
/// nearest-hospital browse screen (that screen is still reachable as a
/// secondary option from [SosConfirmScreen]). See architecture doc §8.
///
/// Pulses gently at rest so it reads as "always live" rather than a static
/// icon among the rest of the chrome.
class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = _pulseController.value;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.35 * (1 - glow)),
                blurRadius: 18 + 14 * glow,
                spreadRadius: 2 + 6 * glow,
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        heroTag: 'sos_button',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SosConfirmScreen()),
          );
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.emergency),
        label: const Text('EMERGENCY SOS', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ),
    );
  }
}
