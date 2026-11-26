import 'dart:async';

import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late _MockScheduleRepository repository;
  late ScheduleProvider provider;

  setUpAll(() => registerFallbackValue(makeSpeaker()));

  setUp(() {
    repository = _MockScheduleRepository();
    provider = ScheduleProvider(repository);
  });

  tearDown(() => provider.dispose());

  test('loadSchedule loads the event schedule', () async {
    when(
      () => repository.getListSchedule('evt-1'),
    ).thenAnswer((_) async => [makeSpeaker()]);

    await provider.loadSchedule('evt-1');

    expect(provider.schedule, hasLength(1));
    expect(provider.loadingSchedule, isFalse);
  });

  test('loadSchedule resets loading and rethrows on error', () async {
    when(
      () => repository.getListSchedule(any()),
    ).thenAnswer((_) async => throw Exception('offline'));

    await expectLater(provider.loadSchedule('evt-1'), throwsException);
    expect(provider.loadingSchedule, isFalse);
  });

  test('deleteSchedule removes only the deleted speaker', () async {
    when(
      () => repository.getListSchedule(any()),
    ).thenAnswer((_) async => [makeSpeaker(uuid: 'a'), makeSpeaker(uuid: 'b')]);
    when(
      () => repository.deleteSchedule(any(), any()),
    ).thenAnswer((_) async {});
    await provider.loadSchedule('evt-1');

    await provider.deleteSchedule('evt-1', 'a');

    expect(provider.schedule.map((s) => s.uuid), ['b']);
  });

  test('updateSchedule saves, reloads and resets loading', () async {
    when(
      () => repository.updateSchedule(
        any(),
        any(),
        imagePath: any(named: 'imagePath'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.getListSchedule('evt-1'),
    ).thenAnswer((_) async => [makeSpeaker(name: 'Updated')]);

    await provider.updateSchedule('evt-1', makeSpeaker());

    expect(provider.schedule.single.name, 'Updated');
    expect(provider.loadingNewSchedule, isFalse);
  });

  test('addNewSchedule resets loading and rethrows on error', () async {
    when(
      () => repository.addNewSchedule(
        any(),
        any(),
        imagePath: any(named: 'imagePath'),
      ),
    ).thenAnswer((_) async => throw Exception('denied'));

    await expectLater(
      provider.addNewSchedule('evt-1', makeSpeaker()),
      throwsException,
    );
    expect(provider.loadingNewSchedule, isFalse);
  });

  group('watchSchedule', () {
    late StreamController<List<Speaker>> first;
    late StreamController<List<Speaker>> second;

    setUp(() {
      first = StreamController<List<Speaker>>.broadcast();
      second = StreamController<List<Speaker>>.broadcast();
      when(
        () => repository.getListScheduleStream('evt-1'),
      ).thenAnswer((_) => first.stream);
      when(
        () => repository.getListScheduleStream('evt-2'),
      ).thenAnswer((_) => second.stream);
    });

    tearDown(() async {
      await first.close();
      await second.close();
    });

    test('keeps the schedule updated', () async {
      provider.watchSchedule('evt-1');
      expect(provider.loadingSchedule, isTrue);

      first.add([makeSpeaker(uuid: 'a')]);
      await pumpEventQueue();
      expect(provider.loadingSchedule, isFalse);
      expect(provider.schedule.map((s) => s.uuid), ['a']);

      first.add([makeSpeaker(uuid: 'a'), makeSpeaker(uuid: 'b')]);
      await pumpEventQueue();
      expect(provider.schedule.map((s) => s.uuid), ['a', 'b']);
    });

    test('never shows the schedule of the previous event', () async {
      provider.watchSchedule('evt-1');
      first.add([makeSpeaker(uuid: 'a')]);
      await pumpEventQueue();

      provider.watchSchedule('evt-2');

      expect(provider.schedule, isEmpty);
      expect(first.hasListener, isFalse);
      expect(second.hasListener, isTrue);
    });

    test('stops loading when the stream fails', () async {
      provider.watchSchedule('evt-1');

      first.addError(Exception('offline'));
      await pumpEventQueue();

      expect(provider.loadingSchedule, isFalse);
    });

    test('stopWatchingSchedule cancels the subscription', () {
      provider.watchSchedule('evt-1');

      provider.stopWatchingSchedule('evt-1');

      expect(first.hasListener, isFalse);
    });

    test('stopping an event that is no longer watched does nothing', () {
      provider.watchSchedule('evt-1');
      provider.watchSchedule('evt-2');

      provider.stopWatchingSchedule('evt-1');

      expect(second.hasListener, isTrue);
    });
  });
}
