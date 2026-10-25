import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:flutter/foundation.dart';

class SignInSocialNetworkProvider extends ChangeNotifier {
  final AuthRepository authRepository;
  final UserProvider userProvider;

  SignInSocialNetworkProvider(this.authRepository, this.userProvider);

  bool _isAuth = false;
  bool _outService = false;
  bool _loadingAuth = false;
  bool _loadingValidate = true;

  late AuthUser _userInfo;

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
  AuthUser get userInfo => _userInfo;
  set userInfo(AuthUser user) {
    _userInfo = user;
  }

  bool get isOutService => _outService;
  set isOutService(bool state) {
    _outService = state;
    notifyListeners();
  }

  Future<void> validateToken() async {
    try {
      authRepository.authStateChanges().listen((user) {
        if (user != null) {
          _userInfo = user;
          if (!isAuth) {
            isAuth = true;
          }
        }
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
      _userInfo = await authRepository.signInWithGoogle();

      await userProvider.addCompetitor(
        name: _userInfo.displayName ?? "Anonymous",
        token: "",
        photoUrl: _userInfo.photoUrl ?? "",
      );

      isAuth = true;
    } catch (e) {
      loadingAuth = false;
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> appleAuth() async {
    try {
      loadingAuth = true;
      _userInfo = await authRepository.signInWithApple();
      isAuth = true;
      await userProvider.addCompetitor(
        name: _userInfo.displayName ?? "Anonymous",
        token: "",
        photoUrl: _userInfo.photoUrl ?? "",
      );
      loadingAuth = false;
    } catch (e) {
      loadingAuth = false;
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> logOut() async {
    await authRepository.signOut();
  }
}
