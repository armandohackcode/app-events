import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { generatePrizeCode, generateTicketSerial } from '../../domain/codes';
import { buildLoseCombo } from '../../domain/combo';
import {
  computeAvailableForWin,
  decideSpinCandidate,
  hasReachedPrizeCap,
  isPrizeEligibleForPlayer,
  nodeCryptoRng,
  rerollRemainingPrize,
  type CryptoRng,
} from '../../domain/pacing';
import { spinPullSchema } from '../../domain/schemas';
import type {
  SpinConfig,
  SpinPrize,
  SpinPullResponseDto,
  SpinPullWonPrizeDto,
  SpinSymbol,
} from '../../domain/types';
import type { CallerIdentity } from '../../services/auth';
import {
  hasWinnableStock,
  tryCloseGameIfPrizesExhausted,
} from '../../services/autoClose';
import {
  parseInput,
  parseSpinConfig,
  parseSpinPlayer,
  parseSpinPrize,
  parseSpinStatsShard,
  throwSpinError,
} from '../../services/converters';
import {
  STAT_SHARD_COUNT,
  competitorDoc,
  spinConfigDoc,
  spinLogDoc,
  spinPlayerDoc,
  spinPrizeDoc,
  spinPrizesCol,
  spinStatsShardDoc,
  spinWinsCol,
} from '../../services/firestorePaths';
import {
  incrementStatsShard,
  writeTicketLedgerEntry,
  type StatShardDelta,
} from '../../services/ledger';

export interface SpinPullExecutionOptions {
  nowMs?: number;
  rng?: CryptoRng;
}

