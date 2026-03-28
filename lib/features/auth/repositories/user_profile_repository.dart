import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/features/auth/models/app_user.dart';

class UserProfileRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late final DatabaseReference _usersRef;

  UserProfileRepository() {
    _usersRef = _database.ref('users');
  }

  /// Get user profile from Firebase
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final snapshot = await _usersRef.child(uid).get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return AppUser.fromJson(data);
      }
      return null;
    } catch (e) {
      print('DEBUG: Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile in Firebase
  Future<void> updateUserProfile(AppUser user) async {
    try {
      await _usersRef.child(user.uid).set(user.toJson());
    } catch (e) {
      print('DEBUG: Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update specific user field
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      await _usersRef.child(uid).update({
        field: value,
      });
    } catch (e) {
      print('DEBUG: Error updating user field: $e');
      throw Exception('Failed to update $field: $e');
    }
  }
}
