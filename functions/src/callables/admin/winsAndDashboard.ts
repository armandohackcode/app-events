import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { CodeParseError, parseWinCodeInput } from '../../domain/codes';
import {
  adminGetSpinDashboardSchema,
  adminLookupWinByCodeSchema,
  adminRedeemWinSchema,
  adminRevokeWinSchema,
} from '../../domain/schemas';
import type {
  AdminGetSpinDashboardResponseDto,
  AdminLookupWinByCodeResponseDto,
  AdminRedeemWinResponseDto,
  AdminRevokeWinResponseDto,
  SpinStatsSummaryDto,
  SpinWin,
} from '../../domain/types';
import type { CallerIdentity } from '../../services/auth';
import { assertIsAdmin } from '../../services/auth';
import {
  parseInput,
  parseSpinConfig,
  parseSpinPlayer,
  parseSpinPrize,
  parseSpinStatsShard,
  parseSpinWin,
  throwSpinError,
  toSpinConfigDto,
  toSpinPlayerDto,
  toSpinPrizeDto,
  toSpinWinDto,
} from '../../services/converters';
import {
  STAT_SHARD_COUNT,
  spinConfigDoc,
  spinPlayerDoc,
  spinPlayersCol,
  spinPrizeDoc,
  spinPrizesCol,
  spinRegistrationsCol,
  spinStatsShardDoc,
  spinWinDoc,
  spinWinsCol,
} from '../../services/firestorePaths';
import { writeSpinAuditLog } from '../../services/ledger';
import type { AdminExecutionOptions } from './configAndPrizes';

export async function executeAdminLookupWinByCode(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
): Promise<AdminLookupWinByCodeResponseDto> {
  await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminLookupWinByCodeSchema, rawInput);

  let normalizedCode: string;
  try {
    normalizedCode = parseWinCodeInput(input.codeOrQr, input.eventId);
  } catch (error) {
    if (error instanceof CodeParseError) {
      throwSpinError('invalid-argument', error.message, error.reason);
    }
    throw error;
  }

  const winsSnap = await spinWinsCol(db, input.eventId)
    .where('code', '==', normalizedCode)
    .limit(1)
    .get();

  if (winsSnap.empty) {
    throwSpinError('not-found', `No win found for code ${normalizedCode}.`);
  }

  const winDocSnap = winsSnap.docs[0];
  const win = parseSpinWin(winDocSnap.id, winDocSnap.data());

  const [prizeSnap, playerSnap] = await Promise.all([
    spinPrizeDoc(db, input.eventId, win.prizeId).get(),
    spinPlayerDoc(db, input.eventId, win.uid).get(),
  ]);

  const prize = prizeSnap.exists
    ? parseSpinPrize(prizeSnap.id, prizeSnap.data() ?? {})
    : null;
  const player = playerSnap.exists
    ? parseSpinPlayer(playerSnap.id, playerSnap.data() ?? {})
    : null;

  return {
    win: toSpinWinDto(win),
    prize: prize ? toSpinPrizeDto(prize) : null,
    player: player ? toSpinPlayerDto(player) : null,
  };
}

