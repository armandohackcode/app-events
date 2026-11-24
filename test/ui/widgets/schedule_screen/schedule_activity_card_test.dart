import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_activity_card.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_general_card.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_talk_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    Speaker speaker, {
    bool highlighted = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ScheduleActivityCard(item: speaker, highlighted: highlighted),
        ),
      ),
    ),
  );

  testWidgets('a talk is drawn with the talk card', (tester) async {
    await pumpCard(tester, makeSpeaker());

    expect(find.byType(ScheduleTalkCard), findsOneWidget);
    expect(find.byType(ScheduleGeneralCard), findsNothing);
  });

  testWidgets('breaks, lunch and networking use the general card', (
    tester,
  ) async {
    for (final type in ['break', 'lunch', 'networking']) {
      await pumpCard(tester, makeSpeaker(type: type));

      expect(find.byType(ScheduleGeneralCard), findsOneWidget, reason: type);
      expect(find.byType(ScheduleTalkCard), findsNothing, reason: type);
    }
  });

  testWidgets('the LIVE marker works on talks and on general activities', (
    tester,
  ) async {
    await pumpCard(tester, makeSpeaker(), highlighted: true);
    expect(find.text(AppStrings.homeLiveBadge), findsOneWidget);

    await pumpCard(tester, makeSpeaker(type: 'lunch'), highlighted: true);
    expect(find.text(AppStrings.homeLiveBadge), findsOneWidget);
  });

  testWidgets('no LIVE badge when it is not highlighted', (tester) async {
    await pumpCard(tester, makeSpeaker());

    expect(find.text(AppStrings.homeLiveBadge), findsNothing);
  });
}
