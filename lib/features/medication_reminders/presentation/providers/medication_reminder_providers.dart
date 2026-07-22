import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/medication_reminders/data/medication_reminder_repository.dart';
import 'package:medilink/features/medication_reminders/domain/entities/medication_reminder.dart';

final medicationReminderRepositoryProvider = Provider<MedicationReminderRepository>(
  (ref) => MedicationReminderRepository(),
);

final medicationRemindersProvider = StreamProvider.autoDispose<List<MedicationReminder>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(medicationReminderRepositoryProvider).watchReminders(uid);
});
