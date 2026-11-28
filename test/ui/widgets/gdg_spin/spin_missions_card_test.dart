import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_missions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleMissions = [
    SpinMission(
      id: 'done_mission',
      type: SpinMissionType.profileComplete,
      title: 'Complete profile',
      reward: 1,
      done: true,
      actionLabel: 'Claim',
    ),
    SpinMission(
      id: 'pending_mission',
      type: SpinMissionType.askSpeaker,
      title: 'Ask speaker',
      reward: 1,
      completions: 1,
      maxCompletionsPerUser: 3,
      done: false,
      actionLabel: AppStrings.askLabel,
    ),
    SpinMission(
      id: 'trivia_1',
      type: SpinMissionType.trivia,
      title: 'Morning trivia',
      reward: 1,
      done: false,
      actionLabel: AppStrings.playLabel,
      triviaQuestion: 'Which Firebase service hosts static web apps?',
      triviaOptions: ['Firebase Hosting', 'Crashlytics', 'App Check'],
    ),
    SpinMission(
      id: 'trivia_2',
      type: SpinMissionType.trivia,
      title: 'Afternoon trivia',
      reward: 2,
      done: false,
      actionLabel: AppStrings.playLabel,
      triviaQuestion: 'Which SDK calls Gemini from mobile apps?',
      triviaOptions: ['Firebase AI Logic', 'Remote Config'],
    ),
  ];

  testWidgets('shows progress, action buttons, and stand code button', (
    tester,
  ) async {
    SpinMission? tapped;
    var standCodeTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpinMissionsCard(
              missions: sampleMissions,
              openTriviaMissionId: null,
              onMissionTap: (m) => tapped = m,
              onAnswerTrivia: (_, _) {},
              onRedeemCodeTap: () => standCodeTapped++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Claim'), findsNothing);
    expect(find.text(AppStrings.askLabel), findsOneWidget);
    expect(find.text(AppStrings.playLabel), findsNWidgets(2));
    expect(
      find.textContaining(AppStrings.spinMissionProgress(1, 3)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.spinHaveStandCode), findsOneWidget);

    await tester.tap(find.text(AppStrings.askLabel));
    await tester.pumpAndSettle();
    expect(tapped?.id, 'pending_mission');

    await tester.tap(find.text(AppStrings.spinHaveStandCode));
    await tester.pumpAndSettle();
    expect(standCodeTapped, 1);
  });

  testWidgets(
    'renders dynamic inline trivia below matching openTriviaMissionId',
    (tester) async {
      String? answeredId;
      int? answeredIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpinMissionsCard(
                missions: sampleMissions,
                openTriviaMissionId: 'trivia_2',
                onMissionTap: (_) {},
                onAnswerTrivia: (missionId, optionIndex) {
                  answeredId = missionId;
                  answeredIndex = optionIndex;
                },
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Which Firebase service hosts static web apps?'),
        findsNothing,
      );
      expect(
        find.text('Which SDK calls Gemini from mobile apps?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Firebase AI Logic'));
      expect(answeredId, 'trivia_2');
      expect(answeredIndex, 0);

      await tester.tap(find.text('Remote Config'));
      expect(answeredId, 'trivia_2');
      expect(answeredIndex, 1);
    },
  );
}
