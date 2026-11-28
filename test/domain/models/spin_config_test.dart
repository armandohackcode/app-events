import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinGameStatus', () {
    test('fromValue maps known values and defaults to paused', () {
      expect(SpinGameStatus.fromValue('paused'), SpinGameStatus.paused);
      expect(SpinGameStatus.fromValue('active'), SpinGameStatus.active);
      expect(SpinGameStatus.fromValue('closed'), SpinGameStatus.closed);
      expect(SpinGameStatus.fromValue(null), SpinGameStatus.paused);
      expect(SpinGameStatus.fromValue('invalid'), SpinGameStatus.paused);
    });
  });

  group('SpinPacingMode', () {
    test('fromValue maps known values and defaults to timePaced', () {
      expect(SpinPacingMode.fromValue('time_paced'), SpinPacingMode.timePaced);
      expect(
        SpinPacingMode.fromValue('dynamic_spins'),
        SpinPacingMode.dynamicSpins,
      );
      expect(
        SpinPacingMode.fromValue('manual_waves'),
        SpinPacingMode.manualWaves,
      );
      expect(SpinPacingMode.fromValue(null), SpinPacingMode.timePaced);
      expect(SpinPacingMode.fromValue('other'), SpinPacingMode.timePaced);
    });
  });

  group('SpinPacingWave', () {
    test('fromJson uses safe defaults and round-trips through toJson', () {
      final empty = SpinPacingWave.fromJson({});
      expect(empty.id, '');
      expect(empty.label, '');
      expect(empty.releaseRatio, 1.0);
      expect(empty.spinBudgetShare, 0.0);

      final wave = SpinPacingWave(
        id: 'morning',
        label: 'Morning',
        startAt: DateTime.utc(2026, 11, 28, 9),
        releaseRatio: 0.35,
        spinBudgetShare: 0.35,
      );
      final restored = SpinPacingWave.fromJson(wave.toJson());
      expect(restored.toJson(), wave.toJson());

      final copied = wave.copyWith(releaseRatio: 0.5);
      expect(copied.releaseRatio, 0.5);
      expect(copied.id, 'morning');
    });
  });

  group('SpinConfig', () {
    test('fromJson uses safe defaults for empty map', () {
      final config = SpinConfig.fromJson({});

      expect(config.status, SpinGameStatus.paused);
      expect(config.pauseMessage, '');
      expect(config.ticketCostPerSpin, 1);
      expect(config.defaultInitialTickets, 2);
      expect(config.packageTicketBonus, isEmpty);
      expect(config.matchRegistrationByEmail, isTrue);
      expect(config.registeredAttendeesCount, 0);
      expect(config.expectedSpinsPerAttendee, 4.0);
      expect(config.estimatedTotalSpinsOverride, isNull);
      expect(config.effectiveEstimatedTotalSpins, 1);
      expect(config.pacingMode, SpinPacingMode.timePaced);
      expect(config.pacingWaves, isEmpty);
      expect(config.rushMode, isFalse);
      expect(config.rushBypassUnlockAt, isTrue);
      expect(config.payoutMultiplier, 1.0);
      expect(config.maxWinProbabilityPerSpin, 0.45);
      expect(config.rushMaxWinProbabilityPerSpin, 0.85);
      expect(config.maxPrizesPerUser, 3);
      expect(config.allowPlayAfterCap, isFalse);
      expect(config.maxWinsByRarity[PrizeRarity.common], 2);
      expect(config.maxWinsByRarity[PrizeRarity.legendary], 1);
      expect(config.minSpinsBetweenWins, 1);
      expect(config.bonusProbability, 0.06);
      expect(config.bonusMinTickets, 1);
      expect(config.bonusMaxTickets, 3);
      expect(config.maxBonusWinsPerUser, 2);
      expect(config.wildReplacementChance, 0.35);
      expect(config.spinCooldownMs, 2500);
      expect(config.maxTotalEarnedTicketsPerUser, 15);
      expect(config.maxManualGrantPerAction, 5);
      expect(config.maxManualTicketsPerUser, 10);
    });

    test('effectiveEstimatedTotalSpins uses override or rounds product', () {
      const calculated = SpinConfig(
        registeredAttendeesCount: 250,
        expectedSpinsPerAttendee: 4.0,
      );
      expect(calculated.effectiveEstimatedTotalSpins, 1000);

      const overridden = SpinConfig(
        registeredAttendeesCount: 250,
        expectedSpinsPerAttendee: 4.0,
        estimatedTotalSpinsOverride: 600,
      );
      expect(overridden.effectiveEstimatedTotalSpins, 600);
    });

    test('round-trip toJson and fromJson preserves all fields', () {
      final original = SpinConfig(
        status: SpinGameStatus.active,
        pauseMessage: 'Paused for keynote',
        ticketCostPerSpin: 2,
        defaultInitialTickets: 3,
        packageTicketBonus: const {'Standard': 1, 'VIP': 3},
        matchRegistrationByEmail: false,
        registeredAttendeesCount: 200,
        expectedSpinsPerAttendee: 3.5,
        estimatedTotalSpinsOverride: 800,
        pacingMode: SpinPacingMode.manualWaves,
        pacingStartAt: DateTime.utc(2026, 11, 28, 9),
        pacingEndAt: DateTime.utc(2026, 11, 28, 17, 30),
        pacingCurveGamma: 1.2,
        pacingWaves: [
          SpinPacingWave(
            id: 'w1',
            label: 'Wave 1',
            startAt: DateTime.utc(2026, 11, 28, 9),
            releaseRatio: 0.4,
            spinBudgetShare: 0.5,
          ),
        ],
        rushMode: true,
        rushBypassUnlockAt: false,
        payoutMultiplier: 1.8,
        maxWinProbabilityPerSpin: 0.5,
        rushMaxWinProbabilityPerSpin: 0.9,
        maxPrizesPerUser: 4,
        allowPlayAfterCap: true,
        maxWinsByRarity: const {
          PrizeRarity.common: 3,
          PrizeRarity.rare: 2,
          PrizeRarity.epic: 1,
          PrizeRarity.legendary: 1,
        },
        minSpinsBetweenWins: 2,
        bonusProbability: 0.1,
        bonusMinTickets: 1,
        bonusMaxTickets: 4,
        maxBonusWinsPerUser: 3,
        wildReplacementChance: 0.25,
        spinCooldownMs: 3000,
        maxTotalEarnedTicketsPerUser: 20,
        maxManualGrantPerAction: 4,
        maxManualTicketsPerUser: 12,
        updatedAt: DateTime.utc(2026, 11, 28, 8),
        updatedBy: 'admin-1',
      );

      final json = original.toJson();
      final restored = SpinConfig.fromJson(json);

      expect(restored.toJson(), json);
    });

    test('copyWith clears nullable fields when flags are set', () {
      final original = SpinConfig(
        estimatedTotalSpinsOverride: 500,
        pacingStartAt: DateTime.utc(2026, 11, 28, 9),
        pacingEndAt: DateTime.utc(2026, 11, 28, 17),
        updatedAt: DateTime.utc(2026, 11, 28, 8),
      );

      final cleared = original.copyWith(
        clearEstimatedTotalSpinsOverride: true,
        clearPacingStartAt: true,
        clearPacingEndAt: true,
        clearUpdatedAt: true,
      );

      expect(cleared.estimatedTotalSpinsOverride, isNull);
      expect(cleared.pacingStartAt, isNull);
      expect(cleared.pacingEndAt, isNull);
      expect(cleared.updatedAt, isNull);
    });
  });
}
