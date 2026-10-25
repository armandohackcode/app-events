import 'dart:async';

import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserProvider extends Mock implements UserProvider {}

const _user = AuthUser(
  uid: 'u-1',
  displayName: 'Grace',
  photoUrl: 'https://img/u.png',
);

void main() {
  late _MockAuthRepository repository;
  late _MockUserProvider userProvider;
  late SignInSocialNetworkProvider provider;

  setUp(() {
    repository = _MockAuthRepository();
    userProvider = _MockUserProvider();
    provider = SignInSocialNetworkProvider(repository, userProvider);
  });

  tearDown(() => provider.dispose());

  void stubAddCompetitor({void Function()? onCall}) {
    when(
      () => userProvider.addCompetitor(
        name: any(named: 'name'),
        token: any(named: 'token'),
        photoUrl: any(named: 'photoUrl'),
      ),
    ).thenAnswer((_) async => onCall?.call());
  }

  group('validateToken', () {
    test('authenticates when the auth state emits a user', () async {
      final controller = StreamController<AuthUser?>();
      when(
        () => repository.authStateChanges(),
      ).thenAnswer((_) => controller.stream);

      await provider.validateToken();
      controller.add(_user);
      await pumpEventQueue();

      expect(provider.isAuth, isTrue);
      expect(provider.userInfo.uid, 'u-1');
      await controller.close();
    });

    test('stays signed out when the auth state emits null', () async {
      when(
        () => repository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));

      await provider.validateToken();
      await pumpEventQueue();

      expect(provider.isAuth, isFalse);
    });
  });

  group('googleAuth', () {
    test(
      'registers the competitor before marking the user as signed in',
      () async {
        when(
          () => repository.signInWithGoogle(),
        ).thenAnswer((_) async => _user);
        bool? isAuthWhenRegistering;
        stubAddCompetitor(
          onCall: () => isAuthWhenRegistering = provider.isAuth,
        );

        await provider.googleAuth();

        verify(
          () => userProvider.addCompetitor(
            name: 'Grace',
            token: '',
            photoUrl: 'https://img/u.png',
          ),
        ).called(1);
        expect(isAuthWhenRegistering, isFalse);
        expect(provider.isAuth, isTrue);
        expect(provider.userInfo.uid, 'u-1');
      },
    );

    test('uses fallbacks when the account has no name or photo', () async {
      when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) async => const AuthUser(uid: 'u-2'));
      stubAddCompetitor();

      await provider.googleAuth();

      verify(
        () => userProvider.addCompetitor(
          name: 'Anonymous',
          token: '',
          photoUrl: '',
        ),
      ).called(1);
    });

    test('stays signed out and stops loading when sign-in fails', () async {
      when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) async => throw Exception('cancelled'));

      await provider.googleAuth();

      expect(provider.isAuth, isFalse);
      expect(provider.loadingAuth, isFalse);
      verifyNever(
        () => userProvider.addCompetitor(
          name: any(named: 'name'),
          token: any(named: 'token'),
          photoUrl: any(named: 'photoUrl'),
        ),
      );
    });

    test(
      'stops loading after a successful sign-in',
      () async {
        // After logging out, the sign-in screen shows a spinner instead of
        // the buttons while loadingAuth is still true.
        when(
          () => repository.signInWithGoogle(),
        ).thenAnswer((_) async => _user);
        stubAddCompetitor();

        await provider.googleAuth();

        expect(provider.loadingAuth, isFalse);
      },
      skip: 'BUG: googleAuth leaves loadingAuth true after success',
    );
  });

  group('appleAuth', () {
    test(
      'marks the user as signed in before registering the competitor',
      () async {
        when(() => repository.signInWithApple()).thenAnswer((_) async => _user);
        bool? isAuthWhenRegistering;
        stubAddCompetitor(
          onCall: () => isAuthWhenRegistering = provider.isAuth,
        );

        await provider.appleAuth();

        expect(isAuthWhenRegistering, isTrue);
        expect(provider.isAuth, isTrue);
        expect(provider.loadingAuth, isFalse);
      },
    );

    test('stays signed out and stops loading when sign-in fails', () async {
      when(
        () => repository.signInWithApple(),
      ).thenAnswer((_) async => throw Exception('cancelled'));

      await provider.appleAuth();

      expect(provider.isAuth, isFalse);
      expect(provider.loadingAuth, isFalse);
    });
  });

  test('logOut signs out through the repository', () async {
    when(() => repository.signOut()).thenAnswer((_) async {});

    await provider.logOut();

    verify(() => repository.signOut()).called(1);
  });
}
