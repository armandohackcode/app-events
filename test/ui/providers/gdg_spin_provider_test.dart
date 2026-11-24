import 'dart:math';

import 'package:app_events/domain/models/spin_combo.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic [Random] stub returning pre-configured values in order.
class _FakeRandom implements Random {
  final List<double> _doubles;
  final List<int> _ints;
  int _dIdx = 0;
  int _iIdx = 0;

  _FakeRandom({List<double>? doubles, List<int>? ints})
    : _doubles = doubles ?? const [0.5],
      _ints = ints ?? const [0];

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => _doubles[(_dIdx++) % _doubles.length];

  @override
  int nextInt(int max) => _ints[(_iIdx++) % _ints.length] % max;
}

void main() {
  late GdgSpinProvider provider;
  late int notifications;

  void attachCounter(GdgSpinProvider p) {
    notifications = 0;
    p.addListener(() => notifications++);
  }

  setUp(() {
    provider = GdgSpinProvider(random: Random(42));
    attachCounter(provider);
  });

  tearDown(() {
    provider.dispose();
  });

  group('GdgSpinProvider.pull', () {
    test('does nothing when tickets are zero', () {
      provider.tickets = 0;

      provider.pull();

      expect(provider.spins, 0);
      expect(provider.spinId, 0);
      expect(provider.phase, SpinPhase.idle);
      expect(notifications, 0);
    });

    test('consumes one ticket, increments spin counters, and notifies', () {
      provider.pull();

      expect(provider.tickets, 2);
      expect(provider.spins, 1);
      expect(provider.done, 1);
      expect(provider.spinId, 1);
      expect(provider.phase, SpinPhase.spinning);
      expect(provider.message, SpinMessage.spinning);
      expect(provider.pendingCombo, hasLength(3));
      expect(notifications, 1);
    });

    test('winning a prize decrements stock and adds code and coins', () {
      // 0.5 >= bonusP (0.06), 0.01 < first prize probability (30/120 = 0.25)
      final winProvider = GdgSpinProvider(
        random: _FakeRandom(doubles: [0.5, 0.01, 0.5], ints: [0x1A2B]),
      );
      addTearDown(winProvider.dispose);
      attachCounter(winProvider);

      winProvider.pull();
      expect(winProvider.prizes.first.remainingStock, 29);

      winProvider.reelsStopped();

      expect(winProvider.phase, SpinPhase.win);
      expect(winProvider.message, SpinMessage.win);
      expect(winProvider.myPrizes, hasLength(1));
      expect(winProvider.myPrizes.first.prizeId, 'stickers');
      expect(
        winProvider.myPrizes.first.code,
        matches(RegExp(r'^GDG-[0-9A-F]{4}$')),
      );
      expect(winProvider.coins, hasLength(6));
      expect(winProvider.coins.every((c) => c.isNew), isTrue);
      expect(notifications, 2);
    });

    test('winning higher rarity grants the corresponding coin count', () {
      final epicProvider = GdgSpinProvider(
        random: _FakeRandom(doubles: [0.5, 0.001, 0.5]),
        initialPrizes: const [
          SpinPrize(
            id: 'sparky',
            name: 'Sparky',
            symbol: SpinSymbol.star,
            initialStock: 2,
            remainingStock: 2,
            rarity: PrizeRarity.epic,
          ),
        ],
      );
      addTearDown(epicProvider.dispose);

      epicProvider.pull();
      epicProvider.reelsStopped();

      expect(epicProvider.coins, hasLength(16));
    });

    test('sold-out prizes are never selected across many spins', () {
      final limitedProvider = GdgSpinProvider(
        random: Random(7),
        initialPrizes: const [
          SpinPrize(
            id: 'sold_out',
            name: 'Sold out',
            symbol: SpinSymbol.seven,
            initialStock: 1,
            remainingStock: 0,
            rarity: PrizeRarity.legendary,
          ),
          SpinPrize(
            id: 'available',
            name: 'Stickers',
            symbol: SpinSymbol.cherries,
            initialStock: 30,
            remainingStock: 30,
            rarity: PrizeRarity.common,
          ),
        ],
      );
      addTearDown(limitedProvider.dispose);

      for (var i = 0; i < 60; i++) {
        limitedProvider.tickets = 5;
        limitedProvider.pull();
        limitedProvider.reelsStopped();
        limitedProvider.celebrationDone();
      }

      expect(
        limitedProvider.myPrizes.where((p) => p.prizeId == 'sold_out'),
        isEmpty,
      );
    });

    test('losing combos never look like a win', () {
      final loseProvider = GdgSpinProvider(random: Random(99));
      addTearDown(loseProvider.dispose);

      for (var i = 0; i < 40; i++) {
        loseProvider.tickets = 5;
        loseProvider.pull();
        final combo = loseProvider.pendingCombo!;
        loseProvider.reelsStopped();
        if (loseProvider.lastOutcome == null) {
          expect(SpinCombo.looksLikeWin(combo), isFalse);
        }
        loseProvider.celebrationDone();
      }
    });

    test('bonus outcome awards 1 to 3 tickets and 8 coins', () {
      final bonusProvider = GdgSpinProvider(
        random: _FakeRandom(doubles: [0.01, 0.5], ints: [1]),
      );
      addTearDown(bonusProvider.dispose);

      bonusProvider.pull();
      expect(bonusProvider.pendingCombo, [
        SpinSymbol.mysteryBox,
        SpinSymbol.mysteryBox,
        SpinSymbol.mysteryBox,
      ]);

      bonusProvider.reelsStopped();

      expect(bonusProvider.phase, SpinPhase.bonus);
      expect(bonusProvider.message, SpinMessage.bonus);
      expect(bonusProvider.tickets, 4);
      expect(bonusProvider.coins, hasLength(8));
    });
  });

  group('GdgSpinProvider missions, trivia, coins and demo', () {
    test('completing a mission grants its reward only once', () {
      final grantedFirst = provider.completeMission('ask');
      final grantedSecond = provider.completeMission('ask');

      expect(grantedFirst, isTrue);
      expect(grantedSecond, isFalse);
      expect(provider.tickets, 4);
      expect(provider.message, SpinMessage.missionDone);
      expect(notifications, 1);
    });

    test('trivia mission toggles open and rewards only on right answer', () {
      final opened = provider.completeMission('trivia');
      expect(opened, isFalse);
      expect(provider.triviaOpen, isTrue);

      final rewarded = provider.answerTrivia(true);
      expect(rewarded, isTrue);
      expect(provider.triviaOpen, isFalse);
      expect(provider.tickets, 4);
      expect(provider.message, SpinMessage.triviaRight);
      expect(provider.missions.last.done, isTrue);
    });

    test('wrong trivia answer completes mission without adding tickets', () {
      final testProvider = GdgSpinProvider(
        random: Random(1),
        initialMissions: const [
          SpinMission(
            id: 'trivia',
            title: 'Trivia',
            reward: 1,
            done: false,
            actionLabel: 'Play',
            isTrivia: true,
          ),
        ],
      );
      addTearDown(testProvider.dispose);

      testProvider.completeMission('trivia');
      final rewarded = testProvider.answerTrivia(false);

      expect(rewarded, isFalse);
      expect(testProvider.tickets, 3);
      expect(testProvider.message, SpinMessage.triviaWrong);
      expect(testProvider.missions.first.done, isTrue);
    });

    test('addDemoTickets adds 5 tickets and notifies', () {
      provider.addDemoTickets();

      expect(provider.tickets, 8);
      expect(provider.message, SpinMessage.demoReloaded);
      expect(notifications, 1);
    });

    test('collectCoins clears non-empty tray and shows hint when empty', () {
      provider.collectCoins();
      expect(provider.message, SpinMessage.trayHint);
      expect(notifications, 1);

      final winProvider = GdgSpinProvider(
        random: _FakeRandom(doubles: [0.5, 0.01, 0.5]),
      );
      addTearDown(winProvider.dispose);
      attachCounter(winProvider);

      winProvider.pull();
      winProvider.reelsStopped();
      expect(winProvider.coins, isNotEmpty);

      winProvider.collectCoins();
      expect(winProvider.coins, isEmpty);
      expect(winProvider.message, SpinMessage.coinsCollected);
    });
  });
}
