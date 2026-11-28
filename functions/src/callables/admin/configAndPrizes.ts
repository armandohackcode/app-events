import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  adminAdjustPrizeStockSchema,
  adminUpdateSpinConfigSchema,
  adminUpsertSpinPrizeSchema,
} from '../../domain/schemas';
import type {
  AdminAdjustPrizeStockResponseDto,
  AdminUpdateSpinConfigResponseDto,
  AdminUpsertSpinPrizeResponseDto,
  SpinConfig,
  SpinPrize,
} from '../../domain/types';
import type { CallerIdentity } from '../../services/auth';
import { assertIsAdmin } from '../../services/auth';
import { tryCloseGameIfPrizesExhausted } from '../../services/autoClose';
import {
  parseInput,
  parseSpinConfig,
  parseSpinPrize,
  throwSpinError,
  toSpinConfigDto,
  toSpinPrizeDto,
  toTimestampOrNull,
} from '../../services/converters';
import {
  spinConfigDoc,
  spinPrizeDoc,
  spinPrizesCol,
} from '../../services/firestorePaths';
import { writeSpinAuditLog } from '../../services/ledger';

export interface AdminExecutionOptions {
  nowMs?: number;
}

export async function executeAdminUpdateSpinConfig(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: AdminExecutionOptions = {},
): Promise<AdminUpdateSpinConfigResponseDto> {
  const admin = await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminUpdateSpinConfigSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const updatedConfig = await db.runTransaction(async (tx) => {
    const configRef = spinConfigDoc(db, input.eventId);
    const configSnap = await tx.get(configRef);
    const prevRaw = configSnap.exists ? (configSnap.data() ?? {}) : {};
    const prevConfig = parseSpinConfig(prevRaw);

    const { patch } = input;
    const merged: SpinConfig = {
      ...prevConfig,
      ...(patch.status !== undefined ? { status: patch.status } : {}),
      ...(patch.pauseMessage !== undefined
        ? { pauseMessage: patch.pauseMessage }
        : {}),
      ...(patch.ticketCostPerSpin !== undefined
        ? { ticketCostPerSpin: patch.ticketCostPerSpin }
        : {}),
      ...(patch.defaultInitialTickets !== undefined
        ? { defaultInitialTickets: patch.defaultInitialTickets }
        : {}),
      ...(patch.packageTicketBonus !== undefined
        ? { packageTicketBonus: { ...patch.packageTicketBonus } }
        : {}),
      ...(patch.matchRegistrationByEmail !== undefined
        ? { matchRegistrationByEmail: patch.matchRegistrationByEmail }
        : {}),
      ...(patch.registeredAttendeesCount !== undefined
        ? { registeredAttendeesCount: patch.registeredAttendeesCount }
        : {}),
      ...(patch.expectedSpinsPerAttendee !== undefined
        ? { expectedSpinsPerAttendee: patch.expectedSpinsPerAttendee }
        : {}),
      ...(patch.estimatedTotalSpinsOverride !== undefined
        ? { estimatedTotalSpinsOverride: patch.estimatedTotalSpinsOverride }
        : {}),
      ...(patch.pacingMode !== undefined
        ? { pacingMode: patch.pacingMode }
        : {}),
      ...(patch.pacingStartAt !== undefined
        ? { pacingStartAtMs: patch.pacingStartAt }
        : {}),
      ...(patch.pacingEndAt !== undefined
        ? { pacingEndAtMs: patch.pacingEndAt }
        : {}),
      ...(patch.pacingCurveGamma !== undefined
        ? { pacingCurveGamma: patch.pacingCurveGamma }
        : {}),
      ...(patch.pacingWaves !== undefined
        ? {
            pacingWaves: patch.pacingWaves.map((wave) => ({
              id: wave.id,
              label: wave.label,
              startAtMs: wave.startAt,
              releaseRatio: wave.releaseRatio,
              spinBudgetShare: wave.spinBudgetShare,
            })),
          }
        : {}),
      ...(patch.rushMode !== undefined ? { rushMode: patch.rushMode } : {}),
      ...(patch.rushBypassUnlockAt !== undefined
        ? { rushBypassUnlockAt: patch.rushBypassUnlockAt }
        : {}),
      ...(patch.payoutMultiplier !== undefined
        ? { payoutMultiplier: patch.payoutMultiplier }
        : {}),
      ...(patch.maxWinProbabilityPerSpin !== undefined
        ? { maxWinProbabilityPerSpin: patch.maxWinProbabilityPerSpin }
        : {}),
      ...(patch.rushMaxWinProbabilityPerSpin !== undefined
        ? { rushMaxWinProbabilityPerSpin: patch.rushMaxWinProbabilityPerSpin }
        : {}),
      ...(patch.maxPrizesPerUser !== undefined
        ? { maxPrizesPerUser: patch.maxPrizesPerUser }
        : {}),
      ...(patch.allowPlayAfterCap !== undefined
        ? { allowPlayAfterCap: patch.allowPlayAfterCap }
        : {}),
      ...(patch.maxWinsByRarity !== undefined
        ? {
            maxWinsByRarity: {
              ...prevConfig.maxWinsByRarity,
              ...patch.maxWinsByRarity,
            },
          }
        : {}),
      ...(patch.minSpinsBetweenWins !== undefined
        ? { minSpinsBetweenWins: patch.minSpinsBetweenWins }
        : {}),
      ...(patch.bonusProbability !== undefined
        ? { bonusProbability: patch.bonusProbability }
        : {}),
      ...(patch.bonusMinTickets !== undefined
        ? { bonusMinTickets: patch.bonusMinTickets }
        : {}),
      ...(patch.bonusMaxTickets !== undefined
        ? { bonusMaxTickets: patch.bonusMaxTickets }
        : {}),
      ...(patch.maxBonusWinsPerUser !== undefined
        ? { maxBonusWinsPerUser: patch.maxBonusWinsPerUser }
        : {}),
      ...(patch.wildReplacementChance !== undefined
        ? { wildReplacementChance: patch.wildReplacementChance }
        : {}),
      ...(patch.spinCooldownMs !== undefined
        ? { spinCooldownMs: patch.spinCooldownMs }
        : {}),
      ...(patch.maxTotalEarnedTicketsPerUser !== undefined
        ? { maxTotalEarnedTicketsPerUser: patch.maxTotalEarnedTicketsPerUser }
        : {}),
      ...(patch.maxManualGrantPerAction !== undefined
        ? { maxManualGrantPerAction: patch.maxManualGrantPerAction }
        : {}),
      ...(patch.maxManualTicketsPerUser !== undefined
        ? { maxManualTicketsPerUser: patch.maxManualTicketsPerUser }
        : {}),
      updatedAtMs: nowMs,
      updatedBy: admin.uid,
    };

    if (merged.bonusMinTickets > merged.bonusMaxTickets) {
      throwSpinError(
        'invalid-argument',
        'bonusMinTickets must be <= bonusMaxTickets.',
      );
    }
    if (
      merged.pacingStartAtMs !== null &&
      merged.pacingEndAtMs !== null &&
      merged.pacingEndAtMs <= merged.pacingStartAtMs
    ) {
      throwSpinError(
        'invalid-argument',
        'pacingEndAt must be after pacingStartAt.',
      );
    }

    const firestorePayload: Record<string, unknown> = {
      status: merged.status,
      pauseMessage: merged.pauseMessage,
      ticketCostPerSpin: merged.ticketCostPerSpin,
      defaultInitialTickets: merged.defaultInitialTickets,
      packageTicketBonus: merged.packageTicketBonus,
      matchRegistrationByEmail: merged.matchRegistrationByEmail,
      registeredAttendeesCount: merged.registeredAttendeesCount,
      expectedSpinsPerAttendee: merged.expectedSpinsPerAttendee,
      estimatedTotalSpinsOverride: merged.estimatedTotalSpinsOverride,
      pacingMode: merged.pacingMode,
      pacingStartAt: toTimestampOrNull(merged.pacingStartAtMs),
      pacingEndAt: toTimestampOrNull(merged.pacingEndAtMs),
      pacingCurveGamma: merged.pacingCurveGamma,
      pacingWaves: merged.pacingWaves.map((wave) => ({
        id: wave.id,
        label: wave.label,
        startAt: Timestamp.fromMillis(wave.startAtMs),
        releaseRatio: wave.releaseRatio,
        spinBudgetShare: wave.spinBudgetShare,
      })),
      rushMode: merged.rushMode,
      rushBypassUnlockAt: merged.rushBypassUnlockAt,
      payoutMultiplier: merged.payoutMultiplier,
      maxWinProbabilityPerSpin: merged.maxWinProbabilityPerSpin,
      rushMaxWinProbabilityPerSpin: merged.rushMaxWinProbabilityPerSpin,
      maxPrizesPerUser: merged.maxPrizesPerUser,
      allowPlayAfterCap: merged.allowPlayAfterCap,
      maxWinsByRarity: merged.maxWinsByRarity,
      minSpinsBetweenWins: merged.minSpinsBetweenWins,
      bonusProbability: merged.bonusProbability,
      bonusMinTickets: merged.bonusMinTickets,
      bonusMaxTickets: merged.bonusMaxTickets,
      maxBonusWinsPerUser: merged.maxBonusWinsPerUser,
      wildReplacementChance: merged.wildReplacementChance,
      spinCooldownMs: merged.spinCooldownMs,
      maxTotalEarnedTicketsPerUser: merged.maxTotalEarnedTicketsPerUser,
      maxManualGrantPerAction: merged.maxManualGrantPerAction,
      maxManualTicketsPerUser: merged.maxManualTicketsPerUser,
      updatedAt: nowTs,
      updatedBy: admin.uid,
    };

    tx.set(configRef, firestorePayload);

    const changedKeys = Object.keys(patch);
    writeSpinAuditLog(tx, db, input.eventId, {
      action: 'update_spin_config',
      actorUid: admin.uid,
      actorName: admin.name,
      targetId: 'main',
      summary: `Updated spinConfig fields: ${changedKeys.join(', ')}`,
      metadata: {
        changedKeys,
        previousStatus: prevConfig.status,
        nextStatus: merged.status,
        previousRushMode: prevConfig.rushMode,
        nextRushMode: merged.rushMode,
      },
      createdAt: nowTs,
    });

    return merged;
  });

  return {
    config: toSpinConfigDto(updatedConfig),
  };
}

