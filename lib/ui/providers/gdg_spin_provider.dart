import 'dart:math';

import 'package:app_events/domain/models/spin_combo.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/providers/gdg_spin_demo_data.dart';
import 'package:flutter/foundation.dart';

enum SpinPhase { idle, spinning, win, bonus, nearMiss }

enum SpinMessage {
  pullHint,
  spinning,
  tease,
  win,
  bonus,
  lose,
  outOfTickets,
  noTickets,
  demoReloaded,
  trayHint,
  coinsCollected,
  missionDone,
  triviaRight,
  triviaWrong,
}

sealed class SpinOutcome {
  const SpinOutcome();
}

class SpinPrizeOutcome extends SpinOutcome {
  final SpinPrize prize;
  const SpinPrizeOutcome(this.prize);
}

class SpinBonusOutcome extends SpinOutcome {
  final int tickets;
  const SpinBonusOutcome(this.tickets);
}

class WonPrize {
  final String prizeId;
  final String name;
  final SpinSymbol symbol;
  final String code;

  const WonPrize({
    required this.prizeId,
    required this.name,
    required this.symbol,
    required this.code,
  });
}

class CoinDrop {
  final double leftFraction;
  final double bottom;
  final double rotation;
  final int delayMs;
  final bool isNew;

  const CoinDrop({
    required this.leftFraction,
    required this.bottom,
    required this.rotation,
    required this.delayMs,
    required this.isNew,
  });

  CoinDrop copyWith({bool? isNew}) => CoinDrop(
    leftFraction: leftFraction,
    bottom: bottom,
    rotation: rotation,
    delayMs: delayMs,
    isNew: isNew ?? this.isNew,
  );
}

/// Local demo state for GDG SPIN. Timers and animations live in widgets.
class GdgSpinProvider extends ChangeNotifier {
  static const int _estimatedEventSpins = 120;
  static const double _bonusProbability = 0.06;
  static const double _wildReplacementChance = 0.35;
  static const int _maxCoinsInTray = 46;
  static const int _bonusCoins = 8;

  static const List<SpinSymbol> fillSymbols = [
    SpinSymbol.cherries,
    SpinSymbol.cherries,
    SpinSymbol.lemon,
    SpinSymbol.lemon,
    SpinSymbol.bell,
    SpinSymbol.bar,
    SpinSymbol.star,
    SpinSymbol.diamond,
    SpinSymbol.diamond,
    SpinSymbol.wild,
    SpinSymbol.mysteryBox,
    SpinSymbol.seven,
  ];

  final Random _random;

  int tickets = 3;
  int spins = 0;
  int spinId = 0;
  int done = 0;

  List<List<SpinSymbol>> visible = [
    [SpinSymbol.lemon, SpinSymbol.seven, SpinSymbol.bell],
    [SpinSymbol.seven, SpinSymbol.cherries, SpinSymbol.bar],
    [SpinSymbol.diamond, SpinSymbol.lemon, SpinSymbol.seven],
  ];

  List<SpinSymbol>? pendingCombo;
  bool teasing = false;
  SpinPhase phase = SpinPhase.idle;
  SpinOutcome? lastOutcome;
  List<SpinPrize> prizes;
  List<SpinMission> missions;
  final List<WonPrize> myPrizes = [];
  List<CoinDrop> coins = [];
  SpinMessage message = SpinMessage.pullHint;
  bool triviaOpen = false;

  SpinOutcome? _pendingOutcome;
  SpinSymbol? _lastWinSymbol;

  GdgSpinProvider({
    Random? random,
    List<SpinPrize>? initialPrizes,
    List<SpinMission>? initialMissions,
  }) : _random = random ?? Random.secure(),
       prizes = List<SpinPrize>.from(
         initialPrizes ?? GdgSpinDemoData.createPrizes(),
       ),
       missions = List<SpinMission>.from(
         initialMissions ?? GdgSpinDemoData.createMissions(),
       );

  bool get canPull => phase == SpinPhase.idle && tickets > 0;

  SpinSymbol? get lastWinSymbol => _lastWinSymbol;

