import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/user/delete_account.dart';
import 'package:app_events/ui/screens/user/profile_screen.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_context_binder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/fixtures.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockEventRepository extends Mock implements EventRepository {}

class _MockSpinRepository extends Mock implements SpinRepository {}

UserCompetitor _makeCompetitor({
  String uuid = 'u-1',
  String name = 'Ada Lovelace',
  String? currentEventId = 'evt-1',
}) => UserCompetitor(
  uuid: uuid,
  name: name,
  photoUrl: '',
  profession: 'Engineer',
  aboutMe: 'Dart enthusiast',
  tokenAuthorization: '',
  score: 10,
  currentEventId: currentEventId,
  socialNetwork: const [],
  friends: const [],
);

void main() {
  group('UserProvider session and admin reset', () {
    late _MockUserRepository userRepo;
    late UserProvider userProvider;

    setUp(() {
      userRepo = _MockUserRepository();
      userProvider = UserProvider(userRepo);
    });

    tearDown(() => userProvider.dispose());

    test(
      'validateIsAdmin resets isAdmin to false for non-admin user',
      () async {
        when(
          () => userRepo.validateIsAdmin('admin-1'),
        ).thenAnswer((_) async => true);
        when(
          () => userRepo.getUserInfo('admin-1'),
        ).thenAnswer((_) async => _makeCompetitor(uuid: 'admin-1'));
        await userProvider.validateIsAdmin('admin-1');
        expect(userProvider.isAdmin, isTrue);

        when(
          () => userRepo.validateIsAdmin('user-2'),
        ).thenAnswer((_) async => false);
        when(
          () => userRepo.getUserInfo('user-2'),
        ).thenAnswer((_) async => _makeCompetitor(uuid: 'user-2'));
        await userProvider.validateIsAdmin('user-2');
        expect(userProvider.isAdmin, isFalse);
      },
    );

    test(
      'clearSession clears isAdmin, userCompetitor, and notifies listeners',
      () {
        userProvider.isAdmin = true;
        userProvider.userCompetitor = _makeCompetitor();
        var notifications = 0;
        userProvider.addListener(() => notifications++);

        userProvider.clearSession();

        expect(userProvider.isAdmin, isFalse);
        expect(userProvider.userCompetitor, isNull);
        expect(notifications, 1);
      },
    );
  });

  group('SignInSocialNetworkProvider validateToken lifecycle', () {
    test(
      'tracks null auth transitions and cancels previous/disposed subscriptions',
      () async {
        final authRepo = _MockAuthRepository();
        final userRepo = _MockUserRepository();
        final userProvider = UserProvider(userRepo);
        final authProvider = SignInSocialNetworkProvider(
          authRepo,
          userProvider,
        );

        var activeSubscriptions = 0;
        Stream<AuthUser?> makeTrackedStream() {
          late StreamController<AuthUser?> controller;
          controller = StreamController<AuthUser?>(
            onListen: () {
              activeSubscriptions++;
            },
            onCancel: () {
              activeSubscriptions--;
            },
          );
          return controller.stream;
        }

        final firstController = StreamController<AuthUser?>(
          onListen: () => activeSubscriptions++,
          onCancel: () => activeSubscriptions--,
        );
        final secondController = StreamController<AuthUser?>(
          onListen: () => activeSubscriptions++,
          onCancel: () => activeSubscriptions--,
        );
        addTearDown(firstController.close);
        addTearDown(secondController.close);

        var calls = 0;
        when(() => authRepo.authStateChanges()).thenAnswer((_) {
          calls++;
          return calls == 1 ? firstController.stream : secondController.stream;
        });
        // Silence unused helper
        expect(makeTrackedStream, isNotNull);

        await authProvider.validateToken();
        expect(activeSubscriptions, 1);

        firstController.add(
          const AuthUser(uid: 'u-1', email: 'u1@example.com'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(authProvider.isAuth, isTrue);

        firstController.add(null);
        await Future<void>.delayed(Duration.zero);
        expect(authProvider.isAuth, isFalse);

        await authProvider.validateToken();
        expect(activeSubscriptions, 1);

        authProvider.dispose();
        userProvider.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(activeSubscriptions, 0);
      },
    );
  });

  group('EventProvider live stream updates', () {
    test(
      'updates events and activeEvent from getEventsStream and cancels on dispose',
      () async {
        final eventRepo = _MockEventRepository();
        final streamController = StreamController<List<Event>>.broadcast();
        addTearDown(streamController.close);

        when(() => eventRepo.getEvents()).thenAnswer(
          (_) async => [makeEvent(id: 'evt-1', status: EventStatus.upcoming)],
        );
        when(
          () => eventRepo.getEventsStream(),
        ).thenAnswer((_) => streamController.stream);

        final provider = EventProvider(eventRepo);
        await provider.loadEvents();
        expect(provider.activeEvent, isNull);
        expect(streamController.hasListener, isTrue);

        streamController.add([
          makeEvent(id: 'evt-1', status: EventStatus.active),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(provider.activeEvent?.id, 'evt-1');

        provider.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(streamController.hasListener, isFalse);
      },
    );
  });

  group('Logout and account deletion cleanup', () {
    setUpAll(() {
      registerFallbackValue(_makeCompetitor());
    });

    late _MockSpinRepository spinRepo;
    late _MockAuthRepository authRepo;
    late _MockUserRepository userRepo;
    late GdgSpinProvider spinProvider;
    late SpinAdminProvider spinAdminProvider;
    late UserProvider userProvider;
    late SignInSocialNetworkProvider authProvider;

    setUp(() async {
      spinRepo = _MockSpinRepository();
      authRepo = _MockAuthRepository();
      userRepo = _MockUserRepository();

      when(
        () => spinRepo.watchConfig(any()),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchPrizes(any(), activeOnly: any(named: 'activeOnly')),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () =>
            spinRepo.watchMissions(any(), activeOnly: any(named: 'activeOnly')),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchPlayer(any(), any()),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchMyWins(any(), any()),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchMyMissionClaims(any(), any()),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchAllWins(any(), status: any(named: 'status')),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchTicketCodes(any()),
      ).thenAnswer((_) => const Stream.empty());
      when(() => spinRepo.initPlayer(any())).thenAnswer(
        (_) async => const SpinInitPlayerResult(
          player: SpinPlayer(uid: 'u-1', tickets: 2),
          initialGranted: false,
        ),
      );
      when(() => spinRepo.getDashboard(any())).thenAnswer(
        (_) async => const SpinDashboardStats(
          config: SpinConfig(),
          stats: SpinStatsSummary(),
          prizes: [],
          winCounts: SpinWinCounts(),
        ),
      );
      when(() => authRepo.signOut()).thenAnswer((_) async {});
      when(
        () => userRepo.streamInfoUser(any()),
      ).thenAnswer((_) => const Stream.empty());

      userProvider = UserProvider(userRepo);
      userProvider.isAdmin = true;
      userProvider.userCompetitor = _makeCompetitor();
      authProvider = SignInSocialNetworkProvider(authRepo, userProvider);
      authProvider.isAuth = true;
      authProvider.userInfo = const AuthUser(uid: 'u-1');
      spinProvider = GdgSpinProvider(spinRepo);
      spinAdminProvider = SpinAdminProvider(spinRepo);

      await spinProvider.bind(eventId: 'evt-1', uid: 'u-1');
      await spinAdminProvider.bind('evt-1');
    });

    tearDown(() {
      spinProvider.dispose();
      spinAdminProvider.dispose();
      authProvider.dispose();
      userProvider.dispose();
    });

    testWidgets(
      'ProfileScreen logout clears session and unbinds spin providers',
      (tester) async {
        expect(spinProvider.isBound, isTrue);
        expect(spinAdminProvider.isBound, isTrue);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: userProvider),
                ChangeNotifierProvider.value(value: authProvider),
                ChangeNotifierProvider.value(value: spinProvider),
                ChangeNotifierProvider.value(value: spinAdminProvider),
              ],
              child: const MaterialApp(home: ProfileScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.profileLogOut));
        await tester.pumpAndSettle();

        verify(() => authRepo.signOut()).called(1);
        expect(userProvider.isAdmin, isFalse);
        expect(userProvider.userCompetitor, isNull);
        expect(authProvider.isAuth, isFalse);
        expect(spinProvider.isBound, isFalse);
        expect(spinAdminProvider.isBound, isFalse);
      },
    );

    testWidgets(
      'DeleteAccount confirmation clears session and unbinds spin providers',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: authProvider),
              ChangeNotifierProvider.value(value: spinProvider),
              ChangeNotifierProvider.value(value: spinAdminProvider),
            ],
            child: const MaterialApp(home: DeleteAccount()),
          ),
        );

        await tester.tap(
          find.widgetWithText(ElevatedButton, AppStrings.deleteAccount),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.commonWordYes));
        await tester.pumpAndSettle();

        verify(() => authRepo.signOut()).called(1);
        expect(userProvider.isAdmin, isFalse);
        expect(userProvider.userCompetitor, isNull);
        expect(authProvider.isAuth, isFalse);
        expect(spinProvider.isBound, isFalse);
        expect(spinAdminProvider.isBound, isFalse);
      },
    );

    testWidgets(
      'SpinContextBinder unbinds GdgSpinProvider when uid transitions to null',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: authProvider),
              ChangeNotifierProvider.value(value: spinProvider),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  context.watch<UserProvider>();
                  context.watch<SignInSocialNetworkProvider>();
                  scheduleSpinContextBinding(
                    context,
                    spinProvider: spinProvider,
                    alreadyRequestedEvents: true,
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        await tester.pump();
        expect(spinProvider.isBound, isTrue);

        userProvider.clearSession();
        authProvider.isAuth = false;
        await tester.pump();
        await tester.pump();

        expect(spinProvider.isBound, isFalse);
      },
    );
  });
}
