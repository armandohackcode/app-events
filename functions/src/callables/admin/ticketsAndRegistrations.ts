import { randomUUID } from 'node:crypto';
import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { generateTicketSerial, hashEmail } from '../../domain/codes';
import {
  adminGrantTicketsSchema,
  adminImportRegistrationsSchema,
} from '../../domain/schemas';
import type {
  AdminGrantTicketsResponseDto,
  AdminImportRegistrationsResponseDto,
} from '../../domain/types';
import type { CallerIdentity } from '../../services/auth';
import { assertIsAdmin } from '../../services/auth';
import {
  buildEmptySpinPlayerRecord,
  parseInput,
  parseSpinConfig,
  parseSpinPlayer,
  throwSpinError,
} from '../../services/converters';
import {
  competitorDoc,
  spinConfigDoc,
  spinImportLockDoc,
  spinPlayerDoc,
  spinRegistrationDoc,
  spinRegistrationsCol,
  ticketLedgerDoc,
} from '../../services/firestorePaths';
import {
  incrementStatsShard,
  saveSpinAuditLog,
  writeSpinAuditLog,
  writeTicketLedgerEntry,
} from '../../services/ledger';
import type { AdminExecutionOptions } from './configAndPrizes';

const FIRESTORE_BATCH_LIMIT = 400;
const IMPORT_LOCK_TTL_MS = 2 * 60 * 1000;

