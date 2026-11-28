import 'dart:async';

import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class _MockSpinRepository extends Mock implements SpinRepository {}

class _MockUuid extends Mock implements Uuid {}

class _AdminHarness {
  final _MockSpinRepository repo = _MockSpinRepository();
  final _MockUuid uuid = _MockUuid();

  final configController = StreamController<SpinConfig?>.broadcast();
  final prizesController = StreamController<List<SpinPrize>>.broadcast();
  final missionsController = StreamController<List<SpinMission>>.broadcast();
  final allWinsController = StreamController<List<SpinWin>>.broadcast();
  final filteredWinsController = StreamController<List<SpinWin>>.broadcast();
  final ticketCodesController =
      StreamController<List<SpinTicketCode>>.broadcast();

  _AdminHarness() {
    when(() => uuid.v4()).thenReturn('req-uuid-v4-1234');
    when(
      () => repo.watchConfig(any()),
    ).thenAnswer((_) => configController.stream);
    when(
      () => repo.watchPrizes(any(), activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) => prizesController.stream);
    when(
      () => repo.watchMissions(any(), activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) => missionsController.stream);
    when(
      () => repo.watchAllWins(any(), status: null),
    ).thenAnswer((_) => allWinsController.stream);
    when(
      () => repo.watchAllWins(any(), status: SpinWinStatus.pending),
    ).thenAnswer((_) => filteredWinsController.stream);
    when(
      () => repo.watchAllWins(any(), status: SpinWinStatus.redeemed),
    ).thenAnswer((_) => filteredWinsController.stream);
    when(
      () => repo.watchAllWins(any(), status: SpinWinStatus.revoked),
    ).thenAnswer((_) => filteredWinsController.stream);
    when(
      () => repo.watchTicketCodes(any()),
    ).thenAnswer((_) => ticketCodesController.stream);
    when(() => repo.getDashboard(any())).thenAnswer(
      (_) async => const SpinDashboardStats(
        config: SpinConfig(status: SpinGameStatus.paused),
        stats: SpinStatsSummary(totalSpins: 42, totalWins: 5),
        prizes: [
          SpinPrize(
            id: 'stickers',
            name: 'Stickers',
            symbol: SpinSymbol.cherries,
            initialStock: 10,
            remainingStock: 7,
            awardedCount: 3,
            rarity: PrizeRarity.common,
          ),
        ],
        winCounts: SpinWinCounts(pending: 2, redeemed: 3, total: 5),
        activePlayersCount: 20,
        registrationsCount: 150,
      ),
    );
  }

  Future<void> dispose() async {
    await Future.wait([
      configController.close(),
      prizesController.close(),
      missionsController.close(),
      allWinsController.close(),
      filteredWinsController.close(),
      ticketCodesController.close(),
    ]);
  }
}

