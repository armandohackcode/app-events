import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/shared/time_and_tags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpTags(
    WidgetTester tester, {
    String schedule = '09:45 - 10:45',
    String technologyType = 'IA',
    String type = 'conference',
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TimeAndTags(
          schedule: schedule,
          technologyType: technologyType,
          type: type,
        ),
      ),
    ),
  );

  testWidgets('shows the time and both tags', (tester) async {
    await pumpTags(tester);

    expect(find.text('09:45 - 10:45'), findsOneWidget);
    expect(find.text('IA'), findsOneWidget);
    expect(find.text(AppStrings.eventTypeConference), findsOneWidget);
  });

  testWidgets('leaves out the parts that are empty', (tester) async {
    await pumpTags(tester, schedule: '', technologyType: '');

    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
    expect(find.text('IA'), findsNothing);
    expect(find.text(AppStrings.eventTypeConference), findsOneWidget);
  });

  testWidgets('long tags do not overflow at 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpTags(
      tester,
      technologyType: 'Artificial intelligence and machine learning',
      type: 'A very long activity type name indeed',
    );

    expect(tester.takeException(), isNull);
  });
}
