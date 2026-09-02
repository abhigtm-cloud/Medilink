enum UserRole { hospitalAdmin, normalUser, doctor }

extension UserRoleExtension on UserRole {
  bool get isHospitalAdmin => this == UserRole.hospitalAdmin;
  bool get isNormalUser => this == UserRole.normalUser;
  bool get isDoctor => this == UserRole.doctor;
  
  String get displayName {
    switch (this) {
      case UserRole.hospitalAdmin:
        return 'Hospital Admin';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.normalUser:
        return 'Patient';
    }
  }
}

/// Returns role based on email domain or keywords
UserRole _getRoleFromEmail(String email, {String? explicitRole}) {
  if (explicitRole == 'doctor') return UserRole.doctor;
  if (explicitRole == 'hospital_admin') return UserRole.hospitalAdmin;
  final normalizedEmail = email.trim().toLowerCase();
  if (normalizedEmail.contains('doctor') || normalizedEmail.startsWith('dr.')) {
    return UserRole.doctor;
  }
  if (normalizedEmail.endsWith('@hospital.com')) {
    return UserRole.hospitalAdmin;
  }
  return UserRole.normalUser;
}

/// Domain model representing an authenticated MEDILINK user.
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final UserRole role;
  final String? photoUrl;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? allergies;
  final String? medicalConditions;
  final String? currentMedications;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    this.photoUrl,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.allergies,
    this.medicalConditions,
    this.currentMedications,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.createdAt,
  });

  factory AppUser.create({
    required String uid,
    required String email,
    String? displayName,
    UserRole? role,
    String? photoUrl,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? allergies,
    String? medicalConditions,
    String? currentMedications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role ?? _getRoleFromEmail(email),
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodGroup: bloodGroup,
      address: address,
      allergies: allergies,
      medicalConditions: medicalConditions,
      currentMedications: currentMedications,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    return AppUser.create(
      uid: json['uid'] as String? ?? '',
      email: email,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      address: json['address'] as String?,
      allergies: json['allergies'] as String?,
      medicalConditions: json['medicalConditions'] as String?,
      currentMedications: json['currentMedications'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactRelation: json['emergencyContactRelation'] as String?,
      createdAt: json['createdAt'] != null 
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
      role: _getRoleFromEmail(email, explicitRole: json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'currentMedications': currentMedications,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelation': emergencyContactRelation,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? photoUrl,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? allergies,
    String? medicalConditions,
    String? currentMedications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

