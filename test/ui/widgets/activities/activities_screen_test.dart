import 'dart:math';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/treasure_hunt_model.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/activities/activities_screen.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_screen.dart';
import 'package:app_events/ui/widgets/activities/activity_ranking_card.dart';
import 'package:app_events/ui/widgets/activities/activity_spin_card.dart';
import 'package:app_events/ui/widgets/activities/activity_treasure_card.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockOtherRepository extends Mock implements OtherRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockSpinRepository extends Mock implements SpinRepository {}

void main() {
  late _MockOtherRepository otherRepo;
  late _MockUserRepository userRepo;
  late _MockSpinRepository spinRepo;
  late OtherProvider otherProvider;
  late UserProvider userProvider;
  late GdgSpinProvider spinProvider;
  late SpinAdminProvider spinAdminProvider;

  setUp(() {
    otherRepo = _MockOtherRepository();
    userRepo = _MockUserRepository();
    spinRepo = _MockSpinRepository();
    when(() => otherRepo.getTreasureHuntItems()).thenAnswer(
      (_) async => [
        TreasureHuntModel(
          uuid: 't1',
          title: 'Item 1',
          imgPath: '',
          question: 'Q',
          answer: 'A',
          description: 'D',
        ),
        TreasureHuntModel(
          uuid: 't2',
          title: 'Item 2',
          imgPath: '',
          question: 'Q',
          answer: 'A',
          description: 'D',
        ),
      ],
    );
    when(() => userRepo.getAttendees()).thenAnswer((_) async => []);
    otherProvider = OtherProvider(otherRepo);
    userProvider = UserProvider(userRepo);
    spinProvider = GdgSpinProvider(spinRepo, random: Random(1));
    spinAdminProvider = SpinAdminProvider(spinRepo);
  });

  tearDown(() {
    otherProvider.dispose();
    userProvider.dispose();
    spinProvider.dispose();
    spinAdminProvider.dispose();
  });

  Widget buildScreen({double width = 390}) => MediaQuery(
    data: MediaQueryData(size: Size(width, 844), disableAnimations: true),
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: otherProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: spinProvider),
        ChangeNotifierProvider.value(value: spinAdminProvider),
      ],
      child: const MaterialApp(home: ActivitiesScreen()),
    ),
  );

  testWidgets(
    'displays GDG brand header and Ranking, GDG SPIN, Treasure Hunt cards in order',
    (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.text(AppStrings.organizersGDGSucre), findsOneWidget);
      expect(find.text(AppStrings.homeHeaderSubtitle), findsOneWidget);

      final headerY = tester.getTopLeft(find.byType(HomeHeader)).dy;
      final rankingY = tester.getTopLeft(find.byType(ActivityRankingCard)).dy;
      final spinY = tester.getTopLeft(find.byType(ActivitySpinCard)).dy;
      final treasureY = tester.getTopLeft(find.byType(ActivityTreasureCard)).dy;

      expect(headerY, lessThan(rankingY));
      expect(rankingY, lessThan(spinY));
      expect(spinY, lessThan(treasureY));
    },
  );

  testWidgets(
    'tapping Treasure Hunt without competitor shows snackbar instead of crashing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final button = find.text(AppStrings.activitiesTreasureAction);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.activitiesJoinEventFirst), findsOneWidget);
    },
  );

  testWidgets('renders cleanly across narrow and tablet widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    userProvider.userCompetitor = UserCompetitor(
      uuid: 'u1',
      name: 'Ada',
      photoUrl: '',
      profession: 'Dev',
      aboutMe: '',
      tokenAuthorization: '',
      score: 10,
      socialNetwork: const [],
      friends: const [],
      treasures: const ['t1'],
    );

    for (final width in [320.0, 390.0, 768.0]) {
      await tester.binding.setSurfaceSize(Size(width, 844));
      await tester.pumpWidget(buildScreen(width: width));
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'admin card is hidden for regular users and opens SpinAdminScreen when isAdmin is true',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Hidden for regular users.
      userProvider.isAdmin = false;
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.spinAdminTitle), findsNothing);

      // Visible for admins, shows helpful snackbar when no event is selected.
      userProvider.isAdmin = true;
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.spinAdminTitle), findsOneWidget);

      final openButton = find.text(AppStrings.spinAdminOpenAction);
      await tester.ensureVisible(openButton);
      await tester.pumpAndSettle();
      await tester.tap(openButton);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.spinAdminNoEventError), findsOneWidget);

      // Navigates to SpinAdminScreen when an event is resolved.
      when(
        () => spinRepo.watchConfig('evt-1'),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () =>
            spinRepo.watchPrizes('evt-1', activeOnly: any(named: 'activeOnly')),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchMissions(
          'evt-1',
          activeOnly: any(named: 'activeOnly'),
        ),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchPlayer('evt-1', 'u1'),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchMyWins('evt-1', 'u1'),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchMyMissionClaims('evt-1', 'u1'),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchAllWins('evt-1', status: any(named: 'status')),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchTicketCodes('evt-1'),
      ).thenAnswer((_) => const Stream.empty());
      when(() => spinRepo.initPlayer('evt-1')).thenAnswer(
        (_) async => const SpinInitPlayerResult(
          player: SpinPlayer(uid: 'u1', tickets: 2),
        ),
      );
      when(() => spinRepo.getDashboard('evt-1')).thenAnswer(
        (_) async => const SpinDashboardStats(
          config: SpinConfig(),
          stats: SpinStatsSummary(),
          prizes: [],
          winCounts: SpinWinCounts(),
        ),
      );

      userProvider.userCompetitor = UserCompetitor(
        uuid: 'u1',
        name: 'Admin User',
        photoUrl: '',
        profession: 'Organizer',
        aboutMe: '',
        tokenAuthorization: '',
        score: 0,
        currentEventId: 'evt-1',
        socialNetwork: const [],
        friends: const [],
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(openButton);
      await tester.pumpAndSettle();
      await tester.tap(openButton);
      await tester.pumpAndSettle();

      expect(find.byType(SpinAdminScreen), findsOneWidget);
    },
  );
}
