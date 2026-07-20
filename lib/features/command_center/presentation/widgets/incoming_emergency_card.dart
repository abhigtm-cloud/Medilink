import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/command_center/presentation/widgets/emergency_priority_badge.dart';

class EmergencyRequestCard extends StatelessWidget {
  const EmergencyRequestCard({super.key, required this.request, required this.onTap});

  final EmergencyRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.errorLight,
          child: const Icon(Icons.emergency, color: AppColors.error),
        ),
        title: Text(
          request.emergencyType.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          request.status.label +
              (request.distanceKm != null
                  ? ' · ${request.distanceKm!.toStringAsFixed(1)} km'
                  : ''),
        ),
        trailing: EmergencyPriorityBadge(priority: request.priority),
      ),
    );
  }
}
