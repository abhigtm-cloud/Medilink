enum UserRole { hospitalAdmin, normalUser }

extension UserRoleExtension on UserRole {
  bool get isHospitalAdmin => this == UserRole.hospitalAdmin;
  bool get isNormalUser => this == UserRole.normalUser;
  
  String get displayName {
    switch (this) {
      case UserRole.hospitalAdmin:
        return 'Hospital Admin';
      case UserRole.normalUser:
        return 'Normal User';
    }
  }
}

/// Returns role based on email domain
UserRole _getRoleFromEmail(String email) {
  final normalizedEmail = email.trim().toLowerCase();
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
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.createdAt,
  });

  factory AppUser.create({
    required String uid,
    required String email,
    String? displayName,
    UserRole? role,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role ?? _getRoleFromEmail(email),
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodGroup: bloodGroup,
      address: address,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String;
    return AppUser.create(
      uid: json['uid'] as String,
      email: email,
      displayName: json['displayName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      address: json['address'] as String?,
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
      role: _getRoleFromEmail(email),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

