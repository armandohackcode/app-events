import 'dart:math';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/treasure_hunt_model.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/activities/activities_screen.dart';
import 'package:app_events/ui/widgets/activities/activity_ranking_card.dart';
import 'package:app_events/ui/widgets/activities/activity_spin_card.dart';
import 'package:app_events/ui/widgets/activities/activity_treasure_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockOtherRepository extends Mock implements OtherRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockOtherRepository otherRepo;
  late _MockUserRepository userRepo;
  late OtherProvider otherProvider;
  late UserProvider userProvider;
  late GdgSpinProvider spinProvider;

  setUp(() {
    otherRepo = _MockOtherRepository();
    userRepo = _MockUserRepository();
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
    otherProvider = OtherProvider(otherRepo);
    userProvider = UserProvider(userRepo);
    spinProvider = GdgSpinProvider(random: Random(1));
  });

  tearDown(() {
    otherProvider.dispose();
    userProvider.dispose();
    spinProvider.dispose();
  });

  Widget buildScreen({double width = 390}) => MediaQuery(
    data: MediaQueryData(size: Size(width, 844), disableAnimations: true),
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: otherProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: spinProvider),
      ],
      child: const MaterialApp(home: ActivitiesScreen()),
    ),
  );

  testWidgets('displays Ranking, GDG SPIN, and Treasure Hunt cards in order', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final rankingY = tester.getTopLeft(find.byType(ActivityRankingCard)).dy;
    final spinY = tester.getTopLeft(find.byType(ActivitySpinCard)).dy;
    final treasureY = tester.getTopLeft(find.byType(ActivityTreasureCard)).dy;

    expect(rankingY, lessThan(spinY));
    expect(spinY, lessThan(treasureY));
  });

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
}
