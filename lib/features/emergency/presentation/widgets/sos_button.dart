import 'package:flutter/material.dart';
import 'package:medilink/features/emergency/presentation/screens/sos_confirm_screen.dart';

/// Persistent, always-reachable red FAB for triggering the real Emergency
/// SOS flow. Replaces the old FAB that just jumped to a manual
/// nearest-hospital browse screen (that screen is still reachable as a
/// secondary option from [SosConfirmScreen]). See architecture doc §8.
class SosButton extends StatelessWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'sos_button',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SosConfirmScreen()),
        );
      },
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.emergency),
      label: const Text('EMERGENCY SOS'),
    );
  }
}
