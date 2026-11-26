import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/schedule_screen/talk_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Speaker speaker) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TalkDetailCard(
                info: speaker,
                photo: const AssetImage(AppAssetsPath.logoGdg),
              ),
            ),
          ),
        ),
      );

  testWidgets('shows schedule, tags, title and speaker', (tester) async {
    await pumpCard(tester, makeSpeaker(schedule: '09:45 - 10:45'));

    expect(find.text('09:45 - 10:45'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text(AppStrings.eventTypeConference), findsOneWidget);
    expect(find.text('Flutter Clean Architecture'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('GDE', findRichText: true), findsOneWidget);
  });

  testWidgets('shows the stored type as a capitalized label', (tester) async {
    await pumpCard(tester, makeSpeaker(type: 'workshop'));

    expect(find.text(AppStrings.eventTypeWorkshop), findsOneWidget);
    expect(find.text('workshop'), findsNothing);
  });

  testWidgets('shows every part of a profession split by a dot', (
    tester,
  ) async {
    await pumpCard(
      tester,
      makeSpeaker(profession: 'AI Manager · Google Developer Expert · Teacher'),
    );

    expect(
      find.textContaining('AI Manager', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Google Developer Expert', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Teacher', findRichText: true), findsOneWidget);
  });

  testWidgets('hides the technology tag when the talk has none', (
    tester,
  ) async {
    await pumpCard(tester, makeSpeaker(technologyType: ''));

    expect(find.text('Mobile'), findsNothing);
    expect(find.text(AppStrings.eventTypeConference), findsOneWidget);
  });

  testWidgets('hides the schedule when there is none', (tester) async {
    await pumpCard(tester, makeSpeaker(schedule: ''));

    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
  });

  testWidgets('hides the profession when it is empty', (tester) async {
    await pumpCard(tester, makeSpeaker(profession: ''));

    expect(find.text('GDE', findRichText: true), findsNothing);
    expect(find.text('Ada'), findsOneWidget);
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
        profession: '$long · $long',
        technologyType: 'Artificial intelligence and machine learning',
        type: 'Workshop of a very long name indeed',
        schedule: '09:45 - 10:45',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('an activity without speaker has no speaker row', (tester) async {
    await pumpCard(tester, makeSpeaker(name: '', profession: 'GDE'));

    expect(find.text('GDE', findRichText: true), findsNothing);
    expect(find.text('Flutter Clean Architecture'), findsOneWidget);
  });
}
