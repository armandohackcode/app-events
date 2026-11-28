import 'package:app_events/data/datasources/firebase_spin_datasource.dart';
import 'package:app_events/data/repositories/spin_repository_impl.dart';
import 'package:app_events/domain/datasources/spin_datasource.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpinDatasource extends Mock implements SpinDatasource {}

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  test(
    'SpinRepositoryImpl forwards optional releasedDelta to datasource',
    () async {
      final datasource = _MockSpinDatasource();
      final repo = SpinRepositoryImpl(datasource);
      const updated = SpinPrize(
        id: 'p1',
        name: 'Plush',
        symbol: SpinSymbol.star,
        initialStock: 10,
        remainingStock: 10,
        releasedStock: 4,
        rarity: PrizeRarity.epic,
      );
      when(
        () => datasource.adjustPrizeStock(
          eventId: 'evt-1',
          prizeId: 'p1',
          delta: 0,
          releasedDelta: 1,
          reason: 'Wave release',
        ),
      ).thenAnswer((_) async => updated);

      final res = await repo.adjustPrizeStock(
        eventId: 'evt-1',
        prizeId: 'p1',
        delta: 0,
        releasedDelta: 1,
        reason: 'Wave release',
      );

      expect(res.releasedStock, 4);
      verify(
        () => datasource.adjustPrizeStock(
          eventId: 'evt-1',
          prizeId: 'p1',
          delta: 0,
          releasedDelta: 1,
          reason: 'Wave release',
        ),
      ).called(1);
    },
  );

  test(
    'FirebaseSpinDatasource includes releasedDelta in adminAdjustPrizeStock payload',
    () async {
      final firestore = FakeFirebaseFirestore();
      final functions = _MockFirebaseFunctions();
      final storage = MockFirebaseStorage();
      final datasource = FirebaseSpinDatasource(firestore, functions, storage);

      final callable = _MockHttpsCallable();
      final callableResult = _MockHttpsCallableResult();
      when(
        () => functions.httpsCallable('adminAdjustPrizeStock'),
      ).thenReturn(callable);
      when(
        () => callable.call<dynamic>(any()),
      ).thenAnswer((_) async => callableResult);
      when(() => callableResult.data).thenReturn({
        'prize': {
          'id': 'p1',
          'name': 'Plush',
          'symbol': 'star',
          'initialStock': 10,
          'remainingStock': 10,
          'releasedStock': 5,
          'rarity': 'epic',
        },
      });

      final prize = await datasource.adjustPrizeStock(
        eventId: 'evt-1',
        prizeId: 'p1',
        delta: 0,
        releasedDelta: 1,
        reason: 'Wave release',
      );

      expect(prize.releasedStock, 5);
      verify(
        () => callable.call<dynamic>({
          'eventId': 'evt-1',
          'prizeId': 'p1',
          'delta': 0,
          'reason': 'Wave release',
          'releasedDelta': 1,
        }),
      ).called(1);
    },
  );
}
