import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/models/talk_question.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:app_events/domain/repositories/talk_interaction_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/live_activity_provider.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:app_events/ui/providers/talk_interaction_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/schedule/schedule_detail.dart';
import 'package:app_events/ui/widgets/home/home_live_section.dart';
import 'package:app_events/ui/widgets/home/live_talk_card.dart';
import 'package:app_events/ui/widgets/home/question_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fixtures.dart';

class _MockEventRepository extends Mock implements EventRepository {}

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockTalkInteractionRepository extends Mock
    implements TalkInteractionRepository {}

void main() {
  late _MockEventRepository eventRepository;
  late _MockScheduleRepository scheduleRepository;
  late StreamController<List<Event>> events;
  late StreamController<List<Speaker>> schedule;

  setUp(() {
    eventRepository = _MockEventRepository();
    scheduleRepository = _MockScheduleRepository();
    events = StreamController<List<Event>>.broadcast();
    schedule = StreamController<List<Speaker>>.broadcast();
    when(
      () => eventRepository.getEventsStream(),
    ).thenAnswer((_) => events.stream);
    when(
      () => scheduleRepository.getListScheduleStream(any()),
    ).thenAnswer((_) => schedule.stream);
  });

  tearDown(() async {
    await events.close();
    await schedule.close();
  });

  // The loading indicator and the backdrop animate forever.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                LiveActivityProvider(eventRepository, scheduleRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => ScheduleProvider(scheduleRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => UserProvider(_MockUserRepository()),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: HomeLiveSection())),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> showActivities(
    WidgetTester tester,
    List<Speaker> activities,
  ) async {
    events.add([makeEvent(id: 'e1', status: EventStatus.active)]);
    await tester.pump();
    schedule.add(activities);
    await settle(tester);
  }

  testWidgets('shows a loading card until the first answer', (tester) async {
    await pumpSection(tester);

    expect(find.text(AppStrings.homeLiveEmpty), findsNothing);
    expect(find.byType(LiveTalkCard), findsNothing);
    expect(find.text(AppStrings.homeLiveWindowTitle), findsOne);
  });

  testWidgets('shows the empty state when no activity is live', (tester) async {
    await pumpSection(tester);

    await showActivities(tester, [makeSpeaker()]);

    expect(find.text(AppStrings.homeLiveEmpty), findsOne);
    expect(find.byType(LiveTalkCard), findsNothing);
  });

  testWidgets('shows the live talk of an event not activated yet', (
    tester,
  ) async {
    await pumpSection(tester);

    events.add([makeEvent(id: 'e1')]);
    await tester.pump();
    schedule.add([makeSpeaker(title: 'Live talk', isLive: true)]);
    await settle(tester);

    expect(find.text('Live talk'), findsOne);
    expect(find.text(AppStrings.homeLiveEmpty), findsNothing);
  });

  testWidgets('shows the empty state when every event is finished', (
    tester,
  ) async {
    await pumpSection(tester);

    events.add([makeEvent(id: 'e1', status: EventStatus.finished)]);
    await settle(tester);

    expect(find.text(AppStrings.homeLiveEmpty), findsOne);
  });

  testWidgets('shows the live talk with its data and question box', (
    tester,
  ) async {
    await pumpSection(tester);

    await showActivities(tester, [
      makeSpeaker(
        title: 'Live talk',
        name: 'Grace Hopper',
        schedule: '10:00 - 11:00',
        isLive: true,
      ),
    ]);

    expect(find.text('Live talk'), findsOne);
    expect(find.text('Grace Hopper'), findsOne);
    expect(find.text('10:00 - 11:00'), findsOne);
    expect(
      find.text('${AppStrings.homeLiveQuestionHintPrefix}Grace...'),
      findsOne,
    );
    final box = tester.widget<QuestionBox>(find.byType(QuestionBox));
    expect(box.eventId, 'e1');
    expect(box.speakerUuid, 'spk-1');
  });

  testWidgets('forwards live question submission to TalkInteractionProvider', (
    tester,
  ) async {
    final talkRepo = _MockTalkInteractionRepository();
    when(
      () => talkRepo.submitQuestion(
        eventId: 'e1',
        speakerUuid: 'spk-live',
        text: 'How does live activity sync work?',
      ),
    ).thenAnswer(
      (_) async => const TalkQuestionSubmitResult(
        questionId: 'q-1',
        missionRewarded: false,
        ticketsAwarded: 0,
        ticketsAfter: 0,
      ),
    );
    final talkProvider = TalkInteractionProvider(talkRepo);
    addTearDown(talkProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                LiveActivityProvider(eventRepository, scheduleRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => ScheduleProvider(scheduleRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => UserProvider(_MockUserRepository()),
          ),
          ChangeNotifierProvider.value(value: talkProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: HomeLiveSection())),
        ),
      ),
    );
    await tester.pump();
    await showActivities(tester, [
      makeSpeaker(
        uuid: 'spk-live',
        title: 'Live talk',
        name: 'Grace Hopper',
        isLive: true,
      ),
    ]);

    await tester.enterText(
      find.byType(TextField),
      'How does live activity sync work?',
    );
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();

    verify(
      () => talkRepo.submitQuestion(
        eventId: 'e1',
        speakerUuid: 'spk-live',
        text: 'How does live activity sync work?',
      ),
    ).called(1);
  });

  testWidgets('a live break has no question box', (tester) async {
    await pumpSection(tester);

    await showActivities(tester, [
      makeSpeaker(type: 'break', name: '', title: 'Coffee', isLive: true),
    ]);

    expect(find.byType(LiveTalkCard), findsOne);
    expect(find.byType(QuestionBox), findsNothing);
  });

  testWidgets('changes with Firebase and clears the old activity', (
    tester,
  ) async {
    await pumpSection(tester);
    await showActivities(tester, [
      makeSpeaker(uuid: 'a', title: 'First talk', isLive: true),
    ]);
    expect(find.text('First talk'), findsOne);

    schedule.add([
      makeSpeaker(uuid: 'a', title: 'First talk'),
      makeSpeaker(uuid: 'b', title: 'Second talk', isLive: true),
    ]);
    await settle(tester);
    expect(find.text('First talk'), findsNothing);
    expect(find.text('Second talk'), findsOne);

    schedule.add([makeSpeaker(uuid: 'b', title: 'Second talk')]);
    await settle(tester);
    expect(find.text('Second talk'), findsNothing);
    expect(find.text(AppStrings.homeLiveEmpty), findsOne);
  });

  testWidgets('tapping the live activity opens its detail screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpSection(tester);
    await showActivities(tester, [
      makeSpeaker(title: 'Live talk', isLive: true),
    ]);

    await tester.tap(find.text('Live talk'));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));

    final detail = tester.widget<ScheduleDetail>(find.byType(ScheduleDetail));
    expect(detail.eventId, 'e1');
    expect(detail.info.title, 'Live talk');
  });
}
