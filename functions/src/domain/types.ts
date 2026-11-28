/**
 * Pure domain types and JSON DTO contracts for GDG SPIN Phase 2.
 *
 * ZERO Firebase SDK imports are allowed in `functions/src/domain/`.
 * Internal domain logic represents timestamps as epoch milliseconds (`EpochMs`).
 * Callable JSON response DTOs serialize all timestamps as ISO-8601 UTC strings
 * (`IsoDateString | null`) for consistent Flutter `DateTime.parse` handling.
 */

export type EpochMs = number;
export type IsoDateString = string;

export type SpinSymbol =
  | 'seven'
  | 'bar'
  | 'cherries'
  | 'bell'
  | 'star'
  | 'diamond'
  | 'lemon'
  | 'mysteryBox'
  | 'wild';

export type WinningPrizeSymbol =
  | 'cherries'
  | 'bell'
  | 'bar'
  | 'star'
  | 'diamond'
  | 'seven';

export type PrizeRarity = 'common' | 'rare' | 'epic' | 'legendary';

export type SpinGameStatus = 'paused' | 'active' | 'closed';

export type SpinPacingMode = 'time_paced' | 'dynamic_spins' | 'manual_waves';

export type SpinMissionType =
  | 'profile_complete'
  | 'workshop_register'
  | 'ask_speaker'
  | 'rate_talk'
  | 'trivia';

export type SpinWinStatus = 'pending' | 'redeemed' | 'revoked';

export type TicketLedgerSource =
  | 'initial'
  | 'package_bonus'
  | 'mission'
  | 'trivia'
  | 'stand_code'
  | 'manual_admin'
  | 'spin_bonus'
  | 'spin_cost';

export type SpinOutcomeType = 'prize' | 'bonus' | 'lose';

export type SpinErrorReason =
  | 'GAME_PAUSED'
  | 'GAME_CLOSED'
  | 'INSUFFICIENT_TICKETS'
  | 'COOLDOWN_ACTIVE'
  | 'PRIZE_CAP_REACHED'
  | 'PLAYER_NOT_INITIALIZED'
  | 'CONFIG_NOT_FOUND'
  | 'REQUIREMENT_NOT_MET'
  | 'TICKET_CAP_REACHED'
  | 'TRIVIA_CLOSED'
  | 'MISSION_INACTIVE'
  | 'CODE_DEPLETED'
  | 'CODE_EXPIRED'
  | 'CODE_ALREADY_EXISTS'
  | 'RATE_LIMITED'
  | 'QUESTION_LIMIT_REACHED'
  | 'ALREADY_REDEEMED'
  | 'ALREADY_REVOKED'
  | 'INVALID_STOCK_ADJUSTMENT'
  | 'STOCK_IMMUTABLE_ON_UPDATE'
  | 'MANUAL_GRANT_CAP_REACHED'
  | 'EVENT_MISMATCH'
  | 'INVALID_CODE_FORMAT'
  | 'INVALID_SECRET';

// ---------------------------------------------------------------------------
// Pure Domain Models (EpochMs timestamps)
// ---------------------------------------------------------------------------

export interface SpinPacingWave {
  id: string;
  label: string;
  startAtMs: EpochMs;
  releaseRatio: number;
  spinBudgetShare: number;
}

export interface SpinConfig {
  status: SpinGameStatus;
  pauseMessage: string;
  ticketCostPerSpin: number;
  defaultInitialTickets: number;
  packageTicketBonus: Record<string, number>;
  matchRegistrationByEmail: boolean;
  registeredAttendeesCount: number;
  expectedSpinsPerAttendee: number;
  estimatedTotalSpinsOverride: number | null;
  pacingMode: SpinPacingMode;
  pacingStartAtMs: EpochMs | null;
  pacingEndAtMs: EpochMs | null;
  pacingCurveGamma: number;
  pacingWaves: SpinPacingWave[];
  rushMode: boolean;
  rushBypassUnlockAt: boolean;
  payoutMultiplier: number;
  maxWinProbabilityPerSpin: number;
  rushMaxWinProbabilityPerSpin: number;
  maxPrizesPerUser: number;
  allowPlayAfterCap: boolean;
  maxWinsByRarity: Record<PrizeRarity, number>;
  minSpinsBetweenWins: number;
  bonusProbability: number;
  bonusMinTickets: number;
  bonusMaxTickets: number;
  maxBonusWinsPerUser: number;
  wildReplacementChance: number;
  spinCooldownMs: number;
  maxTotalEarnedTicketsPerUser: number;
  maxManualGrantPerAction: number;
  maxManualTicketsPerUser: number;
  updatedAtMs: EpochMs | null;
  updatedBy: string;
}

