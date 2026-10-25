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
}
