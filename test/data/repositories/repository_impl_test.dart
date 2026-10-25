import 'package:app_events/data/repositories/event_repository_impl.dart';
import 'package:app_events/data/repositories/speed_run_repository_impl.dart';
import 'package:app_events/domain/datasources/event_datasource.dart';
import 'package:app_events/domain/datasources/speed_run_datasource.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class _MockEventDatasource extends Mock implements EventDatasource {}

class _MockSpeedRunDatasource extends Mock implements SpeedRunDatasource {}

// Repositories are thin adapters: they must delegate to the datasource
// without altering arguments and must propagate datasource errors.
void main() {
  setUpAll(() {
    registerFallbackValue(makeEvent());
    registerFallbackValue(makeChallenge());
    registerFallbackValue(EventStatus.upcoming);
  });

  group('EventRepositoryImpl', () {
    late _MockEventDatasource datasource;
    late EventRepositoryImpl repository;

    setUp(() {
      datasource = _MockEventDatasource();
      repository = EventRepositoryImpl(datasource);
    });

    test('getEvents returns datasource events', () async {
      final events = [makeEvent()];
      when(() => datasource.getEvents()).thenAnswer((_) async => events);

      expect(await repository.getEvents(), events);
    });

    test('addEvent forwards the image path', () async {
      when(
        () => datasource.addEvent(any(), imagePath: any(named: 'imagePath')),
      ).thenAnswer((_) async {});
      final event = makeEvent();

      await repository.addEvent(event, imagePath: '/tmp/a.jpg');

      verify(() => datasource.addEvent(event, imagePath: '/tmp/a.jpg'));
    });

    test('updateEventStatus forwards id and status', () async {
      when(
        () => datasource.updateEventStatus(any(), any()),
      ).thenAnswer((_) async {});

      await repository.updateEventStatus('evt-1', EventStatus.finished);

      verify(() => datasource.updateEventStatus('evt-1', EventStatus.finished));
    });

    test('propagates datasource errors', () {
      when(
        () => datasource.getEvents(),
      ).thenAnswer((_) async => throw Exception('offline'));

      expect(repository.getEvents(), throwsException);
    });
  });

  group('SpeedRunRepositoryImpl', () {
    late _MockSpeedRunDatasource datasource;
    late SpeedRunRepositoryImpl repository;

    setUp(() {
      datasource = _MockSpeedRunDatasource();
      repository = SpeedRunRepositoryImpl(datasource);
    });

    test('getChallenges returns datasource challenges', () async {
      final challenges = [makeChallenge()];
      when(
        () => datasource.getChallenges(),
      ).thenAnswer((_) async => challenges);

      expect(await repository.getChallenges(), challenges);
    });

    test('addChallenge forwards the image path', () async {
      when(
        () =>
            datasource.addChallenge(any(), imagePath: any(named: 'imagePath')),
      ).thenAnswer((_) async {});
      final challenge = makeChallenge();

      await repository.addChallenge(challenge, imagePath: '/tmp/c.png');

      verify(() => datasource.addChallenge(challenge, imagePath: '/tmp/c.png'));
    });
  });
}
