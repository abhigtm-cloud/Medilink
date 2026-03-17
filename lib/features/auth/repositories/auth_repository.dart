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
          (user) => user == null
              ? null
              : AppUser.create(
                  uid: user.uid,
                  email: user.email ?? '',
                  displayName: user.displayName,
                ),
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
}

