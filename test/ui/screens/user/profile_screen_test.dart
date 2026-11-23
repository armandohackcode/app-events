import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/domain/models/event_badge.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/user/profile_screen.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/profile/modal_qr_identify.dart';
import 'package:app_events/ui/widgets/profile/profile_public.dart';
import 'package:app_events/ui/widgets/shared/button_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

UserCompetitor _makeUser({
  List<Friend> friends = const [],
  List<EventBadge> badges = const [],
  String? currentEventId,
  String aboutMe = 'Mobile community builder.',
  String profession = 'Systems Engineer',
  List<SocialNetwork>? socialNetwork,
}) => UserCompetitor(
  uuid: 'user-123',
  name: 'Ada Lovelace',
  photoUrl: '',
  profession: profession,
  aboutMe: aboutMe,
  tokenAuthorization: '',
  score: 340,
  currentEventId: currentEventId,
  badges: badges,
  socialNetwork:
      socialNetwork ??
      [
        SocialNetwork(type: 'GITHUB', link: 'https://github.com/gdgsucre'),
        SocialNetwork(
          type: 'LINKEDIN',
          link: 'https://linkedin.com/in/example',
        ),
      ],
  friends: friends,
);

List<Friend> _makeFriends(int count) => List.generate(
  count,
  (i) => Friend(
    uuid: 'friend-$i',
    name: 'Friend User $i',
    photoUrl: '',
    token: '',
  ),
);

EventBadge _makeBadge(String eventId) => EventBadge(
  eventId: eventId,
  eventName: 'DevFest $eventId',
  eventDate: DateTime(2025, 11, 1),
  finalScore: 100,
  rank: 3,
  assetPath: '',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_makeUser());
  });

  late _MockAuthRepository authRepo;
  late _MockUserRepository userRepo;
  late StreamController<UserCompetitor?> userStreamController;
  late UserProvider userProvider;
  late SignInSocialNetworkProvider authProvider;

  setUp(() {
    authRepo = _MockAuthRepository();
    userRepo = _MockUserRepository();
    userStreamController = StreamController<UserCompetitor?>.broadcast();
    when(
      () => userRepo.streamInfoUser(any()),
    ).thenAnswer((_) => userStreamController.stream);
    when(() => authRepo.signOut()).thenAnswer((_) async {});

    userProvider = UserProvider(userRepo);
    authProvider = SignInSocialNetworkProvider(authRepo, userProvider)
      ..userInfo = AuthUser(
        uid: 'user-123',
        displayName: 'Ada Lovelace',
        photoUrl: '',
        email: 'ada@gdgsucre.dev',
        createdAt: DateTime(2024, 3, 15),
      )
      ..isAuth = true;
  });

  tearDown(() async {
    await userStreamController.close();
    authProvider.dispose();
    userProvider.dispose();
  });

  Widget wrapScreen({Size size = const Size(390, 844), double scale = 1.0}) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: true,
        textScaler: TextScaler.linear(scale),
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: userProvider),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
  }

  testWidgets(
    'renders profile card without badge, email, member-since, unique events count, and QR modal',
    (tester) async {
      userProvider.userCompetitor = _makeUser(
        friends: _makeFriends(2),
        badges: [_makeBadge('evt-1'), _makeBadge('evt-2')],
        currentEventId: 'evt-2',
      );

      await tester.pumpWidget(wrapScreen());
      await tester.pumpAndSettle();

      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.text(AppStrings.organizersGDGSucre), findsOneWidget);
      expect(find.text(AppStrings.homeHeaderSubtitle), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsNothing);
      expect(find.text('ada@gdgsucre.dev'), findsOneWidget);
      expect(find.text('Systems Engineer'), findsOneWidget);
      expect(find.text('Mobile community builder.'), findsOneWidget);
      expect(
        find.text(AppStrings.profileMemberSinceYear(2024)),
        findsOneWidget,
      );
      expect(find.text('340'), findsOneWidget);
      expect(find.text(AppStrings.commonWordPoints), findsOneWidget);
      expect(find.text(AppStrings.profileFriendsStat), findsOneWidget);
      expect(find.text(AppStrings.eventsTitle), findsOneWidget);
      // 2 unique events (badges evt-1 & evt-2, deduplicated with currentEventId evt-2)
      expect(
        find.text('2'),
        findsNWidgets(3),
      ); // stat friends + stat events + badge

      final buttonScanFinder = find.byType(ButtonScan);
      expect(buttonScanFinder, findsOneWidget);
      expect(
        find.ancestor(
          of: buttonScanFinder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Padding &&
                widget.padding == const EdgeInsets.only(bottom: 88),
          ),
        ),
        findsNothing,
      );

      await tester.tap(find.text(AppStrings.profileQrAction));
      await tester.pumpAndSettle();
      expect(find.byType(ModalQrIdentify), findsOneWidget);
    },
  );

  testWidgets('handles incomplete profile and zero connections cleanly', (
    tester,
  ) async {
    authProvider.userInfo = const AuthUser(
      uid: 'user-123',
      displayName: 'Ada Lovelace',
    );
    userProvider.userCompetitor = _makeUser(
      aboutMe: '',
      profession: '',
      socialNetwork: const [],
      friends: const [],
      currentEventId: 'evt-active',
    );

    await tester.pumpWidget(wrapScreen());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.profileEmailUnavailable), findsOneWidget);
    expect(find.text(AppStrings.profileProfessionUnavailable), findsOneWidget);
    expect(find.text(AppStrings.profileMsEditProfile), findsOneWidget);
    expect(find.text(AppStrings.profileMemberSinceUnknown), findsOneWidget);
    expect(find.text(AppStrings.profileNoSocialLinks), findsOneWidget);
    expect(find.text(AppStrings.profileNoConnections), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // active event counts as 1
  });

  testWidgets(
    'shows share public modal and expands connections beyond 5 cleanly',
    (tester) async {
      userProvider.userCompetitor = _makeUser(friends: _makeFriends(7));

      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapScreen(size: const Size(320, 844), scale: 1.3),
      );
      await tester.pumpAndSettle();

      expect(find.text('Friend User 0'), findsOneWidget);
      expect(find.text('Friend User 6'), findsNothing);
      expect(find.text(AppStrings.profileSeeAllConnections), findsOneWidget);
      expect(find.text(AppStrings.profileNewConnection), findsOneWidget);

      await tester.ensureVisible(
        find.text(AppStrings.profileSeeAllConnections),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.profileSeeAllConnections));
      await tester.pumpAndSettle();

      expect(find.text('Friend User 6'), findsOneWidget);
      expect(find.text(AppStrings.profileSeeLessConnections), findsOneWidget);

      final shareButton = find.text(AppStrings.commonWordShare);
      await tester.ensureVisible(shareButton);
      await tester.pumpAndSettle();
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      expect(find.byType(ModalProfilePublic), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('overflow menu triggers logout cleanly', (tester) async {
    userProvider.userCompetitor = _makeUser();

    await tester.pumpWidget(wrapScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.profileLogOut));
    await tester.pumpAndSettle();

    verify(() => authRepo.signOut()).called(1);
    expect(userProvider.userCompetitor, isNull);
    expect(authProvider.isAuth, isFalse);
  });
}
