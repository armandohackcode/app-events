import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { generateTicketSerial } from '../../domain/codes';
import {
  spinSubmitTalkQuestionSchema,
  spinSubmitTalkRatingSchema,
} from '../../domain/schemas';
import type {
  SpinPlayer,
  SpinSubmitTalkQuestionResponseDto,
  SpinSubmitTalkRatingResponseDto,
} from '../../domain/types';
import type { CallerIdentity } from '../../services/auth';
import {
  buildEmptySpinPlayerRecord,
  parseInput,
  parseSpinConfig,
  parseSpinMission,
  parseSpinPlayer,
  throwSpinError,
  toEpochMs,
} from '../../services/converters';
import {
  competitorDoc,
  ratingDoc,
  spinConfigDoc,
  spinMissionClaimDoc,
  spinMissionDoc,
  spinPlayerDoc,
} from '../../services/firestorePaths';
import { incrementStatsShard, writeTicketLedgerEntry } from '../../services/ledger';
import {
  buildNewQuestionRef,
  evaluateAskSpeakerProgress,
  evaluateRatedTalkIds,
  findActiveMissionsByType,
  getTalkQuestionStatsForUser,
  isMissionWithinWindow,
} from '../../services/missionEvaluator';

const QUESTION_COOLDOWN_MS = 30_000;
const MAX_QUESTIONS_PER_TALK = 3;

export interface TalkInteractionExecutionOptions {
  nowMs?: number;
}