export async function executeAdminGrantTickets(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: AdminExecutionOptions = {},
): Promise<AdminGrantTicketsResponseDto> {
  const admin = await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminGrantTicketsSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const txResult = await db.runTransaction(async (tx) => {
    const ledgerDocId = `admin_grant_${input.requestId}`;
    const ledgerRef = ticketLedgerDoc(db, input.eventId, ledgerDocId);
    const configRef = spinConfigDoc(db, input.eventId);
    const playerRef = spinPlayerDoc(db, input.eventId, input.targetUid);
    const targetCompetitorRef = competitorDoc(db, input.targetUid);

    const [ledgerSnap, configSnap, playerSnap, competitorSnap] =
      await Promise.all([
        tx.get(ledgerRef),
        tx.get(configRef),
        tx.get(playerRef),
        tx.get(targetCompetitorRef),
      ]);

    if (ledgerSnap.exists) {
      const prev = ledgerSnap.data() ?? {};
      if (prev.uid !== input.targetUid) {
        throwSpinError(
          'already-exists',
          'requestId has already been used for a different user.',
        );
      }
      const existingTickets = playerSnap.exists
        ? parseSpinPlayer(input.targetUid, playerSnap.data() ?? {}).tickets
        : typeof prev.balanceAfter === 'number'
          ? Math.trunc(prev.balanceAfter)
          : 0;
      const serial =
        typeof prev.ticketSerial === 'string' && prev.ticketSerial
          ? prev.ticketSerial
          : generateTicketSerial();
      const awarded =
        typeof prev.delta === 'number' ? Math.trunc(prev.delta) : input.amount;

      return {
        response: {
          targetUid: input.targetUid,
          ticketsAwarded: awarded,
          ticketsAfter: existingTickets,
          ticketSerial: serial,
          idempotentReplay: true,
        } satisfies AdminGrantTicketsResponseDto,
        ticketsIssuedDelta: 0,
      };
    }

    if (!configSnap.exists) {
      throwSpinError(
        'failed-precondition',
        'Spin configuration has not been initialized for this event.',
        'CONFIG_NOT_FOUND',
      );
    }

    const config = parseSpinConfig(configSnap.data() ?? {});

    if (input.amount > config.maxManualGrantPerAction) {
      throwSpinError(
        'failed-precondition',
        `Grant amount exceeds maxManualGrantPerAction (${config.maxManualGrantPerAction}).`,
        'MANUAL_GRANT_CAP_REACHED',
      );
    }

    const compData = competitorSnap.exists ? (competitorSnap.data() ?? {}) : {};
    const displayName =
      typeof compData.name === 'string' && compData.name.trim()
        ? compData.name.trim()
        : 'Asistente';

    const player = playerSnap.exists
      ? parseSpinPlayer(input.targetUid, playerSnap.data() ?? {})
      : parseSpinPlayer(
          input.targetUid,
          buildEmptySpinPlayerRecord({
            uid: input.targetUid,
            displayName,
            email: '',
            nowTs,
          }),
        );

    if (
      config.maxManualTicketsPerUser > 0 &&
      player.manualTicketsGranted + input.amount > config.maxManualTicketsPerUser
    ) {
      throwSpinError(
        'failed-precondition',
        `Grant exceeds maxManualTicketsPerUser (${config.maxManualTicketsPerUser}).`,
        'MANUAL_GRANT_CAP_REACHED',
      );
    }

    const ticketsAfter = player.tickets + input.amount;
    const totalTicketsEarnedAfter = player.totalTicketsEarned + input.amount;
    const manualTicketsGrantedAfter =
      player.manualTicketsGranted + input.amount;
    const ticketSerial = generateTicketSerial();

    if (!playerSnap.exists) {
      tx.set(playerRef, {
        ...buildEmptySpinPlayerRecord({
          uid: input.targetUid,
          displayName,
          email: '',
          nowTs,
        }),
        tickets: ticketsAfter,
        totalTicketsEarned: totalTicketsEarnedAfter,
        manualTicketsGranted: manualTicketsGrantedAfter,
      });
    } else {
      tx.update(playerRef, {
        tickets: ticketsAfter,
        totalTicketsEarned: totalTicketsEarnedAfter,
        manualTicketsGranted: manualTicketsGrantedAfter,
        updatedAt: nowTs,
      });
    }

    tx.set(ledgerRef, {
      uid: input.targetUid,
      delta: input.amount,
      balanceAfter: ticketsAfter,
      source: 'manual_admin',
      referenceId: input.requestId,
      note: input.reason,
      actorUid: admin.uid,
      ticketSerial,
      createdAt: nowTs,
    });

    // Avoid unused import warning while keeping ledger entry consistent
    void writeTicketLedgerEntry;

    writeSpinAuditLog(tx, db, input.eventId, {
      action: 'grant_tickets',
      actorUid: admin.uid,
      actorName: admin.name,
      targetId: input.targetUid,
      summary: `Granted ${input.amount} ticket(s) manually: ${input.reason}`,
      metadata: {
        targetUid: input.targetUid,
        amount: input.amount,
        reason: input.reason,
        requestId: input.requestId,
        ticketsAfter,
      },
      createdAt: nowTs,
    });

    return {
      response: {
        targetUid: input.targetUid,
        ticketsAwarded: input.amount,
        ticketsAfter,
        ticketSerial,
        idempotentReplay: false,
      } satisfies AdminGrantTicketsResponseDto,
      ticketsIssuedDelta: input.amount,
    };
  });

  if (txResult.ticketsIssuedDelta > 0) {
    try {
      await incrementStatsShard(db, input.eventId, input.targetUid, {
        totalTicketsIssued: txResult.ticketsIssuedDelta,
      });
    } catch {
      // Non-blocking stats shard increment.
    }
  }

  return txResult.response;
}

