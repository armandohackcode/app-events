import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/widgets/home/ranking_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockOtherRepository extends Mock implements OtherRepository {}

UserCompetitor _makeCompetitor(
  String name,
  int score, {
  String profession = 'Mobile Developer',
}) => UserCompetitor(
  uuid: name.toLowerCase(),
  name: name,
  photoUrl: '',
  profession: profession,
  aboutMe: '',
  tokenAuthorization: '',
  score: score,
  socialNetwork: const [],
  friends: const [],
  treasures: const [],
);

void main() {
  late _MockOtherRepository otherRepo;
  late OtherProvider otherProvider;
  late StreamController<List<UserCompetitor>> rankingController;

  setUp(() {
    otherRepo = _MockOtherRepository();
    otherProvider = OtherProvider(otherRepo);
    rankingController = StreamController<List<UserCompetitor>>.broadcast();
    when(
      () => otherRepo.getRanking(),
    ).thenAnswer((_) => rankingController.stream);
  });

  tearDown(() async {
    await rankingController.close();
    otherProvider.dispose();
  });

  Widget wrapScreen({Size size = const Size(390, 844), double scale = 1.0}) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: true,
        textScaler: TextScaler.linear(scale),
      ),
      child: ChangeNotifierProvider.value(
        value: otherProvider,
        child: const MaterialApp(home: RankingData()),
      ),
    );
  }

  testWidgets('shows loading state while ranking is empty', (tester) async {
    await tester.pumpWidget(wrapScreen());
    await tester.pump();

    expect(find.text(AppStrings.rankingTitle), findsOneWidget);
    expect(find.text(AppStrings.rankingLoading), findsOneWidget);
    expect(find.byType(CardRanking), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders podium and general leaderboard cleanly at 320x844 and 1.3x text scale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapScreen(size: const Size(320, 844), scale: 1.3),
      );
      rankingController.add([
        _makeCompetitor('Alice', 500),
        _makeCompetitor('Bruno', 420),
        _makeCompetitor('Carla', 310),
        _makeCompetitor('Diego', 210),
        _makeCompetitor('Elena', 150, profession: ''),
      ]);
      await tester.pump();
      await tester.pump();

      expect(find.text(AppStrings.rankingPodiumTag), findsOneWidget);
      expect(find.text(AppStrings.rankingLeaderboardTag), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Carla'), findsOneWidget);
      expect(find.text('Diego'), findsOneWidget);
      expect(find.text('Elena'), findsOneWidget);
      expect(find.text(AppStrings.rankingPointsBadge(500)), findsOneWidget);
      expect(find.text(AppStrings.rankingPointsBadge(210)), findsOneWidget);
      expect(find.text(AppStrings.rankingPositionLabel(4)), findsOneWidget);
      expect(find.text(AppStrings.rankingPositionLabel(5)), findsOneWidget);
      expect(find.byType(CardRanking), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