export async function executeSpinSubmitTalkQuestion(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: TalkInteractionExecutionOptions = {},
): Promise<SpinSubmitTalkQuestionResponseDto> {
  const input = parseInput(spinSubmitTalkQuestionSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const [questionStats, competitorSnap, activeAskMissions] = await Promise.all([
    getTalkQuestionStatsForUser(
      db,
      input.eventId,
      input.speakerUuid,
      caller.uid,
    ),
    competitorDoc(db, caller.uid).get(),
    findActiveMissionsByType(db, input.eventId, 'ask_speaker', nowMs),
  ]);

  const targetMission = activeAskMissions[0] ?? null;
  const priorAskProgress = targetMission
    ? await evaluateAskSpeakerProgress(
        db,
        input.eventId,
        caller.uid,
        input.speakerUuid,
      )
    : 0;

  const compData = competitorSnap.exists ? (competitorSnap.data() ?? {}) : {};
  const authorName =
    (typeof compData.name === 'string' && compData.name.trim()) ||
    caller.displayName ||
    'Asistente';
  const authorPhotoUrl =
    (typeof compData.photoUrl === 'string' && compData.photoUrl.trim()) ||
    caller.photoUrl ||
    '';

  const txResult = await db.runTransaction(async (tx) => {
    const playerRef = spinPlayerDoc(db, input.eventId, caller.uid);
    const configRef = spinConfigDoc(db, input.eventId);

    // Phase A: All transaction reads FIRST
    const playerSnap = await tx.get(playerRef);
    const configSnap = targetMission ? await tx.get(configRef) : null;
    const missionSnap = targetMission
      ? await tx.get(spinMissionDoc(db, input.eventId, targetMission.id))
      : null;
    const claimSnap = targetMission
      ? await tx.get(
          spinMissionClaimDoc(
            db,
            input.eventId,
            caller.uid,
            targetMission.id,
          ),
        )
      : null;

    const playerRaw = playerSnap.exists ? (playerSnap.data() ?? {}) : {};
    const player: SpinPlayer = playerSnap.exists
      ? parseSpinPlayer(caller.uid, playerRaw)
      : parseSpinPlayer(
          caller.uid,
          buildEmptySpinPlayerRecord({
            uid: caller.uid,
            displayName: authorName,
            email: caller.email,
            nowTs,
          }),
        );

    const playerLastQuestionMs = toEpochMs(playerRaw.lastQuestionAt);
    const latestQuestionMs =
      playerLastQuestionMs !== null && questionStats.lastCreatedAtMs !== null
        ? Math.max(playerLastQuestionMs, questionStats.lastCreatedAtMs)
        : (playerLastQuestionMs ?? questionStats.lastCreatedAtMs);

    if (
      latestQuestionMs !== null &&
      nowMs - latestQuestionMs < QUESTION_COOLDOWN_MS
    ) {
      throwSpinError(
        'failed-precondition',
        'Please wait 30 seconds before submitting another question.',
        'RATE_LIMITED',
      );
    }

    const rawCountsByTalk =
      typeof playerRaw.questionCountsByTalk === 'object' &&
      playerRaw.questionCountsByTalk !== null
        ? (playerRaw.questionCountsByTalk as Record<string, unknown>)
        : {};
    const playerTalkCount =
      typeof rawCountsByTalk[input.speakerUuid] === 'number'
        ? Math.max(0, Math.trunc(rawCountsByTalk[input.speakerUuid] as number))
        : 0;
    const effectiveTalkCount = Math.max(
      questionStats.countInTalk,
      playerTalkCount,
    );

    if (effectiveTalkCount >= MAX_QUESTIONS_PER_TALK) {
      throwSpinError(
        'failed-precondition',
        'You have reached the maximum of 3 questions for this talk.',
        'QUESTION_LIMIT_REACHED',
      );
    }

    // Evaluate mission auto-reward eligibility in memory from preloaded snapshots
    let missionRewarded = false;
    let ticketsAwarded = 0;
    let ticketSerial: string | null = null;
    let qualifiedCompletions = 0;
    let prevAwardedTotal = 0;
    let rewardedMissionTitle = '';
    let rewardedMissionId = '';

    if (
      targetMission &&
      configSnap?.exists &&
      missionSnap?.exists
    ) {
      const config = parseSpinConfig(configSnap.data() ?? {});
      const mission = parseSpinMission(missionSnap.id, missionSnap.data() ?? {});
      if (
        mission.type === 'ask_speaker' &&
        isMissionWithinWindow(mission, nowMs)
      ) {
        const claimData = claimSnap?.exists ? (claimSnap.data() ?? {}) : {};
        const currentCompletions =
          typeof claimData.completions === 'number'
            ? Math.max(0, Math.trunc(claimData.completions))
            : 0;
        prevAwardedTotal =
          typeof claimData.ticketsAwardedTotal === 'number'
            ? Math.max(0, Math.trunc(claimData.ticketsAwardedTotal))
            : 0;

        if (currentCompletions < mission.maxCompletionsPerUser) {
          const newProgressCount = priorAskProgress + 1;
          qualifiedCompletions = Math.min(
            mission.maxCompletionsPerUser,
            Math.floor(newProgressCount / Math.max(1, mission.targetCount)),
          );
          if (qualifiedCompletions > currentCompletions) {
            const rawReward =
              (qualifiedCompletions - currentCompletions) *
              mission.rewardTickets;
            if (config.maxTotalEarnedTicketsPerUser > 0) {
              const room = Math.max(
                0,
                config.maxTotalEarnedTicketsPerUser - player.totalTicketsEarned,
              );
              ticketsAwarded = Math.min(rawReward, room);
            } else {
              ticketsAwarded = rawReward;
            }
            if (ticketsAwarded > 0) {
              missionRewarded = true;
              ticketSerial = generateTicketSerial();
              rewardedMissionTitle = mission.title;
              rewardedMissionId = mission.id;
            }
          }
        }
      }
    }

    // Phase B: All transaction writes AFTER all reads
    const questionRef = buildNewQuestionRef(
      db,
      input.eventId,
      input.speakerUuid,
    );
    tx.set(questionRef, {
      id: questionRef.id,
      uid: caller.uid,
      authorName,
      authorPhotoUrl,
      text: input.text,
      answered: false,
      hidden: false,
      createdAt: nowTs,
    });

    const ticketsAfter = player.tickets + ticketsAwarded;
    const totalTicketsEarnedAfter = player.totalTicketsEarned + ticketsAwarded;
    const nextCountsByTalk = {
      ...rawCountsByTalk,
      [input.speakerUuid]: effectiveTalkCount + 1,
    };

    if (!playerSnap.exists) {
      tx.set(playerRef, {
        ...buildEmptySpinPlayerRecord({
          uid: caller.uid,
          displayName: authorName,
          email: caller.email,
          nowTs,
        }),
        tickets: ticketsAfter,
        totalTicketsEarned: totalTicketsEarnedAfter,
        lastQuestionAt: nowTs,
        questionCountsByTalk: nextCountsByTalk,
      });
    } else {
      tx.update(playerRef, {
        tickets: ticketsAfter,
        totalTicketsEarned: totalTicketsEarnedAfter,
        lastQuestionAt: nowTs,
        questionCountsByTalk: nextCountsByTalk,
        updatedAt: nowTs,
      });
    }

    if (missionRewarded && rewardedMissionId) {
      const claimRef = spinMissionClaimDoc(
        db,
        input.eventId,
        caller.uid,
        rewardedMissionId,
      );
      const prevCreatedAt = claimSnap?.exists
        ? (claimSnap.data()?.createdAt as Timestamp | undefined)
        : undefined;
      tx.set(
        claimRef,
        {
          uid: caller.uid,
          missionId: rewardedMissionId,
          type: 'ask_speaker',
          completions: qualifiedCompletions,
          ticketsAwardedTotal: prevAwardedTotal + ticketsAwarded,
          lastClaimedAt: nowTs,
          createdAt: prevCreatedAt ?? nowTs,
          updatedAt: nowTs,
        },
        { merge: true },
      );

      writeTicketLedgerEntry(tx, db, input.eventId, {
        uid: caller.uid,
        delta: ticketsAwarded,
        balanceAfter: ticketsAfter,
        source: 'mission',
        referenceId: rewardedMissionId,
        note: rewardedMissionTitle,
        actorUid: caller.uid,
        createdAt: nowTs,
        docId: `mission_${caller.uid}_${rewardedMissionId}_${qualifiedCompletions}`,
      });
    }

    return {
      questionId: questionRef.id,
      missionRewarded,
      ticketsAwarded,
      ticketsAfter,
      ticketSerial,
    } satisfies SpinSubmitTalkQuestionResponseDto;
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

export async function executeSpinSubmitTalkRating(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: TalkInteractionExecutionOptions = {},
): Promise<SpinSubmitTalkRatingResponseDto> {
  const input = parseInput(spinSubmitTalkRatingSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const activeRateMissions = await findActiveMissionsByType(
    db,
    input.eventId,
    'rate_talk',
    nowMs,
  );
  const targetMission = activeRateMissions[0] ?? null;

  const existingRatedTalkIds = targetMission
    ? await evaluateRatedTalkIds(
        db,
        input.eventId,
        caller.uid,
        input.speakerUuid,
      )
    : [];

  const txResult = await db.runTransaction(async (tx) => {
    const rateRef = ratingDoc(
      db,
      input.eventId,
      input.speakerUuid,
      caller.uid,
    );
    const playerRef = spinPlayerDoc(db, input.eventId, caller.uid);
    const configRef = spinConfigDoc(db, input.eventId);

    // Phase A: All transaction reads FIRST
    const [rateSnap, playerSnap, configSnap, missionSnap, claimSnap] =
      await Promise.all([
        tx.get(rateRef),
        tx.get(playerRef),
        targetMission ? tx.get(configRef) : Promise.resolve(null),
        targetMission
          ? tx.get(spinMissionDoc(db, input.eventId, targetMission.id))
          : Promise.resolve(null),
        targetMission
          ? tx.get(
              spinMissionClaimDoc(
                db,
                input.eventId,
                caller.uid,
                targetMission.id,
              ),
            )
          : Promise.resolve(null),
      ]);

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

    let missionRewarded = false;
    let ticketsAwarded = 0;
    let ticketSerial: string | null = null;
    let qualifiedCompletions = 0;
    let prevAwardedTotal = 0;
    let nextCountedTalkIds: string[] = [];
    let rewardedMissionTitle = '';
    let rewardedMissionId = '';

    if (
      targetMission &&
      configSnap?.exists &&
      missionSnap?.exists
    ) {
      const config = parseSpinConfig(configSnap.data() ?? {});
      const mission = parseSpinMission(missionSnap.id, missionSnap.data() ?? {});
      if (
        mission.type === 'rate_talk' &&
        isMissionWithinWindow(mission, nowMs)
      ) {
        const claimData = claimSnap?.exists ? (claimSnap.data() ?? {}) : {};
        const currentCompletions =
          typeof claimData.completions === 'number'
            ? Math.max(0, Math.trunc(claimData.completions))
            : 0;
        prevAwardedTotal =
          typeof claimData.ticketsAwardedTotal === 'number'
            ? Math.max(0, Math.trunc(claimData.ticketsAwardedTotal))
            : 0;
        const previousCounted = Array.isArray(claimData.countedTalkIds)
          ? claimData.countedTalkIds.filter(
              (id): id is string => typeof id === 'string',
            )
          : [];

        nextCountedTalkIds = Array.from(
          new Set([
            ...previousCounted,
            ...existingRatedTalkIds,
            input.speakerUuid,
          ]),
        );

        if (currentCompletions < mission.maxCompletionsPerUser) {
          qualifiedCompletions = Math.min(
            mission.maxCompletionsPerUser,
            Math.floor(
              nextCountedTalkIds.length / Math.max(1, mission.targetCount),
            ),
          );
          if (qualifiedCompletions > currentCompletions) {
            const rawReward =
              (qualifiedCompletions - currentCompletions) *
              mission.rewardTickets;
            if (config.maxTotalEarnedTicketsPerUser > 0) {
              const room = Math.max(
                0,
                config.maxTotalEarnedTicketsPerUser - player.totalTicketsEarned,
              );
              ticketsAwarded = Math.min(rawReward, room);
            } else {
              ticketsAwarded = rawReward;
            }
            if (ticketsAwarded > 0) {
              missionRewarded = true;
              ticketSerial = generateTicketSerial();
              rewardedMissionTitle = mission.title;
              rewardedMissionId = mission.id;
            }
          }
        }
      }
    }

    // Phase B: All transaction writes AFTER all reads
    const existingRatingCreatedAt =
      (rateSnap.exists
        ? (rateSnap.data()?.createdAt as Timestamp | undefined)
        : undefined) ?? nowTs;

    tx.set(rateRef, {
      uid: caller.uid,
      stars: input.stars,
      comment: input.comment,
      createdAt: existingRatingCreatedAt,
      updatedAt: nowTs,
    });

    const ticketsAfter = player.tickets + ticketsAwarded;
    const totalTicketsEarnedAfter = player.totalTicketsEarned + ticketsAwarded;

    if (missionRewarded && rewardedMissionId) {
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

      const claimRef = spinMissionClaimDoc(
        db,
        input.eventId,
        caller.uid,
        rewardedMissionId,
      );
      const prevClaimCreatedAt = claimSnap?.exists
        ? (claimSnap.data()?.createdAt as Timestamp | undefined)
        : undefined;
      tx.set(
        claimRef,
        {
          uid: caller.uid,
          missionId: rewardedMissionId,
          type: 'rate_talk',
          completions: qualifiedCompletions,
          countedTalkIds: nextCountedTalkIds,
          ticketsAwardedTotal: prevAwardedTotal + ticketsAwarded,
          lastClaimedAt: nowTs,
          createdAt: prevClaimCreatedAt ?? nowTs,
          updatedAt: nowTs,
        },
        { merge: true },
      );

      writeTicketLedgerEntry(tx, db, input.eventId, {
        uid: caller.uid,
        delta: ticketsAwarded,
        balanceAfter: ticketsAfter,
        source: 'mission',
        referenceId: rewardedMissionId,
        note: rewardedMissionTitle,
        actorUid: caller.uid,
        createdAt: nowTs,
        docId: `mission_${caller.uid}_${rewardedMissionId}_${qualifiedCompletions}`,
      });
    }

    return {
      saved: true,
      missionRewarded,
      ticketsAwarded,
      ticketsAfter,
      ticketSerial,
    } satisfies SpinSubmitTalkRatingResponseDto;
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