export async function executeAdminImportRegistrations(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: AdminExecutionOptions = {},
): Promise<AdminImportRegistrationsResponseDto> {
  const admin = await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminImportRegistrationsSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const dedupedByHash = new Map<
    string,
    {
      emailNormalized: string;
      fullName: string;
      package: string;
      checkedIn: boolean;
    }
  >();

  for (const row of input.rows) {
    const emailNormalized = row.email.trim().toLowerCase();
    const emailHash = hashEmail(emailNormalized);
    dedupedByHash.set(emailHash, {
      emailNormalized,
      fullName: row.fullName,
      package: row.package,
      checkedIn: row.checkedIn,
    });
  }

  const lockRef = spinImportLockDoc(db, input.eventId);
  const lockOwner = randomUUID();
  if (input.replaceAll) {
    await db.runTransaction(async (tx) => {
      const lockSnap = await tx.get(lockRef);
      if (lockSnap.exists) {
        const lockData = lockSnap.data() ?? {};
        const expiresAtMs =
          typeof lockData.expiresAtMs === 'number' ? lockData.expiresAtMs : 0;
        if (expiresAtMs > nowMs) {
          throwSpinError(
            'aborted',
            'Another registration import with replaceAll is currently in progress.',
          );
        }
      }
      tx.set(lockRef, {
        owner: lockOwner,
        actorUid: admin.uid,
        acquiredAtMs: nowMs,
        expiresAtMs: nowMs + IMPORT_LOCK_TTL_MS,
      });
    });
  }

  try {
    const existingSnap = await spinRegistrationsCol(db, input.eventId)
      .select()
      .get();
    const existingHashes = new Set(
      existingSnap.docs.map((docSnap) => docSnap.id),
    );

    let importedCount = 0;
    let updatedCount = 0;

    const entries = Array.from(dedupedByHash.entries());
    for (let i = 0; i < entries.length; i += FIRESTORE_BATCH_LIMIT) {
      const chunk = entries.slice(i, i + FIRESTORE_BATCH_LIMIT);
      const batch = db.batch();
      for (const [emailHash, reg] of chunk) {
        if (existingHashes.has(emailHash)) {
          updatedCount += 1;
        } else {
          importedCount += 1;
        }
        batch.set(spinRegistrationDoc(db, input.eventId, emailHash), {
          emailNormalized: reg.emailNormalized,
          fullName: reg.fullName,
          package: reg.package,
          checkedIn: reg.checkedIn,
          importedAt: nowTs,
          importedBy: admin.uid,
        });
      }
      await batch.commit();
    }

    let deletedCount = 0;
    if (input.replaceAll) {
      const toDelete = Array.from(existingHashes).filter(
        (hash) => !dedupedByHash.has(hash),
      );
      for (let i = 0; i < toDelete.length; i += FIRESTORE_BATCH_LIMIT) {
        const chunk = toDelete.slice(i, i + FIRESTORE_BATCH_LIMIT);
        const batch = db.batch();
        for (const hash of chunk) {
          batch.delete(spinRegistrationDoc(db, input.eventId, hash));
        }
        await batch.commit();
        deletedCount += chunk.length;
      }
    }

    const countSnap = await spinRegistrationsCol(db, input.eventId)
      .count()
      .get();
    const totalRegistrationsCount = countSnap.data().count;

    const configRef = spinConfigDoc(db, input.eventId);
    const configSnap = await configRef.get();
    if (configSnap.exists) {
      await configRef.update({
        registeredAttendeesCount: totalRegistrationsCount,
        updatedAt: nowTs,
        updatedBy: admin.uid,
      });
    } else {
      await configRef.set(
        {
          registeredAttendeesCount: totalRegistrationsCount,
          updatedAt: nowTs,
          updatedBy: admin.uid,
        },
        { merge: true },
      );
    }

    // Audit log stores counts only — ZERO PII (no emails or names).
    await saveSpinAuditLog(db, input.eventId, {
      action: 'import_registrations',
      actorUid: admin.uid,
      actorName: admin.name,
      targetId: null,
      summary: `Imported registrations (created=${importedCount}, updated=${updatedCount}, deleted=${deletedCount}, total=${totalRegistrationsCount})`,
      metadata: {
        importedCount,
        updatedCount,
        deletedCount,
        totalRegistrationsCount,
        replaceAll: input.replaceAll,
      },
      createdAt: nowTs,
    });

    return {
      importedCount,
      updatedCount,
      totalRegistrationsCount,
    };
  } finally {
    if (input.replaceAll) {
      try {
        await db.runTransaction(async (tx) => {
          const lockSnap = await tx.get(lockRef);
          if (lockSnap.exists && lockSnap.data()?.owner === lockOwner) {
            tx.delete(lockRef);
          }
        });
      } catch {
        // Best-effort lock release; TTL prevents permanent deadlock.
      }
    }
  }
}
