import 'package:firebase_auth/firebase_auth.dart';
import 'package:medilink/features/auth/models/app_user.dart';

/// Repository responsible for mediating between FirebaseAuth and
/// the rest of the application.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Stream of [AppUser] used to drive auth state in the app.
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
          (user) {
            print('DEBUG: AuthRepository - Firebase authStateChanges emitted user: ${user?.email}');
            if (user == null) {
              print('DEBUG: AuthRepository - User is null');
              return null;
            }
            final appUser = AppUser.create(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
            );
            print('DEBUG: AuthRepository - Created AppUser: ${appUser.email}, Role: ${appUser.role.displayName}');
            return appUser;
          },
        ).handleError(
          (error, stackTrace) {
            print('DEBUG: AuthRepository - Stream error: $error');
            print('DEBUG: AuthRepository - Stack trace: $stackTrace');
            throw error;
          },
        );
  }

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    return AppUser.create(
      uid: user.uid,
      email: user.email ?? email,
      displayName: user.displayName,
    );
  }

  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    return AppUser.create(
      uid: user.uid,
      email: user.email ?? email,
      displayName: user.displayName,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Delete the current user account from Firebase Auth
  /// Note: Cascade deletion of related data should be handled by the caller
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Get current user UID
  String? getCurrentUserUid() {
    return _firebaseAuth.currentUser?.uid;
  }
}