void main() {
  late _AdminHarness harness;
  late SpinAdminProvider provider;

  setUp(() {
    harness = _AdminHarness();
    provider = SpinAdminProvider(harness.repo, uuid: harness.uuid);
  });

  tearDown(() async {
    provider.dispose();
    await harness.dispose();
  });

  SpinWin makeWin({
    String id = 'win-1',
    SpinWinStatus status = SpinWinStatus.pending,
  }) => SpinWin(
    id: id,
    eventId: 'evt-1',
    uid: 'u1',
    winnerName: 'Ada Lovelace',
    prizeId: 'stickers',
    prizeName: 'Stickers',
    prizeSymbol: SpinSymbol.cherries,
    code: 'GDG-7K9P2M',
    status: status,
  );

  group('bind, streams, and refreshDashboard', () {
    test(
      'bind subscribes to all 5 admin streams, loads dashboard, and is idempotent',
      () async {
        await provider.bind('evt-1');
        await provider.bind('evt-1');

        verify(() => harness.repo.watchConfig('evt-1')).called(1);
        verify(
          () => harness.repo.watchPrizes('evt-1', activeOnly: false),
        ).called(1);
        verify(
          () => harness.repo.watchMissions('evt-1', activeOnly: false),
        ).called(1);
        verify(
          () => harness.repo.watchAllWins('evt-1', status: null),
        ).called(1);
        verify(() => harness.repo.watchTicketCodes('evt-1')).called(1);
        verify(() => harness.repo.getDashboard('evt-1')).called(1);

        expect(provider.isBound, isTrue);
        expect(provider.boundEventId, 'evt-1');
        expect(provider.isLoadingDashboard, isFalse);
        expect(provider.dashboard?.stats.totalSpins, 42);
        expect(provider.prizes, hasLength(1));
      },
    );

    test(
      'refreshDashboard resets isLoadingDashboard in finally and rethrows errors',
      () async {
        await provider.bind('evt-1');
        when(() => harness.repo.getDashboard('evt-1')).thenAnswer(
          (_) async => throw const SpinException(
            reason: SpinErrorReason.permissionDenied,
            code: 'permission-denied',
            message: 'Admin role required',
          ),
        );

        await expectLater(
          provider.refreshDashboard(),
          throwsA(isA<SpinException>()),
        );

        expect(provider.isLoadingDashboard, isFalse);
        expect(provider.lastError?.reason, SpinErrorReason.permissionDenied);
      },
    );

    test(
      'setWinFilter re-subscribes watchAllWins with chosen status',
      () async {
        await provider.bind('evt-1');

        provider.setWinFilter(SpinWinStatus.pending);
        provider.setWinFilter(SpinWinStatus.pending);

        verify(
          () =>
              harness.repo.watchAllWins('evt-1', status: SpinWinStatus.pending),
        ).called(1);
        expect(provider.winFilter, SpinWinStatus.pending);

        harness.filteredWinsController.add([makeWin()]);
        await pumpEventQueue();
        expect(provider.wins, hasLength(1));

        provider.unbind();
        expect(provider.isBound, isFalse);
        expect(provider.wins, isEmpty);
      },
    );
  });

  group('control & config mutations', () {
    test(
      'setGameStatus and setRushMode call updateConfig and refresh dashboard',
      () async {
        await provider.bind('evt-1');

        const activeConfig = SpinConfig(
          status: SpinGameStatus.active,
          pauseMessage: 'Resuming soon',
        );
        when(
          () => harness.repo.updateConfig(
            eventId: 'evt-1',
            patch: {'status': 'active', 'pauseMessage': 'Resuming soon'},
          ),
        ).thenAnswer((_) async => activeConfig);

        final resStatus = await provider.setGameStatus(
          SpinGameStatus.active,
          pauseMessage: 'Resuming soon',
        );
        expect(resStatus.status, SpinGameStatus.active);
        expect(provider.config?.status, SpinGameStatus.active);

        const rushConfig = SpinConfig(
          status: SpinGameStatus.active,
          rushMode: true,
        );
        when(
          () => harness.repo.updateConfig(
            eventId: 'evt-1',
            patch: {'rushMode': true},
          ),
        ).thenAnswer((_) async => rushConfig);

        final resRush = await provider.setRushMode(true);
        expect(resRush.rushMode, isTrue);
        expect(provider.config?.rushMode, isTrue);
        expect(provider.isSubmitting, isFalse);
        verify(() => harness.repo.getDashboard('evt-1')).called(3);
      },
    );

    test(
      'updateConfig resets isSubmitting in finally and rethrows error',
      () async {
        await provider.bind('evt-1');
        when(
          () => harness.repo.updateConfig(
            eventId: 'evt-1',
            patch: any(named: 'patch'),
          ),
        ).thenAnswer(
          (_) async => throw const SpinException(
            reason: SpinErrorReason.network,
            code: 'unavailable',
            message: 'offline',
          ),
        );

        await expectLater(
          provider.updateConfig({'defaultInitialTickets': 4}),
          throwsA(isA<SpinException>()),
        );

        expect(provider.isSubmitting, isFalse);
        expect(provider.lastError?.reason, SpinErrorReason.network);
      },
    );
  });

  group('prizes & missions', () {
    test(
      'upsertPrize and adjustPrizeStock update state and refresh dashboard',
      () async {
        await provider.bind('evt-1');
        const createdPrize = SpinPrize(
          id: 'mug',
          name: 'GDG Mug',
          symbol: SpinSymbol.bell,
          initialStock: 5,
          remainingStock: 5,
          rarity: PrizeRarity.rare,
          order: 1,
        );
        when(
          () => harness.repo.upsertPrize(
            eventId: 'evt-1',
            prizeData: {'name': 'GDG Mug', 'initialStock': 5},
            imagePath: '/tmp/mug.png',
          ),
        ).thenAnswer(
          (_) async =>
              const AdminUpsertPrizeResult(prize: createdPrize, created: true),
        );

        final upsertRes = await provider.upsertPrize({
          'name': 'GDG Mug',
          'initialStock': 5,
        }, imagePath: '/tmp/mug.png');
        expect(upsertRes.created, isTrue);
        expect(provider.prizes.any((p) => p.id == 'mug'), isTrue);

        final adjustedPrize = createdPrize.copyWith(
          initialStock: 8,
          remainingStock: 8,
        );
        when(
          () => harness.repo.adjustPrizeStock(
            eventId: 'evt-1',
            prizeId: 'mug',
            delta: 3,
            reason: 'Extra box',
          ),
        ).thenAnswer((_) async => adjustedPrize);

        final adjRes = await provider.adjustPrizeStock(
          prizeId: 'mug',
          delta: 3,
          reason: 'Extra box',
        );
        expect(adjRes.remainingStock, 8);
        expect(
          provider.prizes.firstWhere((p) => p.id == 'mug').remainingStock,
          8,
        );
      },
    );

    test('upsertMission and toggleMissionActive delegate cleanly', () async {
      await provider.bind('evt-1');
      const trivia = SpinMission(
        id: 't1',
        type: SpinMissionType.trivia,
        title: 'Break Trivia',
        reward: 2,
        active: false,
        triviaQuestion: 'What is Dart?',
        triviaOptions: ['Language', 'Database'],
      );
      when(
        () => harness.repo.upsertMission(
          eventId: 'evt-1',
          missionData: any(named: 'missionData'),
          correctOptionIndex: 0,
          explanation: 'Dart powers Flutter.',
        ),
      ).thenAnswer(
        (_) async =>
            const AdminUpsertMissionResult(mission: trivia, created: true),
      );

      final created = await provider.upsertMission(
        {'type': 'trivia', 'title': 'Break Trivia'},
        correctOptionIndex: 0,
        explanation: 'Dart powers Flutter.',
      );
      expect(created.mission.id, 't1');

      final activated = trivia.copyWith(active: true);
      when(
        () => harness.repo.upsertMission(
          eventId: 'evt-1',
          missionData: any(
            named: 'missionData',
            that: containsPair('active', true),
          ),
          correctOptionIndex: null,
          explanation: null,
        ),
      ).thenAnswer(
        (_) async =>
            AdminUpsertMissionResult(mission: activated, created: false),
      );

      final toggled = await provider.toggleMissionActive(trivia, true);
      expect(toggled.mission.active, isTrue);
      expect(provider.missions.single.active, isTrue);
    });
  });

  group('tickets, codes, registrations, and win redemption', () {
    test(
      'upsertTicketCode, grantTickets (with UUID), and importRegistrations work',
      () async {
        await provider.bind('evt-1');

        const standCode = SpinTicketCode(
          id: 'c1',
          code: 'CLOUD26',
          label: 'Cloud Stand',
          rewardTickets: 1,
          maxTotalUses: 100,
          active: true,
        );
        when(
          () => harness.repo.upsertTicketCode(
            eventId: 'evt-1',
            codeData: any(named: 'codeData'),
          ),
        ).thenAnswer(
          (_) async => const AdminUpsertTicketCodeResult(
            ticketCode: standCode,
            created: true,
          ),
        );

        final codeRes = await provider.upsertTicketCode({
          'code': 'CLOUD26',
          'label': 'Cloud Stand',
        });
        expect(codeRes.ticketCode.code, 'CLOUD26');
        expect(provider.ticketCodes.single.code, 'CLOUD26');

        when(
          () => harness.repo.grantTickets(
            eventId: 'evt-1',
            targetUid: 'u1',
            amount: 2,
            reason: 'Quiz winner',
            requestId: 'req-uuid-v4-1234',
          ),
        ).thenAnswer(
          (_) async => const AdminGrantTicketsResult(
            targetUid: 'u1',
            ticketsAwarded: 2,
            ticketsAfter: 5,
            ticketSerial: 'ADM01',
          ),
        );

        final grantRes = await provider.grantTickets(
          targetUid: 'u1',
          amount: 2,
          reason: 'Quiz winner',
        );
        expect(grantRes.ticketsAfter, 5);
        verify(() => harness.uuid.v4()).called(1);

        const rows = [
          SpinRegistrationRow(
            email: 'ada@example.com',
            fullName: 'Ada',
            package: 'VIP',
          ),
        ];
        when(
          () => harness.repo.importRegistrations(
            eventId: 'evt-1',
            rows: rows,
            replaceAll: true,
          ),
        ).thenAnswer(
          (_) async => const AdminImportRegistrationsResult(
            importedCount: 1,
            updatedCount: 0,
            totalRegistrationsCount: 1,
          ),
        );

        final importRes = await provider.importRegistrations(
          rows,
          replaceAll: true,
        );
        expect(importRes.importedCount, 1);
      },
    );

    test(
      'lookupWinByCode, redeemWin, and revokeWin sync lookupResult and wins',
      () async {
        await provider.bind('evt-1');
        final pendingWin = makeWin();
        harness.allWinsController.add([pendingWin]);
        await pumpEventQueue();

        when(
          () => harness.repo.lookupWinByCode(
            eventId: 'evt-1',
            codeOrQr: 'GDG-7K9P2M',
          ),
        ).thenAnswer((_) async => AdminLookupWinResult(win: pendingWin));

        final lookedUp = await provider.lookupWinByCode('GDG-7K9P2M');
        expect(lookedUp.win.id, 'win-1');
        expect(provider.lookupResult?.win.status, SpinWinStatus.pending);

        final redeemedWin = pendingWin.copyWith(
          status: SpinWinStatus.redeemed,
          redeemedByName: 'Staff User',
        );
        when(
          () => harness.repo.redeemWin(eventId: 'evt-1', winId: 'win-1'),
        ).thenAnswer((_) async => redeemedWin);

        final redeemed = await provider.redeemWin('win-1');
        expect(redeemed.status, SpinWinStatus.redeemed);
        expect(provider.lookupResult?.win.status, SpinWinStatus.redeemed);
        expect(provider.wins.single.status, SpinWinStatus.redeemed);

        provider.clearLookup();
        expect(provider.lookupResult, isNull);

        provider.selectWinForReview(pendingWin);
        expect(provider.lookupResult?.win.id, 'win-1');

        final revokedWin = pendingWin.copyWith(
          status: SpinWinStatus.revoked,
          revokeReason: 'Duplicate',
          returnedToStock: true,
        );
        when(
          () => harness.repo.revokeWin(
            eventId: 'evt-1',
            winId: 'win-1',
            returnToStock: true,
            reason: 'Duplicate',
          ),
        ).thenAnswer((_) async => revokedWin);

        final revoked = await provider.revokeWin(
          winId: 'win-1',
          returnToStock: true,
          reason: 'Duplicate',
        );
        expect(revoked.status, SpinWinStatus.revoked);
        expect(provider.lookupResult?.win.returnedToStock, isTrue);
        expect(provider.wins.single.status, SpinWinStatus.revoked);
      },
    );
  });
}
