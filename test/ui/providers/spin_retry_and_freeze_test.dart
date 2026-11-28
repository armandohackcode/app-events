import 'dart:async';
import 'dart:math';

import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class _MockSpinRepository extends Mock implements SpinRepository {}

class _SequentialUuid extends Uuid {
  int _counter = 0;

  @override
  String v4({Map<String, dynamic>? options, dynamic config}) {
    _counter++;
    return 'req-$_counter';
  }
}

void main() {
  late _MockSpinRepository repo;
  late StreamController<SpinConfig?> configController;
  late StreamController<List<SpinPrize>> prizesController;
  late StreamController<List<SpinMission>> missionsController;
  late StreamController<SpinPlayer?> playerController;
  late StreamController<List<SpinWin>> winsController;
  late StreamController<List<SpinMissionClaim>> claimsController;
  late StreamController<List<SpinTicketCode>> codesController;

  setUp(() {
    repo = _MockSpinRepository();
    configController = StreamController<SpinConfig?>.broadcast();
    prizesController = StreamController<List<SpinPrize>>.broadcast();
    missionsController = StreamController<List<SpinMission>>.broadcast();
    playerController = StreamController<SpinPlayer?>.broadcast();
    winsController = StreamController<List<SpinWin>>.broadcast();
    claimsController = StreamController<List<SpinMissionClaim>>.broadcast();
    codesController = StreamController<List<SpinTicketCode>>.broadcast();

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
      () => repo.watchPlayer(any(), any()),
    ).thenAnswer((_) => playerController.stream);
    when(
      () => repo.watchMyWins(any(), any()),
    ).thenAnswer((_) => winsController.stream);
    when(
      () => repo.watchAllWins(any(), status: any(named: 'status')),
    ).thenAnswer((_) => winsController.stream);
    when(
      () => repo.watchMyMissionClaims(any(), any()),
    ).thenAnswer((_) => claimsController.stream);
    when(
      () => repo.watchTicketCodes(any()),
    ).thenAnswer((_) => codesController.stream);
    when(() => repo.initPlayer(any())).thenAnswer(
      (_) async => const SpinInitPlayerResult(
        player: SpinPlayer(uid: 'u1', tickets: 1, spinsCount: 0),
        initialGranted: true,
      ),
    );
  });

  tearDown(() async {
    await Future.wait([
      configController.close(),
      prizesController.close(),
      missionsController.close(),
      playerController.close(),
      winsController.close(),
      claimsController.close(),
      codesController.close(),
    ]);
  });

  group('GdgSpinProvider retry and freeze hardening', () {
    test(
      'allows idempotent retry when stream drops tickets to 0 after timeout and clears on non-network error',
      () async {
        final provider = GdgSpinProvider(
          repo,
          random: Random(7),
          uuid: _SequentialUuid(),
        );
        addTearDown(provider.dispose);

        await provider.bind(eventId: 'evt-1', uid: 'u1');
        configController.add(const SpinConfig(status: SpinGameStatus.active));
        playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 1, spinsCount: 0),
        );
        await Future<void>.delayed(Duration.zero);

        var attempts = 0;
        when(
          () => repo.pull(eventId: 'evt-1', spinRequestId: 'req-1'),
        ).thenAnswer((_) async {
          attempts++;
          if (attempts == 1) {
            throw const SpinException(
              reason: SpinErrorReason.network,
              code: 'unavailable',
              message: 'Timed out',
            );
          }
          return const SpinPullResult(
            spinRequestId: 'req-1',
            outcomeType: SpinOutcomeType.lose,
            combo: [SpinSymbol.lemon, SpinSymbol.bar, SpinSymbol.cherries],
            ticketsAfter: 0,
            spinsCountAfter: 1,
          );
        });

        await provider.pull();
        expect(provider.hasPendingNetworkRetry, isTrue);
        expect(provider.phase, SpinPhase.idle);

        // Stream delivers committed ticket deduction while response was lost.
        playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 0, spinsCount: 1),
        );
        await Future<void>.delayed(Duration.zero);

        expect(provider.tickets, 0);
        expect(provider.canPull, isTrue);

        await provider.pull();
        expect(provider.hasPendingNetworkRetry, isFalse);
        expect(provider.phase, SpinPhase.spinning);
        expect(provider.tickets, 0);
        expect(provider.spins, 1);

        provider.reelsStopped();
        expect(provider.phase, SpinPhase.idle);
        expect(provider.tickets, 0);
        expect(provider.spins, 1);

        // Next definitive non-network error clears any pending retry ID.
        playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 1, spinsCount: 1),
        );
        await Future<void>.delayed(Duration.zero);

        var secondAttempts = 0;
        when(
          () => repo.pull(eventId: 'evt-1', spinRequestId: 'req-2'),
        ).thenAnswer((_) async {
          secondAttempts++;
          if (secondAttempts == 1) {
            throw const SpinException(
              reason: SpinErrorReason.network,
              code: 'unavailable',
              message: 'Temporary failure',
            );
          }
          throw const SpinException(
            reason: SpinErrorReason.insufficientTickets,
            code: 'failed-precondition',
            message: 'No tickets',
          );
        });

        await provider.pull();
        expect(provider.hasPendingNetworkRetry, isTrue);

        await provider.pull();
        expect(provider.hasPendingNetworkRetry, isFalse);
        expect(provider.phase, SpinPhase.idle);
      },
    );

    test(
      'settleInterruptedSpin flushes buffered streams and settles back to idle',
      () async {
        final provider = GdgSpinProvider(
          repo,
          random: Random(7),
          uuid: _SequentialUuid(),
        );
        addTearDown(provider.dispose);

        await provider.bind(eventId: 'evt-1', uid: 'u1');
        configController.add(const SpinConfig(status: SpinGameStatus.active));
        playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 2, spinsCount: 0),
        );
        await Future<void>.delayed(Duration.zero);

        when(
          () => repo.pull(eventId: 'evt-1', spinRequestId: 'req-1'),
        ).thenAnswer(
          (_) async => const SpinPullResult(
            spinRequestId: 'req-1',
            outcomeType: SpinOutcomeType.prize,
            combo: [SpinSymbol.star, SpinSymbol.star, SpinSymbol.star],
            wonPrize: SpinPullWonPrize(
              winId: 'w1',
              prizeId: 'p1',
              name: 'Sparky',
              symbol: SpinSymbol.star,
              rarity: PrizeRarity.epic,
              code: 'GDG-7K9P2M',
            ),
            ticketsAfter: 1,
            spinsCountAfter: 1,
          ),
        );

        await provider.pull();
        expect(provider.phase, SpinPhase.spinning);

        // Emit buffered stream updates while spinning.
        const updatedPrize = SpinPrize(
          id: 'p1',
          name: 'Sparky',
          symbol: SpinSymbol.star,
          initialStock: 5,
          remainingStock: 4,
          rarity: PrizeRarity.epic,
        );
        const updatedWin = SpinWin(
          id: 'w1',
          eventId: 'evt-1',
          uid: 'u1',
          winnerName: 'Ada',
          prizeId: 'p1',
          prizeName: 'Sparky',
          prizeSymbol: SpinSymbol.star,
          code: 'GDG-7K9P2M',
          status: SpinWinStatus.pending,
        );
        prizesController.add([updatedPrize]);
        winsController.add([updatedWin]);
        await Future<void>.delayed(Duration.zero);

        // Before settling, buffered lists are deferred.
        expect(provider.prizes, isEmpty);
        expect(provider.myWins, isEmpty);

        provider.settleInterruptedSpin();

        expect(provider.phase, SpinPhase.idle);
        expect(provider.pendingCombo, isNull);
        expect(provider.tickets, 1);
        expect(provider.spins, 1);
        expect(provider.prizes, hasLength(1));
        expect(provider.myWins, hasLength(1));
      },
    );

    test(
      'detaching the view during an in-flight pull settles directly to idle',
      () async {
        final provider = GdgSpinProvider(
          repo,
          random: Random(7),
          uuid: _SequentialUuid(),
        );
        addTearDown(provider.dispose);

        await provider.bind(eventId: 'evt-1', uid: 'u1');
        configController.add(const SpinConfig(status: SpinGameStatus.active));
        playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 2, spinsCount: 0),
        );
        await Future<void>.delayed(Duration.zero);

        final completer = Completer<SpinPullResult>();
        when(
          () => repo.pull(eventId: 'evt-1', spinRequestId: 'req-1'),
        ).thenAnswer((_) => completer.future);

        provider.attachView();
        final pullFuture = provider.pull();
        expect(provider.phase, SpinPhase.requesting);

        provider.detachView();
        completer.complete(
          const SpinPullResult(
            spinRequestId: 'req-1',
            outcomeType: SpinOutcomeType.bonus,
            combo: [
              SpinSymbol.mysteryBox,
              SpinSymbol.mysteryBox,
              SpinSymbol.mysteryBox,
            ],
            bonusTickets: 2,
            ticketsAfter: 3,
            spinsCountAfter: 1,
          ),
        );
        await pullFuture;

        expect(provider.phase, SpinPhase.idle);
        expect(provider.tickets, 3);
        expect(provider.spins, 1);
        expect(provider.lastOutcome, isA<SpinBonusOutcome>());
      },
    );
  });

  group('SpinAdminProvider multi-admin concurrency hardening', () {
    test(
      'syncs lookupResult from live wins stream, sends toggle-only mission patch, and forwards releasedDelta',
      () async {
        final adminProvider = SpinAdminProvider(repo);
        addTearDown(adminProvider.dispose);

        when(() => repo.getDashboard('evt-1')).thenAnswer(
          (_) async => const SpinDashboardStats(
            config: SpinConfig(),
            stats: SpinStatsSummary(),
            prizes: [],
            winCounts: SpinWinCounts(),
          ),
        );

        await adminProvider.bind('evt-1');

        const pendingWin = SpinWin(
          id: 'w1',
          eventId: 'evt-1',
          uid: 'u1',
          winnerName: 'Ada',
          prizeId: 'p1',
          prizeName: 'Sparky',
          prizeSymbol: SpinSymbol.star,
          code: 'GDG-7K9P2M',
          status: SpinWinStatus.pending,
        );
        when(
          () => repo.lookupWinByCode(eventId: 'evt-1', codeOrQr: 'GDG-7K9P2M'),
        ).thenAnswer((_) async => const AdminLookupWinResult(win: pendingWin));

        await adminProvider.lookupWinByCode('GDG-7K9P2M');
        expect(adminProvider.lookupResult?.win.status, SpinWinStatus.pending);

        // Concurrent admin redeems the win and Firestore stream emits update.
        winsController.add([
          pendingWin.copyWith(status: SpinWinStatus.redeemed),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(adminProvider.lookupResult?.win.status, SpinWinStatus.redeemed);

        // toggleMissionActive sends only {id, active}.
        const mission = SpinMission(
          id: 'm1',
          title: 'Concurrent Title',
          reward: 2,
          active: false,
        );
        when(
          () => repo.upsertMission(
            eventId: 'evt-1',
            missionData: {'id': 'm1', 'active': true},
          ),
        ).thenAnswer(
          (_) async =>
              AdminUpsertMissionResult(mission: mission.copyWith(active: true)),
        );

        final toggled = await adminProvider.toggleMissionActive(mission, true);
        expect(toggled.mission.active, isTrue);
        verify(
          () => repo.upsertMission(
            eventId: 'evt-1',
            missionData: {'id': 'm1', 'active': true},
          ),
        ).called(1);

        // adjustPrizeStock forwards optional releasedDelta.
        const adjusted = SpinPrize(
          id: 'p1',
          name: 'Sparky',
          symbol: SpinSymbol.star,
          initialStock: 10,
          remainingStock: 10,
          releasedStock: 4,
          rarity: PrizeRarity.epic,
        );
        when(
          () => repo.adjustPrizeStock(
            eventId: 'evt-1',
            prizeId: 'p1',
            delta: 0,
            releasedDelta: 1,
            reason: 'Wave release',
          ),
        ).thenAnswer((_) async => adjusted);

        final updatedPrize = await adminProvider.adjustPrizeStock(
          prizeId: 'p1',
          delta: 0,
          releasedDelta: 1,
          reason: 'Wave release',
        );
        expect(updatedPrize.releasedStock, 4);
        verify(
          () => repo.adjustPrizeStock(
            eventId: 'evt-1',
            prizeId: 'p1',
            delta: 0,
            releasedDelta: 1,
            reason: 'Wave release',
          ),
        ).called(1);
      },
    );
  });
}
