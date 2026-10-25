/// The signed-in user, independent of the authentication provider.
class AuthUser {
  final String uid;
  final String? displayName;
  final String? photoUrl;

  const AuthUser({required this.uid, this.displayName, this.photoUrl});
}
