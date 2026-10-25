import 'package:app_events/data/datasources/firebase_auth_datasource.dart';
import 'package:app_events/env.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleAccount extends Mock implements GoogleSignInAccount {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

// Apple sign-in calls a static platform API (SignInWithApple) and is covered
// by the provider tests through the repository contract instead.
void main() {
  late _MockFirebaseAuth auth;
  late _MockGoogleSignIn google;
  late FirebaseAuthDatasource datasource;

  _MockUser firebaseUser() {
    final user = _MockUser();
    when(() => user.uid).thenReturn('u-1');
    when(() => user.displayName).thenReturn('Grace');
    when(() => user.photoURL).thenReturn('https://img/u.png');
    return user;
  }

  setUpAll(() {
    registerFallbackValue(GoogleAuthProvider.credential(idToken: 'fallback'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = _MockFirebaseAuth();
    google = _MockGoogleSignIn();
    datasource = FirebaseAuthDatasource(auth, google);
  });

  test('authStateChanges maps Firebase users and sign-outs', () {
    when(
      () => auth.authStateChanges(),
    ).thenAnswer((_) => Stream.fromIterable([firebaseUser(), null]));

    expect(
      datasource.authStateChanges().map((u) => u?.uid),
      emitsInOrder(['u-1', null, emitsDone]),
    );
  });

  test(
    'signInWithGoogle signs in with the Google id token and stores the uid',
    () async {
      final account = _MockGoogleAccount();
      final credential = _MockUserCredential();
      when(
        () => google.initialize(serverClientId: any(named: 'serverClientId')),
      ).thenAnswer((_) async {});
      when(() => google.authenticate()).thenAnswer((_) async => account);
      when(
        () => account.authentication,
      ).thenReturn(const GoogleSignInAuthentication(idToken: 'id-token'));
      when(
        () => auth.signInWithCredential(any()),
      ).thenAnswer((_) async => credential);
      final user = firebaseUser();
      when(() => credential.user).thenReturn(user);

      final result = await datasource.signInWithGoogle();

      verify(
        () => google.initialize(serverClientId: serviceClientId),
      ).called(1);
      final sent =
          verify(() => auth.signInWithCredential(captureAny())).captured.single
              as OAuthCredential;
      expect(sent.idToken, 'id-token');
      expect(result.uid, 'u-1');
      expect(result.displayName, 'Grace');
      expect(result.photoUrl, 'https://img/u.png');
      final storage = await SharedPreferences.getInstance();
      expect(storage.getString('uid_user'), 'u-1');
    },
  );

  test(
    'signOut signs out of Google, clears the session, then Firebase',
    () async {
      SharedPreferences.setMockInitialValues({'uid_user': 'u-1'});
      final calls = <String>[];
      when(() => google.signOut()).thenAnswer((_) async => calls.add('google'));
      when(() => auth.signOut()).thenAnswer((_) async {
        final storage = await SharedPreferences.getInstance();
        calls.add('firebase:${storage.getString('uid_user')}');
      });

      await datasource.signOut();

      expect(calls, ['google', 'firebase:null']);
    },
  );

  test('generateNonce uses only URL-safe characters', () {
    final nonce = datasource.generateNonce(64);

    expect(nonce, hasLength(64));
    expect(nonce, matches(RegExp(r'^[0-9A-Za-z\-._]+$')));
  });
}
