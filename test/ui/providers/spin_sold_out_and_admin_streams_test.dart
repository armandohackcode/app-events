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

SpinPrize _prize({required String id, required int remainingStock}) =>
    SpinPrize(
      id: id,
      name: 'Prize $id',
      symbol: SpinSymbol.cherries,
      initialStock: 5,
      remainingStock: remainingStock,
      rarity: PrizeRarity.common,
    );

const _loseResult = SpinPullResult(
  spinRequestId: 'req-1',
  outcomeType: SpinOutcomeType.lose,
  combo: [SpinSymbol.lemon, SpinSymbol.bar, SpinSymbol.cherries],
  ticketsAfter: 2,
  spinsCountAfter: 1,
);

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
      () => repo.watchMyMissionClaims(any(), any()),
    ).thenAnswer((_) => claimsController.stream);
    when(() => repo.initPlayer(any())).thenAnswer(
      (_) async => const SpinInitPlayerResult(
        player: SpinPlayer(uid: 'u1', tickets: 3, spinsCount: 0),
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

  Future<GdgSpinProvider> bindActivePlayer() async {
    final provider = GdgSpinProvider(
      repo,
      random: Random(7),
      uuid: _SequentialUuid(),
    );
    addTearDown(provider.dispose);
    await provider.bind(eventId: 'evt-1', uid: 'u1');
    configController.add(const SpinConfig(status: SpinGameStatus.active));
    playerController.add(
      const SpinPlayer(uid: 'u1', tickets: 3, spinsCount: 0),
    );
    await Future<void>.delayed(Duration.zero);
    return provider;
  }

  group('GdgSpinProvider sold-out state', () {
    test('is not sold out before the prize catalog loads', () async {
      final provider = await bindActivePlayer();

      expect(provider.isSoldOut, isFalse);
      expect(provider.canPull, isTrue);
    });

    test(
      'is not sold out with an empty catalog, so a paused setup is not shown as sold out',
      () async {
        final provider = await bindActivePlayer();
        prizesController.add(const []);
        await Future<void>.delayed(Duration.zero);

        expect(provider.isSoldOut, isFalse);
      },
    );

    test(
      'blocks the lever without calling the server once every prize is out of stock',
      () async {
        final provider = await bindActivePlayer();
        prizesController.add([
          _prize(id: 'a', remainingStock: 0),
          _prize(id: 'b', remainingStock: 0),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(provider.isSoldOut, isTrue);
        expect(provider.canPull, isFalse);

        await provider.pull();

        expect(provider.message, SpinMessage.soldOut);
        expect(provider.phase, SpinPhase.idle);
        verifyNever(
          () => repo.pull(
            eventId: any(named: 'eventId'),
            spinRequestId: any(named: 'spinRequestId'),
          ),
        );
      },
    );

    test('stays playable while at least one prize has stock', () async {
      final provider = await bindActivePlayer();
      prizesController.add([
        _prize(id: 'a', remainingStock: 0),
        _prize(id: 'b', remainingStock: 1),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.isSoldOut, isFalse);
      expect(provider.canPull, isTrue);
    });

    test(
      'still allows replaying a pending spin after the catalog sells out',
      () async {
        final provider = await bindActivePlayer();
        prizesController.add([_prize(id: 'a', remainingStock: 1)]);
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
              message: 'Lost response',
            );
          }
          return _loseResult;
        });

        await provider.pull();
        expect(provider.hasPendingNetworkRetry, isTrue);

        // The lost spin may have taken the last unit.
        prizesController.add([_prize(id: 'a', remainingStock: 0)]);
        await Future<void>.delayed(Duration.zero);

        expect(provider.isSoldOut, isTrue);
        expect(provider.canPull, isTrue);

        await provider.pull();
        expect(provider.phase, SpinPhase.spinning);
        verify(
          () => repo.pull(eventId: 'evt-1', spinRequestId: 'req-1'),
        ).called(2);
      },
    );
  });

  group('GdgSpinProvider offline retry on Android and iOS', () {
    test(
      'keeps the same spinRequestId when the plugin reports an unknown/internal error',
      () async {
        final provider = await bindActivePlayer();
        prizesController.add([_prize(id: 'a', remainingStock: 3)]);
        await Future<void>.delayed(Duration.zero);

        var attempts = 0;
        when(
          () => repo.pull(eventId: 'evt-1', spinRequestId: 'req-1'),
        ).thenAnswer((_) async {
          attempts++;
          if (attempts == 1) {
            // Android reports a dropped connection as `internal`.
            throw const SpinException(
              reason: SpinErrorReason.unknown,
              code: 'internal',
              message: 'INTERNAL',
            );
          }
          return _loseResult;
        });

        await provider.pull();
        expect(provider.hasPendingNetworkRetry, isTrue);
        expect(provider.message, SpinMessage.networkError);

        await provider.pull();
        expect(provider.hasPendingNetworkRetry, isFalse);
        expect(provider.phase, SpinPhase.spinning);
        verify(
          () => repo.pull(eventId: 'evt-1', spinRequestId: 'req-1'),
        ).called(2);
      },
    );

    test(
      'drops the retry id when the server gives a business reason',
      () async {
        final provider = await bindActivePlayer();
        prizesController.add([_prize(id: 'a', remainingStock: 3)]);
        await Future<void>.delayed(Duration.zero);

        when(
          () => repo.pull(eventId: 'evt-1', spinRequestId: 'req-1'),
        ).thenThrow(
          const SpinException(
            reason: SpinErrorReason.gameClosed,
            code: 'failed-precondition',
            message: 'No prizes left',
          ),
        );

        await provider.pull();

        expect(provider.hasPendingNetworkRetry, isFalse);
        expect(provider.message, SpinMessage.closed);
      },
    );
  });

  group('SpinAdminProvider admin-only streams', () {
    const dashboard = SpinDashboardStats(
      config: SpinConfig(status: SpinGameStatus.active),
      stats: SpinStatsSummary(),
      prizes: [],
      winCounts: SpinWinCounts(),
    );

    setUp(() {
      when(
        () => repo.watchAllWins(any(), status: any(named: 'status')),
      ).thenAnswer((_) => winsController.stream);
      when(
        () => repo.watchTicketCodes(any()),
      ).thenAnswer((_) => codesController.stream);
    });

    test(
      'opens admin-only streams after the dashboard call normalizes the admin',
      () async {
        final calls = <String>[];
        when(() => repo.getDashboard('evt-1')).thenAnswer((_) async {
          calls.add('dashboard');
          return dashboard;
        });
        when(() => repo.watchAllWins('evt-1', status: null)).thenAnswer((_) {
          calls.add('wins');
          return winsController.stream;
        });
        when(() => repo.watchTicketCodes('evt-1')).thenAnswer((_) {
          calls.add('codes');
          return codesController.stream;
        });

        final admin = SpinAdminProvider(repo);
        addTearDown(admin.dispose);
        await admin.bind('evt-1');

        expect(calls, ['dashboard', 'wins', 'codes']);
      },
    );

    test(
      'resubscribes denied admin-only streams after a successful refresh',
      () async {
        when(
          () => repo.getDashboard('evt-1'),
        ).thenAnswer((_) async => dashboard);
        final admin = SpinAdminProvider(repo);
        addTearDown(admin.dispose);
        await admin.bind('evt-1');

        winsController.addError(
          const SpinException(
            reason: SpinErrorReason.permissionDenied,
            code: 'permission-denied',
            message: 'Missing users-admin/{uid}',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(admin.lastError?.reason, SpinErrorReason.permissionDenied);

        await admin.refreshDashboard();

        verify(() => repo.watchAllWins('evt-1', status: null)).called(2);
        verify(() => repo.watchTicketCodes('evt-1')).called(2);
        expect(admin.lastError, isNull);
      },
    );
  });
}
