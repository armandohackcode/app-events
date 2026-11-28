import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';
import type { z } from 'zod';
import type {
  EpochMs,
  IsoDateString,
  PrizeRarity,
  SpinConfig,
  SpinConfigDto,
  SpinErrorReason,
  SpinGameStatus,
  SpinMission,
  SpinMissionConfig,
  SpinMissionDto,
  SpinMissionType,
  SpinPacingMode,
  SpinPacingWave,
  SpinPlayer,
  SpinPlayerDto,
  SpinPrize,
  SpinPrizeDto,
  SpinStatsShard,
  SpinSymbol,
  SpinTicketCode,
  SpinTicketCodeDto,
  SpinWin,
  SpinWinDto,
  SpinWinStatus,
} from '../domain/types';

export function throwSpinError(
  code: FunctionsErrorCode,
  message: string,
  reason?: SpinErrorReason,
): never {
  throw new HttpsError(code, message, reason ? { reason } : undefined);
}

export function parseInput<TSchema extends z.ZodTypeAny>(
  schema: TSchema,
  raw: unknown,
): z.output<TSchema> {
  const parsed = schema.safeParse(raw);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    const path = issue?.path.length ? `${issue.path.join('.')}: ` : '';
    throw new HttpsError(
      'invalid-argument',
      `${path}${issue?.message ?? 'Invalid request input'}`,
    );
  }
  return parsed.data as z.output<TSchema>;
}

export function toEpochMs(value: unknown): EpochMs | null {
  if (value === null || value === undefined) return null;
  if (value instanceof Timestamp) return value.toMillis();
  if (value instanceof Date) return value.getTime();
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? null : parsed;
  }
  if (typeof value === 'object') {
    const maybeTs = value as {
      toMillis?: () => number;
      seconds?: number;
      _seconds?: number;
      nanoseconds?: number;
      _nanoseconds?: number;
    };
    if (typeof maybeTs.toMillis === 'function') {
      return maybeTs.toMillis();
    }
    const secs =
      typeof maybeTs.seconds === 'number'
        ? maybeTs.seconds
        : typeof maybeTs._seconds === 'number'
          ? maybeTs._seconds
          : null;
    if (secs !== null) {
      const nanos =
        typeof maybeTs.nanoseconds === 'number'
          ? maybeTs.nanoseconds
          : typeof maybeTs._nanoseconds === 'number'
            ? maybeTs._nanoseconds
            : 0;
      return secs * 1000 + Math.floor(nanos / 1_000_000);
    }
  }
  return null;
}

export function toIsoOrNull(ms: EpochMs | null): IsoDateString | null {
  return ms === null ? null : new Date(ms).toISOString();
}

export function toTimestampOrNull(ms: EpochMs | null): Timestamp | null {
  return ms === null ? null : Timestamp.fromMillis(ms);
}

function asString(value: unknown, fallback = ''): string {
  return typeof value === 'string' ? value : fallback;
}

function asNullableString(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

function asBool(value: unknown, fallback = false): boolean {
  return typeof value === 'boolean' ? value : fallback;
}

function asNumber(value: unknown, fallback = 0): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}

function asInt(value: unknown, fallback = 0): number {
  return typeof value === 'number' && Number.isFinite(value)
    ? Math.trunc(value)
    : fallback;
}

function asRecord(value: unknown): Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function parseGameStatus(value: unknown): SpinGameStatus {
  if (value === 'active' || value === 'closed' || value === 'paused') {
    return value;
  }
  return 'paused';
}

function parsePacingMode(value: unknown): SpinPacingMode {
  if (
    value === 'time_paced' ||
    value === 'dynamic_spins' ||
    value === 'manual_waves'
  ) {
    return value;
  }
  return 'time_paced';
}

function parseSymbol(value: unknown): SpinSymbol {
  switch (value) {
    case 'seven':
    case 'bar':
    case 'cherries':
    case 'bell':
    case 'star':
    case 'diamond':
    case 'lemon':
    case 'mysteryBox':
    case 'wild':
      return value;
    default:
      return 'lemon';
  }
}

