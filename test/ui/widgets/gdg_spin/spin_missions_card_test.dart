import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_missions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleMissions = [
    SpinMission(
      id: 'done_mission',
      title: 'Check-in',
      reward: 1,
      done: true,
      actionLabel: 'Claim',
    ),
    SpinMission(
      id: 'pending_mission',
      title: 'Ask speaker',
      reward: 1,
      done: false,
      actionLabel: AppStrings.askLabel,
    ),
    SpinMission(
      id: 'trivia',
      title: 'Break trivia',
      reward: 1,
      done: false,
      actionLabel: AppStrings.playLabel,
      isTrivia: true,
    ),
  ];

  testWidgets('shows action buttons only for pending missions', (tester) async {
    SpinMission? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpinMissionsCard(
            missions: sampleMissions,
            triviaOpen: false,
            onMissionTap: (m) => tapped = m,
            onAnswerTrivia: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Claim'), findsNothing);
    expect(find.text(AppStrings.askLabel), findsOneWidget);
    expect(find.text(AppStrings.playLabel), findsOneWidget);
    expect(find.text(AppStrings.spinTriviaQuestion), findsNothing);

    final askTargetSize = tester.getSize(
      find
          .ancestor(
            of: find.text(AppStrings.askLabel),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(askTargetSize.height, greaterThanOrEqualTo(44));

    await tester.tap(find.text(AppStrings.askLabel));
    await tester.pumpAndSettle();

    expect(tapped?.id, 'pending_mission');
  });

  testWidgets('expands trivia options and reports right/wrong answers', (
    tester,
  ) async {
    bool? answeredCorrect;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpinMissionsCard(
              missions: sampleMissions,
              triviaOpen: true,
              onMissionTap: (_) {},
              onAnswerTrivia: (correct) => answeredCorrect = correct,
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.spinTriviaQuestion), findsOneWidget);

    await tester.tap(find.text(AppStrings.spinTriviaOptionA));
    expect(answeredCorrect, isTrue);

    await tester.tap(find.text(AppStrings.spinTriviaOptionB));
    expect(answeredCorrect, isFalse);
  });
}
