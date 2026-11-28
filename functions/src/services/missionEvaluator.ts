import { Timestamp, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { generateTicketSerial } from '../domain/codes';
import type { EpochMs, SpinConfig, SpinMission, SpinPlayer } from '../domain/types';
import {
  buildEmptySpinPlayerRecord,
  parseSpinConfig,
  parseSpinMission,
  parseSpinPlayer,
  throwSpinError,
} from './converters';
import {
  competitorDoc,
  questionDoc,
  questionsCol,
  ratingDoc,
  scheduleCol,
  spinConfigDoc,
  spinMissionClaimDoc,
  spinMissionDoc,
  spinMissionsCol,
  spinPlayerDoc,
  workshowCol,
} from './firestorePaths';
import { writeTicketLedgerEntry } from './ledger';
import type { CallerIdentity } from './auth';

export function isMissionWithinWindow(
  mission: SpinMission,
  nowMs: EpochMs,
): boolean {
  if (!mission.active) return false;
  if (mission.startsAtMs !== null && nowMs < mission.startsAtMs) return false;
  if (mission.endsAtMs !== null && nowMs > mission.endsAtMs) return false;
  return true;
}

async function listScheduleIds(
  db: Firestore,
  eventId: string,
  extraSpeakerUuid?: string,
): Promise<string[]> {
  const refs = await scheduleCol(db, eventId).listDocuments();
  const ids = new Set<string>(refs.map((ref) => ref.id));
  if (extraSpeakerUuid) {
    ids.add(extraSpeakerUuid);
  }
  return Array.from(ids);
}

export async function evaluateProfileCompleteProgress(
  db: Firestore,
  uid: string,
  mission: SpinMission,
): Promise<number> {
  const snap = await competitorDoc(db, uid).get();
  if (!snap.exists) return 0;
  const data = snap.data() ?? {};
  const minAboutMeLength =
    typeof mission.config.minAboutMeLength === 'number' &&
    Number.isFinite(mission.config.minAboutMeLength)
      ? Math.max(0, Math.trunc(mission.config.minAboutMeLength))
      : 200;
  const profession =
    typeof data.profession === 'string' ? data.profession.trim() : '';
  const aboutMe = typeof data.aboutMe === 'string' ? data.aboutMe.trim() : '';

  return profession.length > 0 && aboutMe.length >= minAboutMeLength ? 1 : 0;
}

export async function evaluateWorkshopRegisterProgress(
  db: Firestore,
  eventId: string,
  uid: string,
): Promise<number> {
  const speakerIds = await listScheduleIds(db, eventId);
  if (speakerIds.length === 0) return 0;

  const checks = await Promise.all(
    speakerIds.map((speakerId) =>
      workshowCol(db, eventId, speakerId).where('uuid', '==', uid).limit(1).get(),
    ),
  );
  return checks.filter((snap) => !snap.empty).length;
}

export async function evaluateAskSpeakerProgress(
  db: Firestore,
  eventId: string,
  uid: string,
  extraSpeakerUuid?: string,
): Promise<number> {
  const speakerIds = await listScheduleIds(db, eventId, extraSpeakerUuid);
  if (speakerIds.length === 0) return 0;

  const snaps = await Promise.all(
    speakerIds.map((speakerId) =>
      questionsCol(db, eventId, speakerId).where('uid', '==', uid).get(),
    ),
  );

  let count = 0;
  for (const snap of snaps) {
    for (const docSnap of snap.docs) {
      if (docSnap.data().hidden !== true) {
        count += 1;
      }
    }
  }
  return count;
}

export async function evaluateRatedTalkIds(
  db: Firestore,
  eventId: string,
  uid: string,
  extraSpeakerUuid?: string,
): Promise<string[]> {
  const speakerIds = await listScheduleIds(db, eventId, extraSpeakerUuid);
  if (speakerIds.length === 0) return [];

  const snaps = await Promise.all(
    speakerIds.map((speakerId) => ratingDoc(db, eventId, speakerId, uid).get()),
  );
  const ratedIds: string[] = [];
  for (let i = 0; i < speakerIds.length; i += 1) {
    if (snaps[i].exists) {
      ratedIds.push(speakerIds[i]);
    }
  }
  return ratedIds;
}

export interface MissionProgressSnapshot {
  progressCount: number;
  ratedTalkIds: string[];
}

export async function evaluateMissionProgress(
  db: Firestore,
  eventId: string,
  uid: string,
  mission: SpinMission,
): Promise<MissionProgressSnapshot> {
  switch (mission.type) {
    case 'profile_complete': {
      const count = await evaluateProfileCompleteProgress(db, uid, mission);
      return { progressCount: count, ratedTalkIds: [] };
    }
    case 'workshop_register': {
      const count = await evaluateWorkshopRegisterProgress(db, eventId, uid);
      return { progressCount: count, ratedTalkIds: [] };
    }
    case 'ask_speaker': {
      const count = await evaluateAskSpeakerProgress(db, eventId, uid);
      return { progressCount: count, ratedTalkIds: [] };
    }
    case 'rate_talk': {
      const ratedTalkIds = await evaluateRatedTalkIds(db, eventId, uid);
      return { progressCount: ratedTalkIds.length, ratedTalkIds };
    }
    case 'trivia':
      return { progressCount: 0, ratedTalkIds: [] };
  }
}

export interface ClaimMissionInTxResult {
  rewarded: boolean;
  ticketsAwarded: number;
  ticketsAfter: number;
  ticketSerial: string | null;
}

/**
 * Evaluates and grants a non-trivia mission reward inside an existing Firestore transaction.
 * Throws when `throwOnNotEligible` is true (used by `spinClaimMission`); returns
 * `{ rewarded: false }` quietly when `throwOnNotEligible` is false (auto-evaluation hooks).
 */
export async function applyMissionRewardInTx(params: {
  tx: Transaction;
  db: Firestore;
  eventId: string;
  caller: CallerIdentity;
  missionId: string;
  progress: MissionProgressSnapshot;
  nowMs: EpochMs;
  throwOnNotEligible: boolean;
  /** Optional pre-fetched snapshots if caller already read them in the same tx. */
  preloadedConfig?: SpinConfig;
  preloadedPlayer?: { exists: boolean; data: SpinPlayer };
  /** If caller already updated player fields in tx, pass effective balance & earned counters. */
  actorNotePrefix?: string;
}): Promise<ClaimMissionInTxResult> {
  const {
    tx,
    db,
    eventId,
    caller,
    missionId,
    progress,
    nowMs,
    throwOnNotEligible,
  } = params;

  const missionRef = spinMissionDoc(db, eventId, missionId);
  const claimRef = spinMissionClaimDoc(db, eventId, caller.uid, missionId);
  const playerRef = spinPlayerDoc(db, eventId, caller.uid);
  const configRef = spinConfigDoc(db, eventId);

  const missionSnap = await tx.get(missionRef);
  if (!missionSnap.exists) {
    if (throwOnNotEligible) {
      throwSpinError('not-found', 'Mission not found.');
    }
    return {
      rewarded: false,
      ticketsAwarded: 0,
      ticketsAfter: params.preloadedPlayer?.data.tickets ?? 0,
      ticketSerial: null,
    };
  }

  const mission = parseSpinMission(missionSnap.id, missionSnap.data() ?? {});
  if (mission.type === 'trivia') {
    if (throwOnNotEligible) {
      throwSpinError(
        'failed-precondition',
        'Trivia missions must be submitted via spinSubmitTrivia.',
      );
    }
    return {
      rewarded: false,
      ticketsAwarded: 0,
      ticketsAfter: params.preloadedPlayer?.data.tickets ?? 0,
      ticketSerial: null,
    };
  }

  if (!isMissionWithinWindow(mission, nowMs)) {
    if (throwOnNotEligible) {
      throwSpinError(
        'failed-precondition',
        'Mission is currently inactive or outside its active window.',
        'MISSION_INACTIVE',
      );
    }
    return {
      rewarded: false,
      ticketsAwarded: 0,
      ticketsAfter: params.preloadedPlayer?.data.tickets ?? 0,
      ticketSerial: null,
    };
  }

  let config = params.preloadedConfig;
  if (!config) {
    const configSnap = await tx.get(configRef);
    if (!configSnap.exists) {
      if (throwOnNotEligible) {
        throwSpinError(
          'failed-precondition',
          'Spin configuration has not been initialized for this event.',
          'CONFIG_NOT_FOUND',
        );
      }
      return {
        rewarded: false,
        ticketsAwarded: 0,
        ticketsAfter: params.preloadedPlayer?.data.tickets ?? 0,
        ticketSerial: null,
      };
    }
    config = parseSpinConfig(configSnap.data() ?? {});
  }

  const claimSnap = await tx.get(claimRef);
  let playerExists: boolean;
  let player: SpinPlayer;
  if (params.preloadedPlayer) {
    playerExists = params.preloadedPlayer.exists;
    player = params.preloadedPlayer.data;
  } else {
    const playerSnap = await tx.get(playerRef);
    playerExists = playerSnap.exists;
    player = playerSnap.exists
      ? parseSpinPlayer(caller.uid, playerSnap.data() ?? {})
      : parseSpinPlayer(
          caller.uid,
          buildEmptySpinPlayerRecord({
            uid: caller.uid,
            displayName: caller.displayName,
            email: caller.email,
            nowTs: Timestamp.fromMillis(nowMs),
          }),
        );
  }

  const claimData = claimSnap.exists ? (claimSnap.data() ?? {}) : {};
  const currentCompletions =
    typeof claimData.completions === 'number'
      ? Math.max(0, Math.trunc(claimData.completions))
      : 0;

  if (currentCompletions >= mission.maxCompletionsPerUser) {
    if (throwOnNotEligible) {
      throwSpinError(
        'already-exists',
        'Mission has already reached its maximum completions.',
      );
    }
    return {
      rewarded: false,
      ticketsAwarded: 0,
      ticketsAfter: player.tickets,
      ticketSerial: null,
    };
  }

  let nextCountedTalkIds: string[] = [];
  let effectiveCount = progress.progressCount;

  if (mission.type === 'rate_talk') {
    const previousCounted = Array.isArray(claimData.countedTalkIds)
      ? claimData.countedTalkIds.filter(
          (id): id is string => typeof id === 'string',
        )
      : [];
    nextCountedTalkIds = Array.from(
      new Set([...previousCounted, ...progress.ratedTalkIds]),
    );
    effectiveCount = nextCountedTalkIds.length;
  }

  const qualifiedCompletions = Math.min(
    mission.maxCompletionsPerUser,
    Math.floor(effectiveCount / Math.max(1, mission.targetCount)),
  );

  if (qualifiedCompletions <= currentCompletions) {
    if (throwOnNotEligible) {
      throwSpinError(
        'failed-precondition',
        'Mission requirements are not met yet.',
        'REQUIREMENT_NOT_MET',
      );
    }
    return {
      rewarded: false,
      ticketsAwarded: 0,
      ticketsAfter: player.tickets,
      ticketSerial: null,
    };
  }

  const deltaCompletions = qualifiedCompletions - currentCompletions;
  const rawReward = deltaCompletions * mission.rewardTickets;

  let ticketsAwarded = rawReward;
  if (config.maxTotalEarnedTicketsPerUser > 0) {
    const remainingRoom = Math.max(
      0,
      config.maxTotalEarnedTicketsPerUser - player.totalTicketsEarned,
    );
    if (remainingRoom <= 0) {
      if (throwOnNotEligible) {
        throwSpinError(
          'failed-precondition',
          'Maximum earned tickets per user limit reached.',
          'TICKET_CAP_REACHED',
        );
      }
      return {
        rewarded: false,
        ticketsAwarded: 0,
        ticketsAfter: player.tickets,
        ticketSerial: null,
      };
    }
    ticketsAwarded = Math.min(rawReward, remainingRoom);
  }

  const nowTs = Timestamp.fromMillis(nowMs);
  const newBalance = player.tickets + ticketsAwarded;
  const newTotalEarned = player.totalTicketsEarned + ticketsAwarded;
  const ticketSerial = generateTicketSerial();

  if (!playerExists) {
    tx.set(playerRef, {
      ...buildEmptySpinPlayerRecord({
        uid: caller.uid,
        displayName: caller.displayName,
        email: caller.email,
        nowTs,
      }),
      tickets: newBalance,
      totalTicketsEarned: newTotalEarned,
    });
  } else {
    tx.update(playerRef, {
      tickets: newBalance,
      totalTicketsEarned: newTotalEarned,
      updatedAt: nowTs,
    });
  }

  const prevAwardedTotal =
    typeof claimData.ticketsAwardedTotal === 'number'
      ? Math.max(0, Math.trunc(claimData.ticketsAwardedTotal))
      : 0;

  const claimPayload: Record<string, unknown> = {
    uid: caller.uid,
    missionId: mission.id,
    type: mission.type,
    completions: qualifiedCompletions,
    ticketsAwardedTotal: prevAwardedTotal + ticketsAwarded,
    lastClaimedAt: nowTs,
    updatedAt: nowTs,
  };
  if (!claimSnap.exists) {
    claimPayload.createdAt = nowTs;
  }
  if (mission.type === 'rate_talk') {
    claimPayload.countedTalkIds = nextCountedTalkIds;
  }
  tx.set(claimRef, claimPayload, { merge: true });

  writeTicketLedgerEntry(tx, db, eventId, {
    uid: caller.uid,
    delta: ticketsAwarded,
    balanceAfter: newBalance,
    source: 'mission',
    referenceId: mission.id,
    note: mission.title,
    actorUid: caller.uid,
    createdAt: nowTs,
    docId: `mission_${caller.uid}_${mission.id}_${qualifiedCompletions}`,
  });

  return {
    rewarded: true,
    ticketsAwarded,
    ticketsAfter: newBalance,
    ticketSerial,
  };
}

export async function findActiveMissionsByType(
  db: Firestore,
  eventId: string,
  type: 'ask_speaker' | 'rate_talk',
  nowMs: EpochMs,
): Promise<SpinMission[]> {
  const snap = await spinMissionsCol(db, eventId)
    .where('type', '==', type)
    .where('active', '==', true)
    .get();
  return snap.docs
    .map((d) => parseSpinMission(d.id, d.data()))
    .filter((m) => isMissionWithinWindow(m, nowMs))
    .sort((a, b) => a.order - b.order);
}

/**
 * Counts existing valid questions by `uid` on a single talk and returns the most recent creation timestamp.
 */
export async function getTalkQuestionStatsForUser(
  db: Firestore,
  eventId: string,
  speakerUuid: string,
  uid: string,
): Promise<{ countInTalk: number; lastCreatedAtMs: EpochMs | null }> {
  const snap = await questionsCol(db, eventId, speakerUuid)
    .where('uid', '==', uid)
    .get();

  let countInTalk = 0;
  let lastCreatedAtMs: EpochMs | null = null;
  for (const docSnap of snap.docs) {
    const data = docSnap.data();
    if (data.hidden !== true) {
      countInTalk += 1;
    }
    const createdAt: unknown = data.createdAt;
    if (createdAt instanceof Timestamp) {
      const ms = createdAt.toMillis();
      if (lastCreatedAtMs === null || ms > lastCreatedAtMs) {
        lastCreatedAtMs = ms;
      }
    }
  }
  return { countInTalk, lastCreatedAtMs };
}

export function buildNewQuestionRef(
  db: Firestore,
  eventId: string,
  speakerUuid: string,
) {
  return questionDoc(
    db,
    eventId,
    speakerUuid,
    questionsCol(db, eventId, speakerUuid).doc().id,
  );
}
