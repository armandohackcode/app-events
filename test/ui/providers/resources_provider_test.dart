import 'package:app_events/domain/models/resource_library.dart';
import 'package:app_events/domain/repositories/resource_repository.dart';
import 'package:app_events/ui/providers/resources_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockResourceRepository extends Mock implements ResourceRepository {}

final _resource = ResourceLibrary(
  title: 'Flutter docs',
  link: 'https://docs.flutter.dev',
  type: 'Mobile',
);

void main() {
  late _MockResourceRepository repository;
  late ResourcesProvider provider;

  setUp(() {
    repository = _MockResourceRepository();
    provider = ResourcesProvider(repository);
  });

  tearDown(() => provider.dispose());

  test('loadResources exposes resources and resets loading', () async {
    when(() => repository.getResources()).thenAnswer((_) async => [_resource]);

    await provider.loadResources();

    expect(provider.resources, [_resource]);
    expect(provider.loadingResource, isFalse);
  });

  test('searchResource forwards the search param', () async {
    when(
      () => repository.searchResource(param: 'Mobile'),
    ).thenAnswer((_) async => [_resource]);

    await provider.searchResource(param: 'Mobile');

    expect(provider.resources, [_resource]);
  });

  test('cleanTag disables every filter', () {
    provider
      ..activeWeb = true
      ..activeMobile = true
      ..activeIA = true;

    provider.cleanTag();

    expect([
      provider.activeWeb,
      provider.activeMobile,
      provider.activeCloud,
      provider.activeIA,
      provider.activeUIUX,
    ], everyElement(isFalse));
  });

  test('loadResources resets loading when the repository fails', () async {
    when(
      () => repository.getResources(),
    ).thenAnswer((_) async => throw Exception('offline'));

    await expectLater(provider.loadResources(), throwsException);
    expect(provider.loadingResource, isFalse);
  });

  test('searchResource resets loading when the repository fails', () async {
    when(
      () => repository.searchResource(param: any(named: 'param')),
    ).thenAnswer((_) async => throw Exception('offline'));

    await expectLater(
      provider.searchResource(param: 'Mobile'),
      throwsException,
    );
    expect(provider.loadingResource, isFalse);
  });
}