function parseRarity(value: unknown): PrizeRarity {
  switch (value) {
    case 'common':
    case 'rare':
    case 'epic':
    case 'legendary':
      return value;
    default:
      return 'common';
  }
}

function parseMissionType(value: unknown): SpinMissionType {
  switch (value) {
    case 'profile_complete':
    case 'workshop_register':
    case 'ask_speaker':
    case 'rate_talk':
    case 'trivia':
      return value;
    default:
      return 'profile_complete';
  }
}

function parseWinStatus(value: unknown): SpinWinStatus {
  switch (value) {
    case 'pending':
    case 'redeemed':
    case 'revoked':
      return value;
    default:
      return 'pending';
  }
}

function parseRarityCounts(value: unknown): Record<PrizeRarity, number> {
  const raw = asRecord(value);
  return {
    common: asInt(raw.common, 0),
    rare: asInt(raw.rare, 0),
    epic: asInt(raw.epic, 0),
    legendary: asInt(raw.legendary, 0),
  };
}

function parseMaxWinsByRarity(value: unknown): Record<PrizeRarity, number> {
  const raw = asRecord(value);
  return {
    common: asInt(raw.common, 2),
    rare: asInt(raw.rare, 1),
    epic: asInt(raw.epic, 1),
    legendary: asInt(raw.legendary, 1),
  };
}

function parsePacingWaves(value: unknown): SpinPacingWave[] {
  if (!Array.isArray(value)) return [];
  const waves: SpinPacingWave[] = [];
  for (const item of value) {
    const raw = asRecord(item);
    const startAtMs = toEpochMs(raw.startAt ?? raw.startAtMs);
    if (startAtMs === null) continue;
    waves.push({
      id: asString(raw.id, `wave_${waves.length}`),
      label: asString(raw.label, ''),
      startAtMs,
      releaseRatio: asNumber(raw.releaseRatio, 1),
      spinBudgetShare: asNumber(raw.spinBudgetShare, 0),
    });
  }
  return waves;
}

export function parseSpinConfig(data: Record<string, unknown>): SpinConfig {
  const rawBonusMap = asRecord(data.packageTicketBonus);
  const packageTicketBonus: Record<string, number> = {};
  for (const [key, val] of Object.entries(rawBonusMap)) {
    packageTicketBonus[key] = asInt(val, 0);
  }

  return {
    status: parseGameStatus(data.status),
    pauseMessage: asString(
      data.pauseMessage,
      'GDG SPIN abre en unos minutos. ¡Prepárate!',
    ),
    ticketCostPerSpin: Math.max(1, asInt(data.ticketCostPerSpin, 1)),
    defaultInitialTickets: Math.max(0, asInt(data.defaultInitialTickets, 2)),
    packageTicketBonus,
    matchRegistrationByEmail: asBool(data.matchRegistrationByEmail, true),
    registeredAttendeesCount: Math.max(
      0,
      asInt(data.registeredAttendeesCount, 0),
    ),
    expectedSpinsPerAttendee: Math.max(
      0.1,
      asNumber(data.expectedSpinsPerAttendee, 4),
    ),
    estimatedTotalSpinsOverride:
      data.estimatedTotalSpinsOverride === null ||
      data.estimatedTotalSpinsOverride === undefined
        ? null
        : Math.max(1, asInt(data.estimatedTotalSpinsOverride, 1)),
    pacingMode: parsePacingMode(data.pacingMode),
    pacingStartAtMs: toEpochMs(data.pacingStartAt),
    pacingEndAtMs: toEpochMs(data.pacingEndAt),
    pacingCurveGamma: Math.max(0.1, asNumber(data.pacingCurveGamma, 1.0)),
    pacingWaves: parsePacingWaves(data.pacingWaves),
    rushMode: asBool(data.rushMode, false),
    rushBypassUnlockAt: asBool(data.rushBypassUnlockAt, true),
    payoutMultiplier: Math.max(0.01, asNumber(data.payoutMultiplier, 1.0)),
    maxWinProbabilityPerSpin: asNumber(data.maxWinProbabilityPerSpin, 0.45),
    rushMaxWinProbabilityPerSpin: asNumber(
      data.rushMaxWinProbabilityPerSpin,
      0.85,
    ),
    maxPrizesPerUser: Math.max(0, asInt(data.maxPrizesPerUser, 3)),
    allowPlayAfterCap: asBool(data.allowPlayAfterCap, false),
    maxWinsByRarity: parseMaxWinsByRarity(data.maxWinsByRarity),
    minSpinsBetweenWins: Math.max(0, asInt(data.minSpinsBetweenWins, 1)),
    bonusProbability: Math.max(0, asNumber(data.bonusProbability, 0.06)),
    bonusMinTickets: Math.max(1, asInt(data.bonusMinTickets, 1)),
    bonusMaxTickets: Math.max(1, asInt(data.bonusMaxTickets, 3)),
    maxBonusWinsPerUser: Math.max(0, asInt(data.maxBonusWinsPerUser, 2)),
    wildReplacementChance: Math.max(
      0,
      asNumber(data.wildReplacementChance, 0.35),
    ),
    spinCooldownMs: Math.max(0, asInt(data.spinCooldownMs, 2500)),
    maxTotalEarnedTicketsPerUser: Math.max(
      0,
      asInt(data.maxTotalEarnedTicketsPerUser, 15),
    ),
    maxManualGrantPerAction: Math.max(
      1,
      asInt(data.maxManualGrantPerAction, 5),
    ),
    maxManualTicketsPerUser: Math.max(
      0,
      asInt(data.maxManualTicketsPerUser, 10),
    ),
    updatedAtMs: toEpochMs(data.updatedAt),
    updatedBy: asString(data.updatedBy, ''),
  };
}

