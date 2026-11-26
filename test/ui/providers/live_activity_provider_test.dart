import 'dart:async';

import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:app_events/ui/providers/live_activity_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class _MockEventRepository extends Mock implements EventRepository {}

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late _MockEventRepository eventRepository;
  late _MockScheduleRepository scheduleRepository;
  late StreamController<List<Event>> events;
  late Map<String, StreamController<List<Speaker>>> schedules;
  late LiveActivityProvider provider;

  StreamController<List<Speaker>> scheduleOf(String eventId) => schedules
      .putIfAbsent(eventId, () => StreamController<List<Speaker>>.broadcast());

  setUp(() {
    eventRepository = _MockEventRepository();
    scheduleRepository = _MockScheduleRepository();
    events = StreamController<List<Event>>.broadcast();
    schedules = {};
    when(
      () => eventRepository.getEventsStream(),
    ).thenAnswer((_) => events.stream);
    when(() => scheduleRepository.getListScheduleStream(any())).thenAnswer((
      invocation,
    ) {
      final eventId = invocation.positionalArguments.first as String;
      return scheduleOf(eventId).stream;
    });
    provider = LiveActivityProvider(eventRepository, scheduleRepository);
  });

  tearDown(() async {
    provider.dispose();
    await events.close();
    for (final controller in schedules.values) {
      await controller.close();
    }
  });

  Event active(String id) => makeEvent(id: id, status: EventStatus.active);

  test('starts without an activity and loading until the first answer', () {
    expect(provider.activity, isNull);
    expect(provider.eventId, isNull);

    provider.start();

    expect(provider.loading, isTrue);
  });

  test('finished events are not followed', () async {
    provider.start();

    events.add([makeEvent(id: 'e1', status: EventStatus.finished)]);
    await pumpEventQueue();

    expect(provider.activity, isNull);
    expect(provider.eventId, isNull);
    expect(provider.loading, isFalse);
    verifyNever(() => scheduleRepository.getListScheduleStream(any()));
  });

  test('follows the live activity of the active event', () async {
    provider.start();
    events.add([
      makeEvent(id: 'old', status: EventStatus.finished),
      active('e1'),
    ]);
    await pumpEventQueue();
    expect(provider.loading, isTrue);

    scheduleOf(
      'e1',
    ).add([makeSpeaker(uuid: 'a'), makeSpeaker(uuid: 'b', isLive: true)]);
    await pumpEventQueue();

    expect(provider.activity?.uuid, 'b');
    expect(provider.eventId, 'e1');
    expect(provider.loading, isFalse);
  });

  test('there is no live activity when none is marked', () async {
    provider.start();
    events.add([active('e1')]);
    await pumpEventQueue();

    scheduleOf('e1').add([makeSpeaker(uuid: 'a')]);
    await pumpEventQueue();

    expect(provider.activity, isNull);
    expect(provider.loading, isFalse);
  });

  test(
    'updates when the live activity changes and when it is cleared',
    () async {
      provider.start();
      events.add([active('e1')]);
      await pumpEventQueue();
      final seen = <String?>[];
      provider.addListener(() => seen.add(provider.activity?.uuid));

      scheduleOf('e1').add([makeSpeaker(uuid: 'a', isLive: true)]);
      await pumpEventQueue();
      scheduleOf(
        'e1',
      ).add([makeSpeaker(uuid: 'a'), makeSpeaker(uuid: 'b', isLive: true)]);
      await pumpEventQueue();
      scheduleOf('e1').add([makeSpeaker(uuid: 'a'), makeSpeaker(uuid: 'b')]);
      await pumpEventQueue();

      expect(seen, ['a', 'b', null]);
      expect(provider.activity, isNull);
    },
  );

  test('shows only one activity when several are marked as live', () async {
    provider.start();
    events.add([active('e1')]);
    await pumpEventQueue();

    scheduleOf('e1').add([
      makeSpeaker(uuid: 'late', position: 5, isLive: true),
      makeSpeaker(uuid: 'early', position: 2, isLive: true),
    ]);
    await pumpEventQueue();

    expect(provider.activity?.uuid, 'early');
  });

  test(
    'does not keep the old activity when the active event changes',
    () async {
      provider.start();
      events.add([active('e1')]);
      await pumpEventQueue();
      scheduleOf('e1').add([makeSpeaker(uuid: 'a', isLive: true)]);
      await pumpEventQueue();
      expect(provider.activity?.uuid, 'a');

      events.add([
        makeEvent(id: 'e1', status: EventStatus.finished),
        active('e2'),
      ]);
      await pumpEventQueue();

      expect(provider.activity, isNull);
      expect(provider.eventId, isNull);
      expect(provider.loading, isTrue);
      expect(scheduleOf('e1').hasListener, isFalse);
      expect(scheduleOf('e2').hasListener, isTrue);
    },
  );

  test('clears the activity when the event stops being active', () async {
    provider.start();
    events.add([active('e1')]);
    await pumpEventQueue();
    scheduleOf('e1').add([makeSpeaker(uuid: 'a', isLive: true)]);
    await pumpEventQueue();

    events.add([makeEvent(id: 'e1', status: EventStatus.finished)]);
    await pumpEventQueue();

    expect(provider.activity, isNull);
    expect(provider.eventId, isNull);
    expect(scheduleOf('e1').hasListener, isFalse);
  });

  test(
    'keeps the same schedule subscription while the event is the same',
    () async {
      provider.start();
      events.add([active('e1')]);
      await pumpEventQueue();

      events.add([active('e1'), makeEvent(id: 'e3')]);
      await pumpEventQueue();

      verify(() => scheduleRepository.getListScheduleStream('e1')).called(1);
    },
  );

  test('shows the live activity of an event not activated yet', () async {
    provider.start();
    events.add([makeEvent(id: 'next')]);
    await pumpEventQueue();

    scheduleOf('next').add([makeSpeaker(uuid: 'a', isLive: true)]);
    await pumpEventQueue();

    expect(provider.activity?.uuid, 'a');
    expect(provider.eventId, 'next');
  });

  test('the active event goes before an upcoming one', () async {
    provider.start();
    events.add([makeEvent(id: 'next'), active('now')]);
    await pumpEventQueue();

    scheduleOf('next').add([makeSpeaker(uuid: 'later', isLive: true)]);
    await pumpEventQueue();
    expect(provider.activity?.uuid, 'later');

    scheduleOf('now').add([makeSpeaker(uuid: 'current', isLive: true)]);
    await pumpEventQueue();

    expect(provider.activity?.uuid, 'current');
    expect(provider.eventId, 'now');
  });

  test('looks in another event when the active one has none', () async {
    provider.start();
    events.add([active('now'), makeEvent(id: 'next')]);
    await pumpEventQueue();

    scheduleOf('now').add([makeSpeaker(uuid: 'a')]);
    await pumpEventQueue();
    expect(provider.loading, isTrue);

    scheduleOf('next').add([makeSpeaker(uuid: 'b', isLive: true)]);
    await pumpEventQueue();

    expect(provider.activity?.uuid, 'b');
    expect(provider.eventId, 'next');
    expect(provider.loading, isFalse);
  });

  test('a failing schedule does not hide the other events', () async {
    provider.start();
    events.add([active('now'), makeEvent(id: 'next')]);
    await pumpEventQueue();
    scheduleOf('next').add([makeSpeaker(uuid: 'b', isLive: true)]);
    await pumpEventQueue();

    scheduleOf('now').addError(Exception('permission denied'));
    await pumpEventQueue();

    expect(provider.activity?.uuid, 'b');
    expect(scheduleOf('now').hasListener, isFalse);
  });

  test('start retries a schedule that failed', () async {
    provider.start();
    events.add([active('e1')]);
    await pumpEventQueue();
    scheduleOf('e1').addError(Exception('offline'));
    await pumpEventQueue();

    provider.start();
    scheduleOf('e1').add([makeSpeaker(uuid: 'a', isLive: true)]);
    await pumpEventQueue();

    expect(provider.activity?.uuid, 'a');
    verify(() => eventRepository.getEventsStream()).called(1);
  });

  test('start listens only once', () async {
    provider.start();
    provider.start();

    verify(() => eventRepository.getEventsStream()).called(1);
  });

  test('an error in the events stream clears the activity', () async {
    provider.start();
    events.add([active('e1')]);
    await pumpEventQueue();
    scheduleOf('e1').add([makeSpeaker(uuid: 'a', isLive: true)]);
    await pumpEventQueue();

    events.addError(Exception('offline'));
    await pumpEventQueue();

    expect(provider.activity, isNull);
    expect(provider.loading, isFalse);
  });

  test('an error in the schedule stream clears the activity', () async {
    provider.start();
    events.add([active('e1')]);
    await pumpEventQueue();
    scheduleOf('e1').add([makeSpeaker(uuid: 'a', isLive: true)]);
    await pumpEventQueue();

    scheduleOf('e1').addError(Exception('permission denied'));
    await pumpEventQueue();

    expect(provider.activity, isNull);
    expect(provider.loading, isFalse);
  });

  test('after an error, start listens again', () async {
    provider.start();
    events.addError(Exception('offline'));
    await pumpEventQueue();

    provider.start();
    events.add([active('e1')]);
    await pumpEventQueue();
    scheduleOf('e1').add([makeSpeaker(uuid: 'a', isLive: true)]);
    await pumpEventQueue();

    expect(provider.activity?.uuid, 'a');
    verify(() => eventRepository.getEventsStream()).called(2);
  });

  test('dispose stops listening to both streams', () async {
    provider.start();
    events.add([active('e1')]);
    await pumpEventQueue();

    provider.dispose();

    expect(events.hasListener, isFalse);
    expect(scheduleOf('e1').hasListener, isFalse);
    // tearDown disposes it again, which must be harmless.
    provider = LiveActivityProvider(eventRepository, scheduleRepository);
  });
}
