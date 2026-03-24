/// Represents a doctor in a hospital
class Doctor {
  final String? id;
  final String hospitalId;
  final String name;
  final String specialization;
  final String startTime; // Format: "HH:mm" (24-hour)
  final String endTime; // Format: "HH:mm" (24-hour)
  final int slotDurationMinutes;
  final String? photoUrl; // Base64 encoded doctor photo (optional)
  final DateTime? createdAt;

  const Doctor({
    this.id,
    required this.hospitalId,
    required this.name,
    required this.specialization,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
    this.photoUrl,
    this.createdAt,
  });

  Doctor copyWith({
    String? id,
    String? hospitalId,
    String? name,
    String? specialization,
    String? startTime,
    String? endTime,
    int? slotDurationMinutes,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      hospitalId: hospitalId ?? this.hospitalId,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Doctor.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Doctor(
      id: docId ?? json['id'] as String?,
      hospitalId: json['hospitalId'] as String,
      name: json['name'] as String,
      specialization: json['specialization'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      slotDurationMinutes: json['slotDurationMinutes'] as int,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hospitalId': hospitalId,
      'name': name,
      'specialization': specialization,
      'startTime': startTime,
      'endTime': endTime,
      'slotDurationMinutes': slotDurationMinutes,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