  /// Pulls the lever when idle and at least one ticket is available.
  void pull() {
    if (!canPull) return;

    final outcome = _random.nextDouble() < _bonusProbability
        ? SpinBonusOutcome(_random.nextInt(3) + 1)
        : _decidePrizeOutcome();

    if (outcome is SpinPrizeOutcome) {
      final index = prizes.indexWhere((p) => p.id == outcome.prize.id);
      if (index != -1) {
        prizes[index] = prizes[index].copyWith(
          remainingStock: prizes[index].remainingStock - 1,
        );
      }
    }

    final combo = _buildCombo(outcome);

    tickets--;
    spins++;
    done++;
    spinId++;
    teasing = false;
    phase = SpinPhase.spinning;
    message = SpinMessage.spinning;
    pendingCombo = combo;
    _pendingOutcome = outcome;
    notifyListeners();
  }

  /// Evaluates near-win suspense once the second reel stops.
  void secondReelStopped({bool reducedMotion = false}) {
    if (phase != SpinPhase.spinning || pendingCombo == null) return;
    final nextTeasing =
        SpinCombo.canStillWin(pendingCombo![0], pendingCombo![1]) &&
        !reducedMotion;
    if (nextTeasing == teasing) return;
    teasing = nextTeasing;
    if (teasing) {
      message = SpinMessage.tease;
    }
    notifyListeners();
  }

  /// Applies the pending outcome once all three reels stop.
  void reelsStopped({List<List<SpinSymbol>>? finalVisible}) {
    if (phase != SpinPhase.spinning || pendingCombo == null) return;

    final combo = pendingCombo!;
    final outcome = _pendingOutcome;
    _pendingOutcome = null;
    lastOutcome = outcome;
    teasing = false;

    if (finalVisible != null && finalVisible.length == 3) {
      visible = finalVisible;
    } else {
      for (var r = 0; r < 3; r++) {
        visible[r][1] = combo[r];
      }
    }

    switch (outcome) {
      case SpinBonusOutcome(:final tickets):
        this.tickets += tickets;
        _lastWinSymbol = SpinSymbol.mysteryBox;
        _addCoins(_bonusCoins);
        phase = SpinPhase.bonus;
        message = SpinMessage.bonus;
      case SpinPrizeOutcome(:final prize):
        _lastWinSymbol = prize.symbol;
        myPrizes.insert(
          0,
          WonPrize(
            prizeId: prize.id,
            name: prize.name,
            symbol: prize.symbol,
            code: _generatePrizeCode(),
          ),
        );
        _addCoins(_coinsForRarity(prize.rarity));
        phase = SpinPhase.win;
        message = SpinMessage.win;
      case null:
        _lastWinSymbol = null;
        phase = SpinCombo.canStillWin(combo[0], combo[1])
            ? SpinPhase.nearMiss
            : SpinPhase.idle;
        message = tickets <= 0 ? SpinMessage.outOfTickets : SpinMessage.lose;
    }

    pendingCombo = null;
    notifyListeners();
  }

  /// Returns the machine from win/bonus/near-miss celebration back to idle.
  void celebrationDone() {
    if (phase == SpinPhase.idle || phase == SpinPhase.spinning) return;
    phase = SpinPhase.idle;
    notifyListeners();
  }

  /// Marks a regular mission done or toggles the trivia box.
  /// Returns true when a ticket reward was granted.
  bool completeMission(String id) {
    final index = missions.indexWhere((m) => m.id == id);
    if (index == -1) return false;
    final mission = missions[index];
    if (mission.done) return false;

    if (mission.isTrivia) {
      triviaOpen = !triviaOpen;
      notifyListeners();
      return false;
    }

    missions[index] = mission.copyWith(done: true);
    tickets += mission.reward;
    message = SpinMessage.missionDone;
    notifyListeners();
    return true;
  }

  /// Records the trivia answer, granting a ticket only when [correct] is true.
  bool answerTrivia(bool correct) {
    final index = missions.indexWhere((m) => m.isTrivia);
    if (index == -1 || missions[index].done) return false;

    final mission = missions[index];
    missions[index] = mission.copyWith(done: true);
    triviaOpen = false;

    if (correct) {
      tickets += mission.reward;
      message = SpinMessage.triviaRight;
    } else {
      message = SpinMessage.triviaWrong;
    }
    notifyListeners();
    return correct;
  }

