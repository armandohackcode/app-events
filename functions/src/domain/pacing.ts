import { randomBytes, randomInt } from 'node:crypto';
import {
  buildBonusCombo,
  buildLoseCombo,
  buildWinCombo,
  type ComboRng,
} from './combo';
import type {
  EpochMs,
  SpinConfig,
  SpinOutcomeType,
  SpinPlayer,
  SpinPrize,
  SpinSymbol,
} from './types';

export interface CryptoRng extends ComboRng {
  nextFloat(): number;
  nextInt(min: number, maxExclusive: number): number;
}

const UINT48_RANGE = 0x1_0000_0000_0000;

/** Default CSPRNG backed by Node `node:crypto` (never `Math.random`). */
export const nodeCryptoRng: CryptoRng = {
  nextFloat(): number {
    return randomBytes(6).readUIntBE(0, 6) / UINT48_RANGE;
  },
  nextInt(min: number, maxExclusive: number): number {
    return randomInt(min, maxExclusive);
  },
};

export interface PrizeProbabilityEntry {
  prize: SpinPrize;
  availableForWin: number;
  rawProbability: number;
  probability: number;
}

export type SpinDecisionResult =
  | {
      outcomeType: 'bonus';
      bonusTickets: number;
      combo: [SpinSymbol, SpinSymbol, SpinSymbol];
    }
  | {
      outcomeType: 'prize';
      prize: SpinPrize;
      combo: [SpinSymbol, SpinSymbol, SpinSymbol];
    }
  | {
      outcomeType: 'lose';
      combo: [SpinSymbol, SpinSymbol, SpinSymbol];
    };

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

/**
 * Effective total estimated spins across the event.
 */
export function effectiveEstimatedTotalSpins(config: SpinConfig): number {
  if (config.estimatedTotalSpinsOverride !== null) {
    return Math.max(1, config.estimatedTotalSpinsOverride);
  }
  return Math.max(
    1,
    Math.round(config.registeredAttendeesCount * config.expectedSpinsPerAttendee),
  );
}

/**
 * Returns true when the player has reached the global per-user prize cap.
 */
export function hasReachedPrizeCap(
  player: SpinPlayer,
  config: SpinConfig,
): boolean {
  return (
    config.maxPrizesPerUser > 0 &&
    player.totalPrizesWon >= config.maxPrizesPerUser
  );
}

/**
 * Evaluates all 6 anti-hoarding eligibility rules (Section 4.2) for a prize.
 */
export function isPrizeEligibleForPlayer(
  prize: SpinPrize,
  player: SpinPlayer,
  config: SpinConfig,
  nowMs: EpochMs,
): boolean {
  if (!prize.active || prize.remainingStock <= 0) {
    return false;
  }

  if (
    prize.unlockAtMs !== null &&
    nowMs < prize.unlockAtMs &&
    !(config.rushMode && config.rushBypassUnlockAt)
  ) {
    return false;
  }

  if (hasReachedPrizeCap(player, config)) {
    return false;
  }

  // 0 means "no limit", like every other per-user cap in SpinConfig.
  const maxForRarity = config.maxWinsByRarity[prize.rarity];
  if (
    typeof maxForRarity === 'number' &&
    maxForRarity > 0 &&
    (player.winsByRarity[prize.rarity] ?? 0) >= maxForRarity
  ) {
    return false;
  }

  if (
    prize.maxPerUser > 0 &&
    (player.winsByPrize[prize.id] ?? 0) >= prize.maxPerUser
  ) {
    return false;
  }

  if (
    config.minSpinsBetweenWins > 0 &&
    player.lastWinSpinNumber !== null &&
    player.spinsCount - player.lastWinSpinNumber < config.minSpinsBetweenWins
  ) {
    return false;
  }

  return true;
}

interface ReleaseWindowState {
  releaseRatio: number;
  cumBudget: number;
}

