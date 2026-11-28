import 'dart:async';
import 'dart:math';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpinRepository extends Mock implements SpinRepository {}

class _SpinHarness {
  final _MockSpinRepository repository = _MockSpinRepository();
  final StreamController<SpinConfig?> configController =
      StreamController<SpinConfig?>.broadcast();
  final StreamController<List<SpinPrize>> prizesController =
      StreamController<List<SpinPrize>>.broadcast();
  final StreamController<List<SpinMission>> missionsController =
      StreamController<List<SpinMission>>.broadcast();
  final StreamController<SpinPlayer?> playerController =
      StreamController<SpinPlayer?>.broadcast();
  final StreamController<List<SpinWin>> winsController =
      StreamController<List<SpinWin>>.broadcast();
  final StreamController<List<SpinMissionClaim>> claimsController =
      StreamController<List<SpinMissionClaim>>.broadcast();

  _SpinHarness() {
    when(
      () => repository.watchConfig(any()),
    ).thenAnswer((_) => configController.stream);
    when(
      () => repository.watchPrizes(any(), activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) => prizesController.stream);
    when(
      () =>
          repository.watchMissions(any(), activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) => missionsController.stream);
    when(
      () => repository.watchPlayer(any(), any()),
    ).thenAnswer((_) => playerController.stream);
    when(
      () => repository.watchMyWins(any(), any()),
    ).thenAnswer((_) => winsController.stream);
    when(
      () => repository.watchMyMissionClaims(any(), any()),
    ).thenAnswer((_) => claimsController.stream);
    when(() => repository.initPlayer(any())).thenAnswer(
      (_) async => const SpinInitPlayerResult(
        player: SpinPlayer(uid: 'u1', tickets: 3, spinsCount: 0),
        initialGranted: true,
      ),
    );
  }

  Future<void> dispose() async {
    await Future.wait([
      configController.close(),
      prizesController.close(),
      missionsController.close(),
      playerController.close(),
      winsController.close(),
      claimsController.close(),
    ]);
  }
}