export async function executeAdminRedeemWin(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: AdminExecutionOptions = {},
): Promise<AdminRedeemWinResponseDto> {
  const admin = await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminRedeemWinSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const updatedWin = await db.runTransaction(async (tx) => {
    const winRef = spinWinDoc(db, input.eventId, input.winId);
    const winSnap = await tx.get(winRef);
    if (!winSnap.exists) {
      throwSpinError('not-found', 'Win record not found.');
    }

    const win = parseSpinWin(winSnap.id, winSnap.data() ?? {});
    if (win.status === 'redeemed') {
      throwSpinError(
        'failed-precondition',
        'This prize has already been redeemed.',
        'ALREADY_REDEEMED',
      );
    }
    if (win.status === 'revoked') {
      throwSpinError(
        'failed-precondition',
        'This win was revoked and cannot be redeemed.',
        'ALREADY_REVOKED',
      );
    }

    const prizeRef = spinPrizeDoc(db, input.eventId, win.prizeId);
    const prizeSnap = await tx.get(prizeRef);

    const nextWin: SpinWin = {
      ...win,
      status: 'redeemed',
      redeemedAtMs: nowMs,
      redeemedByUid: admin.uid,
      redeemedByName: admin.name,
    };

    tx.update(winRef, {
      status: 'redeemed',
      redeemedAt: nowTs,
      redeemedByUid: admin.uid,
      redeemedByName: admin.name,
    });

    if (prizeSnap.exists) {
      const prize = parseSpinPrize(prizeSnap.id, prizeSnap.data() ?? {});
      tx.update(prizeRef, {
        redeemedCount: prize.redeemedCount + 1,
        updatedAt: nowTs,
      });
    }

    writeSpinAuditLog(tx, db, input.eventId, {
      action: 'redeem_win',
      actorUid: admin.uid,
      actorName: admin.name,
      targetId: input.winId,
      summary: `Redeemed prize "${win.prizeName}" (${win.code}) for ${win.winnerName}`,
      metadata: {
        winId: input.winId,
        code: win.code,
        prizeId: win.prizeId,
        winnerUid: win.uid,
      },
      createdAt: nowTs,
    });

    return nextWin;
  });

  return {
    win: toSpinWinDto(updatedWin),
  };
}

export async function executeAdminRevokeWin(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: AdminExecutionOptions = {},
): Promise<AdminRevokeWinResponseDto> {
  const admin = await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminRevokeWinSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const updatedWin = await db.runTransaction(async (tx) => {
    const winRef = spinWinDoc(db, input.eventId, input.winId);
    const winSnap = await tx.get(winRef);
    if (!winSnap.exists) {
      throwSpinError('not-found', 'Win record not found.');
    }

    const win = parseSpinWin(winSnap.id, winSnap.data() ?? {});
    if (win.status === 'redeemed') {
      throwSpinError(
        'failed-precondition',
        'Redeemed prizes cannot be revoked.',
        'ALREADY_REDEEMED',
      );
    }
    if (win.status === 'revoked') {
      throwSpinError(
        'failed-precondition',
        'This win has already been revoked.',
        'ALREADY_REVOKED',
      );
    }

    const prizeRef = spinPrizeDoc(db, input.eventId, win.prizeId);
    const playerRef = spinPlayerDoc(db, input.eventId, win.uid);
    const [prizeSnap, playerSnap] = await Promise.all([
      tx.get(prizeRef),
      tx.get(playerRef),
    ]);

    const nextWin: SpinWin = {
      ...win,
      status: 'revoked',
      revokedAtMs: nowMs,
      revokedByUid: admin.uid,
      revokeReason: input.reason,
      returnedToStock: input.returnToStock,
    };

    tx.update(winRef, {
      status: 'revoked',
      revokedAt: nowTs,
      revokedByUid: admin.uid,
      revokeReason: input.reason,
      returnedToStock: input.returnToStock,
    });

    if (input.returnToStock) {
      if (prizeSnap.exists) {
        const prize = parseSpinPrize(prizeSnap.id, prizeSnap.data() ?? {});
        const nextRemaining = prize.remainingStock + 1;
        const nextAwarded = Math.max(0, prize.awardedCount - 1);
        tx.update(prizeRef, {
          remainingStock: nextRemaining,
          awardedCount: nextAwarded,
          updatedAt: nowTs,
        });
      }

      if (playerSnap.exists) {
        const player = parseSpinPlayer(playerSnap.id, playerSnap.data() ?? {});
        const nextTotalPrizes = Math.max(0, player.totalPrizesWon - 1);
        const nextWinsByRarity = {
          ...player.winsByRarity,
          [win.prizeRarity]: Math.max(
            0,
            (player.winsByRarity[win.prizeRarity] ?? 0) - 1,
          ),
        };
        const nextWinsByPrize = {
          ...player.winsByPrize,
          [win.prizeId]: Math.max(0, (player.winsByPrize[win.prizeId] ?? 0) - 1),
        };

        tx.update(playerRef, {
          totalPrizesWon: nextTotalPrizes,
          winsByRarity: nextWinsByRarity,
          winsByPrize: nextWinsByPrize,
          ...(nextTotalPrizes === 0 ? { lastWinSpinNumber: null } : {}),
          updatedAt: nowTs,
        });
      }
    }

    writeSpinAuditLog(tx, db, input.eventId, {
      action: 'revoke_win',
      actorUid: admin.uid,
      actorName: admin.name,
      targetId: input.winId,
      summary: `Revoked prize "${win.prizeName}" (${win.code}): ${input.reason}`,
      metadata: {
        winId: input.winId,
        code: win.code,
        prizeId: win.prizeId,
        winnerUid: win.uid,
        returnToStock: input.returnToStock,
        reason: input.reason,
      },
      createdAt: nowTs,
    });

    return nextWin;
  });

  return {
    win: toSpinWinDto(updatedWin),
  };
}

