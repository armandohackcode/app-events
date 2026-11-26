import 'dart:convert';
import 'dart:math';

import 'package:app_events/domain/datasources/auth_datasource.dart';
import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/env.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthDatasource implements AuthDatasource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInitFuture;

  FirebaseAuthDatasource(this._auth, this._googleSignIn);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(
    (user) => user == null ? null : _toAuthUser(user),
  );

  /// Initializes Google Sign-In once and caches the future across calls,
  /// clearing it on failure so subsequent sign-in attempts can retry.
  Future<void> _ensureGoogleSignInInitialized() {
    final existing = _googleInitFuture;
    if (existing != null) return existing;

    final future = _initializeGoogleSignIn();
    _googleInitFuture = future;
    return future;
  }

  Future<void> _initializeGoogleSignIn() async {
    // Yield once so _googleInitFuture is cached before initialize can throw.
    await Future<void>.value();
    try {
      await _googleSignIn.initialize(serverClientId: serviceClientId);
    } catch (_) {
      _googleInitFuture = null;
      rethrow;
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google sign-in did not return an ID token.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _signInWithCredential(credential);
  }

  @override
  Future<AuthUser> signInWithApple() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    return _signInWithCredential(oauthCredential);
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    var storage = await SharedPreferences.getInstance();
    await storage.clear();
    await _auth.signOut();
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Signs in with Firebase and stores the uid that the user datasource reads.
  Future<AuthUser> _signInWithCredential(AuthCredential credential) async {
    var resInfo = await _auth.signInWithCredential(credential);
    final user = resInfo.user!;
    var storage = await SharedPreferences.getInstance();
    await storage.setString('uid_user', user.uid);
    return _toAuthUser(user);
  }

  AuthUser _toAuthUser(User user) => AuthUser(
    uid: user.uid,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    email: user.email,
    createdAt: user.metadata.creationTime,
  );
}