export function parseSpinStatsShard(
  data: Record<string, unknown> | undefined,
): SpinStatsShard {
  const raw = data ?? {};
  return {
    totalSpins: asInt(raw.totalSpins, 0),
    totalWins: asInt(raw.totalWins, 0),
    totalBonusSpins: asInt(raw.totalBonusSpins, 0),
    totalBonusTickets: asInt(raw.totalBonusTickets, 0),
    totalTicketsIssued: asInt(raw.totalTicketsIssued, 0),
    totalTicketsSpent: asInt(raw.totalTicketsSpent, 0),
    updatedAtMs: toEpochMs(raw.updatedAt),
  };
}

export function parseSpinPrize(
  id: string,
  data: Record<string, unknown>,
): SpinPrize {
  const initialStock = Math.max(0, asInt(data.initialStock, 0));
  return {
    id: asString(data.id, id) || id,
    name: asString(data.name, ''),
    description: asString(data.description, ''),
    symbol: parseSymbol(data.symbol),
    imageUrl: asNullableString(data.imageUrl),
    rarity: parseRarity(data.rarity),
    initialStock,
    remainingStock: Math.max(0, asInt(data.remainingStock, initialStock)),
    awardedCount: Math.max(0, asInt(data.awardedCount, 0)),
    redeemedCount: Math.max(0, asInt(data.redeemedCount, 0)),
    releasedStock: Math.max(0, asInt(data.releasedStock, initialStock)),
    maxPerUser: Math.max(0, asInt(data.maxPerUser, 1)),
    weight: Math.max(0, asNumber(data.weight, 1.0)),
    unlockAtMs: toEpochMs(data.unlockAt),
    active: asBool(data.active, true),
    order: asInt(data.order, 0),
    updatedAtMs: toEpochMs(data.updatedAt),
  };
}

