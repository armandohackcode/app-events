import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_talk_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    Speaker speaker, {
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScheduleTalkCard(info: speaker, onTap: onTap),
        ),
      ),
    ),
  );

  testWidgets('shows time, tags, title and speaker', (tester) async {
    await pumpCard(tester, makeSpeaker(schedule: '09:45 - 10:45'));

    expect(find.text('09:45 - 10:45'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text(AppStrings.eventTypeConference), findsOneWidget);
    expect(find.text('Flutter Clean Architecture'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('GDE'), findsOneWidget);
  });

  testWidgets('shows the workshop and panel labels', (tester) async {
    await pumpCard(tester, makeSpeaker(type: 'workshop'));
    expect(find.text(AppStrings.eventTypeWorkshop), findsOneWidget);

    await pumpCard(tester, makeSpeaker(type: 'panel'));
    expect(find.text(AppStrings.eventTypePanel), findsOneWidget);
  });

  testWidgets('hides the speaker row when there is no speaker name', (
    tester,
  ) async {
    await pumpCard(tester, makeSpeaker(name: ''));

    expect(find.text('GDE'), findsNothing);
  });

  testWidgets('tapping the card calls onTap', (tester) async {
    var taps = 0;
    await pumpCard(tester, makeSpeaker(), onTap: () => taps++);

    await tester.tap(find.text('Flutter Clean Architecture'));

    expect(taps, 1);
  });

  testWidgets('very long texts do not overflow at 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final long = List.filled(40, 'extraordinarily').join(' ');
    await pumpCard(
      tester,
      makeSpeaker(
        title: long,
        name: long,
        profession: long,
        technologyType: 'Artificial intelligence and machine learning',
        type: 'panel',
        schedule: '09:45 - 10:45',
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
