import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/user/profile_screen.dart';
import 'package:app_events/ui/widgets/profile/modal_qr_identify.dart';
import 'package:app_events/ui/widgets/profile/profile_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

UserCompetitor _makeUser({
  List<Friend> friends = const [],
  List<String> treasures = const ['t1', 't2'],
  String aboutMe = 'Mobile community builder.',
}) => UserCompetitor(
  uuid: 'user-123',
  name: 'Ada Lovelace',
  photoUrl: '',
  profession: 'Systems Engineer',
  aboutMe: aboutMe,
  tokenAuthorization: '',
  score: 340,
  socialNetwork: [
    SocialNetwork(type: 'GITHUB', link: 'https://github.com/gdgsucre'),
    SocialNetwork(type: 'LINKEDIN', link: 'https://linkedin.com/in/example'),
  ],
  friends: friends,
  treasures: treasures,
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
      ..userInfo = const AuthUser(
        uid: 'user-123',
        displayName: 'Ada Lovelace',
        photoUrl: '',
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

  testWidgets('renders profile card, stats, social icons, and QR modal', (
    tester,
  ) async {
    userProvider.userCompetitor = _makeUser(friends: _makeFriends(2));

    await tester.pumpWidget(wrapScreen());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.profileCommunityHeader), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Systems Engineer'), findsOneWidget);
    expect(find.text('Mobile community builder.'), findsOneWidget);
    expect(find.text('340'), findsOneWidget);
    expect(find.text(AppStrings.commonWordPoints), findsOneWidget);
    expect(find.text(AppStrings.profileFriendsStat), findsOneWidget);
    expect(find.text(AppStrings.profileTreasuresStat), findsOneWidget);

    await tester.tap(find.text(AppStrings.profileQrAction));
    await tester.pumpAndSettle();
    expect(find.byType(ModalQrIdentify), findsOneWidget);
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
