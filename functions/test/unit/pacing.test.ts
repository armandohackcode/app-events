import { describe, expect, it } from 'vitest';
import {
  FILL_SYMBOLS,
  WILDABLE_SYMBOLS,
  WINNING_PRIZE_SYMBOLS,
  buildBonusCombo,
  buildLoseCombo,
  buildWinCombo,
  canStillWin,
  looksLikeWin,
} from '../../src/domain/combo';
import {
  computeAvailableForWin,
  computeEffectiveRemainingSpins,
  computePrizeProbabilities,
  decideSpinCandidate,
  effectiveEstimatedTotalSpins,
  hasReachedPrizeCap,
  isPrizeEligibleForPlayer,
  nodeCryptoRng,
  type CryptoRng,
} from '../../src/domain/pacing';
import type { SpinConfig, SpinPlayer, SpinPrize } from '../../src/domain/types';

function makeConfig(overrides: Partial<SpinConfig> = {}): SpinConfig {
  const morningStart = Date.parse('2026-11-28T09:00:00-04:00');
  const afternoonStart = Date.parse('2026-11-28T13:30:00-04:00');
  const closingStart = Date.parse('2026-11-28T16:30:00-04:00');
  const eventEnd = Date.parse('2026-11-28T17:30:00-04:00');

  return {
    status: 'active',
    pauseMessage: 'Paused',
    ticketCostPerSpin: 1,
    defaultInitialTickets: 2,
    packageTicketBonus: { Standard: 1, VIP: 3 },
    matchRegistrationByEmail: true,
    registeredAttendeesCount: 250,
    expectedSpinsPerAttendee: 4,
    estimatedTotalSpinsOverride: null,
    pacingMode: 'time_paced',
    pacingStartAtMs: morningStart,
    pacingEndAtMs: eventEnd,
    pacingCurveGamma: 1.0,
    pacingWaves: [
      {
        id: 'morning',
        label: 'Morning',
        startAtMs: morningStart,
        releaseRatio: 0.35,
        spinBudgetShare: 0.35,
      },
      {
        id: 'afternoon',
        label: 'Afternoon',
        startAtMs: afternoonStart,
        releaseRatio: 0.8,
        spinBudgetShare: 0.45,
      },
      {
        id: 'closing',
        label: 'Closing',
        startAtMs: closingStart,
        releaseRatio: 1.0,
        spinBudgetShare: 0.2,
      },
    ],
    rushMode: false,
    rushBypassUnlockAt: true,
    payoutMultiplier: 1.0,
    maxWinProbabilityPerSpin: 0.45,
    rushMaxWinProbabilityPerSpin: 0.85,
    maxPrizesPerUser: 3,
    allowPlayAfterCap: false,
    maxWinsByRarity: { common: 2, rare: 1, epic: 1, legendary: 1 },
    minSpinsBetweenWins: 1,
    bonusProbability: 0.06,
    bonusMinTickets: 1,
    bonusMaxTickets: 3,
    maxBonusWinsPerUser: 2,
    wildReplacementChance: 0.35,
    spinCooldownMs: 2500,
    maxTotalEarnedTicketsPerUser: 15,
    maxManualGrantPerAction: 5,
    maxManualTicketsPerUser: 10,
    updatedAtMs: null,
    updatedBy: 'admin',
    ...overrides,
  };
}

function makePlayer(overrides: Partial<SpinPlayer> = {}): SpinPlayer {
  return {
    uid: 'user-1',
    displayName: 'Ana',
    email: 'ana@example.com',
    tickets: 5,
    spinsCount: 0,
    totalTicketsEarned: 5,
    totalTicketsSpent: 0,
    manualTicketsGranted: 0,
    bonusWinsCount: 0,
    totalPrizesWon: 0,
    winsByRarity: { common: 0, rare: 0, epic: 0, legendary: 0 },
    winsByPrize: {},
    initialTicketsGranted: true,
    packageBonusGranted: false,
    matchedPackage: null,
    lastSpinAtMs: null,
    lastWinSpinNumber: null,
    createdAtMs: null,
    updatedAtMs: null,
    ...overrides,
  };
}

