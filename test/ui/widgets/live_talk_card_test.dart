import 'package:app_events/config/theme/app_strings.dart';
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
}
