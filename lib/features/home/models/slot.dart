/// Represents a time slot for a doctor
class Slot {
  final String? id;
  final String doctorId;
  final String hospitalId;
  final String date; // Format: "yyyy-MM-dd"
  final String time; // Format: "HH:mm - HH:mm" (e.g., "10:00 - 10:30")
  final String? bookedBy; // UID of the user who booked this slot, null if available
  final DateTime? createdAt;

  const Slot({
    this.id,
    required this.doctorId,
    required this.hospitalId,
    required this.date,
    required this.time,
    this.bookedBy,
    this.createdAt,
  });

  bool get isAvailable => bookedBy == null;

  Slot copyWith({
    String? id,
    String? doctorId,
    String? hospitalId,
    String? date,
    String? time,
    String? bookedBy,
    DateTime? createdAt,
  }) {
    return Slot(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      hospitalId: hospitalId ?? this.hospitalId,
      date: date ?? this.date,
      time: time ?? this.time,
      bookedBy: bookedBy ?? this.bookedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Slot.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Slot(
      id: docId ?? json['id'] as String?,
      doctorId: json['doctorId'] as String,
      hospitalId: json['hospitalId'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      bookedBy: json['bookedBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      'date': date,
      'time': time,
      'bookedBy': bookedBy,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