void main() {
  late _SpinHarness harness;
  late GdgSpinProvider provider;

  setUp(() {
    harness = _SpinHarness();
    provider = GdgSpinProvider(harness.repository, random: Random(7));
  });

  tearDown(() async {
    provider.dispose();
    await harness.dispose();
  });

  SpinPrize makePrize({
    String id = 'stickers',
    String name = 'Stickers',
    SpinSymbol symbol = SpinSymbol.cherries,
    int initialStock = 10,
    int remainingStock = 5,
    PrizeRarity rarity = PrizeRarity.common,
  }) => SpinPrize(
    id: id,
    name: name,
    symbol: symbol,
    initialStock: initialStock,
    remainingStock: remainingStock,
    rarity: rarity,
  );

  SpinWin makeWin({
    String id = 'win-1',
    String prizeId = 'stickers',
    String prizeName = 'Stickers',
    SpinWinStatus status = SpinWinStatus.pending,
  }) => SpinWin(
    id: id,
    eventId: 'evt-1',
    uid: 'u1',
    prizeId: prizeId,
    prizeName: prizeName,
    prizeSymbol: SpinSymbol.cherries,
    code: 'GDG-7K9P2M',
    status: status,
  );

  group('bind & mission merging', () {
    test(
      'bind subscribes to streams, initializes player, and is idempotent',
      () async {
        await provider.bind(eventId: 'evt-1', uid: 'u1');
        await provider.bind(eventId: 'evt-1', uid: 'u1');

        verify(() => harness.repository.initPlayer('evt-1')).called(1);
        verify(() => harness.repository.watchConfig('evt-1')).called(1);
        verify(
          () => harness.repository.watchPrizes('evt-1', activeOnly: true),
        ).called(1);
        verify(
          () => harness.repository.watchMissions('evt-1', activeOnly: true),
        ).called(1);
        verify(() => harness.repository.watchPlayer('evt-1', 'u1')).called(1);
        verify(() => harness.repository.watchMyWins('evt-1', 'u1')).called(1);
        verify(
          () => harness.repository.watchMyMissionClaims('evt-1', 'u1'),
        ).called(1);

        expect(provider.isBound, isTrue);
        expect(provider.isLoading, isFalse);
        expect(provider.tickets, 3);
      },
    );

    test(
      'bind exposes bindError and resets isLoading when initPlayer fails',
      () async {
        when(() => harness.repository.initPlayer('evt-1')).thenAnswer(
          (_) async => throw const SpinException(
            reason: SpinErrorReason.network,
            code: 'unavailable',
            message: 'offline',
          ),
        );

        await provider.bind(eventId: 'evt-1', uid: 'u1');

        expect(provider.isLoading, isFalse);
        expect(provider.bindError?.reason, SpinErrorReason.network);
        expect(provider.message, SpinMessage.networkError);
      },
    );

    test('merges mission claims onto active missions', () async {
      await provider.bind(eventId: 'evt-1', uid: 'u1');

      harness.missionsController.add(const [
        SpinMission(
          id: 'ask',
          type: SpinMissionType.askSpeaker,
          title: 'Ask speaker',
          reward: 1,
          maxCompletionsPerUser: 2,
        ),
        SpinMission(
          id: 'profile',
          type: SpinMissionType.profileComplete,
          title: 'Complete profile',
          reward: 1,
          maxCompletionsPerUser: 1,
        ),
      ]);
      harness.claimsController.add(const [
        SpinMissionClaim(uid: 'u1', missionId: 'ask', completions: 1),
        SpinMissionClaim(uid: 'u1', missionId: 'profile', completions: 1),
      ]);
      await pumpEventQueue();

      expect(provider.missions[0].completions, 1);
      expect(provider.missions[0].done, isFalse);
      expect(provider.missions[1].completions, 1);
      expect(provider.missions[1].done, isTrue);
    });
  });

  group('pull lifecycle & stream buffering', () {
    test('transitions idle -> requesting -> spinning -> win -> idle', () async {
      await provider.bind(eventId: 'evt-1', uid: 'u1');
      harness.configController.add(
        const SpinConfig(status: SpinGameStatus.active),
      );
      harness.prizesController.add([makePrize()]);
      harness.playerController.add(
        const SpinPlayer(uid: 'u1', tickets: 3, spinsCount: 0),
      );
      await pumpEventQueue();

      final completer = Completer<SpinPullResult>();
      when(
        () => harness.repository.pull(
          eventId: 'evt-1',
          spinRequestId: any(named: 'spinRequestId'),
        ),
      ).thenAnswer((_) => completer.future);

      final pullFuture = provider.pull();
      expect(provider.phase, SpinPhase.requesting);
      expect(provider.message, SpinMessage.connecting);
      expect(provider.canPull, isFalse);

      completer.complete(
        const SpinPullResult(
          spinRequestId: 'req-1',
          outcomeType: SpinOutcomeType.prize,
          combo: [SpinSymbol.cherries, SpinSymbol.cherries, SpinSymbol.wild],
          wonPrize: SpinPullWonPrize(
            winId: 'win-1',
            prizeId: 'stickers',
            name: 'Stickers',
            symbol: SpinSymbol.cherries,
            rarity: PrizeRarity.common,
            code: 'GDG-7K9P2M',
          ),
          ticketsAfter: 2,
          spinsCountAfter: 1,
        ),
      );
      await pullFuture;

      expect(provider.phase, SpinPhase.spinning);
      expect(provider.message, SpinMessage.spinning);
      expect(provider.tickets, 2);
      expect(provider.spins, 1);

      provider.secondReelStopped();
      expect(provider.teasing, isTrue);
      expect(provider.message, SpinMessage.tease);

      provider.reelsStopped();
      expect(provider.phase, SpinPhase.win);
      expect(provider.message, SpinMessage.win);
      expect(provider.myWins, hasLength(1));
      expect(provider.myWins.first.id, 'win-1');
      expect(provider.coins, hasLength(6));

      provider.celebrationDone();
      expect(provider.phase, SpinPhase.idle);
    });

    test(
      'buffers player, prizes, and wins streams during spinning until reelsStopped()',
      () async {
        await provider.bind(eventId: 'evt-1', uid: 'u1');
        harness.configController.add(
          const SpinConfig(status: SpinGameStatus.active),
        );
        harness.prizesController.add([makePrize(remainingStock: 5)]);
        harness.playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 3, spinsCount: 0),
        );
        harness.winsController.add(const []);
        await pumpEventQueue();

        when(
          () => harness.repository.pull(
            eventId: 'evt-1',
            spinRequestId: any(named: 'spinRequestId'),
          ),
        ).thenAnswer(
          (_) async => const SpinPullResult(
            spinRequestId: 'req-buf',
            outcomeType: SpinOutcomeType.prize,
            combo: [
              SpinSymbol.cherries,
              SpinSymbol.cherries,
              SpinSymbol.cherries,
            ],
            wonPrize: SpinPullWonPrize(
              winId: 'win-1',
              prizeId: 'stickers',
              name: 'Stickers',
              symbol: SpinSymbol.cherries,
              rarity: PrizeRarity.common,
              code: 'GDG-7K9P2M',
            ),
            ticketsAfter: 2,
            spinsCountAfter: 1,
          ),
        );

        await provider.pull();
        expect(provider.phase, SpinPhase.spinning);

        // Simulate Firestore emitting live updates 300ms after spinPull while reels spin.
        harness.playerController.add(
          const SpinPlayer(
            uid: 'u1',
            tickets: 2,
            spinsCount: 1,
            totalPrizesWon: 1,
          ),
        );
        harness.prizesController.add([makePrize(remainingStock: 4)]);
        harness.winsController.add([makeWin()]);
        await pumpEventQueue();

        // Visible state MUST remain frozen during spin animation.
        expect(provider.myWins, isEmpty);
        expect(provider.prizes.first.remainingStock, 5);
        expect(provider.player?.totalPrizesWon, 0);
        expect(provider.tickets, 2);
        expect(provider.spins, 1);

        // Flush occurs at the exact moment reels stop.
        provider.reelsStopped();

        expect(provider.phase, SpinPhase.win);
        expect(provider.myWins, hasLength(1));
        expect(provider.myWins.first.id, 'win-1');
        expect(provider.prizes.first.remainingStock, 4);
        expect(provider.player?.totalPrizesWon, 1);
        expect(provider.tickets, 2);
        expect(provider.spins, 1);
      },
    );

    test('buffers bonus ticket increments until reelsStopped()', () async {
      await provider.bind(eventId: 'evt-1', uid: 'u1');
      harness.configController.add(
        const SpinConfig(status: SpinGameStatus.active),
      );
      harness.playerController.add(
        const SpinPlayer(uid: 'u1', tickets: 3, spinsCount: 0),
      );
      await pumpEventQueue();

      when(
        () => harness.repository.pull(
          eventId: 'evt-1',
          spinRequestId: any(named: 'spinRequestId'),
        ),
      ).thenAnswer(
        (_) async => const SpinPullResult(
          spinRequestId: 'req-bonus',
          outcomeType: SpinOutcomeType.bonus,
          combo: [
            SpinSymbol.mysteryBox,
            SpinSymbol.mysteryBox,
            SpinSymbol.mysteryBox,
          ],
          bonusTickets: 2,
          ticketsAfter: 4,
          spinsCountAfter: 1,
        ),
      );

      await provider.pull();
      harness.playerController.add(
        const SpinPlayer(uid: 'u1', tickets: 4, spinsCount: 1),
      );
      await pumpEventQueue();

      // Still shows visually spent ticket balance (3 - 1 = 2) until reels stop.
      expect(provider.tickets, 2);

      provider.reelsStopped();
      expect(provider.phase, SpinPhase.bonus);
      expect(provider.tickets, 4);
      expect(provider.coins, hasLength(8));
    });

    test(
      'maps blocked pull states and server errors cleanly, keeping network retry idempotent',
      () async {
        await provider.pull();
        expect(provider.message, SpinMessage.noActiveEvent);

        await provider.bind(eventId: 'evt-1', uid: 'u1');
        harness.configController.add(
          const SpinConfig(
            status: SpinGameStatus.paused,
            pauseMessage: 'Paused for keynote',
          ),
        );
        await pumpEventQueue();

        await provider.pull();
        expect(provider.message, SpinMessage.paused);
        expect(provider.customStatusMessage, 'Paused for keynote');

        harness.configController.add(
          const SpinConfig(status: SpinGameStatus.active, maxPrizesPerUser: 1),
        );
        harness.playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 2, totalPrizesWon: 1),
        );
        await pumpEventQueue();

        expect(provider.isBlockedByPrizeCap, isTrue);
        await provider.pull();
        expect(provider.message, SpinMessage.prizeCapReached);

        // Clear prize cap and test network retry idempotency.
        harness.playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 2, totalPrizesWon: 0),
        );
        await pumpEventQueue();

        final capturedIds = <String>[];
        var callCount = 0;
        when(
          () => harness.repository.pull(
            eventId: 'evt-1',
            spinRequestId: any(named: 'spinRequestId'),
          ),
        ).thenAnswer((invocation) async {
          callCount++;
          capturedIds.add(invocation.namedArguments[#spinRequestId] as String);
          if (callCount == 1) {
            throw const SpinException(
              reason: SpinErrorReason.network,
              code: 'unavailable',
              message: 'timeout',
            );
          }
          return const SpinPullResult(
            spinRequestId: 'replayed',
            outcomeType: SpinOutcomeType.lose,
            combo: [SpinSymbol.lemon, SpinSymbol.cherries, SpinSymbol.bar],
            ticketsAfter: 1,
            spinsCountAfter: 1,
          );
        });

        await provider.pull();
        expect(provider.phase, SpinPhase.idle);
        expect(provider.message, SpinMessage.networkError);
        expect(provider.hasPendingNetworkRetry, isTrue);

        await provider.pull();
        expect(provider.phase, SpinPhase.spinning);
        expect(provider.hasPendingNetworkRetry, isFalse);
        expect(capturedIds, hasLength(2));
        expect(capturedIds[0], equals(capturedIds[1]));

        provider.reelsStopped();
        expect(provider.phase, SpinPhase.idle);
        expect(provider.message, SpinMessage.lose);
      },
    );

    test('handles null buffered player snapshot safely', () async {
      await provider.bind(eventId: 'evt-1', uid: 'u1');
      harness.configController.add(
        const SpinConfig(status: SpinGameStatus.active),
      );
      harness.playerController.add(
        const SpinPlayer(uid: 'u1', tickets: 2, spinsCount: 0),
      );
      await pumpEventQueue();

      when(
        () => harness.repository.pull(
          eventId: 'evt-1',
          spinRequestId: any(named: 'spinRequestId'),
        ),
      ).thenAnswer(
        (_) async => const SpinPullResult(
          spinRequestId: 'req-null',
          outcomeType: SpinOutcomeType.lose,
          combo: [SpinSymbol.lemon, SpinSymbol.bell, SpinSymbol.bar],
          ticketsAfter: 1,
          spinsCountAfter: 1,
        ),
      );

      await provider.pull();
      harness.playerController.add(null);
      await pumpEventQueue();

      expect(provider.player, isNotNull);
      provider.reelsStopped();
      expect(provider.player, isNull);
    });
  });

  group('missions, trivia, stand codes, and coins', () {
    test(
      'claimMission updates tickets on success and rethrows SpinException on error',
      () async {
        await provider.bind(eventId: 'evt-1', uid: 'u1');
        when(
          () => harness.repository.claimMission(
            eventId: 'evt-1',
            missionId: 'profile',
          ),
        ).thenAnswer(
          (_) async => const SpinClaimMissionResult(
            granted: true,
            ticketsAwarded: 1,
            ticketsAfter: 4,
            ticketSerial: 'A1B2C3D4',
          ),
        );

        final result = await provider.claimMission('profile');
        expect(result?.granted, isTrue);
        expect(provider.tickets, 4);
        expect(provider.message, SpinMessage.missionDone);
        expect(provider.isMissionBusy, isFalse);

        when(
          () => harness.repository.claimMission(
            eventId: 'evt-1',
            missionId: 'profile',
          ),
        ).thenAnswer(
          (_) async => throw const SpinException(
            reason: SpinErrorReason.requirementNotMet,
            code: 'failed-precondition',
            message: 'incomplete',
          ),
        );

        await expectLater(
          provider.claimMission('profile'),
          throwsA(
            isA<SpinException>().having(
              (e) => e.reason,
              'reason',
              SpinErrorReason.requirementNotMet,
            ),
          ),
        );
        expect(provider.message, SpinMessage.requirementNotMet);
        expect(provider.isMissionBusy, isFalse);
      },
    );

    test(
      'toggleTrivia and submitTrivia update state and server explanation',
      () async {
        await provider.bind(eventId: 'evt-1', uid: 'u1');

        provider.toggleTrivia('trivia-1');
        expect(provider.openTriviaMissionId, 'trivia-1');

        when(
          () => harness.repository.submitTrivia(
            eventId: 'evt-1',
            missionId: 'trivia-1',
            selectedIndex: 0,
          ),
        ).thenAnswer(
          (_) async => const SpinSubmitTriviaResult(
            correct: true,
            explanation: 'Firebase AI Logic calls Gemini cleanly.',
            ticketsAwarded: 1,
            ticketsAfter: 4,
            ticketSerial: 'FF001122',
          ),
        );

        final res = await provider.submitTrivia('trivia-1', 0);
        expect(res?.correct, isTrue);
        expect(provider.openTriviaMissionId, isNull);
        expect(provider.tickets, 4);
        expect(provider.message, SpinMessage.triviaRight);
        expect(
          provider.customStatusMessage,
          'Firebase AI Logic calls Gemini cleanly.',
        );
        expect(provider.isMissionBusy, isFalse);
      },
    );

    test(
      'redeemTicketCode updates tickets on success and rethrows errors',
      () async {
        await provider.bind(eventId: 'evt-1', uid: 'u1');
        when(
          () => harness.repository.redeemTicketCode(
            eventId: 'evt-1',
            code: 'CLOUD26',
          ),
        ).thenAnswer(
          (_) async => const SpinRedeemTicketCodeResult(
            label: 'Google Cloud',
            ticketsAwarded: 2,
            ticketsAfter: 5,
            ticketSerial: 'CC260001',
          ),
        );

        final res = await provider.redeemTicketCode('CLOUD26');
        expect(res?.ticketsAwarded, 2);
        expect(provider.tickets, 5);
        expect(provider.message, SpinMessage.codeRedeemed);
        expect(
          provider.customStatusMessage,
          AppStrings.spinCodeRedeemed('Google Cloud', 2),
        );

        when(
          () => harness.repository.redeemTicketCode(
            eventId: 'evt-1',
            code: 'EXPIRED',
          ),
        ).thenAnswer(
          (_) async => throw const SpinException(
            reason: SpinErrorReason.codeExpired,
            code: 'failed-precondition',
            message: 'expired',
          ),
        );

        await expectLater(
          provider.redeemTicketCode('EXPIRED'),
          throwsA(isA<SpinException>()),
        );
        expect(provider.message, SpinMessage.codeError);
        expect(provider.isMissionBusy, isFalse);
      },
    );

    test('collectCoins handles empty and non-empty tray', () async {
      provider.collectCoins();
      expect(provider.message, SpinMessage.trayHint);

      await provider.bind(eventId: 'evt-1', uid: 'u1');
      harness.configController.add(
        const SpinConfig(status: SpinGameStatus.active),
      );
      await pumpEventQueue();

      when(
        () => harness.repository.pull(
          eventId: 'evt-1',
          spinRequestId: any(named: 'spinRequestId'),
        ),
      ).thenAnswer(
        (_) async => const SpinPullResult(
          spinRequestId: 'req-coins',
          outcomeType: SpinOutcomeType.bonus,
          combo: [
            SpinSymbol.mysteryBox,
            SpinSymbol.mysteryBox,
            SpinSymbol.mysteryBox,
          ],
          bonusTickets: 1,
          ticketsAfter: 3,
          spinsCountAfter: 1,
        ),
      );

      await provider.pull();
      provider.reelsStopped();
      expect(provider.coins, isNotEmpty);

      provider.collectCoins();
      expect(provider.coins, isEmpty);
      expect(provider.message, SpinMessage.coinsCollected);
    });
  });
}
