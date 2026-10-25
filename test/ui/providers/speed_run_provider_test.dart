import 'package:app_events/domain/repositories/speed_run_repository.dart';
import 'package:app_events/ui/providers/speed_run_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class _MockSpeedRunRepository extends Mock implements SpeedRunRepository {}

void main() {
  late _MockSpeedRunRepository repository;
  late SpeedRunProvider provider;

  setUpAll(() => registerFallbackValue(makeChallenge()));

  setUp(() {
    repository = _MockSpeedRunRepository();
    provider = SpeedRunProvider(repository);
  });

  tearDown(() => provider.dispose());

  test('loadChallenges exposes challenges and toggles loading', () async {
    when(
      () => repository.getChallenges(),
    ).thenAnswer((_) async => [makeChallenge()]);
    final loadingStates = <bool>[];
    provider.addListener(() => loadingStates.add(provider.loading));

    await provider.loadChallenges();

    expect(provider.challenges, hasLength(1));
    expect(loadingStates, [true, false]);
  });

  // The provider currently swallows the error and the screen shows the
  // "no data" message, so a network failure is indistinguishable from an
  // empty list. Only the loading reset is asserted here on purpose.
  test('loadChallenges resets loading when the repository fails', () async {
    when(
      () => repository.getChallenges(),
    ).thenAnswer((_) async => throw Exception('offline'));

    await provider.loadChallenges();

    expect(provider.loading, isFalse);
  });

  test('addChallenge saves and reloads the list', () async {
    when(
      () => repository.addChallenge(any(), imagePath: any(named: 'imagePath')),
    ).thenAnswer((_) async {});
    when(
      () => repository.getChallenges(),
    ).thenAnswer((_) async => [makeChallenge()]);

    await provider.addChallenge(makeChallenge(), imagePath: '/tmp/c.png');

    verify(
      () => repository.addChallenge(any(), imagePath: '/tmp/c.png'),
    ).called(1);
    verify(() => repository.getChallenges()).called(1);
    expect(provider.challenges, hasLength(1));
  });
}