export async function executeAdminUpsertSpinPrize(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: AdminExecutionOptions = {},
): Promise<AdminUpsertSpinPrizeResponseDto> {
  const admin = await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminUpsertSpinPrizeSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const txResult = await db.runTransaction(async (tx) => {
    const prizeId = input.prize.id ?? spinPrizesCol(db, input.eventId).doc().id;
    const prizeRef = spinPrizeDoc(db, input.eventId, prizeId);
    const prizeSnap = await tx.get(prizeRef);

    if (prizeSnap.exists) {
      if (
        input.prize.initialStock !== undefined ||
        input.prize.remainingStock !== undefined
      ) {
        throwSpinError(
          'invalid-argument',
          'Cannot modify initialStock or remainingStock directly on update; use adminAdjustPrizeStock.',
          'STOCK_IMMUTABLE_ON_UPDATE',
        );
      }

      const existing = parseSpinPrize(prizeSnap.id, prizeSnap.data() ?? {});
      const nextReleasedStock =
        input.prize.releasedStock !== undefined
          ? input.prize.releasedStock
          : existing.releasedStock;

      if (nextReleasedStock > existing.initialStock) {
        throwSpinError(
          'invalid-argument',
          'releasedStock cannot exceed initialStock.',
          'INVALID_STOCK_ADJUSTMENT',
        );
      }

      const updated: SpinPrize = {
        ...existing,
        name: input.prize.name,
        description: input.prize.description,
        symbol: input.prize.symbol,
        imageUrl: input.prize.imageUrl,
        rarity: input.prize.rarity,
        releasedStock: nextReleasedStock,
        maxPerUser: input.prize.maxPerUser,
        weight: input.prize.weight,
        unlockAtMs: input.prize.unlockAt,
        active: input.prize.active,
        order: input.prize.order,
        updatedAtMs: nowMs,
      };

      tx.update(prizeRef, {
        name: updated.name,
        description: updated.description,
        symbol: updated.symbol,
        imageUrl: updated.imageUrl,
        rarity: updated.rarity,
        releasedStock: updated.releasedStock,
        maxPerUser: updated.maxPerUser,
        weight: updated.weight,
        unlockAt: toTimestampOrNull(updated.unlockAtMs),
        active: updated.active,
        order: updated.order,
        updatedAt: nowTs,
      });

      writeSpinAuditLog(tx, db, input.eventId, {
        action: 'update_spin_prize',
        actorUid: admin.uid,
        actorName: admin.name,
        targetId: prizeId,
        summary: `Updated prize "${updated.name}"`,
        metadata: { prizeId, active: updated.active, order: updated.order },
        createdAt: nowTs,
      });

      return { prize: updated, created: false };
    }

    if (input.prize.initialStock === undefined) {
      throwSpinError(
        'invalid-argument',
        'initialStock is required when creating a new prize.',
      );
    }
    if (
      input.prize.remainingStock !== undefined &&
      input.prize.remainingStock !== input.prize.initialStock
    ) {
      throwSpinError(
        'invalid-argument',
        'On create, remainingStock must equal initialStock or be omitted.',
        'INVALID_STOCK_ADJUSTMENT',
      );
    }

    const initialStock = input.prize.initialStock;
    const releasedStock =
      input.prize.releasedStock !== undefined
        ? Math.min(initialStock, input.prize.releasedStock)
        : initialStock;

    const createdPrize: SpinPrize = {
      id: prizeId,
      name: input.prize.name,
      description: input.prize.description,
      symbol: input.prize.symbol,
      imageUrl: input.prize.imageUrl,
      rarity: input.prize.rarity,
      initialStock,
      remainingStock: initialStock,
      awardedCount: 0,
      redeemedCount: 0,
      releasedStock,
      maxPerUser: input.prize.maxPerUser,
      weight: input.prize.weight,
      unlockAtMs: input.prize.unlockAt,
      active: input.prize.active,
      order: input.prize.order,
      updatedAtMs: nowMs,
    };

    tx.set(prizeRef, {
      id: createdPrize.id,
      name: createdPrize.name,
      description: createdPrize.description,
      symbol: createdPrize.symbol,
      imageUrl: createdPrize.imageUrl,
      rarity: createdPrize.rarity,
      initialStock: createdPrize.initialStock,
      remainingStock: createdPrize.remainingStock,
      awardedCount: 0,
      redeemedCount: 0,
      releasedStock: createdPrize.releasedStock,
      maxPerUser: createdPrize.maxPerUser,
      weight: createdPrize.weight,
      unlockAt: toTimestampOrNull(createdPrize.unlockAtMs),
      active: createdPrize.active,
      order: createdPrize.order,
      updatedAt: nowTs,
    });

    writeSpinAuditLog(tx, db, input.eventId, {
      action: 'create_spin_prize',
      actorUid: admin.uid,
      actorName: admin.name,
      targetId: prizeId,
      summary: `Created prize "${createdPrize.name}" with stock ${initialStock}`,
      metadata: {
        prizeId,
        rarity: createdPrize.rarity,
        initialStock,
      },
      createdAt: nowTs,
    });

    return { prize: createdPrize, created: true };
  });

  if (!txResult.prize.active || txResult.prize.remainingStock <= 0) {
    await tryCloseGameIfPrizesExhausted(db, input.eventId, nowMs);
  }

  return {
    prize: toSpinPrizeDto(txResult.prize),
    created: txResult.created,
  };
}

