import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_timeline_event.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatEventTime(DateTime dt) {
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '${_months[dt.month - 1]} ${dt.day}, $hour12:$minute $period';
}

/// Vertical stepper rendering `emergency_requests/{id}/timeline`, ordered
/// oldest-first (matches the Firestore query order). See architecture
/// doc §8.
class EmergencyStatusTimeline extends StatelessWidget {
  const EmergencyStatusTimeline({super.key, required this.events});

  final List<EmergencyTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineTile(
            event: events[i],
            isLast: i == events.length - 1,
            isCurrent: i == events.length - 1,
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isLast,
    required this.isCurrent,
  });

  final EmergencyTimelineEvent event;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? AppColors.primary : AppColors.success;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.success),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.label,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    _formatEventTime(event.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
