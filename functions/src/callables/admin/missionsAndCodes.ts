import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  adminUpsertSpinMissionSchema,
  adminUpsertTicketCodeSchema,
} from '../../domain/schemas';
import type {
  AdminUpsertSpinMissionResponseDto,
  AdminUpsertTicketCodeResponseDto,
  SpinMission,
  SpinTicketCode,
} from '../../domain/types';
import type { CallerIdentity } from '../../services/auth';
import { assertIsAdmin } from '../../services/auth';
import {
  parseInput,
  parseSpinMission,
  parseSpinTicketCode,
  throwSpinError,
  toSpinMissionDto,
  toSpinTicketCodeDto,
  toTimestampOrNull,
} from '../../services/converters';
import {
  spinMissionDoc,
  spinMissionSecretDoc,
  spinMissionsCol,
  spinTicketCodeDoc,
  spinTicketCodesCol,
} from '../../services/firestorePaths';
import { writeSpinAuditLog } from '../../services/ledger';
import type { AdminExecutionOptions } from './configAndPrizes';

export async function executeAdminUpsertSpinMission(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: AdminExecutionOptions = {},
): Promise<AdminUpsertSpinMissionResponseDto> {
  const admin = await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminUpsertSpinMissionSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const txResult = await db.runTransaction(async (tx) => {
    const rawMission = input.mission;
    if (!('type' in rawMission)) {
      const missionRef = spinMissionDoc(db, input.eventId, rawMission.id);
      const missionSnap = await tx.get(missionRef);
      if (!missionSnap.exists) {
        throwSpinError('not-found', 'Mission not found.');
      }

      const existing = parseSpinMission(
        missionSnap.id,
        missionSnap.data() ?? {},
      );
      const updatedMission: SpinMission = {
        ...existing,
        active: rawMission.active,
        updatedAtMs: nowMs,
      };

      tx.update(missionRef, {
        active: updatedMission.active,
        updatedAt: nowTs,
      });

      writeSpinAuditLog(tx, db, input.eventId, {
        action: 'update_spin_mission',
        actorUid: admin.uid,
        actorName: admin.name,
        targetId: rawMission.id,
        summary: `Toggled mission "${updatedMission.title}" active=${updatedMission.active}`,
        metadata: {
          missionId: rawMission.id,
          type: updatedMission.type,
          active: updatedMission.active,
          toggleOnly: true,
        },
        createdAt: nowTs,
      });

      return { mission: updatedMission, created: false };
    }

    const missionId =
      rawMission.id ?? spinMissionsCol(db, input.eventId).doc().id;
    const missionRef = spinMissionDoc(db, input.eventId, missionId);
    const secretRef = spinMissionSecretDoc(db, input.eventId, missionId);

    const [missionSnap, secretSnap] = await Promise.all([
      tx.get(missionRef),
      tx.get(secretRef),
    ]);

    const created = !missionSnap.exists;

    if (rawMission.type === 'trivia') {
      if (created && !input.secret) {
        throwSpinError(
          'invalid-argument',
          'Trivia missions require secret (correctOptionIndex) when created.',
          'INVALID_SECRET',
        );
      }
      if (!created && !input.secret && !secretSnap.exists) {
        throwSpinError(
          'invalid-argument',
          'Trivia mission is missing secret configuration.',
          'INVALID_SECRET',
        );
      }
    }

    const missionObj: SpinMission = {
      id: missionId,
      type: rawMission.type,
      title: rawMission.title,
      description: rawMission.description,
      rewardTickets: rawMission.rewardTickets,
      targetCount: rawMission.targetCount,
      maxCompletionsPerUser: rawMission.maxCompletionsPerUser,
      actionLabel: rawMission.actionLabel,
      active: rawMission.active,
      order: rawMission.order,
      startsAtMs: rawMission.startsAt,
      endsAtMs: rawMission.endsAt,
      config: { ...rawMission.config },
      updatedAtMs: nowMs,
    };

    tx.set(missionRef, {
      id: missionObj.id,
      type: missionObj.type,
      title: missionObj.title,
      description: missionObj.description,
      rewardTickets: missionObj.rewardTickets,
      targetCount: missionObj.targetCount,
      maxCompletionsPerUser: missionObj.maxCompletionsPerUser,
      actionLabel: missionObj.actionLabel,
      active: missionObj.active,
      order: missionObj.order,
      startsAt: toTimestampOrNull(missionObj.startsAtMs),
      endsAt: toTimestampOrNull(missionObj.endsAtMs),
      config: missionObj.config,
      updatedAt: nowTs,
    });

    if (rawMission.type === 'trivia' && input.secret) {
      tx.set(secretRef, {
        correctOptionIndex: input.secret.correctOptionIndex,
        explanation: input.secret.explanation,
      });
    }

    writeSpinAuditLog(tx, db, input.eventId, {
      action: created ? 'create_spin_mission' : 'update_spin_mission',
      actorUid: admin.uid,
      actorName: admin.name,
      targetId: missionId,
      summary: `${created ? 'Created' : 'Updated'} mission "${missionObj.title}" (${missionObj.type})`,
      metadata: {
        missionId,
        type: missionObj.type,
        active: missionObj.active,
        rewardTickets: missionObj.rewardTickets,
        secretUpdated: Boolean(input.secret),
      },
      createdAt: nowTs,
    });

    return { mission: missionObj, created };
  });

  return {
    mission: toSpinMissionDto(txResult.mission),
    created: txResult.created,
  };
}

