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

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
  });

  factory AppUser.create({
    required String uid,
    required String email,
    String? displayName,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role ?? _getRoleFromEmail(email),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String;
    return AppUser.create(
      uid: json['uid'] as String,
      email: email,
      displayName: json['displayName'] as String?,
      role: _getRoleFromEmail(email),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }
}