export async function executeAdminAdjustPrizeStock(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: AdminExecutionOptions = {},
): Promise<AdminAdjustPrizeStockResponseDto> {
  const admin = await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminAdjustPrizeStockSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const updatedPrize = await db.runTransaction(async (tx) => {
    const prizeRef = spinPrizeDoc(db, input.eventId, input.prizeId);
    const prizeSnap = await tx.get(prizeRef);
    if (!prizeSnap.exists) {
      throwSpinError('not-found', 'Prize not found.');
    }

    const existing = parseSpinPrize(prizeSnap.id, prizeSnap.data() ?? {});
    const newInitial = existing.initialStock + input.delta;
    const newRemaining = existing.remainingStock + input.delta;

    if (newRemaining < 0 || newInitial < existing.awardedCount) {
      throwSpinError(
        'failed-precondition',
        'Stock adjustment would make remainingStock negative.',
        'INVALID_STOCK_ADJUSTMENT',
      );
    }

    // Support atomic releasedStock increments/decrements without overwriting metadata.
    const newReleased =
      input.releasedDelta !== undefined
        ? Math.min(
            newInitial,
            Math.max(0, existing.releasedStock + input.releasedDelta),
          )
        : existing.releasedStock === existing.initialStock
          ? newInitial
          : Math.min(newInitial, Math.max(0, existing.releasedStock));

    const nextPrize: SpinPrize = {
      ...existing,
      initialStock: newInitial,
      remainingStock: newRemaining,
      releasedStock: newReleased,
      updatedAtMs: nowMs,
    };

    tx.update(prizeRef, {
      initialStock: newInitial,
      remainingStock: newRemaining,
      releasedStock: newReleased,
      updatedAt: nowTs,
    });

    writeSpinAuditLog(tx, db, input.eventId, {
      action: 'adjust_prize_stock',
      actorUid: admin.uid,
      actorName: admin.name,
      targetId: input.prizeId,
      summary: `Adjusted prize stock (delta=${input.delta}, releasedDelta=${input.releasedDelta ?? 0}): ${input.reason}`,
      metadata: {
        prizeId: input.prizeId,
        delta: input.delta,
        releasedDelta: input.releasedDelta ?? 0,
        reason: input.reason,
        previousInitialStock: existing.initialStock,
        newInitialStock: newInitial,
        previousRemainingStock: existing.remainingStock,
        newRemainingStock: newRemaining,
        previousReleasedStock: existing.releasedStock,
        newReleasedStock: newReleased,
      },
      createdAt: nowTs,
    });

    return nextPrize;
  });

  if (updatedPrize.remainingStock <= 0) {
    await tryCloseGameIfPrizesExhausted(db, input.eventId, nowMs);
  }

  return {
    prize: toSpinPrizeDto(updatedPrize),
  };
}