export async function executeAdminUpsertTicketCode(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: AdminExecutionOptions = {},
): Promise<AdminUpsertTicketCodeResponseDto> {
  const admin = await assertIsAdmin(db, caller.uid);
  const input = parseInput(adminUpsertTicketCodeSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const txResult = await db.runTransaction(async (tx) => {
    const codeId =
      input.codeConfig.id ?? spinTicketCodesCol(db, input.eventId).doc().id;
    const codeRef = spinTicketCodeDoc(db, input.eventId, codeId);
    const duplicateQuery = spinTicketCodesCol(db, input.eventId).where(
      'code',
      '==',
      input.codeConfig.code,
    );

    const [existingSnap, duplicateSnap] = await Promise.all([
      tx.get(codeRef),
      tx.get(duplicateQuery),
    ]);

    for (const dupDoc of duplicateSnap.docs) {
      if (dupDoc.id !== codeId) {
        throwSpinError(
          'already-exists',
          `Ticket code "${input.codeConfig.code}" already exists in this event.`,
          'CODE_ALREADY_EXISTS',
        );
      }
    }

    const created = !existingSnap.exists;
    const existing = existingSnap.exists
      ? parseSpinTicketCode(existingSnap.id, existingSnap.data() ?? {})
      : null;

    const ticketCode: SpinTicketCode = {
      id: codeId,
      code: input.codeConfig.code,
      label: input.codeConfig.label,
      rewardTickets: input.codeConfig.rewardTickets,
      maxTotalUses: input.codeConfig.maxTotalUses,
      usedCount: existing ? existing.usedCount : 0,
      maxUsesPerUser: input.codeConfig.maxUsesPerUser,
      active: input.codeConfig.active,
      startsAtMs: input.codeConfig.startsAt,
      endsAtMs: input.codeConfig.endsAt,
      createdAtMs: existing?.createdAtMs ?? nowMs,
      createdBy: existing?.createdBy || admin.uid,
    };

    tx.set(codeRef, {
      id: ticketCode.id,
      code: ticketCode.code,
      label: ticketCode.label,
      rewardTickets: ticketCode.rewardTickets,
      maxTotalUses: ticketCode.maxTotalUses,
      usedCount: ticketCode.usedCount,
      maxUsesPerUser: ticketCode.maxUsesPerUser,
      active: ticketCode.active,
      startsAt: toTimestampOrNull(ticketCode.startsAtMs),
      endsAt: toTimestampOrNull(ticketCode.endsAtMs),
      createdAt: existing?.createdAtMs
        ? Timestamp.fromMillis(existing.createdAtMs)
        : nowTs,
      createdBy: ticketCode.createdBy,
    });

    writeSpinAuditLog(tx, db, input.eventId, {
      action: created ? 'create_ticket_code' : 'update_ticket_code',
      actorUid: admin.uid,
      actorName: admin.name,
      targetId: codeId,
      summary: `${created ? 'Created' : 'Updated'} stand ticket code "${ticketCode.code}"`,
      metadata: {
        codeId,
        code: ticketCode.code,
        active: ticketCode.active,
        maxTotalUses: ticketCode.maxTotalUses,
        rewardTickets: ticketCode.rewardTickets,
      },
      createdAt: nowTs,
    });

    return { ticketCode, created };
  });

  return {
    ticketCode: toSpinTicketCodeDto(txResult.ticketCode),
    created: txResult.created,
  };
}
