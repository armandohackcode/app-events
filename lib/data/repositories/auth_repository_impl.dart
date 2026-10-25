import 'package:app_events/domain/datasources/auth_datasource.dart';
import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource _auth;
  AuthRepositoryImpl(this._auth);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<AuthUser> signInWithGoogle() => _auth.signInWithGoogle();

  @override
  Future<AuthUser> signInWithApple() => _auth.signInWithApple();

  @override
  Future<void> signOut() => _auth.signOut();
}
