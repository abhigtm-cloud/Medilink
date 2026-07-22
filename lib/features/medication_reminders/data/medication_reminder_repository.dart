import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/core/services/local_notification_service.dart';
import 'package:medilink/features/medication_reminders/domain/entities/medication_reminder.dart';

/// Plain Firestore-backed repository — CRUD on one per-user subcollection
/// guarded by rules (`medication_reminders/{uid}/items`, owner-only), same
/// precedent as NotificationCenterRepository/PharmacyRepository: no
/// Callable Function involved, so the full Clean Architecture split isn't
/// justified. Every write also (re)schedules or cancels the matching local
/// notifications so Firestore state and on-device schedules never drift
/// apart.
class MedicationReminderRepository {
  MedicationReminderRepository({
    FirebaseFirestore? firestore,
    LocalNotificationService? notifications,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notifications = notifications ?? LocalNotificationService.instance;

  final FirebaseFirestore _firestore;
  final LocalNotificationService _notifications;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection('medication_reminders').doc(uid).collection('items');

  Stream<List<MedicationReminder>> watchReminders(String uid) {
    return _items(uid).snapshots().map(
          (snap) => snap.docs.map(_fromFirestore).toList(),
        );
  }

  Future<void> createReminder(String uid, MedicationReminder reminder) async {
    final ref = await _items(uid).add(_toFirestore(reminder));
    if (!reminder.isActive) return;
    await _notifications.scheduleReminder(
      reminderId: ref.id,
      medicineName: reminder.medicineName,
      daysOfWeek: reminder.daysOfWeek,
      times: reminder.times,
    );
  }

  Future<void> updateReminder(
    String uid,
    MedicationReminder previous,
    MedicationReminder updated,
  ) async {
    await _items(uid).doc(updated.id).set(_toFirestore(updated), SetOptions(merge: true));
    // Cancel the old schedule unconditionally (day/time/name may have
    // changed) then reschedule only if still active.
    await _notifications.cancelReminder(
      reminderId: previous.id,
      daysOfWeek: previous.daysOfWeek,
      times: previous.times,
    );
    if (updated.isActive) {
      await _notifications.scheduleReminder(
        reminderId: updated.id,
        medicineName: updated.medicineName,
        daysOfWeek: updated.daysOfWeek,
        times: updated.times,
      );
    }
  }

  Future<void> setActive(String uid, MedicationReminder reminder, bool isActive) =>
      updateReminder(uid, reminder, reminder.copyWith(isActive: isActive));

  Future<void> deleteReminder(String uid, MedicationReminder reminder) async {
    await _items(uid).doc(reminder.id).delete();
    await _notifications.cancelReminder(
      reminderId: reminder.id,
      daysOfWeek: reminder.daysOfWeek,
      times: reminder.times,
    );
  }

  MedicationReminder _fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return MedicationReminder(
      id: doc.id,
      medicineName: data['medicineName'] as String? ?? '',
      times: (data['times'] as List?)?.cast<String>() ?? const [],
      daysOfWeek: (data['daysOfWeek'] as List?)?.cast<int>() ?? const [],
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _toFirestore(MedicationReminder reminder) {
    return {
      'medicineName': reminder.medicineName,
      'times': reminder.times,
      'daysOfWeek': reminder.daysOfWeek,
      'isActive': reminder.isActive,
    };
  }
}
