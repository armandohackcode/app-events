import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  CodeParseError,
  generateTicketSerial,
  parseStandCodeInput,
} from '../../domain/codes';
import { spinRedeemTicketCodeSchema } from '../../domain/schemas';
import type { SpinRedeemTicketCodeResponseDto } from '../../domain/types';
import type { CallerIdentity } from '../../services/auth';
import {
  buildEmptySpinPlayerRecord,
  parseInput,
  parseSpinConfig,
  parseSpinPlayer,
  parseSpinTicketCode,
  throwSpinError,
} from '../../services/converters';
import {
  spinCodeClaimDoc,
  spinConfigDoc,
  spinPlayerDoc,
  spinTicketCodeDoc,
  spinTicketCodesCol,
} from '../../services/firestorePaths';
import { incrementStatsShard, writeTicketLedgerEntry } from '../../services/ledger';

export interface RedeemTicketCodeExecutionOptions {
  nowMs?: number;
}

export async function executeSpinRedeemTicketCode(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: RedeemTicketCodeExecutionOptions = {},
): Promise<SpinRedeemTicketCodeResponseDto> {
  const input = parseInput(spinRedeemTicketCodeSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  let normalizedCode: string;
  try {
    normalizedCode = parseStandCodeInput(input.code, input.eventId);
  } catch (error) {
    if (error instanceof CodeParseError) {
      throwSpinError('invalid-argument', error.message, error.reason);
    }
    throw error;
  }

  const matchingCodes = await spinTicketCodesCol(db, input.eventId)
    .where('code', '==', normalizedCode)
    .limit(1)
    .get();

  if (matchingCodes.empty) {
    throwSpinError('not-found', 'Ticket code not found.');
  }

  const codeId = matchingCodes.docs[0].id;

  const txResult = await db.runTransaction(async (tx) => {
    const configRef = spinConfigDoc(db, input.eventId);
    const codeRef = spinTicketCodeDoc(db, input.eventId, codeId);
    const claimRef = spinCodeClaimDoc(db, input.eventId, caller.uid, codeId);
    const playerRef = spinPlayerDoc(db, input.eventId, caller.uid);

    const [configSnap, codeSnap, claimSnap, playerSnap] = await Promise.all([
      tx.get(configRef),
      tx.get(codeRef),
      tx.get(claimRef),
      tx.get(playerRef),
    ]);

    if (!configSnap.exists) {
      throwSpinError(
        'failed-precondition',
        'Spin configuration has not been initialized for this event.',
        'CONFIG_NOT_FOUND',
      );
    }
    if (!codeSnap.exists) {
      throwSpinError('not-found', 'Ticket code not found.');
    }

    const config = parseSpinConfig(configSnap.data() ?? {});
    const ticketCode = parseSpinTicketCode(codeSnap.id, codeSnap.data() ?? {});

    if (
      !ticketCode.active ||
      (ticketCode.startsAtMs !== null && nowMs < ticketCode.startsAtMs) ||
      (ticketCode.endsAtMs !== null && nowMs > ticketCode.endsAtMs)
    ) {
      throwSpinError(
        'failed-precondition',
        'This ticket code is inactive or expired.',
        'CODE_EXPIRED',
      );
    }

    const prevUses = claimSnap.exists
      ? Math.max(
          1,
          typeof claimSnap.data()?.usesCount === 'number'
            ? Math.trunc(claimSnap.data()!.usesCount as number)
            : 1,
        )
      : 0;

    if (prevUses >= ticketCode.maxUsesPerUser) {
      throwSpinError(
        'already-exists',
        'You have already redeemed this ticket code.',
      );
    }

    if (ticketCode.usedCount >= ticketCode.maxTotalUses) {
      throwSpinError(
        'resource-exhausted',
        'This ticket code has reached its maximum uses.',
        'CODE_DEPLETED',
      );
    }

    const player = playerSnap.exists
      ? parseSpinPlayer(caller.uid, playerSnap.data() ?? {})
      : parseSpinPlayer(
          caller.uid,
          buildEmptySpinPlayerRecord({
            uid: caller.uid,
            displayName: caller.displayName,
            email: caller.email,
            nowTs,
          }),
        );

    let ticketsAwarded = ticketCode.rewardTickets;
    if (config.maxTotalEarnedTicketsPerUser > 0) {
      const remainingRoom = Math.max(
        0,
        config.maxTotalEarnedTicketsPerUser - player.totalTicketsEarned,
      );
      if (remainingRoom <= 0) {
        throwSpinError(
          'failed-precondition',
          'Maximum earned tickets per user limit reached.',
          'TICKET_CAP_REACHED',
        );
      }
      ticketsAwarded = Math.min(ticketCode.rewardTickets, remainingRoom);
    }

    const ticketsAfter = player.tickets + ticketsAwarded;
    const totalTicketsEarnedAfter = player.totalTicketsEarned + ticketsAwarded;
    const ticketSerial = generateTicketSerial();

    tx.update(codeRef, {
      usedCount: ticketCode.usedCount + 1,
    });

    const prevClaimedAt = claimSnap.exists
      ? (claimSnap.data()?.claimedAt as Timestamp | undefined)
      : undefined;
    tx.set(
      claimRef,
      {
        uid: caller.uid,
        codeId: ticketCode.id,
        code: ticketCode.code,
        usesCount: prevUses + 1,
        claimedAt: prevClaimedAt ?? nowTs,
        updatedAt: nowTs,
      },
      { merge: true },
    );

    if (!playerSnap.exists) {
      tx.set(playerRef, {
        ...buildEmptySpinPlayerRecord({
          uid: caller.uid,
          displayName: caller.displayName,
          email: caller.email,
          nowTs,
        }),
        tickets: ticketsAfter,
        totalTicketsEarned: totalTicketsEarnedAfter,
      });
    } else {
      tx.update(playerRef, {
        tickets: ticketsAfter,
        totalTicketsEarned: totalTicketsEarnedAfter,
        updatedAt: nowTs,
      });
    }

    writeTicketLedgerEntry(tx, db, input.eventId, {
      uid: caller.uid,
      delta: ticketsAwarded,
      balanceAfter: ticketsAfter,
      source: 'stand_code',
      referenceId: ticketCode.id,
      note: ticketCode.label,
      actorUid: caller.uid,
      createdAt: nowTs,
      docId: `code_${caller.uid}_${ticketCode.id}_${prevUses + 1}`,
    });

    return {
      label: ticketCode.label,
      ticketsAwarded,
      ticketsAfter,
      ticketSerial,
    } satisfies SpinRedeemTicketCodeResponseDto;
  });

  if (txResult.ticketsAwarded > 0) {
    try {
      await incrementStatsShard(db, input.eventId, caller.uid, {
        totalTicketsIssued: txResult.ticketsAwarded,
      });
    } catch {
      // Non-blocking stats shard increment.
    }
  }

  return txResult;
}
