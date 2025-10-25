import 'dart:convert';
import 'dart:math';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:crypto/crypto.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInSocialNetworkProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth auth;
  final UserProvider userProvider;

  SignInSocialNetworkProvider(this.googleSignIn, this.auth, this.userProvider);

  bool _isAuth = false;
  bool _outService = false;
  bool _loadingAuth = false;
  bool _loadingValidate = true;

  late User _userInfo;

  bool get isAuth => _isAuth;
  bool get loadingAuth => _loadingAuth;
  bool get loadingValidate => _loadingValidate;

  set loadingValidate(bool state) {
    _loadingValidate = state;
    notifyListeners();
  }

  set loadingAuth(bool state) {
    _loadingAuth = state;
    notifyListeners();
  }

  set isAuth(bool state) {
    _isAuth = state;
    notifyListeners();
  }

  // ignore: unnecessary_getters_setters
  User get userInfo => _userInfo;
  set userInfo(User user) {
    _userInfo = user;
  }

  bool get isOutService => _outService;
  set isOutService(bool state) {
    _outService = state;
    notifyListeners();
  }

  Future<void> validateToken() async {
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _userInfo = user;
          if (!isAuth) {
            isAuth = true;
          }
        }
        // return;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> googleAuth() async {
    try {
      loadingAuth = true;
      googleSignIn.initialize(serverClientId: "567592938140-hrje5fbbdfmfoitkvgf5dmef94ufk714.apps.googleusercontent.com");
      var googleUser = await googleSignIn.authenticate();
      var googleAuth = googleUser.authentication;
      var credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      var resInfo = await auth.signInWithCredential(credential);
      _userInfo = resInfo.user!;
      var storage = await SharedPreferences.getInstance();
      storage.setString('uid_user', resInfo.user!.uid);

      await userProvider.addCompetitor(
        name: _userInfo.displayName ?? "Anonymous",
        token: "",
        photoUrl: _userInfo.photoURL ?? "",
      );

      isAuth = true;
    } catch (e) {
      loadingAuth = false;
      if (kDebugMode) {
        print(e);
      }
    }
  }

  // Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
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

  Future<void> appleAuth() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    try {
      loadingAuth = true;
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
      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      // Sign in the user with Firebase. If the nonce we generated earlier does
      // not match the nonce in `appleCredential.identityToken`, sign in will fail.
      var resInfo = await auth.signInWithCredential(oauthCredential);
      _userInfo = resInfo.user!;
      var storage = await SharedPreferences.getInstance();
      storage.setString('uid_user', resInfo.user!.uid);
      isAuth = true;
      // var res = await _identifyUser(resInfo.user!.email!, "APPLE");
      // if (res == true) {
      //   isAuth = true;
      // }
      await userProvider.addCompetitor(
        name: _userInfo.displayName ?? "Anonymous",
        token: "",
        photoUrl: _userInfo.photoURL ?? "",
      );
      loadingAuth = false;
    } on FirebaseAuthException catch (e) {
      loadingAuth = false;
      if (kDebugMode) {
        print(e);
      }
    } catch (e) {
      loadingAuth = false;
    }
  }

  Future<void> logOut() async {
    await googleSignIn.signOut();
    var storage = await SharedPreferences.getInstance();
    await storage.clear();
    await auth.signOut();
  }
}
