import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

/// Reuses the existing [AppColors] design tokens rather than inventing a
/// new palette, per architecture doc §9.
class EmergencyPriorityBadge extends StatelessWidget {
  const EmergencyPriorityBadge({super.key, required this.priority});

  final EmergencyPriority priority;

  Color get _color {
    switch (priority) {
      case EmergencyPriority.critical:
        return AppColors.error;
      case EmergencyPriority.high:
        return Colors.orange;
      case EmergencyPriority.medium:
        return AppColors.warning;
      case EmergencyPriority.low:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