export async function executeAdminGetSpinDashboard(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
): Promise<AdminGetSpinDashboardResponseDto> {
  await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminGetSpinDashboardSchema, rawInput);

  const shardRefs = Array.from({ length: STAT_SHARD_COUNT }, (_, idx) =>
    spinStatsShardDoc(db, input.eventId, idx),
  );

  const [
    configSnap,
    prizesSnap,
    pendingCountSnap,
    redeemedCountSnap,
    revokedCountSnap,
    playersCountSnap,
    registrationsCountSnap,
    ...shardSnaps
  ] = await Promise.all([
    spinConfigDoc(db, input.eventId).get(),
    spinPrizesCol(db, input.eventId).orderBy('order', 'asc').get(),
    spinWinsCol(db, input.eventId).where('status', '==', 'pending').count().get(),
    spinWinsCol(db, input.eventId).where('status', '==', 'redeemed').count().get(),
    spinWinsCol(db, input.eventId).where('status', '==', 'revoked').count().get(),
    spinPlayersCol(db, input.eventId).count().get(),
    spinRegistrationsCol(db, input.eventId).count().get(),
    ...shardRefs.map((ref) => ref.get()),
  ]);

  if (!configSnap.exists) {
    throwSpinError(
      'failed-precondition',
      'Spin configuration has not been initialized for this event.',
      'CONFIG_NOT_FOUND',
    );
  }

  const config = parseSpinConfig(configSnap.data() ?? {});
  const stats: SpinStatsSummaryDto = {
    totalSpins: 0,
    totalWins: 0,
    totalBonusSpins: 0,
    totalBonusTickets: 0,
    totalTicketsIssued: 0,
    totalTicketsSpent: 0,
  };

  for (const shardSnap of shardSnaps) {
    const parsed = parseSpinStatsShard(shardSnap.data());
    stats.totalSpins += parsed.totalSpins;
    stats.totalWins += parsed.totalWins;
    stats.totalBonusSpins += parsed.totalBonusSpins;
    stats.totalBonusTickets += parsed.totalBonusTickets;
    stats.totalTicketsIssued += parsed.totalTicketsIssued;
    stats.totalTicketsSpent += parsed.totalTicketsSpent;
  }

  const prizes = prizesSnap.docs.map((docSnap) =>
    toSpinPrizeDto(parseSpinPrize(docSnap.id, docSnap.data())),
  );

  const pending = pendingCountSnap.data().count;
  const redeemed = redeemedCountSnap.data().count;
  const revoked = revokedCountSnap.data().count;

  return {
    config: toSpinConfigDto(config),
    stats,
    prizes,
    winCounts: {
      pending,
      redeemed,
      revoked,
      total: pending + redeemed + revoked,
    },
    activePlayersCount: playersCountSnap.data().count,
    registrationsCount: registrationsCountSnap.data().count,
  };
}