export interface SpinStatsShard {
  totalSpins: number;
  totalWins: number;
  totalBonusSpins: number;
  totalBonusTickets: number;
  totalTicketsIssued: number;
  totalTicketsSpent: number;
  updatedAtMs: EpochMs | null;
}

export interface SpinPrize {
  id: string;
  name: string;
  description: string;
  symbol: SpinSymbol;
  imageUrl: string | null;
  rarity: PrizeRarity;
  initialStock: number;
  remainingStock: number;
  awardedCount: number;
  redeemedCount: number;
  releasedStock: number;
  maxPerUser: number;
  weight: number;
  unlockAtMs: EpochMs | null;
  active: boolean;
  order: number;
  updatedAtMs: EpochMs | null;
}

export interface SpinMissionConfig {
  question?: string;
  options?: string[];
  minAboutMeLength?: number;
  [key: string]: unknown;
}

export interface SpinMission {
  id: string;
  type: SpinMissionType;
  title: string;
  description: string;
  rewardTickets: number;
  targetCount: number;
  maxCompletionsPerUser: number;
  actionLabel: string | null;
  active: boolean;
  order: number;
  startsAtMs: EpochMs | null;
  endsAtMs: EpochMs | null;
  config: SpinMissionConfig;
  updatedAtMs: EpochMs | null;
}

export interface SpinMissionSecret {
  correctOptionIndex: number;
  explanation: string;
}

export interface SpinPlayer {
  uid: string;
  displayName: string;
  email: string;
  tickets: number;
  spinsCount: number;
  totalTicketsEarned: number;
  totalTicketsSpent: number;
  manualTicketsGranted: number;
  bonusWinsCount: number;
  totalPrizesWon: number;
  winsByRarity: Record<PrizeRarity, number>;
  winsByPrize: Record<string, number>;
  initialTicketsGranted: boolean;
  packageBonusGranted: boolean;
  matchedPackage: string | null;
  lastSpinAtMs: EpochMs | null;
  lastWinSpinNumber: number | null;
  createdAtMs: EpochMs | null;
  updatedAtMs: EpochMs | null;
}

export interface SpinWin {
  id: string;
  eventId: string;
  uid: string;
  winnerName: string;
  winnerPhotoUrl: string;
  prizeId: string;
  prizeName: string;
  prizeSymbol: SpinSymbol;
  prizeImageUrl: string | null;
  prizeRarity: PrizeRarity;
  code: string;
  status: SpinWinStatus;
  spinRequestId: string;
  wonAtMs: EpochMs | null;
  redeemedAtMs: EpochMs | null;
  redeemedByUid: string | null;
  redeemedByName: string | null;
  revokedAtMs: EpochMs | null;
  revokedByUid: string | null;
  revokeReason: string | null;
  returnedToStock: boolean;
}

export interface SpinTicketCode {
  id: string;
  code: string;
  label: string;
  rewardTickets: number;
  maxTotalUses: number;
  usedCount: number;
  maxUsesPerUser: number;
  active: boolean;
  startsAtMs: EpochMs | null;
  endsAtMs: EpochMs | null;
  createdAtMs: EpochMs | null;
  createdBy: string;
}

export interface SpinRegistration {
  emailNormalized: string;
  fullName: string;
  package: string;
  checkedIn: boolean;
  importedAtMs: EpochMs | null;
  importedBy: string;
}

export interface SpinLog {
  uid: string;
  spinRequestId: string;
  outcomeType: SpinOutcomeType;
  prizeId: string | null;
  winId: string | null;
  bonusTickets: number;
  combo: [SpinSymbol, SpinSymbol, SpinSymbol];
  ticketsBefore: number;
  ticketsAfter: number;
  spinsCountAfter: number;
  createdAtMs: EpochMs | null;
  responseSnapshot: SpinPullResponseDto;
}

export interface TicketLedgerEntry {
  id?: string;
  uid: string;
  delta: number;
  balanceAfter: number;
  source: TicketLedgerSource;
  referenceId: string;
  note: string;
  actorUid: string;
  createdAtMs: EpochMs | null;
}