export function parseSpinMission(
  id: string,
  data: Record<string, unknown>,
): SpinMission {
  const rawConfig = asRecord(data.config);
  const config: SpinMissionConfig = { ...rawConfig };
  if (Array.isArray(rawConfig.options)) {
    config.options = rawConfig.options.filter(
      (item): item is string => typeof item === 'string',
    );
  }

  return {
    id: asString(data.id, id) || id,
    type: parseMissionType(data.type),
    title: asString(data.title, ''),
    description: asString(data.description, ''),
    rewardTickets: Math.max(1, asInt(data.rewardTickets, 1)),
    targetCount: Math.max(1, asInt(data.targetCount, 1)),
    maxCompletionsPerUser: Math.max(1, asInt(data.maxCompletionsPerUser, 1)),
    actionLabel: asNullableString(data.actionLabel),
    active: asBool(data.active, false),
    order: asInt(data.order, 0),
    startsAtMs: toEpochMs(data.startsAt),
    endsAtMs: toEpochMs(data.endsAt),
    config,
    updatedAtMs: toEpochMs(data.updatedAt),
  };
}

export function parseSpinPlayer(
  uid: string,
  data: Record<string, unknown>,
): SpinPlayer {
  const rawWinsByPrize = asRecord(data.winsByPrize);
  const winsByPrize: Record<string, number> = {};
  for (const [key, val] of Object.entries(rawWinsByPrize)) {
    winsByPrize[key] = Math.max(0, asInt(val, 0));
  }

  return {
    uid: asString(data.uid, uid) || uid,
    displayName: asString(data.displayName, ''),
    email: asString(data.email, ''),
    tickets: Math.max(0, asInt(data.tickets, 0)),
    spinsCount: Math.max(0, asInt(data.spinsCount, 0)),
    totalTicketsEarned: Math.max(0, asInt(data.totalTicketsEarned, 0)),
    totalTicketsSpent: Math.max(0, asInt(data.totalTicketsSpent, 0)),
    manualTicketsGranted: Math.max(0, asInt(data.manualTicketsGranted, 0)),
    bonusWinsCount: Math.max(0, asInt(data.bonusWinsCount, 0)),
    totalPrizesWon: Math.max(0, asInt(data.totalPrizesWon, 0)),
    winsByRarity: parseRarityCounts(data.winsByRarity),
    winsByPrize,
    initialTicketsGranted: asBool(data.initialTicketsGranted, false),
    packageBonusGranted: asBool(data.packageBonusGranted, false),
    matchedPackage: asNullableString(data.matchedPackage),
    lastSpinAtMs: toEpochMs(data.lastSpinAt),
    lastWinSpinNumber:
      data.lastWinSpinNumber === null || data.lastWinSpinNumber === undefined
        ? null
        : asInt(data.lastWinSpinNumber, 0),
    createdAtMs: toEpochMs(data.createdAt),
    updatedAtMs: toEpochMs(data.updatedAt),
  };
}

export function parseSpinWin(
  id: string,
  data: Record<string, unknown>,
): SpinWin {
  return {
    id: asString(data.id, id) || id,
    eventId: asString(data.eventId, ''),
    uid: asString(data.uid, ''),
    winnerName: asString(data.winnerName, ''),
    winnerPhotoUrl: asString(data.winnerPhotoUrl, ''),
    prizeId: asString(data.prizeId, ''),
    prizeName: asString(data.prizeName, ''),
    prizeSymbol: parseSymbol(data.prizeSymbol),
    prizeImageUrl: asNullableString(data.prizeImageUrl),
    prizeRarity: parseRarity(data.prizeRarity),
    code: asString(data.code, ''),
    status: parseWinStatus(data.status),
    spinRequestId: asString(data.spinRequestId, ''),
    wonAtMs: toEpochMs(data.wonAt),
    redeemedAtMs: toEpochMs(data.redeemedAt),
    redeemedByUid: asNullableString(data.redeemedByUid),
    redeemedByName: asNullableString(data.redeemedByName),
    revokedAtMs: toEpochMs(data.revokedAt),
    revokedByUid: asNullableString(data.revokedByUid),
    revokeReason: asNullableString(data.revokeReason),
    returnedToStock: asBool(data.returnedToStock, false),
  };
}

