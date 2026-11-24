import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/schedule_screen/talk_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Speaker speaker) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TalkDetailCard(
                info: speaker,
                photo: const AssetImage(AppAssetsPath.liveTalkPhoto),
              ),
            ),
          ),
        ),
      );

  testWidgets('shows title, speaker, profession, technology and activity', (
    tester,
  ) async {
    await pumpCard(tester, makeSpeaker(schedule: '09:45 - 10:45'));

    expect(find.text('Flutter Clean Architecture'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('GDE'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('conference | 09:45 - 10:45'), findsOneWidget);
  });

  testWidgets('hides the technology tag when the talk has none', (
    tester,
  ) async {
    await pumpCard(tester, makeSpeaker(technologyType: ''));

    expect(find.text('Mobile'), findsNothing);
    expect(find.text('Flutter Clean Architecture'), findsOneWidget);
  });

  testWidgets('shows only the activity when there is no schedule', (
    tester,
  ) async {
    await pumpCard(tester, makeSpeaker(schedule: ''));

    expect(find.text('conference'), findsOneWidget);
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
        technologyType: 'Artificial intelligence and machine learning',
        type: 'Workshop of a very long name indeed',
        schedule: '09:45 - 10:45',
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
