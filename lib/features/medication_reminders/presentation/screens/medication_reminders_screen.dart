import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/services/local_notification_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/medication_reminders/domain/entities/medication_reminder.dart';
import 'package:medilink/features/medication_reminders/presentation/providers/medication_reminder_providers.dart';

const _dayLabels = {
  DateTime.monday: 'Mon',
  DateTime.tuesday: 'Tue',
  DateTime.wednesday: 'Wed',
  DateTime.thursday: 'Thu',
  DateTime.friday: 'Fri',
  DateTime.saturday: 'Sat',
  DateTime.sunday: 'Sun',
};

/// Local scheduled notifications for medication times — not an AI feature
/// (architecture doc §11), just CRUD on `medication_reminders/{uid}/items`
/// plus on-device scheduling via [LocalNotificationService].
class MedicationRemindersScreen extends ConsumerWidget {
  const MedicationRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(medicationRemindersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('Medication Reminders')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddReminderSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm_add_outlined, size: 56, color: AppColors.textTertiaryLight),
                    const SizedBox(height: 16),
                    Text(
                      'No reminders yet. Tap + to add one.',
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _ReminderTile(reminder: reminders[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load reminders: $error')),
      ),
    );
  }

  void _openAddReminderSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddReminderSheet(),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder});

  final MedicationReminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = reminder.daysOfWeek.toList()..sort();
    final daySummary = days.map((d) => _dayLabels[d] ?? '').join(', ');

    return Card(
      color: AppColors.cardLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.medicineName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reminder.times.join(', ')}  •  $daySummary',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: reminder.isActive,
              onChanged: (value) {
                final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
                if (uid == null) return;
                ref
                    .read(medicationReminderRepositoryProvider)
                    .setActive(uid, reminder, value);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () {
                final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
                if (uid == null) return;
                ref.read(medicationReminderRepositoryProvider).deleteReminder(uid, reminder);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  const _AddReminderSheet();

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _nameController = TextEditingController();
  final Set<int> _selectedDays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  };
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _times.add(picked));
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedDays.isEmpty || _times.isEmpty) return;
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    // Only block on a denied permission where notifications can actually
    // fire — on an unsupported platform (e.g. Windows desktop) the reminder
    // is still saved, it just won't produce a local notification.
    if (LocalNotificationService.instance.isSupportedPlatform) {
      final granted = await LocalNotificationService.instance.requestPermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission is required for reminders')),
        );
        return;
      }
    }

    await ref.read(medicationReminderRepositoryProvider).createReminder(
          uid,
          MedicationReminder(
            id: '',
            medicineName: name,
            times: _times.map(_formatTime).toList(),
            daysOfWeek: _selectedDays.toList(),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'New Reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Days', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _dayLabels.entries.map((entry) {
                  final selected = _selectedDays.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (value) => setState(() {
                      if (value) {
                        _selectedDays.add(entry.key);
                      } else {
                        _selectedDays.remove(entry.key);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Times', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final time in _times)
                    Chip(
                      label: Text(_formatTime(time)),
                      onDeleted: _times.length > 1
                          ? () => setState(() => _times.remove(time))
                          : null,
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Add time'),
                    onPressed: _addTime,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Reminder'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
