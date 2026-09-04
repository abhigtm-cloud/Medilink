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
  final String? email; // Doctor's email for notifications and login
  final bool isAbsent; // Absent / On Leave status
  final String? absentReason; // Reason for absence (e.g. sick leave, emergency)
  final String? authUid; // Firebase Auth UID linked to this doctor
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
    this.email,
    this.isAbsent = false,
    this.absentReason,
    this.authUid,
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
    String? email,
    bool? isAbsent,
    String? absentReason,
    String? authUid,
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
      email: email ?? this.email,
      isAbsent: isAbsent ?? this.isAbsent,
      absentReason: absentReason ?? this.absentReason,
      authUid: authUid ?? this.authUid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Doctor.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Doctor(
      id: docId ?? json['id'] as String?,
      hospitalId: json['hospitalId'] as String? ?? '',
      name: json['name'] as String? ?? 'Doctor',
      specialization: json['specialization'] as String? ?? 'General Physician',
      startTime: json['startTime'] as String? ?? '09:00',
      endTime: json['endTime'] as String? ?? '17:00',
      slotDurationMinutes: json['slotDurationMinutes'] != null
          ? int.tryParse(json['slotDurationMinutes'].toString()) ?? 30
          : 30,
      photoUrl: json['photoUrl'] as String?,
      email: json['email'] as String?,
      isAbsent: json['isAbsent'] as bool? ?? false,
      absentReason: json['absentReason'] as String?,
      authUid: json['authUid'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
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
      'email': email,
      'isAbsent': isAbsent,
      'absentReason': absentReason,
      'authUid': authUid,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