  /// Collects all coins in the tray or shows a hint when already empty.
  void collectCoins() {
    if (coins.isEmpty) {
      message = SpinMessage.trayHint;
      notifyListeners();
      return;
    }
    coins = [];
    message = SpinMessage.coinsCollected;
    notifyListeners();
  }

  /// Grants five demo tickets for testing.
  void addDemoTickets() {
    tickets += 5;
    message = SpinMessage.demoReloaded;
    notifyListeners();
  }

  /// Shows the out-of-tickets nudge when trying to pull with zero tickets.
  void showNoTicketsHint() {
    if (tickets > 0 || phase != SpinPhase.idle) return;
    message = SpinMessage.noTickets;
    notifyListeners();
  }

  /// Generates an 8-character uppercase hex ticket serial.
  String generateTicketSerial() {
    final high = _random.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
    final low = _random.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
    return '$high$low'.toUpperCase();
  }

  SpinOutcome? _decidePrizeOutcome() {
    final remainingSpins = max(1, _estimatedEventSpins - done);
    final entries = <(SpinPrize, double)>[];
    var totalProbability = 0.0;

    for (final prize in prizes) {
      if (prize.remainingStock <= 0) continue;
      final probability = prize.remainingStock / remainingSpins;
      entries.add((prize, probability));
      totalProbability += probability;
    }

    if (totalProbability <= 0) return null;

    final scale = totalProbability > 1.0 ? 1.0 / totalProbability : 1.0;
    final roll = _random.nextDouble();
    var cumulative = 0.0;

    for (final (prize, probability) in entries) {
      cumulative += probability * scale;
      if (roll < cumulative) {
        return SpinPrizeOutcome(prize);
      }
    }
    return null;
  }

  List<SpinSymbol> _buildCombo(SpinOutcome? outcome) {
    switch (outcome) {
      case SpinBonusOutcome():
        return [
          SpinSymbol.mysteryBox,
          SpinSymbol.mysteryBox,
          SpinSymbol.mysteryBox,
        ];
      case SpinPrizeOutcome(:final prize):
        final symbol = prize.symbol;
        final combo = [symbol, symbol, symbol];
        if (SpinCombo.wildable.contains(symbol) &&
            _random.nextDouble() < _wildReplacementChance) {
          combo[_random.nextInt(3)] = SpinSymbol.wild;
        }
        return combo;
      case null:
        for (var attempt = 0; attempt < 100; attempt++) {
          final candidate = [
            fillSymbols[_random.nextInt(fillSymbols.length)],
            fillSymbols[_random.nextInt(fillSymbols.length)],
            fillSymbols[_random.nextInt(fillSymbols.length)],
          ];
          if (!SpinCombo.looksLikeWin(candidate)) {
            return candidate;
          }
        }
        return [SpinSymbol.lemon, SpinSymbol.cherries, SpinSymbol.bar];
    }
  }

  void _addCoins(int count) {
    final aged = coins.map((c) => c.copyWith(isNew: false)).toList();
    final added = List<CoinDrop>.generate(
      count,
      (index) => CoinDrop(
        leftFraction: 0.08 + _random.nextDouble() * 0.84,
        bottom: 2 + _random.nextDouble() * 16,
        rotation: _random.nextDouble() * 50 - 25,
        delayMs: index * 45,
        isNew: true,
      ),
    );
    final combined = [...aged, ...added];
    if (combined.length > _maxCoinsInTray) {
      coins = combined.sublist(combined.length - _maxCoinsInTray);
    } else {
      coins = combined;
    }
  }

  int _coinsForRarity(PrizeRarity rarity) => switch (rarity) {
    PrizeRarity.common => 6,
    PrizeRarity.rare => 10,
    PrizeRarity.epic => 16,
    PrizeRarity.legendary => 26,
  };

  String _generatePrizeCode() {
    final hex = _random
        .nextInt(0x10000)
        .toRadixString(16)
        .padLeft(4, '0')
        .toUpperCase();
    return 'GDG-$hex';
  }
}