export async function executeSpinPull(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: SpinPullExecutionOptions = {},
): Promise<SpinPullResponseDto> {
  const input = parseInput(spinPullSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const rng = options.rng ?? nodeCryptoRng;

  // Phase 1: Pre-transaction reads (stats shards stay outside tx to avoid write contention)
  const shardRefs = Array.from({ length: STAT_SHARD_COUNT }, (_, idx) =>
    spinStatsShardDoc(db, input.eventId, idx),
  );

  const [prizesSnap, ...shardSnaps] = await Promise.all([
    spinPrizesCol(db, input.eventId).where('active', '==', true).get(),
    ...shardRefs.map((ref) => ref.get()),
  ]);

  let totalSpinsDone = 0;
  for (const shardSnap of shardSnaps) {
    totalSpinsDone += parseSpinStatsShard(shardSnap.data()).totalSpins;
  }

  const activePrizes: SpinPrize[] = prizesSnap.docs.map((docSnap) =>
    parseSpinPrize(docSnap.id, docSnap.data()),
  );
  const stockAvailable = hasWinnableStock(activePrizes);
  let rejectedForNoStock = false;

  // Phase 2: ACID Transaction (idempotency check + transactional config + fresh stock lock)
  const runSpinTransaction = () => db.runTransaction(async (tx) => {
    rejectedForNoStock = false;
    const logRef = spinLogDoc(db, input.eventId, caller.uid, input.spinRequestId);
    const logSnap = await tx.get(logRef);
    if (logSnap.exists) {
      const logData = logSnap.data() ?? {};
      return {
        wasReplay: true as const,
        response: logData.responseSnapshot as SpinPullResponseDto,
        shardDelta: null as StatShardDelta | null,
        depletedPrizeStock: false,
      };
    }

    const configRef = spinConfigDoc(db, input.eventId);
    const playerRef = spinPlayerDoc(db, input.eventId, caller.uid);
    const [configSnap, playerSnap] = await Promise.all([
      tx.get(configRef),
      tx.get(playerRef),
    ]);

    if (!configSnap.exists) {
      throwSpinError(
        'failed-precondition',
        'Spin configuration has not been initialized for this event.',
        'CONFIG_NOT_FOUND',
      );
    }

    const config: SpinConfig = parseSpinConfig(configSnap.data() ?? {});

    if (!playerSnap.exists) {
      throwSpinError(
        'failed-precondition',
        'Player must be initialized via spinInitPlayer before spinning.',
        'PLAYER_NOT_INITIALIZED',
      );
    }

    const player = parseSpinPlayer(caller.uid, playerSnap.data() ?? {});

    if (config.status === 'paused') {
      throwSpinError(
        'failed-precondition',
        config.pauseMessage || 'GDG SPIN is currently paused.',
        'GAME_PAUSED',
      );
    }
    if (config.status === 'closed') {
      throwSpinError(
        'failed-precondition',
        'GDG SPIN has closed for this event.',
        'GAME_CLOSED',
      );
    }

    // Business rule: when no active prize has stock left the game is over.
    // Reject before charging the ticket; the caller then closes the game.
    if (!stockAvailable) {
      rejectedForNoStock = true;
      throwSpinError(
        'failed-precondition',
        'GDG SPIN has no prizes left for this event.',
        'GAME_CLOSED',
      );
    }

    if (hasReachedPrizeCap(player, config) && !config.allowPlayAfterCap) {
      throwSpinError(
        'failed-precondition',
        'Maximum prizes per user reached.',
        'PRIZE_CAP_REACHED',
      );
    }

    const ticketCost = config.ticketCostPerSpin;
    if (player.tickets < ticketCost) {
      throwSpinError(
        'failed-precondition',
        'Insufficient tickets to spin.',
        'INSUFFICIENT_TICKETS',
      );
    }

    if (
      config.spinCooldownMs > 0 &&
      player.lastSpinAtMs !== null &&
      nowMs - player.lastSpinAtMs < config.spinCooldownMs
    ) {
      throwSpinError(
        'failed-precondition',
        'Spin cooldown active. Please wait a moment before spinning again.',
        'COOLDOWN_ACTIVE',
      );
    }

    const candidate = decideSpinCandidate(
      {
        prizes: activePrizes,
        player,
        config,
        totalSpinsDone,
        nowMs,
      },
      rng,
    );

    let finalOutcomeType = candidate.outcomeType;
    let finalCombo: [SpinSymbol, SpinSymbol, SpinSymbol] = candidate.combo;
    let finalBonusTickets =
      candidate.outcomeType === 'bonus' ? candidate.bonusTickets : 0;
    let wonFreshPrize: SpinPrize | null = null;
    let winnerName = caller.displayName || player.displayName || 'Asistente';
    let winnerPhotoUrl = caller.photoUrl;

    if (candidate.outcomeType === 'prize') {
      const candidatePrizeRef = spinPrizeDoc(
        db,
        input.eventId,
        candidate.prize.id,
      );
      const competitorRef = competitorDoc(db, caller.uid);
      const [candidateFreshSnap, competitorSnap] = await Promise.all([
        tx.get(candidatePrizeRef),
        tx.get(competitorRef),
      ]);

      if (competitorSnap.exists) {
        const compData = competitorSnap.data() ?? {};
        if (typeof compData.name === 'string' && compData.name.trim()) {
          winnerName = compData.name.trim();
        }
        if (typeof compData.photoUrl === 'string' && compData.photoUrl.trim()) {
          winnerPhotoUrl = compData.photoUrl.trim();
        }
      }

      const freshCandidate = candidateFreshSnap.exists
        ? parseSpinPrize(candidateFreshSnap.id, candidateFreshSnap.data() ?? {})
        : null;

      if (
        freshCandidate &&
        isPrizeEligibleForPlayer(freshCandidate, player, config, nowMs) &&
        computeAvailableForWin(freshCandidate, config, nowMs) >= 1
      ) {
        wonFreshPrize = freshCandidate;
      } else {
        // Stale or concurrently depleted prize: re-roll once among remaining eligible prizes.
        const excluded = new Set<string>([candidate.prize.id]);
        const fallback = rerollRemainingPrize(
          {
            prizes: activePrizes,
            player,
            config,
            totalSpinsDone,
            nowMs,
            excludedPrizeIds: excluded,
          },
          rng,
        );

        if (fallback) {
          const fallbackSnap = await tx.get(
            spinPrizeDoc(db, input.eventId, fallback.prize.id),
          );
          const fallbackFresh = fallbackSnap.exists
            ? parseSpinPrize(fallbackSnap.id, fallbackSnap.data() ?? {})
            : null;
          if (
            fallbackFresh &&
            isPrizeEligibleForPlayer(fallbackFresh, player, config, nowMs) &&
            computeAvailableForWin(fallbackFresh, config, nowMs) >= 1
          ) {
            wonFreshPrize = fallbackFresh;
            finalCombo = fallback.combo;
          } else {
            finalOutcomeType = 'lose';
            finalCombo = buildLoseCombo(rng);
          }
        } else {
          finalOutcomeType = 'lose';
          finalCombo = buildLoseCombo(rng);
        }
      }
    }

    // All reads complete — execute atomic writes.
    const nowTs = Timestamp.fromMillis(nowMs);
    const ticketsBefore = player.tickets;
    const balanceAfterCost = ticketsBefore - ticketCost;
    const spinsCountAfter = player.spinsCount + 1;

    writeTicketLedgerEntry(tx, db, input.eventId, {
      uid: caller.uid,
      delta: -ticketCost,
      balanceAfter: balanceAfterCost,
      source: 'spin_cost',
      referenceId: input.spinRequestId,
      note: 'Giro GDG SPIN',
      actorUid: caller.uid,
      createdAt: nowTs,
      docId: `spin_cost_${caller.uid}_${input.spinRequestId}`,
    });

    let ticketsAfter = balanceAfterCost;
    let totalTicketsEarned = player.totalTicketsEarned;
    const totalTicketsSpent = player.totalTicketsSpent + ticketCost;
    let bonusWinsCount = player.bonusWinsCount;
    let totalPrizesWon = player.totalPrizesWon;
    const winsByRarity = { ...player.winsByRarity };
    const winsByPrize = { ...player.winsByPrize };
    let lastWinSpinNumber = player.lastWinSpinNumber;
    let winId: string | null = null;
    let wonPrizeDto: SpinPullWonPrizeDto | null = null;
    let ticketSerial: string | null = null;
    let depletedPrizeStock = false;

    if (finalOutcomeType === 'bonus' && finalBonusTickets > 0) {
      ticketsAfter += finalBonusTickets;
      totalTicketsEarned += finalBonusTickets;
      bonusWinsCount += 1;
      ticketSerial = generateTicketSerial();

      writeTicketLedgerEntry(tx, db, input.eventId, {
        uid: caller.uid,
        delta: finalBonusTickets,
        balanceAfter: ticketsAfter,
        source: 'spin_bonus',
        referenceId: input.spinRequestId,
        note: `Caja misteriosa (+${finalBonusTickets} tickets)`,
        actorUid: caller.uid,
        createdAt: nowTs,
        docId: `spin_bonus_${caller.uid}_${input.spinRequestId}`,
      });
    } else if (finalOutcomeType === 'prize' && wonFreshPrize) {
      // Final hard invariant guard before mutating stock
      if (wonFreshPrize.remainingStock < 1) {
        finalOutcomeType = 'lose';
        finalCombo = buildLoseCombo(rng);
      } else {
        const winRef = spinWinsCol(db, input.eventId).doc();
        const winCode = generatePrizeCode();
        winId = winRef.id;
        finalBonusTickets = 0;

        tx.update(spinPrizeDoc(db, input.eventId, wonFreshPrize.id), {
          remainingStock: wonFreshPrize.remainingStock - 1,
          awardedCount: wonFreshPrize.awardedCount + 1,
          updatedAt: nowTs,
        });

        tx.set(winRef, {
          id: winId,
          eventId: input.eventId,
          uid: caller.uid,
          winnerName,
          winnerPhotoUrl,
          prizeId: wonFreshPrize.id,
          prizeName: wonFreshPrize.name,
          prizeSymbol: wonFreshPrize.symbol,
          prizeImageUrl: wonFreshPrize.imageUrl,
          prizeRarity: wonFreshPrize.rarity,
          code: winCode,
          status: 'pending',
          spinRequestId: input.spinRequestId,
          wonAt: nowTs,
          redeemedAt: null,
          redeemedByUid: null,
          redeemedByName: null,
          revokedAt: null,
          revokedByUid: null,
          revokeReason: null,
          returnedToStock: false,
        });

        totalPrizesWon += 1;
        winsByRarity[wonFreshPrize.rarity] =
          (winsByRarity[wonFreshPrize.rarity] ?? 0) + 1;
        winsByPrize[wonFreshPrize.id] =
          (winsByPrize[wonFreshPrize.id] ?? 0) + 1;
        lastWinSpinNumber = spinsCountAfter;
        depletedPrizeStock = wonFreshPrize.remainingStock - 1 === 0;

        wonPrizeDto = {
          winId,
          prizeId: wonFreshPrize.id,
          name: wonFreshPrize.name,
          symbol: wonFreshPrize.symbol,
          imageUrl: wonFreshPrize.imageUrl,
          rarity: wonFreshPrize.rarity,
          code: winCode,
          wonAt: new Date(nowMs).toISOString(),
        };
      }
    }

    tx.update(playerRef, {
      tickets: ticketsAfter,
      spinsCount: spinsCountAfter,
      totalTicketsEarned,
      totalTicketsSpent,
      bonusWinsCount,
      totalPrizesWon,
      winsByRarity,
      winsByPrize,
      lastSpinAt: nowTs,
      lastWinSpinNumber,
      updatedAt: nowTs,
    });

    const reachedPrizeCap =
      config.maxPrizesPerUser > 0 &&
      totalPrizesWon >= config.maxPrizesPerUser;

    const responseSnapshot: SpinPullResponseDto = {
      spinRequestId: input.spinRequestId,
      outcomeType: finalOutcomeType,
      combo: finalCombo,
      wonPrize: wonPrizeDto,
      bonusTickets: finalBonusTickets,
      ticketsAfter,
      spinsCountAfter,
      reachedPrizeCap,
      ticketSerial,
    };

    tx.set(logRef, {
      uid: caller.uid,
      spinRequestId: input.spinRequestId,
      outcomeType: finalOutcomeType,
      prizeId: wonPrizeDto?.prizeId ?? null,
      winId,
      bonusTickets: finalBonusTickets,
      combo: finalCombo,
      ticketsBefore,
      ticketsAfter,
      spinsCountAfter,
      createdAt: nowTs,
      responseSnapshot,
    });

    const shardDelta: StatShardDelta = {
      totalSpins: 1,
      totalTicketsSpent: ticketCost,
      ...(finalOutcomeType === 'prize' ? { totalWins: 1 } : {}),
      ...(finalOutcomeType === 'bonus'
        ? {
            totalBonusSpins: 1,
            totalBonusTickets: finalBonusTickets,
            totalTicketsIssued: finalBonusTickets,
          }
        : {}),
    };

    return {
      wasReplay: false as const,
      response: responseSnapshot,
      shardDelta,
      depletedPrizeStock,
    };
  });

  let txOutcome: Awaited<ReturnType<typeof runSpinTransaction>>;
  try {
    txOutcome = await runSpinTransaction();
  } catch (error) {
    if (rejectedForNoStock) {
      await tryCloseGameIfPrizesExhausted(db, input.eventId, nowMs);
    }
    throw error;
  }

  // Phase 3: Non-blocking distributed stats shard increment
  if (!txOutcome.wasReplay && txOutcome.shardDelta) {
    try {
      await incrementStatsShard(
        db,
        input.eventId,
        caller.uid,
        txOutcome.shardDelta,
      );
    } catch {
      // Non-blocking stats shard update.
    }
  }

  // Phase 4: this spin took the last unit of a prize; close the game if it
  // was the last prize with stock.
  if (!txOutcome.wasReplay && txOutcome.depletedPrizeStock) {
    await tryCloseGameIfPrizesExhausted(db, input.eventId, nowMs);
  }

  return txOutcome.response;
}
