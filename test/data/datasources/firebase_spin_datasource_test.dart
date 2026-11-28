import 'dart:io';

import 'package:app_events/data/datasources/firebase_spin_datasource.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseFunctions functions;
  late MockFirebaseStorage storage;
  late FirebaseSpinDatasource datasource;

  const eventId = 'evt-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    functions = _MockFirebaseFunctions();
    storage = MockFirebaseStorage();
    datasource = FirebaseSpinDatasource(firestore, functions, storage);
  });

  _MockHttpsCallable stubCallable(
    String name,
    Map<Object?, Object?> responseData,
  ) {
    final callable = _MockHttpsCallable();
    final result = _MockHttpsCallableResult();
    when(() => result.data).thenReturn(responseData);
    when(() => functions.httpsCallable(name)).thenReturn(callable);
    when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);
    return callable;
  }

  group('Firestore streams', () {
    test(
      'watchConfig emits null when missing and normalizes Timestamp fields',
      () async {
        final stream = datasource.watchConfig(eventId);
        final emitted = <SpinConfig?>[];
        final sub = stream.listen(emitted.add);
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        await firestore
            .collection('events')
            .doc(eventId)
            .collection('spinConfig')
            .doc('main')
            .set({
              'status': 'active',
              'pacingStartAt': Timestamp.fromDate(
                DateTime.utc(2026, 11, 28, 9),
              ),
              'pacingWaves': [
                {
                  'id': 'morning',
                  'label': 'Morning',
                  'startAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 9)),
                  'releaseRatio': 0.35,
                  'spinBudgetShare': 0.35,
                },
              ],
            });

        await Future<void>.delayed(Duration.zero);
        expect(emitted.first, isNull);
        expect(emitted.last?.status, SpinGameStatus.active);
        expect(
          emitted.last?.pacingWaves.single.startAt,
          DateTime.utc(2026, 11, 28, 9),
        );
      },
    );

    test(
      'watchPrizes filters activeOnly and orders by order with fallback doc id',
      () async {
        final col = firestore
            .collection('events')
            .doc(eventId)
            .collection('spinPrizes');
        await col.doc('p2').set({
          'name': 'Mug',
          'symbol': 'bell',
          'initialStock': 5,
          'remainingStock': 5,
          'rarity': 'rare',
          'active': true,
          'order': 2,
        });
        await col.doc('p1').set({
          'name': 'Stickers',
          'symbol': 'cherries',
          'initialStock': 10,
          'remainingStock': 10,
          'rarity': 'common',
          'active': true,
          'order': 1,
        });
        await col.doc('p3').set({
          'name': 'Hidden',
          'symbol': 'star',
          'initialStock': 1,
          'remainingStock': 1,
          'rarity': 'epic',
          'active': false,
          'order': 0,
        });

        final activeList = await datasource.watchPrizes(eventId).first;
        expect(activeList.map((p) => p.id), ['p1', 'p2']);

        final allList = await datasource
            .watchPrizes(eventId, activeOnly: false)
            .first;
        expect(allList.map((p) => p.id), ['p3', 'p1', 'p2']);
      },
    );

    test('watchMissions filters activeOnly and parses nested config', () async {
      final col = firestore
          .collection('events')
          .doc(eventId)
          .collection('spinMissions');
      await col.doc('m1').set({
        'type': 'trivia',
        'title': 'Break Trivia',
        'rewardTickets': 2,
        'active': true,
        'order': 1,
        'config': {
          'question': 'What is Dart?',
          'options': ['Language', 'OS'],
        },
      });
      await col.doc('m2').set({
        'type': 'profile_complete',
        'title': 'Profile',
        'rewardTickets': 1,
        'active': false,
        'order': 0,
      });

      final active = await datasource.watchMissions(eventId).first;
      expect(active.map((m) => m.id), ['m1']);
      expect(active.single.isTrivia, isTrue);
      expect(active.single.triviaOptions, ['Language', 'OS']);

      final all = await datasource
          .watchMissions(eventId, activeOnly: false)
          .first;
      expect(all.map((m) => m.id), ['m2', 'm1']);
    });

    test(
      'watchPlayer emits null when absent and uses doc id fallback',
      () async {
        await firestore
            .collection('events')
            .doc(eventId)
            .collection('spinPlayers')
            .doc('u-1')
            .set({
              'tickets': 4,
              'lastSpinAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 12)),
            });

        final player = await datasource.watchPlayer(eventId, 'u-1').first;
        expect(player?.uid, 'u-1');
        expect(player?.tickets, 4);
        expect(player?.lastSpinAt, DateTime.utc(2026, 11, 28, 12));

        final missing = await datasource.watchPlayer(eventId, 'missing').first;
        expect(missing, isNull);
      },
    );

    test(
      'watchMyWins and watchAllWins filter and sort by wonAt descending',
      () async {
        final winsCol = firestore
            .collection('events')
            .doc(eventId)
            .collection('spinWins');
        await winsCol.doc('w1').set({
          'eventId': eventId,
          'uid': 'u-1',
          'prizeId': 'stickers',
          'prizeName': 'Stickers',
          'prizeSymbol': 'cherries',
          'code': 'GDG-111111',
          'status': 'pending',
          'wonAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 10)),
        });
        await winsCol.doc('w2').set({
          'eventId': eventId,
          'uid': 'u-1',
          'prizeId': 'mug',
          'prizeName': 'Mug',
          'prizeSymbol': 'bell',
          'code': 'GDG-222222',
          'status': 'redeemed',
          'wonAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 12)),
        });
        await winsCol.doc('w3').set({
          'eventId': eventId,
          'uid': 'u-2',
          'prizeId': 'shirt',
          'prizeName': 'Shirt',
          'prizeSymbol': 'bar',
          'code': 'GDG-333333',
          'status': 'pending',
          'wonAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 11)),
        });

        final myWins = await datasource.watchMyWins(eventId, 'u-1').first;
        expect(myWins.map((w) => w.id), ['w2', 'w1']);

        final allWins = await datasource.watchAllWins(eventId).first;
        expect(allWins.map((w) => w.id), ['w2', 'w3', 'w1']);

        final pendingWins = await datasource
            .watchAllWins(eventId, status: SpinWinStatus.pending)
            .first;
        expect(pendingWins.map((w) => w.id), ['w3', 'w1']);
      },
    );

    test(
      'watchMyMissionClaims and watchTicketCodes emit normalized records',
      () async {
        await firestore
            .collection('events')
            .doc(eventId)
            .collection('spinMissionClaims')
            .doc('u-1_m-1')
            .set({
              'uid': 'u-1',
              'missionId': 'm-1',
              'completions': 1,
              'lastClaimedAt': Timestamp.fromDate(
                DateTime.utc(2026, 11, 28, 10),
              ),
            });

        await firestore
            .collection('events')
            .doc(eventId)
            .collection('spinTicketCodes')
            .doc('c-1')
            .set({
              'code': 'cloud26',
              'label': 'Cloud Booth',
              'rewardTickets': 1,
              'maxTotalUses': 50,
              'active': true,
              'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 8)),
            });

        final claims = await datasource
            .watchMyMissionClaims(eventId, 'u-1')
            .first;
        expect(claims.single.missionId, 'm-1');
        expect(claims.single.claimedAt, DateTime.utc(2026, 11, 28, 10));

        final codes = await datasource.watchTicketCodes(eventId).first;
        expect(codes.single.id, 'c-1');
        expect(codes.single.code, 'CLOUD26');
      },
    );
  });

  group('Player and Admin Cloud Function callables', () {
    test(
      'initPlayer, pull, claimMission, submitTrivia, redeemTicketCode call exact functions',
      () async {
        final initCallable = stubCallable('spinInitPlayer', <Object?, Object?>{
          'player': <Object?, Object?>{'uid': 'u-1', 'tickets': 3},
          'initialGranted': true,
          'packageBonusGranted': false,
          'matchedPackage': null,
        });
        final initRes = await datasource.initPlayer(eventId);
        expect(initRes.player.tickets, 3);
        verify(
          () => initCallable.call<dynamic>({'eventId': eventId}),
        ).called(1);

        final pullCallable = stubCallable('spinPull', <Object?, Object?>{
          'spinRequestId': 'req-12345678',
          'outcomeType': 'bonus',
          'combo': ['mysteryBox', 'mysteryBox', 'mysteryBox'],
          'wonPrize': null,
          'bonusTickets': 2,
          'ticketsAfter': 4,
          'spinsCountAfter': 1,
          'reachedPrizeCap': false,
          'ticketSerial': 'SER12345',
        });
        final pullRes = await datasource.pull(
          eventId: eventId,
          spinRequestId: 'req-12345678',
        );
        expect(pullRes.outcomeType, SpinOutcomeType.bonus);
        expect(pullRes.bonusTickets, 2);
        verify(
          () => pullCallable.call<dynamic>({
            'eventId': eventId,
            'spinRequestId': 'req-12345678',
          }),
        ).called(1);

        final claimCallable = stubCallable('spinClaimMission', {
          'granted': true,
          'ticketsAwarded': 1,
          'ticketsAfter': 5,
          'ticketSerial': 'MIS12345',
        });
        final claimRes = await datasource.claimMission(
          eventId: eventId,
          missionId: 'profile',
        );
        expect(claimRes.granted, isTrue);
        verify(
          () => claimCallable.call<dynamic>({
            'eventId': eventId,
            'missionId': 'profile',
          }),
        ).called(1);

        final triviaCallable = stubCallable('spinSubmitTrivia', {
          'correct': true,
          'explanation': 'Nice!',
          'ticketsAwarded': 1,
          'ticketsAfter': 6,
          'ticketSerial': 'TRV12345',
        });
        final triviaRes = await datasource.submitTrivia(
          eventId: eventId,
          missionId: 'trivia-1',
          selectedIndex: 0,
        );
        expect(triviaRes.correct, isTrue);
        verify(
          () => triviaCallable.call<dynamic>({
            'eventId': eventId,
            'missionId': 'trivia-1',
            'selectedIndex': 0,
          }),
        ).called(1);

        final codeCallable = stubCallable('spinRedeemTicketCode', {
          'label': 'Sponsor Booth',
          'ticketsAwarded': 2,
          'ticketsAfter': 8,
          'ticketSerial': 'COD12345',
        });
        final codeRes = await datasource.redeemTicketCode(
          eventId: eventId,
          code: 'CLOUD26',
        );
        expect(codeRes.label, 'Sponsor Booth');
        verify(
          () => codeCallable.call<dynamic>({
            'eventId': eventId,
            'code': 'CLOUD26',
          }),
        ).called(1);
      },
    );

    test('admin callables send exact payloads and parse responses', () async {
      stubCallable('adminUpdateSpinConfig', {
        'config': {'status': 'active', 'rushMode': true},
      });
      final updatedConfig = await datasource.updateConfig(
        eventId: eventId,
        patch: {'status': 'active', 'rushMode': true},
      );
      expect(updatedConfig.status, SpinGameStatus.active);
      expect(updatedConfig.rushMode, isTrue);

      stubCallable('adminAdjustPrizeStock', {
        'prize': {
          'id': 'mug',
          'name': 'Mug',
          'symbol': 'bell',
          'initialStock': 7,
          'remainingStock': 7,
          'rarity': 'rare',
        },
      });
      final adjusted = await datasource.adjustPrizeStock(
        eventId: eventId,
        prizeId: 'mug',
        delta: 2,
        reason: 'Found extra box',
      );
      expect(adjusted.initialStock, 7);

      final missionCallable = stubCallable('adminUpsertSpinMission', {
        'mission': {
          'id': 'trivia-1',
          'type': 'trivia',
          'title': 'Trivia',
          'rewardTickets': 1,
          'active': true,
        },
        'created': true,
      });
      final missionRes = await datasource.upsertMission(
        eventId: eventId,
        missionData: {'id': '', 'type': 'trivia', 'title': 'Trivia'},
        correctOptionIndex: 1,
        explanation: 'Because B',
      );
      expect(missionRes.created, isTrue);
      verify(
        () => missionCallable.call<dynamic>({
          'eventId': eventId,
          'mission': {'type': 'trivia', 'title': 'Trivia'},
          'secret': {'correctOptionIndex': 1, 'explanation': 'Because B'},
        }),
      ).called(1);

      final codeCallable = stubCallable('adminUpsertTicketCode', {
        'ticketCode': {'id': 'c1', 'code': 'CLOUD26', 'label': 'Cloud'},
        'created': true,
      });
      final codeRes = await datasource.upsertTicketCode(
        eventId: eventId,
        codeData: {'id': '', 'code': 'CLOUD26', 'label': 'Cloud'},
      );
      expect(codeRes.created, isTrue);
      verify(
        () => codeCallable.call<dynamic>({
          'eventId': eventId,
          'codeConfig': {'code': 'CLOUD26', 'label': 'Cloud'},
        }),
      ).called(1);

      stubCallable('adminGrantTickets', {
        'targetUid': 'u-2',
        'ticketsAwarded': 2,
        'ticketsAfter': 4,
        'ticketSerial': 'ADM12345',
        'idempotentReplay': false,
      });
      final grantRes = await datasource.grantTickets(
        eventId: eventId,
        targetUid: 'u-2',
        amount: 2,
        reason: 'Volunteer help',
        requestId: 'req-admin-1',
      );
      expect(grantRes.ticketsAwarded, 2);

      stubCallable('adminImportRegistrations', {
        'importedCount': 1,
        'updatedCount': 0,
        'totalRegistrationsCount': 1,
      });
      final importRes = await datasource.importRegistrations(
        eventId: eventId,
        rows: const [
          SpinRegistrationRow(email: 'ada@example.com', package: 'VIP'),
        ],
      );
      expect(importRes.importedCount, 1);

      stubCallable('adminLookupWinByCode', {
        'win': {
          'id': 'w1',
          'eventId': eventId,
          'uid': 'u1',
          'prizeId': 'mug',
          'prizeName': 'Mug',
          'prizeSymbol': 'bell',
          'code': 'GDG-7K9P2M',
          'status': 'pending',
        },
        'prize': null,
        'player': null,
      });
      final lookupRes = await datasource.lookupWinByCode(
        eventId: eventId,
        codeOrQr: 'GDG-7K9P2M',
      );
      expect(lookupRes.win.code, 'GDG-7K9P2M');

      stubCallable('adminRedeemWin', {
        'win': {
          'id': 'w1',
          'eventId': eventId,
          'uid': 'u1',
          'prizeId': 'mug',
          'prizeName': 'Mug',
          'prizeSymbol': 'bell',
          'code': 'GDG-7K9P2M',
          'status': 'redeemed',
        },
      });
      final redeemed = await datasource.redeemWin(
        eventId: eventId,
        winId: 'w1',
      );
      expect(redeemed.status, SpinWinStatus.redeemed);

      stubCallable('adminRevokeWin', {
        'win': {
          'id': 'w1',
          'eventId': eventId,
          'uid': 'u1',
          'prizeId': 'mug',
          'prizeName': 'Mug',
          'prizeSymbol': 'bell',
          'code': 'GDG-7K9P2M',
          'status': 'revoked',
          'returnedToStock': true,
        },
      });
      final revoked = await datasource.revokeWin(
        eventId: eventId,
        winId: 'w1',
        returnToStock: true,
        reason: 'Wrong booth scan',
      );
      expect(revoked.status, SpinWinStatus.revoked);
      expect(revoked.returnedToStock, isTrue);

      stubCallable('adminGetSpinDashboard', {
        'config': {'status': 'active'},
        'stats': {'totalSpins': 42},
        'prizes': [],
        'winCounts': {'pending': 2, 'redeemed': 3, 'revoked': 0, 'total': 5},
        'activePlayersCount': 20,
        'registrationsCount': 100,
      });
      final dashboard = await datasource.getDashboard(eventId);
      expect(dashboard.stats.totalSpins, 42);
      expect(dashboard.activePlayersCount, 20);
    });

    test(
      'upsertPrize uploads image to Storage when imagePath is provided',
      () async {
        final dir = Directory.systemTemp.createTempSync('spin_prize_test');
        addTearDown(() => dir.deleteSync(recursive: true));
        final image = File('${dir.path}/prize.png')
          ..writeAsBytesSync([1, 2, 3]);

        final callable = stubCallable('adminUpsertSpinPrize', {
          'prize': {
            'id': 'generated-id',
            'name': 'Sparky',
            'symbol': 'star',
            'imageUrl': 'https://storage.mock/prize.png',
            'initialStock': 4,
            'remainingStock': 4,
            'rarity': 'epic',
          },
          'created': true,
        });

        final result = await datasource.upsertPrize(
          eventId: eventId,
          prizeData: {
            'id': '',
            'name': 'Sparky',
            'symbol': 'star',
            'initialStock': 4,
            'rarity': 'epic',
          },
          imagePath: image.path,
        );

        expect(result.created, isTrue);
        expect(result.prize.symbol, SpinSymbol.star);
        final captured =
            verify(() => callable.call<dynamic>(captureAny())).captured.single
                as Map<String, dynamic>;
        final prizePayload = captured['prize'] as Map<String, dynamic>;
        expect(prizePayload['id'], isNotEmpty);
        expect(prizePayload['imageUrl'], isNotEmpty);
      },
    );

    test(
      'maps FirebaseFunctionsException details.reason and code fallbacks to SpinException',
      () async {
        final callable = _MockHttpsCallable();
        when(() => functions.httpsCallable('spinPull')).thenReturn(callable);
        when(() => callable.call<dynamic>(any())).thenThrow(
          // ignore: invalid_use_of_protected_member
          FirebaseFunctionsException(
            message: 'Game is paused',
            code: 'failed-precondition',
            details: {'reason': 'GAME_PAUSED'},
          ),
        );

        await expectLater(
          datasource.pull(eventId: eventId, spinRequestId: 'req-12345678'),
          throwsA(
            isA<SpinException>()
                .having((e) => e.reason, 'reason', SpinErrorReason.gamePaused)
                .having((e) => e.code, 'code', 'failed-precondition')
                .having((e) => e.message, 'message', 'Game is paused'),
          ),
        );

        when(() => callable.call<dynamic>(any())).thenThrow(
          // ignore: invalid_use_of_protected_member
          FirebaseFunctionsException(message: 'Offline', code: 'unavailable'),
        );

        await expectLater(
          datasource.pull(eventId: eventId, spinRequestId: 'req-12345678'),
          throwsA(
            isA<SpinException>().having(
              (e) => e.reason,
              'reason',
              SpinErrorReason.network,
            ),
          ),
        );
      },
    );
  });
}