export interface SpinAuditLog {
  id?: string;
  action: string;
  actorUid: string;
  actorName: string;
  targetId: string | null;
  summary: string;
  metadata: Record<string, unknown>;
  createdAtMs: EpochMs | null;
}

export interface TalkQuestion {
  id: string;
  uid: string;
  authorName: string;
  authorPhotoUrl: string;
  text: string;
  answered: boolean;
  hidden: boolean;
  createdAtMs: EpochMs | null;
}

export interface TalkRating {
  uid: string;
  stars: number;
  comment: string;
  createdAtMs: EpochMs | null;
  updatedAtMs: EpochMs | null;
}

// ---------------------------------------------------------------------------
// Callable JSON DTOs (ISO-8601 date strings for Flutter JSON parsing)
// ---------------------------------------------------------------------------

export interface SpinPacingWaveDto {
  id: string;
  label: string;
  startAt: IsoDateString;
  releaseRatio: number;
  spinBudgetShare: number;
}

export interface SpinConfigDto {
  status: SpinGameStatus;
  pauseMessage: string;
  ticketCostPerSpin: number;
  defaultInitialTickets: number;
  packageTicketBonus: Record<string, number>;
  matchRegistrationByEmail: boolean;
  registeredAttendeesCount: number;
  expectedSpinsPerAttendee: number;
  estimatedTotalSpinsOverride: number | null;
  pacingMode: SpinPacingMode;
  pacingStartAt: IsoDateString | null;
  pacingEndAt: IsoDateString | null;
  pacingCurveGamma: number;
  pacingWaves: SpinPacingWaveDto[];
  rushMode: boolean;
  rushBypassUnlockAt: boolean;
  payoutMultiplier: number;
  maxWinProbabilityPerSpin: number;
  rushMaxWinProbabilityPerSpin: number;
  maxPrizesPerUser: number;
  allowPlayAfterCap: boolean;
  maxWinsByRarity: Record<PrizeRarity, number>;
  minSpinsBetweenWins: number;
  bonusProbability: number;
  bonusMinTickets: number;
  bonusMaxTickets: number;
  maxBonusWinsPerUser: number;
  wildReplacementChance: number;
  spinCooldownMs: number;
  maxTotalEarnedTicketsPerUser: number;
  maxManualGrantPerAction: number;
  maxManualTicketsPerUser: number;
  updatedAt: IsoDateString | null;
  updatedBy: string;
}

export interface SpinPrizeDto {
  id: string;
  name: string;
  description: string;
  symbol: SpinSymbol;
  imageUrl: string | null;
  rarity: PrizeRarity;
  initialStock: number;
  remainingStock: number;
  awardedCount: number;
  redeemedCount: number;
  releasedStock: number;
  maxPerUser: number;
  weight: number;
  unlockAt: IsoDateString | null;
  active: boolean;
  order: number;
  updatedAt: IsoDateString | null;
}

export interface SpinMissionDto {
  id: string;
  type: SpinMissionType;
  title: string;
  description: string;
  rewardTickets: number;
  targetCount: number;
  maxCompletionsPerUser: number;
  actionLabel: string | null;
  active: boolean;
  order: number;
  startsAt: IsoDateString | null;
  endsAt: IsoDateString | null;
  config: SpinMissionConfig;
  updatedAt: IsoDateString | null;
}

export interface SpinPlayerDto {
  uid: string;
  displayName: string;
  email: string;
  tickets: number;
  spinsCount: number;
  totalTicketsEarned: number;
  totalTicketsSpent: number;
  manualTicketsGranted: number;
  bonusWinsCount: number;
  totalPrizesWon: number;
  winsByRarity: Record<PrizeRarity, number>;
  winsByPrize: Record<string, number>;
  initialTicketsGranted: boolean;
  packageBonusGranted: boolean;
  matchedPackage: string | null;
  lastSpinAt: IsoDateString | null;
  lastWinSpinNumber: number | null;
  createdAt: IsoDateString | null;
  updatedAt: IsoDateString | null;
}

export interface SpinWinDto {
  id: string;
  eventId: string;
  uid: string;
  winnerName: string;
  winnerPhotoUrl: string;
  prizeId: string;
  prizeName: string;
  prizeSymbol: SpinSymbol;
  prizeImageUrl: string | null;
  prizeRarity: PrizeRarity;
  code: string;
  status: SpinWinStatus;
  spinRequestId: string;
  wonAt: IsoDateString | null;
  redeemedAt: IsoDateString | null;
  redeemedByUid: string | null;
  redeemedByName: string | null;
  revokedAt: IsoDateString | null;
  revokedByUid: string | null;
  revokeReason: string | null;
  returnedToStock: boolean;
}

