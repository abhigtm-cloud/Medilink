/// One `medication_reminders/{uid}/items/{id}` document. See architecture
/// doc §11 — "not actually an AI feature... local scheduled notifications."
class MedicationReminder {
  final String id;
  final String medicineName;

  /// 24-hour "HH:mm" strings, e.g. "08:00".
  final List<String> times;

  /// `DateTime.monday`(1)..`DateTime.sunday`(7).
  final List<int> daysOfWeek;

  final bool isActive;

  const MedicationReminder({
    required this.id,
    required this.medicineName,
    required this.times,
    required this.daysOfWeek,
    this.isActive = true,
  });

  MedicationReminder copyWith({
    String? medicineName,
    List<String>? times,
    List<int>? daysOfWeek,
    bool? isActive,
  }) {
    return MedicationReminder(
      id: id,
      medicineName: medicineName ?? this.medicineName,
      times: times ?? this.times,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
    );
  }
}