export function parseSpinTicketCode(
  id: string,
  data: Record<string, unknown>,
): SpinTicketCode {
  return {
    id: asString(data.id, id) || id,
    code: asString(data.code, '').toUpperCase(),
    label: asString(data.label, ''),
    rewardTickets: Math.max(1, asInt(data.rewardTickets, 1)),
    maxTotalUses: Math.max(1, asInt(data.maxTotalUses, 1)),
    usedCount: Math.max(0, asInt(data.usedCount, 0)),
    maxUsesPerUser: Math.max(1, asInt(data.maxUsesPerUser, 1)),
    active: asBool(data.active, false),
    startsAtMs: toEpochMs(data.startsAt),
    endsAtMs: toEpochMs(data.endsAt),
    createdAtMs: toEpochMs(data.createdAt),
    createdBy: asString(data.createdBy, ''),
  };
}

export function toSpinConfigDto(config: SpinConfig): SpinConfigDto {
  return {
    status: config.status,
    pauseMessage: config.pauseMessage,
    ticketCostPerSpin: config.ticketCostPerSpin,
    defaultInitialTickets: config.defaultInitialTickets,
    packageTicketBonus: { ...config.packageTicketBonus },
    matchRegistrationByEmail: config.matchRegistrationByEmail,
    registeredAttendeesCount: config.registeredAttendeesCount,
    expectedSpinsPerAttendee: config.expectedSpinsPerAttendee,
    estimatedTotalSpinsOverride: config.estimatedTotalSpinsOverride,
    pacingMode: config.pacingMode,
    pacingStartAt: toIsoOrNull(config.pacingStartAtMs),
    pacingEndAt: toIsoOrNull(config.pacingEndAtMs),
    pacingCurveGamma: config.pacingCurveGamma,
    pacingWaves: config.pacingWaves.map((wave) => ({
      id: wave.id,
      label: wave.label,
      startAt: new Date(wave.startAtMs).toISOString(),
      releaseRatio: wave.releaseRatio,
      spinBudgetShare: wave.spinBudgetShare,
    })),
    rushMode: config.rushMode,
    rushBypassUnlockAt: config.rushBypassUnlockAt,
    payoutMultiplier: config.payoutMultiplier,
    maxWinProbabilityPerSpin: config.maxWinProbabilityPerSpin,
    rushMaxWinProbabilityPerSpin: config.rushMaxWinProbabilityPerSpin,
    maxPrizesPerUser: config.maxPrizesPerUser,
    allowPlayAfterCap: config.allowPlayAfterCap,
    maxWinsByRarity: { ...config.maxWinsByRarity },
    minSpinsBetweenWins: config.minSpinsBetweenWins,
    bonusProbability: config.bonusProbability,
    bonusMinTickets: config.bonusMinTickets,
    bonusMaxTickets: config.bonusMaxTickets,
    maxBonusWinsPerUser: config.maxBonusWinsPerUser,
    wildReplacementChance: config.wildReplacementChance,
    spinCooldownMs: config.spinCooldownMs,
    maxTotalEarnedTicketsPerUser: config.maxTotalEarnedTicketsPerUser,
    maxManualGrantPerAction: config.maxManualGrantPerAction,
    maxManualTicketsPerUser: config.maxManualTicketsPerUser,
    updatedAt: toIsoOrNull(config.updatedAtMs),
    updatedBy: config.updatedBy,
  };
}

export function toSpinPrizeDto(prize: SpinPrize): SpinPrizeDto {
  return {
    id: prize.id,
    name: prize.name,
    description: prize.description,
    symbol: prize.symbol,
    imageUrl: prize.imageUrl,
    rarity: prize.rarity,
    initialStock: prize.initialStock,
    remainingStock: prize.remainingStock,
    awardedCount: prize.awardedCount,
    redeemedCount: prize.redeemedCount,
    releasedStock: prize.releasedStock,
    maxPerUser: prize.maxPerUser,
    weight: prize.weight,
    unlockAt: toIsoOrNull(prize.unlockAtMs),
    active: prize.active,
    order: prize.order,
    updatedAt: toIsoOrNull(prize.updatedAtMs),
  };
}