export interface SpinTicketCodeDto {
  id: string;
  code: string;
  label: string;
  rewardTickets: number;
  maxTotalUses: number;
  usedCount: number;
  maxUsesPerUser: number;
  active: boolean;
  startsAt: IsoDateString | null;
  endsAt: IsoDateString | null;
  createdAt: IsoDateString | null;
  createdBy: string;
}

export interface SpinStatsSummaryDto {
  totalSpins: number;
  totalWins: number;
  totalBonusSpins: number;
  totalBonusTickets: number;
  totalTicketsIssued: number;
  totalTicketsSpent: number;
}

// Player Callable Response DTOs

export interface SpinInitPlayerResponseDto {
  player: SpinPlayerDto;
  initialGranted: boolean;
  packageBonusGranted: boolean;
  matchedPackage: string | null;
}

export interface SpinPullWonPrizeDto {
  winId: string;
  prizeId: string;
  name: string;
  symbol: SpinSymbol;
  imageUrl: string | null;
  rarity: PrizeRarity;
  code: string;
  wonAt: IsoDateString;
}

export interface SpinPullResponseDto {
  spinRequestId: string;
  outcomeType: SpinOutcomeType;
  combo: [SpinSymbol, SpinSymbol, SpinSymbol];
  wonPrize: SpinPullWonPrizeDto | null;
  bonusTickets: number;
  ticketsAfter: number;
  spinsCountAfter: number;
  reachedPrizeCap: boolean;
  ticketSerial: string | null;
}

export interface SpinClaimMissionResponseDto {
  granted: boolean;
  ticketsAwarded: number;
  ticketsAfter: number;
  ticketSerial: string;
}

export interface SpinSubmitTriviaResponseDto {
  correct: boolean;
  explanation: string;
  ticketsAwarded: number;
  ticketsAfter: number;
  ticketSerial: string | null;
}

export interface SpinRedeemTicketCodeResponseDto {
  label: string;
  ticketsAwarded: number;
  ticketsAfter: number;
  ticketSerial: string;
}

export interface SpinSubmitTalkQuestionResponseDto {
  questionId: string;
  missionRewarded: boolean;
  ticketsAwarded: number;
  ticketsAfter: number;
  ticketSerial: string | null;
}

export interface SpinSubmitTalkRatingResponseDto {
  saved: boolean;
  missionRewarded: boolean;
  ticketsAwarded: number;
  ticketsAfter: number;
  ticketSerial: string | null;
}

// Admin Callable Response DTOs

export interface AdminUpdateSpinConfigResponseDto {
  config: SpinConfigDto;
}

export interface AdminUpsertSpinPrizeResponseDto {
  prize: SpinPrizeDto;
  created: boolean;
}

export interface AdminAdjustPrizeStockResponseDto {
  prize: SpinPrizeDto;
}

export interface AdminUpsertSpinMissionResponseDto {
  mission: SpinMissionDto;
  created: boolean;
}

export interface AdminUpsertTicketCodeResponseDto {
  ticketCode: SpinTicketCodeDto;
  created: boolean;
}

export interface AdminGrantTicketsResponseDto {
  targetUid: string;
  ticketsAwarded: number;
  ticketsAfter: number;
  ticketSerial: string;
  idempotentReplay: boolean;
}

export interface AdminImportRegistrationsResponseDto {
  importedCount: number;
  updatedCount: number;
  totalRegistrationsCount: number;
}

export interface AdminLookupWinByCodeResponseDto {
  win: SpinWinDto;
  prize: SpinPrizeDto | null;
  player: SpinPlayerDto | null;
}

export interface AdminRedeemWinResponseDto {
  win: SpinWinDto;
}

export interface AdminRevokeWinResponseDto {
  win: SpinWinDto;
}

export interface AdminGetSpinDashboardResponseDto {
  config: SpinConfigDto;
  stats: SpinStatsSummaryDto;
  prizes: SpinPrizeDto[];
  winCounts: {
    pending: number;
    redeemed: number;
    revoked: number;
    total: number;
  };
  activePlayersCount: number;
  registrationsCount: number;
}