function computeTimePacedReleaseState(
  config: SpinConfig,
  nowMs: EpochMs,
): ReleaseWindowState {
  if (config.pacingWaves.length > 0) {
    const sortedWaves = [...config.pacingWaves].sort(
      (a, b) => a.startAtMs - b.startAtMs,
    );
    let activeIndex = -1;
    for (let i = 0; i < sortedWaves.length; i += 1) {
      if (sortedWaves[i].startAtMs <= nowMs) {
        activeIndex = i;
      }
    }
    if (activeIndex === -1) {
      return { releaseRatio: 0, cumBudget: 0 };
    }
    let cumBudget = 0;
    for (let i = 0; i <= activeIndex; i += 1) {
      cumBudget += Math.max(0, sortedWaves[i].spinBudgetShare);
    }
    return {
      releaseRatio: clamp(sortedWaves[activeIndex].releaseRatio, 0, 1),
      cumBudget: clamp(cumBudget, 0, 1),
    };
  }

  const start = config.pacingStartAtMs;
  const end = config.pacingEndAtMs;
  let t: number;
  if (start === null && end === null) {
    t = 1;
  } else if (start !== null && end === null) {
    t = nowMs >= start ? 1 : 0;
  } else if (start === null && end !== null) {
    t = nowMs >= end ? 1 : 0;
  } else if (start !== null && end !== null) {
    if (end <= start) {
      t = nowMs >= end ? 1 : 0;
    } else {
      t = clamp((nowMs - start) / (end - start), 0, 1);
    }
  } else {
    t = 1;
  }

  const gamma = config.pacingCurveGamma > 0 ? config.pacingCurveGamma : 1.0;
  const releaseRatio = clamp(Math.pow(t, gamma), 0, 1);
  return { releaseRatio, cumBudget: releaseRatio };
}

/**
 * Computes currently released stock eligible to be won for a prize (Section 4.3 Step 1),
 * enforcing `unlockAt` and the unique-prize rule (`initialStock === 1` requires
 * `releaseRatio >= 0.5` in `time_paced` unless `rushMode` is active).
 */
export function computeAvailableForWin(
  prize: SpinPrize,
  config: SpinConfig,
  nowMs: EpochMs,
): number {
  const remaining = Math.max(0, prize.remainingStock);
  if (!prize.active || remaining <= 0) {
    return 0;
  }

  if (
    prize.unlockAtMs !== null &&
    nowMs < prize.unlockAtMs &&
    !(config.rushMode && config.rushBypassUnlockAt)
  ) {
    return 0;
  }

  if (config.rushMode) {
    return remaining;
  }

  if (config.pacingMode === 'manual_waves') {
    return Math.max(
      0,
      Math.min(remaining, prize.releasedStock - prize.awardedCount),
    );
  }

  if (config.pacingMode === 'dynamic_spins') {
    return remaining;
  }

  // Default: time_paced
  const { releaseRatio } = computeTimePacedReleaseState(config, nowMs);
  let allowed: number;
  if (prize.initialStock === 1) {
    allowed = releaseRatio >= 0.5 ? 1 : 0;
  } else {
    allowed = Math.floor(prize.initialStock * releaseRatio);
  }

  return Math.max(0, Math.min(remaining, allowed - prize.awardedCount));
}

/**
 * Computes effective remaining spins R for probability pacing (Section 4.3 Step 2).
 */
export function computeEffectiveRemainingSpins(
  config: SpinConfig,
  totalSpinsDone: number,
  nowMs: EpochMs,
): number {
  const estimated = effectiveEstimatedTotalSpins(config);
  const done = Math.max(0, totalSpinsDone);

  if (
    config.rushMode ||
    config.pacingMode === 'dynamic_spins' ||
    config.pacingMode === 'manual_waves'
  ) {
    return Math.max(1, estimated - done);
  }

  const { releaseRatio, cumBudget } = computeTimePacedReleaseState(
    config,
    nowMs,
  );
  if (config.pacingWaves.length > 0) {
    return Math.max(1, Math.ceil(estimated * cumBudget) - done);
  }
  return Math.max(1, Math.ceil(estimated * Math.max(0.15, releaseRatio)) - done);
}

/**
 * Computes capped normalized per-spin probabilities for eligible prizes.
 */
export function computePrizeProbabilities(
  eligiblePrizes: readonly SpinPrize[],
  config: SpinConfig,
  totalSpinsDone: number,
  nowMs: EpochMs,
): PrizeProbabilityEntry[] {
  const remainingSpins = computeEffectiveRemainingSpins(
    config,
    totalSpinsDone,
    nowMs,
  );

  const rawEntries: Array<{
    prize: SpinPrize;
    availableForWin: number;
    rawProbability: number;
  }> = [];
  let totalRaw = 0;

  for (const prize of eligiblePrizes) {
    const availableForWin = computeAvailableForWin(prize, config, nowMs);
    if (availableForWin <= 0 || prize.weight <= 0 || config.payoutMultiplier <= 0) {
      continue;
    }
    const rawProbability =
      (availableForWin / remainingSpins) * prize.weight * config.payoutMultiplier;
    if (rawProbability <= 0) continue;
    rawEntries.push({ prize, availableForWin, rawProbability });
    totalRaw += rawProbability;
  }

  if (totalRaw <= 0) {
    return [];
  }

  const cap = config.rushMode
    ? config.rushMaxWinProbabilityPerSpin
    : config.maxWinProbabilityPerSpin;
  const safeCap = clamp(cap, 0, 1);
  const scale = totalRaw > safeCap ? safeCap / totalRaw : 1.0;

  return rawEntries.map((entry) => ({
    prize: entry.prize,
    availableForWin: entry.availableForWin,
    rawProbability: entry.rawProbability,
    probability: entry.rawProbability * scale,
  }));
}

