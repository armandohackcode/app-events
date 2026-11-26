import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/home/live_talk_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    VoidCallback? onTap,
    String title = 'Flutter Clean Architecture',
    String technologyType = 'Mobile',
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LiveTalkCard(
            talk: makeSpeaker(
              title: title,
              technologyType: technologyType,
              schedule: '09:45 - 10:45',
            ),
            onTap: onTap ?? () {},
          ),
        ),
      ),
    ),
  );

  testWidgets('shows the talk, speaker, schedule and live badge', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Flutter Clean Architecture'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('GDE'), findsOneWidget);
    expect(find.text('09:45 - 10:45'), findsOneWidget);
    expect(find.text(AppStrings.homeLiveWindowTitle), findsOneWidget);
    expect(find.text(AppStrings.homeLiveBadge), findsOneWidget);
  });

  testWidgets('shows the technology area of the talk', (tester) async {
    await pumpCard(tester);

    expect(find.text('Mobile'), findsOneWidget);
  });

  testWidgets('hides the technology tag when the talk has none', (
    tester,
  ) async {
    await pumpCard(tester, technologyType: '');

    expect(find.text('Mobile'), findsNothing);
  });

  testWidgets('a long technology area is cut instead of overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpCard(
      tester,
      technologyType: 'Artificial intelligence and machine learning',
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text('Artificial intelligence and machine learning'),
      findsOneWidget,
    );
  });

  testWidgets('tapping the talk calls onTap', (tester) async {
    var taps = 0;
    await pumpCard(tester, onTap: () => taps++);

    await tester.tap(find.text('Flutter Clean Architecture'));

    expect(taps, 1);
  });

  Future<void> pumpActivity(WidgetTester tester, Speaker activity) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveTalkCard(talk: activity, onTap: () {}),
            ),
          ),
        ),
      );

  testWidgets('a live lunch shows its icon and description, not a speaker', (
    tester,
  ) async {
    await pumpActivity(
      tester,
      makeSpeaker(type: 'lunch', title: 'Lunch time', description: 'Buffet'),
    );

    expect(find.text('Lunch time'), findsOneWidget);
    expect(find.text('Buffet'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    expect(find.text('Ada'), findsNothing);
  });

  testWidgets('uses the type name when the activity has no title', (
    tester,
  ) async {
    await pumpActivity(tester, makeSpeaker(type: 'break', title: ''));

    expect(find.text(AppStrings.eventTypeBreak), findsOneWidget);
  });

  testWidgets('leaves out the speaker data that is empty', (tester) async {
    await pumpActivity(
      tester,
      makeSpeaker(name: '', profession: '', socialNetwork: []),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Flutter Clean Architecture'), findsOneWidget);
    expect(find.text('GDE'), findsNothing);
  });

  testWidgets('long speaker data does not overflow at 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final long = List.filled(40, 'extraordinarily').join(' ');

    await pumpActivity(
      tester,
      makeSpeaker(name: long, profession: long, title: long),
    );

    expect(tester.takeException(), isNull);
  });
}