function makePrize(overrides: Partial<SpinPrize> = {}): SpinPrize {
  return {
    id: 'stickers',
    name: 'Stickers',
    description: '',
    symbol: 'cherries',
    imageUrl: null,
    rarity: 'common',
    initialStock: 30,
    remainingStock: 30,
    awardedCount: 0,
    redeemedCount: 0,
    releasedStock: 30,
    maxPerUser: 2,
    weight: 1.0,
    unlockAtMs: null,
    active: true,
    order: 0,
    updatedAtMs: null,
    ...overrides,
  };
}

function makeFixedRng(floats: number[], ints: number[] = []): CryptoRng {
  let fi = 0;
  let ii = 0;
  return {
    nextFloat() {
      const value = floats[fi % floats.length];
      fi += 1;
      return value;
    },
    nextInt(min: number, maxExclusive: number) {
      if (ints.length === 0) return min;
      const raw = ints[ii % ints.length];
      ii += 1;
      return min + (raw % (maxExclusive - min));
    },
  };
}

describe('pacing engine & combo domain', () => {
  it('computes effectiveEstimatedTotalSpins with override and fallback', () => {
    const config = makeConfig({
      registeredAttendeesCount: 250,
      expectedSpinsPerAttendee: 4,
      estimatedTotalSpinsOverride: null,
    });
    expect(effectiveEstimatedTotalSpins(config)).toBe(1000);

    const overridden = makeConfig({ estimatedTotalSpinsOverride: 450 });
    expect(effectiveEstimatedTotalSpins(overridden)).toBe(450);

    const zeroAttendees = makeConfig({ registeredAttendeesCount: 0 });
    expect(effectiveEstimatedTotalSpins(zeroAttendees)).toBe(1);
  });

  it('enforces time_paced wave caps and prevents premature depletion', () => {
    const config = makeConfig();
    const stickers = makePrize({ initialStock: 30, remainingStock: 30 });
    const preOpen = Date.parse('2026-11-28T08:45:00-04:00');
    const morningMid = Date.parse('2026-11-28T10:30:00-04:00');
    const afternoonMid = Date.parse('2026-11-28T14:00:00-04:00');
    const closingMid = Date.parse('2026-11-28T17:00:00-04:00');

    expect(computeAvailableForWin(stickers, config, preOpen)).toBe(0);
    // Morning wave is 35%: floor(30 * 0.35) = 10
    expect(computeAvailableForWin(stickers, config, morningMid)).toBe(10);

    const stickersAfter6 = makePrize({
      initialStock: 30,
      remainingStock: 24,
      awardedCount: 6,
    });
    expect(computeAvailableForWin(stickersAfter6, config, morningMid)).toBe(4);

    const stickersAfter10 = makePrize({
      initialStock: 30,
      remainingStock: 20,
      awardedCount: 10,
    });
    expect(computeAvailableForWin(stickersAfter10, config, morningMid)).toBe(0);
    // Afternoon wave 80%: floor(30 * 0.80) = 24 -> 24 - 10 = 14
    expect(computeAvailableForWin(stickersAfter10, config, afternoonMid)).toBe(
      14,
    );
    // Closing wave 100%: 30 - 10 = 20
    expect(computeAvailableForWin(stickersAfter10, config, closingMid)).toBe(
      20,
    );
  });

  it('enforces S0 === 1 lock until releaseRatio >= 0.5 and unlockAt', () => {
    const config = makeConfig();
    const androidUnlock = Date.parse('2026-11-28T15:00:00-04:00');
    const android = makePrize({
      id: 'android',
      symbol: 'seven',
      rarity: 'legendary',
      initialStock: 1,
      remainingStock: 1,
      unlockAtMs: androidUnlock,
    });

    const morningMid = Date.parse('2026-11-28T10:30:00-04:00'); // ratio 0.35
    const afternoonBeforeUnlock = Date.parse('2026-11-28T14:00:00-04:00'); // ratio 0.80, < 15:00
    const afternoonAfterUnlock = Date.parse('2026-11-28T15:15:00-04:00'); // ratio 0.80, >= 15:00

    expect(computeAvailableForWin(android, config, morningMid)).toBe(0);
    expect(computeAvailableForWin(android, config, afternoonBeforeUnlock)).toBe(
      0,
    );
    expect(computeAvailableForWin(android, config, afternoonAfterUnlock)).toBe(
      1,
    );

    // Even with unlockAt: null, unique prize stays locked in morning (ratio 0.35 < 0.5)
    const uniqueNoUnlock = makePrize({
      id: 'unique',
      initialStock: 1,
      remainingStock: 1,
      unlockAtMs: null,
    });
    expect(computeAvailableForWin(uniqueNoUnlock, config, morningMid)).toBe(0);
    expect(
      computeAvailableForWin(uniqueNoUnlock, config, afternoonBeforeUnlock),
    ).toBe(1);
  });

  it('supports continuous time_paced curve (t^gamma) when pacingWaves is empty', () => {
    const start = 1_000_000;
    const end = 2_000_000;
    const midpoint = 1_500_000;
    const config = makeConfig({
      pacingWaves: [],
      pacingStartAtMs: start,
      pacingEndAtMs: end,
      pacingCurveGamma: 2.0,
    });

    // t = 0.5 -> releaseRatio = 0.5^2 = 0.25 -> floor(20 * 0.25) = 5
    const prize = makePrize({ initialStock: 20, remainingStock: 20 });
    expect(computeAvailableForWin(prize, config, start - 1)).toBe(0);
    expect(computeAvailableForWin(prize, config, midpoint)).toBe(5);
    expect(computeAvailableForWin(prize, config, end)).toBe(20);
  });

  it('supports manual_waves, dynamic_spins, and rushMode', () => {
    const morningMid = Date.parse('2026-11-28T10:30:00-04:00');
    const futureUnlock = Date.parse('2026-11-28T17:00:00-04:00');

    const manualConfig = makeConfig({ pacingMode: 'manual_waves' });
    const manualPrize = makePrize({
      initialStock: 10,
      remainingStock: 8,
      awardedCount: 2,
      releasedStock: 4,
    });
    expect(computeAvailableForWin(manualPrize, manualConfig, morningMid)).toBe(
      2,
    );

    const dynamicConfig = makeConfig({ pacingMode: 'dynamic_spins' });
    expect(computeAvailableForWin(manualPrize, dynamicConfig, morningMid)).toBe(
      8,
    );

    const rushConfig = makeConfig({
      rushMode: true,
      rushBypassUnlockAt: true,
    });
    const lockedUnique = makePrize({
      id: 'android',
      initialStock: 1,
      remainingStock: 1,
      unlockAtMs: futureUnlock,
    });
    expect(computeAvailableForWin(lockedUnique, rushConfig, morningMid)).toBe(1);

    const rushRespectUnlock = makeConfig({
      rushMode: true,
      rushBypassUnlockAt: false,
    });
    expect(
      computeAvailableForWin(lockedUnique, rushRespectUnlock, morningMid),
    ).toBe(0);
  });

  it('computes effective remaining spins and caps normalized probabilities', () => {
    const morningMid = Date.parse('2026-11-28T10:30:00-04:00');
    const config = makeConfig({
      estimatedTotalSpinsOverride: 100,
      maxWinProbabilityPerSpin: 0.45,
      rushMaxWinProbabilityPerSpin: 0.85,
      payoutMultiplier: 2.0,
    });

    // Morning cumBudget = 0.35 => ceil(100 * 0.35) = 35; done = 20 => R = 15
    expect(computeEffectiveRemainingSpins(config, 20, morningMid)).toBe(15);

    const prizes = [
      makePrize({ id: 'p1', initialStock: 30, remainingStock: 30 }),
      makePrize({ id: 'p2', initialStock: 20, remainingStock: 20 }),
    ];
    const normalProbs = computePrizeProbabilities(prizes, config, 20, morningMid);
    const normalSum = normalProbs.reduce((acc, e) => acc + e.probability, 0);
    expect(normalSum).toBeCloseTo(0.45, 6);

    const rushConfig = makeConfig({
      ...config,
      rushMode: true,
      payoutMultiplier: 5.0,
    });
    const rushProbs = computePrizeProbabilities(
      prizes,
      rushConfig,
      20,
      morningMid,
    );
    const rushSum = rushProbs.reduce((acc, e) => acc + e.probability, 0);
    expect(rushSum).toBeCloseTo(0.85, 6);
  });

  it('enforces all 6 anti-hoarding user eligibility filters', () => {
    const now = Date.parse('2026-11-28T14:00:00-04:00');
    const config = makeConfig();
    const basePrize = makePrize({
      id: 'mug',
      rarity: 'rare',
      initialStock: 5,
      remainingStock: 5,
      maxPerUser: 1,
    });

    // Inactive prize
    expect(
      isPrizeEligibleForPlayer(
        { ...basePrize, active: false },
        makePlayer(),
        config,
        now,
      ),
    ).toBe(false);

    // Out of stock
    expect(
      isPrizeEligibleForPlayer(
        { ...basePrize, remainingStock: 0 },
        makePlayer(),
        config,
        now,
      ),
    ).toBe(false);

    // Global prize cap
    const cappedPlayer = makePlayer({ totalPrizesWon: 3 });
    expect(hasReachedPrizeCap(cappedPlayer, config)).toBe(true);
    expect(
      isPrizeEligibleForPlayer(basePrize, cappedPlayer, config, now),
    ).toBe(false);

    // Rarity cap
    const rareCapped = makePlayer({
      totalPrizesWon: 1,
      winsByRarity: { common: 0, rare: 1, epic: 0, legendary: 0 },
    });
    expect(isPrizeEligibleForPlayer(basePrize, rareCapped, config, now)).toBe(
      false,
    );

    // Per-prize cap
    const samePrizeCapped = makePlayer({
      winsByPrize: { mug: 1 },
    });
    expect(
      isPrizeEligibleForPlayer(
        basePrize,
        samePrizeCapped,
        makeConfig({ maxWinsByRarity: { common: 5, rare: 5, epic: 5, legendary: 5 } }),
        now,
      ),
    ).toBe(false);

    // minSpinsBetweenWins: won on spin 2, current spinsCount is 2 -> blocked until spinsCount >= 3
    const streakPlayer = makePlayer({ spinsCount: 2, lastWinSpinNumber: 2 });
    expect(isPrizeEligibleForPlayer(basePrize, streakPlayer, config, now)).toBe(
      false,
    );
    expect(
      isPrizeEligibleForPlayer(
        basePrize,
        makePlayer({ spinsCount: 3, lastWinSpinNumber: 2 }),
        config,
        now,
      ),
    ).toBe(true);
  });

  it('decides bonus first and respects bonus + global ticket caps', () => {
    const now = Date.parse('2026-11-28T14:00:00-04:00');
    const config = makeConfig({
      bonusProbability: 0.5,
      bonusMinTickets: 2,
      bonusMaxTickets: 3,
      maxBonusWinsPerUser: 1,
      maxTotalEarnedTicketsPerUser: 10,
    });

    // Player at 9 earned tickets -> rolled bonus clamped to 1
    const result = decideSpinCandidate(
      {
        prizes: [makePrize()],
        player: makePlayer({ totalTicketsEarned: 9, bonusWinsCount: 0 }),
        config,
        totalSpinsDone: 0,
        nowMs: now,
      },
      makeFixedRng([0.1], [1]),
    );
    expect(result.outcomeType).toBe('bonus');
    if (result.outcomeType === 'bonus') {
      expect(result.bonusTickets).toBe(1);
      expect(result.combo).toEqual(['mysteryBox', 'mysteryBox', 'mysteryBox']);
    }

    // Player already reached maxBonusWinsPerUser -> cannot win bonus
    const noBonus = decideSpinCandidate(
      {
        prizes: [],
        player: makePlayer({ bonusWinsCount: 1 }),
        config,
        totalSpinsDone: 0,
        nowMs: now,
      },
      makeFixedRng([0.1], [0]),
    );
    expect(noBonus.outcomeType).toBe('lose');
  });

  it('treats 0 as "no limit" for rarity and mystery-box caps, like every other per-user cap', () => {
    const now = Date.parse('2026-11-28T14:00:00-04:00');
    const legendary = makePrize({ id: 'android', rarity: 'legendary', maxPerUser: 0 });
    const player = makePlayer({
      totalPrizesWon: 2,
      winsByRarity: { common: 0, rare: 0, epic: 0, legendary: 2 },
      winsByPrize: { android: 2 },
      spinsCount: 10,
      lastWinSpinNumber: 2,
    });

    const unlimited = makeConfig({
      maxPrizesPerUser: 0,
      maxWinsByRarity: { common: 0, rare: 0, epic: 0, legendary: 0 },
    });
    expect(isPrizeEligibleForPlayer(legendary, player, unlimited, now)).toBe(true);

    const capped = makeConfig({
      maxPrizesPerUser: 0,
      maxWinsByRarity: { common: 0, rare: 0, epic: 0, legendary: 2 },
    });
    expect(isPrizeEligibleForPlayer(legendary, player, capped, now)).toBe(false);

    const bonusConfig = makeConfig({
      bonusProbability: 0.5,
      bonusMinTickets: 1,
      bonusMaxTickets: 1,
      maxBonusWinsPerUser: 0,
      maxTotalEarnedTicketsPerUser: 0,
    });
    const bonus = decideSpinCandidate(
      {
        prizes: [],
        player: makePlayer({ bonusWinsCount: 7 }),
        config: bonusConfig,
        totalSpinsDone: 0,
        nowMs: now,
      },
      makeFixedRng([0.1], [1]),
    );
    expect(bonus.outcomeType).toBe('bonus');
  });

  it('mirrors SpinCombo rules and generates valid win/bonus/lose combos', () => {
    expect(WILDABLE_SYMBOLS.has('seven')).toBe(false);
    expect(WILDABLE_SYMBOLS.has('lemon')).toBe(false);
    expect(WILDABLE_SYMBOLS.has('mysteryBox')).toBe(false);
    expect(WINNING_PRIZE_SYMBOLS.has('seven')).toBe(true);
    expect(FILL_SYMBOLS).toHaveLength(12);

    // looksLikeWin
    expect(looksLikeWin(['seven', 'seven', 'seven'])).toBe(true);
    expect(looksLikeWin(['lemon', 'lemon', 'lemon'])).toBe(true);
    expect(looksLikeWin(['cherries', 'wild', 'cherries'])).toBe(true);
    expect(looksLikeWin(['seven', 'wild', 'seven'])).toBe(false);
    expect(looksLikeWin(['lemon', 'wild', 'lemon'])).toBe(false);
    expect(looksLikeWin(['wild', 'wild', 'lemon'])).toBe(true);

    // canStillWin
    expect(canStillWin('lemon', 'lemon')).toBe(false);
    expect(canStillWin('seven', 'seven')).toBe(true);
    expect(canStillWin('wild', 'star')).toBe(true);
    expect(canStillWin('wild', 'seven')).toBe(false);
    expect(canStillWin('wild', 'wild')).toBe(true);

    // Seven never gets replaced by wild even with wildReplacementChance = 1
    const sevenWin = buildWinCombo('seven', 1.0, makeFixedRng([0.0], [1]));
    expect(sevenWin).toEqual(['seven', 'seven', 'seven']);

    // Wildable symbol gets wild substitution when roll < chance
    const starWin = buildWinCombo('star', 1.0, makeFixedRng([0.0], [1]));
    expect(starWin).toEqual(['star', 'wild', 'star']);
    expect(looksLikeWin(starWin)).toBe(true);

    expect(buildBonusCombo()).toEqual([
      'mysteryBox',
      'mysteryBox',
      'mysteryBox',
    ]);

    // 1000 losing combos generated via CSPRNG never look like wins
    for (let i = 0; i < 1000; i += 1) {
      const loseCombo = buildLoseCombo(nodeCryptoRng);
      expect(loseCombo).toHaveLength(3);
      expect(looksLikeWin(loseCombo)).toBe(false);
    }
  });
});
