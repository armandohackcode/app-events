import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { generateTicketSerial } from '../../domain/codes';
import {
  spinClaimMissionSchema,
  spinSubmitTriviaSchema,
} from '../../domain/schemas';
import type {
  SpinClaimMissionResponseDto,
  SpinSubmitTriviaResponseDto,
} from '../../domain/types';
import type { CallerIdentity } from '../../services/auth';
import {
  buildEmptySpinPlayerRecord,
  parseInput,
  parseSpinConfig,
  parseSpinMission,
  parseSpinPlayer,
  throwSpinError,
} from '../../services/converters';
import {
  spinConfigDoc,
  spinMissionClaimDoc,
  spinMissionDoc,
  spinMissionSecretDoc,
  spinPlayerDoc,
} from '../../services/firestorePaths';
import { incrementStatsShard, writeTicketLedgerEntry } from '../../services/ledger';
import {
  applyMissionRewardInTx,
  evaluateMissionProgress,
  isMissionWithinWindow,
} from '../../services/missionEvaluator';

export interface MissionExecutionOptions {
  nowMs?: number;
}

export async function executeSpinClaimMission(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: MissionExecutionOptions = {},
): Promise<SpinClaimMissionResponseDto> {
  const input = parseInput(spinClaimMissionSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();

  const missionSnap = await spinMissionDoc(
    db,
    input.eventId,
    input.missionId,
  ).get();
  if (!missionSnap.exists) {
    throwSpinError('not-found', 'Mission not found.');
  }

  const mission = parseSpinMission(missionSnap.id, missionSnap.data() ?? {});
  if (mission.type === 'trivia') {
    throwSpinError(
      'failed-precondition',
      'Trivia missions must be submitted via spinSubmitTrivia.',
    );
  }
  if (!isMissionWithinWindow(mission, nowMs)) {
    throwSpinError(
      'failed-precondition',
      'Mission is currently inactive or outside its active window.',
      'MISSION_INACTIVE',
    );
  }

  const progress = await evaluateMissionProgress(
    db,
    input.eventId,
    caller.uid,
    mission,
  );

  const rewardResult = await db.runTransaction((tx) =>
    applyMissionRewardInTx({
      tx,
      db,
      eventId: input.eventId,
      caller,
      missionId: input.missionId,
      progress,
      nowMs,
      throwOnNotEligible: true,
    }),
  );

  if (rewardResult.ticketsAwarded > 0) {
    try {
      await incrementStatsShard(db, input.eventId, caller.uid, {
        totalTicketsIssued: rewardResult.ticketsAwarded,
      });
    } catch {
      // Non-blocking stats shard increment.
    }
  }

  return {
    granted: rewardResult.rewarded,
    ticketsAwarded: rewardResult.ticketsAwarded,
    ticketsAfter: rewardResult.ticketsAfter,
    ticketSerial: rewardResult.ticketSerial ?? generateTicketSerial(),
  };
}

export async function executeSpinSubmitTrivia(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: MissionExecutionOptions = {},
): Promise<SpinSubmitTriviaResponseDto> {
  const input = parseInput(spinSubmitTriviaSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const txResult = await db.runTransaction(async (tx) => {
    const configRef = spinConfigDoc(db, input.eventId);
    const missionRef = spinMissionDoc(db, input.eventId, input.missionId);
    const secretRef = spinMissionSecretDoc(db, input.eventId, input.missionId);
    const claimRef = spinMissionClaimDoc(
      db,
      input.eventId,
      caller.uid,
      input.missionId,
    );
    const playerRef = spinPlayerDoc(db, input.eventId, caller.uid);

    const [configSnap, missionSnap, secretSnap, claimSnap, playerSnap] =
      await Promise.all([
        tx.get(configRef),
        tx.get(missionRef),
        tx.get(secretRef),
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
    if (!missionSnap.exists) {
      throwSpinError('not-found', 'Trivia mission not found.');
    }

    const config = parseSpinConfig(configSnap.data() ?? {});
    const mission = parseSpinMission(missionSnap.id, missionSnap.data() ?? {});

    if (mission.type !== 'trivia') {
      throwSpinError(
        'failed-precondition',
        'Specified mission is not a trivia mission.',
      );
    }

    if (!isMissionWithinWindow(mission, nowMs)) {
      throwSpinError(
        'failed-precondition',
        'Trivia is currently closed.',
        'TRIVIA_CLOSED',
      );
    }

    const optionsList = mission.config.options ?? [];
    if (
      optionsList.length > 0 &&
      input.selectedIndex >= optionsList.length
    ) {
      throwSpinError(
        'invalid-argument',
        'selectedIndex is out of range for trivia options.',
      );
    }

    if (!secretSnap.exists) {
      throwSpinError(
        'failed-precondition',
        'Trivia answer configuration is missing.',
        'TRIVIA_CLOSED',
      );
    }

    if (claimSnap.exists) {
      throwSpinError(
        'already-exists',
        'You have already answered this trivia.',
      );
    }

    const secretData = secretSnap.data() ?? {};
    const correctOptionIndex =
      typeof secretData.correctOptionIndex === 'number'
        ? Math.trunc(secretData.correctOptionIndex)
        : -1;
    const explanation =
      typeof secretData.explanation === 'string' ? secretData.explanation : '';

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

    const correct = input.selectedIndex === correctOptionIndex;
    let ticketsAwarded = 0;
    let ticketSerial: string | null = null;

    if (correct) {
      if (config.maxTotalEarnedTicketsPerUser > 0) {
        const remainingRoom = Math.max(
          0,
          config.maxTotalEarnedTicketsPerUser - player.totalTicketsEarned,
        );
        ticketsAwarded = Math.min(mission.rewardTickets, remainingRoom);
      } else {
        ticketsAwarded = mission.rewardTickets;
      }
      if (ticketsAwarded > 0) {
        ticketSerial = generateTicketSerial();
      }
    }

    const ticketsAfter = player.tickets + ticketsAwarded;
    const totalTicketsEarnedAfter = player.totalTicketsEarned + ticketsAwarded;

    tx.set(claimRef, {
      uid: caller.uid,
      missionId: mission.id,
      type: 'trivia',
      selectedIndex: input.selectedIndex,
      correct,
      completions: 1,
      ticketsAwardedTotal: ticketsAwarded,
      lastClaimedAt: nowTs,
      createdAt: nowTs,
      updatedAt: nowTs,
    });

    if (ticketsAwarded > 0) {
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
        source: 'trivia',
        referenceId: mission.id,
        note: mission.title,
        actorUid: caller.uid,
        createdAt: nowTs,
        docId: `trivia_${caller.uid}_${mission.id}`,
      });
    }

    return {
      response: {
        correct,
        explanation,
        ticketsAwarded,
        ticketsAfter,
        ticketSerial,
      } satisfies SpinSubmitTriviaResponseDto,
    };
  });

  if (txResult.response.ticketsAwarded > 0) {
    try {
      await incrementStatsShard(db, input.eventId, caller.uid, {
        totalTicketsIssued: txResult.response.ticketsAwarded,
      });
    } catch {
      // Non-blocking stats shard increment.
    }
  }

  return txResult.response;
}
