import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/schedule/schedule_detail.dart';
import 'package:app_events/ui/screens/schedule/schedule_screen.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_general_card.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_talk_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fixtures.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockEventRepository extends Mock implements EventRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockScheduleRepository scheduleRepository;
  late StreamController<List<Speaker>> scheduleStream;

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    scheduleRepository = _MockScheduleRepository();
    scheduleStream = StreamController<List<Speaker>>.broadcast();
    when(
      () => scheduleRepository.getListScheduleStream(any()),
    ).thenAnswer((_) => scheduleStream.stream);
  });

  tearDown(() => scheduleStream.close());

  // The animated backdrop never stops, so pumpAndSettle would time out.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
  }

  Event makeScreenEvent({String locationUrl = 'https://maps.example.com'}) =>
      Event(
        id: 'evt-1',
        title: 'DevFest',
        description: 'The flagship event of the community.',
        startDate: DateTime(2026, 10, 24),
        endDate: DateTime(2026, 10, 24),
        locationUrl: locationUrl,
        imageUrl: '',
        status: EventStatus.active,
      );

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Speaker>? schedule,
    Event? event,
  }) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => UserProvider(_MockUserRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => ScheduleProvider(scheduleRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => EventProvider(_MockEventRepository()),
          ),
        ],
        child: MaterialApp(
          home: ScheduleScreen(event: event ?? makeScreenEvent()),
        ),
      ),
    );
    await tester.pump();
    if (schedule != null) scheduleStream.add(schedule);
    await settle(tester);
  }

  testWidgets('shows the event status, description, date and place', (
    tester,
  ) async {
    await pumpScreen(tester, schedule: [makeSpeaker()]);

    expect(find.text(AppStrings.eventStatusActive.toUpperCase()), findsOne);
    expect(find.text('The flagship event of the community.'), findsOne);
    final weekday = DateFormat.EEEE('es').format(DateTime(2026, 10, 24));
    expect(
      find.text('${weekday[0].toUpperCase()}${weekday.substring(1)}'),
      findsOne,
    );
    expect(find.text(AppStrings.eventPlace), findsOne);
    expect(find.text(AppStrings.eventViewLocationHowTo), findsOne);
  });

  testWidgets('hides the place when the event has no location link', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      schedule: [makeSpeaker()],
      event: makeScreenEvent(locationUrl: ''),
    );

    expect(find.text(AppStrings.eventPlace), findsNothing);
  });

  testWidgets('the header counts every activity of the schedule', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      schedule: [
        makeSpeaker(uuid: 'a'),
        makeSpeaker(uuid: 'b', type: 'break'),
        makeSpeaker(uuid: 'c', type: 'lunch'),
      ],
    );

    expect(find.text('3 ${AppStrings.scheduleActivityPlural}'), findsOne);
  });

  testWidgets('talks use the talk card and breaks use the general card', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      schedule: [
        makeSpeaker(uuid: 'a'),
        makeSpeaker(uuid: 'b', type: 'break'),
        makeSpeaker(uuid: 'c', type: 'panel'),
      ],
    );

    expect(find.byType(ScheduleTalkCard), findsNWidgets(2));
    expect(find.byType(ScheduleGeneralCard), findsOne);
  });

  group('live activity', () {
    testWidgets('no activity is marked as LIVE when none is live', (
      tester,
    ) async {
      await pumpScreen(tester, schedule: [makeSpeaker()]);

      expect(find.text(AppStrings.homeLiveBadge), findsNothing);
    });

    testWidgets('the activity with isLive shows the LIVE badge', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        schedule: [
          makeSpeaker(uuid: 'a'),
          makeSpeaker(uuid: 'b', isLive: true),
        ],
      );

      expect(find.text(AppStrings.homeLiveBadge), findsOne);
    });

    testWidgets('a live break or lunch is marked too', (tester) async {
      await pumpScreen(
        tester,
        schedule: [makeSpeaker(uuid: 'a', type: 'lunch', isLive: true)],
      );

      expect(find.text(AppStrings.homeLiveBadge), findsOne);
    });

    testWidgets('the badge follows the live activity without reloading', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        schedule: [
          makeSpeaker(uuid: 'a', title: 'First talk', isLive: true),
          makeSpeaker(uuid: 'b', title: 'Second talk'),
        ],
      );
      expect(find.text(AppStrings.homeLiveBadge), findsOne);

      scheduleStream.add([
        makeSpeaker(uuid: 'a', title: 'First talk'),
        makeSpeaker(uuid: 'b', title: 'Second talk', isLive: true),
      ]);
      await settle(tester);
      expect(find.text(AppStrings.homeLiveBadge), findsOne);

      scheduleStream.add([
        makeSpeaker(uuid: 'a', title: 'First talk'),
        makeSpeaker(uuid: 'b', title: 'Second talk'),
      ]);
      await settle(tester);
      expect(find.text(AppStrings.homeLiveBadge), findsNothing);
    });

    testWidgets('only one activity is marked even if several are live', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        schedule: [
          makeSpeaker(uuid: '', isLive: true),
          makeSpeaker(uuid: '', isLive: true),
        ],
      );

      expect(find.text(AppStrings.homeLiveBadge), findsOne);
    });

    testWidgets('a finished event marks no activity as LIVE', (tester) async {
      await pumpScreen(
        tester,
        schedule: [makeSpeaker(isLive: true)],
        event: makeEvent(status: EventStatus.finished),
      );

      expect(find.text(AppStrings.homeLiveBadge), findsNothing);
    });

    testWidgets('it stops listening to the schedule when the screen closes', (
      tester,
    ) async {
      await pumpScreen(tester, schedule: [makeSpeaker()]);
      expect(scheduleStream.hasListener, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(scheduleStream.hasListener, isFalse);
    });
  });

  testWidgets('tapping a talk opens its detail screen', (tester) async {
    await pumpScreen(
      tester,
      schedule: [makeSpeaker(title: 'Clean architecture talk')],
    );

    await tester.tap(find.byType(ScheduleTalkCard));
    await settle(tester);

    expect(find.byType(ScheduleDetail), findsOne);
  });

  testWidgets('breaks and panels do not open a detail screen', (tester) async {
    await pumpScreen(
      tester,
      schedule: [
        makeSpeaker(uuid: 'a', type: 'break', title: 'Coffee break'),
        makeSpeaker(uuid: 'b', type: 'panel', title: 'Panel of experts'),
      ],
    );

    await tester.tap(
      find.textContaining('Coffee break', findRichText: true),
      warnIfMissed: false,
    );
    await settle(tester);
    await tester.tap(find.text('Panel of experts'), warnIfMissed: false);
    await settle(tester);

    expect(find.byType(ScheduleDetail), findsNothing);
  });
}