export function toSpinMissionDto(mission: SpinMission): SpinMissionDto {
  return {
    id: mission.id,
    type: mission.type,
    title: mission.title,
    description: mission.description,
    rewardTickets: mission.rewardTickets,
    targetCount: mission.targetCount,
    maxCompletionsPerUser: mission.maxCompletionsPerUser,
    actionLabel: mission.actionLabel,
    active: mission.active,
    order: mission.order,
    startsAt: toIsoOrNull(mission.startsAtMs),
    endsAt: toIsoOrNull(mission.endsAtMs),
    config: { ...mission.config },
    updatedAt: toIsoOrNull(mission.updatedAtMs),
  };
}

export function toSpinPlayerDto(player: SpinPlayer): SpinPlayerDto {
  return {
    uid: player.uid,
    displayName: player.displayName,
    email: player.email,
    tickets: player.tickets,
    spinsCount: player.spinsCount,
    totalTicketsEarned: player.totalTicketsEarned,
    totalTicketsSpent: player.totalTicketsSpent,
    manualTicketsGranted: player.manualTicketsGranted,
    bonusWinsCount: player.bonusWinsCount,
    totalPrizesWon: player.totalPrizesWon,
    winsByRarity: { ...player.winsByRarity },
    winsByPrize: { ...player.winsByPrize },
    initialTicketsGranted: player.initialTicketsGranted,
    packageBonusGranted: player.packageBonusGranted,
    matchedPackage: player.matchedPackage,
    lastSpinAt: toIsoOrNull(player.lastSpinAtMs),
    lastWinSpinNumber: player.lastWinSpinNumber,
    createdAt: toIsoOrNull(player.createdAtMs),
    updatedAt: toIsoOrNull(player.updatedAtMs),
  };
}

export function toSpinWinDto(win: SpinWin): SpinWinDto {
  return {
    id: win.id,
    eventId: win.eventId,
    uid: win.uid,
    winnerName: win.winnerName,
    winnerPhotoUrl: win.winnerPhotoUrl,
    prizeId: win.prizeId,
    prizeName: win.prizeName,
    prizeSymbol: win.prizeSymbol,
    prizeImageUrl: win.prizeImageUrl,
    prizeRarity: win.prizeRarity,
    code: win.code,
    status: win.status,
    spinRequestId: win.spinRequestId,
    wonAt: toIsoOrNull(win.wonAtMs),
    redeemedAt: toIsoOrNull(win.redeemedAtMs),
    redeemedByUid: win.redeemedByUid,
    redeemedByName: win.redeemedByName,
    revokedAt: toIsoOrNull(win.revokedAtMs),
    revokedByUid: win.revokedByUid,
    revokeReason: win.revokeReason,
    returnedToStock: win.returnedToStock,
  };
}

export function toSpinTicketCodeDto(code: SpinTicketCode): SpinTicketCodeDto {
  return {
    id: code.id,
    code: code.code,
    label: code.label,
    rewardTickets: code.rewardTickets,
    maxTotalUses: code.maxTotalUses,
    usedCount: code.usedCount,
    maxUsesPerUser: code.maxUsesPerUser,
    active: code.active,
    startsAt: toIsoOrNull(code.startsAtMs),
    endsAt: toIsoOrNull(code.endsAtMs),
    createdAt: toIsoOrNull(code.createdAtMs),
    createdBy: code.createdBy,
  };
}

export function buildEmptySpinPlayerRecord(params: {
  uid: string;
  displayName: string;
  email: string;
  nowTs: Timestamp;
}): Record<string, unknown> {
  return {
    uid: params.uid,
    displayName: params.displayName,
    email: params.email,
    tickets: 0,
    spinsCount: 0,
    totalTicketsEarned: 0,
    totalTicketsSpent: 0,
    manualTicketsGranted: 0,
    bonusWinsCount: 0,
    totalPrizesWon: 0,
    winsByRarity: { common: 0, rare: 0, epic: 0, legendary: 0 },
    winsByPrize: {},
    initialTicketsGranted: false,
    packageBonusGranted: false,
    matchedPackage: null,
    lastSpinAt: null,
    lastWinSpinNumber: null,
    createdAt: params.nowTs,
    updatedAt: params.nowTs,
  };
}
