import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/auth/models/app_user.dart';
import 'package:medilink/features/auth/repositories/auth_repository.dart';

/// Provides a singleton instance of [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// A synchronous representation of the current [AppUser] state.
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// StateNotifier responsible for handling explicit login / logout actions.
class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  AuthRepository get _repo => _read.read(authRepositoryProvider);

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clears error state when switching between login and register screens.
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

/// Public provider exposing the [AuthController].
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>(
  (ref) => AuthController(ref),
);

