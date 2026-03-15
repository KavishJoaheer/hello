import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';

/// Provides a singleton instance of [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Streams the current Firebase [User] whenever auth state changes
/// (sign-in, sign-out, token refresh).
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Exposes the currently signed-in [User] synchronously (may be null).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Handles the sign-in action.
///
/// Usage from a widget:
/// ```dart
/// final signIn = ref.read(signInProvider);
/// await signIn(email: 'test@test.com', password: '123456');
/// ```
final signInProvider = Provider<
    Future<UserCredential> Function({
      required String email,
      required String password,
    })>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return ({required String email, required String password}) {
    return repo.signInWithEmail(email: email, password: password);
  };
});

/// Handles the sign-up action.
///
/// Usage from a widget:
/// ```dart
/// final signUp = ref.read(signUpProvider);
/// await signUp(email: 'a@b.com', password: 'secret', displayName: 'Alice');
/// ```
final signUpProvider = Provider<
    Future<UserCredential> Function({
      required String email,
      required String password,
      required String displayName,
    })>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return ({
    required String email,
    required String password,
    required String displayName,
  }) {
    return repo.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  };
});

/// Handles the sign-out action.
final signOutProvider = Provider<Future<void> Function()>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.signOut;
});

/// Handles the account deletion action.
final deleteAccountProvider = Provider<Future<void> Function()>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.deleteAccount;
});

/// Handles the password-reset action.
final resetPasswordProvider =
    Provider<Future<void> Function({required String email})>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return ({required String email}) => repo.resetPassword(email: email);
});