export interface DecideSpinCandidateParams {
  prizes: readonly SpinPrize[];
  player: SpinPlayer;
  config: SpinConfig;
  totalSpinsDone: number;
  nowMs: EpochMs;
}

/**
 * Rolls bonus first (respecting user caps), then eligible prizes, otherwise lose.
 */
export function decideSpinCandidate(
  params: DecideSpinCandidateParams,
  rng: CryptoRng = nodeCryptoRng,
): SpinDecisionResult {
  const { prizes, player, config, totalSpinsDone, nowMs } = params;

  const canEarnMoreTickets =
    config.maxTotalEarnedTicketsPerUser === 0 ||
    player.totalTicketsEarned < config.maxTotalEarnedTicketsPerUser;
  // maxBonusWinsPerUser 0 means "no limit"; set bonusProbability 0 to disable boxes.
  const bonusEligible =
    config.bonusProbability > 0 &&
    (config.maxBonusWinsPerUser === 0 ||
      player.bonusWinsCount < config.maxBonusWinsPerUser) &&
    canEarnMoreTickets;

  if (bonusEligible && rng.nextFloat() < config.bonusProbability) {
    const minTickets = Math.max(1, config.bonusMinTickets);
    const maxTickets = Math.max(minTickets, config.bonusMaxTickets);
    const rolledBonus = rng.nextInt(minTickets, maxTickets + 1);
    const cappedBonus =
      config.maxTotalEarnedTicketsPerUser === 0
        ? rolledBonus
        : Math.min(
            rolledBonus,
            Math.max(0, config.maxTotalEarnedTicketsPerUser - player.totalTicketsEarned),
          );

    if (cappedBonus >= 1) {
      return {
        outcomeType: 'bonus',
        bonusTickets: cappedBonus,
        combo: buildBonusCombo(),
      };
    }
  }

  const eligiblePrizes = prizes.filter((prize) =>
    isPrizeEligibleForPlayer(prize, player, config, nowMs),
  );
  const probabilities = computePrizeProbabilities(
    eligiblePrizes,
    config,
    totalSpinsDone,
    nowMs,
  );

  if (probabilities.length > 0) {
    const roll = rng.nextFloat();
    let cumulative = 0;
    for (const entry of probabilities) {
      cumulative += entry.probability;
      if (roll < cumulative) {
        return {
          outcomeType: 'prize',
          prize: entry.prize,
          combo: buildWinCombo(
            entry.prize.symbol,
            config.wildReplacementChance,
            rng,
          ),
        };
      }
    }
  }

  return {
    outcomeType: 'lose',
    combo: buildLoseCombo(rng),
  };
}

/**
 * Single fallback re-roll excluding prizes known to be depleted inside the ACID transaction.
 */
export function rerollRemainingPrize(
  params: DecideSpinCandidateParams & { excludedPrizeIds: ReadonlySet<string> },
  rng: CryptoRng = nodeCryptoRng,
): { prize: SpinPrize; combo: [SpinSymbol, SpinSymbol, SpinSymbol] } | null {
  const { prizes, player, config, totalSpinsDone, nowMs, excludedPrizeIds } =
    params;
  const remainingEligible = prizes.filter(
    (prize) =>
      !excludedPrizeIds.has(prize.id) &&
      isPrizeEligibleForPlayer(prize, player, config, nowMs),
  );
  const probabilities = computePrizeProbabilities(
    remainingEligible,
    config,
    totalSpinsDone,
    nowMs,
  );

  if (probabilities.length === 0) {
    return null;
  }

  const roll = rng.nextFloat();
  let cumulative = 0;
  for (const entry of probabilities) {
    cumulative += entry.probability;
    if (roll < cumulative) {
      return {
        prize: entry.prize,
        combo: buildWinCombo(
          entry.prize.symbol,
          config.wildReplacementChance,
          rng,
        ),
      };
    }
  }

  return null;
}

export function serializeOutcomeType(
  decision: SpinDecisionResult,
): SpinOutcomeType {
  return decision.outcomeType;
}
