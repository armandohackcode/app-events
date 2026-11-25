import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_general_card.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Speaker speaker) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScheduleGeneralCard(info: speaker),
            ),
          ),
        ),
      );

  testWidgets('shows time, title, description and the break icon', (
    tester,
  ) async {
    await pumpCard(
      tester,
      makeSpeaker(
        type: 'break',
        title: 'Coffee',
        description: 'Networking',
        schedule: '10:45 - 11:00',
      ),
    );

    expect(find.text('10:45 - 11:00'), findsOneWidget);
    expect(find.textContaining('Coffee', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('Networking', findRichText: true),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.coffee_rounded), findsOneWidget);
  });

  testWidgets('each kind has its own icon', (tester) async {
    await pumpCard(tester, makeSpeaker(type: 'lunch'));
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);

    await pumpCard(tester, makeSpeaker(type: 'networking'));
    expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);
  });

  testWidgets('lunch and networking cards have an opaque background', (
    tester,
  ) async {
    for (final type in ['lunch', 'networking']) {
      await pumpCard(tester, makeSpeaker(type: type));

      final box = tester.widgetList<HardShadowBox>(find.byType(HardShadowBox));
      expect(box.first.color.a, 1.0, reason: type);
    }
  });

  testWidgets('uses the type label when there is no title', (tester) async {
    await pumpCard(tester, makeSpeaker(type: 'lunch', title: ''));

    expect(
      find.textContaining(AppStrings.eventTypeLunch, findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('does not show a time pill without schedule', (tester) async {
    await pumpCard(tester, makeSpeaker(type: 'break', schedule: ''));

    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
  });

  testWidgets('long texts do not overflow at 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final long = List.filled(40, 'extraordinarily').join(' ');
    await pumpCard(
      tester,
      makeSpeaker(type: 'lunch', title: long, description: long),
    );

    expect(tester.takeException(), isNull);
  });
}
