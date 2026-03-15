import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the singleton [FirebaseAuth] instance.
///
/// All authentication operations should use this provider rather than
/// calling `FirebaseAuth.instance` directly, enabling testability.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the singleton [FirebaseFirestore] instance.
///
/// All Firestore read/write operations should use this provider.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Streams the current Firebase [User] whenever auth state changes.
///
/// Emits `null` when the user is signed out.
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Provides the currently signed-in [User] synchronously.
///
/// Returns `null` if not signed in or if the auth state hasn't loaded yet.
final currentFirebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthStateProvider).valueOrNull;
});
