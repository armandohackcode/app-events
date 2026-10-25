import 'package:app_events/domain/models/auth_user.dart';

abstract class AuthDatasource {
  /// Emits the current user on every sign-in/sign-out, or null when signed out
  Stream<AuthUser?> authStateChanges();

  /// Signs in with a Google account and stores the session locally
  Future<AuthUser> signInWithGoogle();

  /// Signs in with an Apple ID and stores the session locally
  Future<AuthUser> signInWithApple();

  /// Signs out of every provider and clears the local session
  Future<void> signOut();
}
