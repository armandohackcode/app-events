import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class _MockOtherRepository extends Mock implements OtherRepository {}

void main() {
  late _MockOtherRepository repository;
  late OtherProvider provider;

  setUpAll(() => registerFallbackValue(makeSponsor()));

  setUp(() {
    repository = _MockOtherRepository();
    provider = OtherProvider(repository);
  });

  tearDown(() => provider.dispose());

  test('getSponsors caches the first successful load', () async {
    when(
      () => repository.getSponsors(),
    ).thenAnswer((_) async => [makeSponsor()]);

    await provider.getSponsors();
    await provider.getSponsors();

    verify(() => repository.getSponsors()).called(1);
    expect(provider.sponsors, hasLength(1));
  });

  test('addSponsor refreshes sponsors and resets loading', () async {
    when(() => repository.addSponsor(any(), any())).thenAnswer((_) async {});
    when(() => repository.getSponsors()).thenAnswer(
      (_) async => [makeSponsor(), makeSponsor(id: 'sp-2', name: 'GDG')],
    );

    await provider.addSponsor(makeSponsor(id: 'sp-2'), null);

    expect(provider.sponsors, hasLength(2));
    expect(provider.loadingSponsor, isFalse);
  });

  test('deleteSponsor resets loading even when it fails', () async {
    when(
      () => repository.deleteSponsor(any()),
    ).thenAnswer((_) async => throw Exception('denied'));

    await expectLater(provider.deleteSponsor('sp-1'), throwsException);
    expect(provider.loadingSponsor, isFalse);
  });
}
