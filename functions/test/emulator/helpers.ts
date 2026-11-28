import { getApps, initializeApp } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { expect } from 'vitest';
import type { CallerIdentity } from '../../src/services/auth';
import {
  STAT_SHARD_COUNT,
  spinConfigDoc,
  spinMissionDoc,
  spinMissionSecretDoc,
  spinPlayerDoc,
  spinPrizeDoc,
  spinStatsShardDoc,
  ticketLedgerCol,
  usersAdminDoc,
} from '../../src/services/firestorePaths';

export const TEST_PROJECT_ID = 'demo-gdgsucre-events';
export const TEST_EVENT_ID = 'evt-devfest-2026';
export const ADMIN_UID = 'admin-1';

export function getEmulatorFirestore(): Firestore {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
  }
  if (getApps().length === 0) {
    initializeApp({ projectId: TEST_PROJECT_ID });
  }
  return getFirestore();
}

export async function clearEmulatorFirestore(): Promise<void> {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';
  const url = `http://${host}/emulator/v1/projects/${TEST_PROJECT_ID}/databases/(default)/documents`;
  const response = await fetch(url, { method: 'DELETE' });
  if (!response.ok) {
    throw new Error(
      `Failed to clear Firestore emulator: ${response.status} ${response.statusText}`,
    );
  }
}

export function makeCaller(
  uid: string,
  overrides: Partial<CallerIdentity> = {},
): CallerIdentity {
  return {
    uid,
    email: `${uid}@example.com`,
    displayName: `User ${uid}`,
    photoUrl: `https://example.com/${uid}.png`,
    ...overrides,
  };
}

export async function seedAdmin(
  db: Firestore,
  uid = ADMIN_UID,
  name = 'Staff Admin',
): Promise<void> {
  await usersAdminDoc(db, uid).set({ uuid: uid, name });
}

export async function seedSpinBaseline(
  db: Firestore,
  options: {
    eventId?: string;
    configOverrides?: Record<string, unknown>;
    nowMs?: number;
  } = {},
): Promise<void> {
  const eventId = options.eventId ?? TEST_EVENT_ID;
  const nowMs = options.nowMs ?? Date.parse('2026-11-28T14:00:00-04:00');
  const nowTs = Timestamp.fromMillis(nowMs);

  await db.collection('events').doc(eventId).set({
    id: eventId,
    title: 'DevFest Sucre 2026',
    status: 'active',
  });

  await spinConfigDoc(db, eventId).set({
    status: 'active',
    pauseMessage: 'GDG SPIN paused for break.',
    ticketCostPerSpin: 1,
    defaultInitialTickets: 2,
    packageTicketBonus: {
      'Entrada libre': 0,
      Standard: 1,
      VIP: 3,
    },
    matchRegistrationByEmail: true,
    registeredAttendeesCount: 100,
    expectedSpinsPerAttendee: 4,
    estimatedTotalSpinsOverride: 100,
    pacingMode: 'dynamic_spins',
    pacingStartAt: Timestamp.fromMillis(
      Date.parse('2026-11-28T09:00:00-04:00'),
    ),
    pacingEndAt: Timestamp.fromMillis(Date.parse('2026-11-28T17:30:00-04:00')),
    pacingCurveGamma: 1.0,
    pacingWaves: [],
    rushMode: false,
    rushBypassUnlockAt: true,
    payoutMultiplier: 1.0,
    maxWinProbabilityPerSpin: 0.45,
    rushMaxWinProbabilityPerSpin: 0.85,
    maxPrizesPerUser: 3,
    allowPlayAfterCap: false,
    maxWinsByRarity: {
      common: 2,
      rare: 1,
      epic: 1,
      legendary: 1,
    },
    minSpinsBetweenWins: 1,
    bonusProbability: 0.0,
    bonusMinTickets: 1,
    bonusMaxTickets: 3,
    maxBonusWinsPerUser: 2,
    wildReplacementChance: 0.35,
    spinCooldownMs: 0,
    maxTotalEarnedTicketsPerUser: 15,
    maxManualGrantPerAction: 5,
    maxManualTicketsPerUser: 10,
    updatedAt: nowTs,
    updatedBy: ADMIN_UID,
    ...options.configOverrides,
  });

  await Promise.all(
    Array.from({ length: STAT_SHARD_COUNT }, (_, i) =>
      spinStatsShardDoc(db, eventId, i).set({
        totalSpins: 0,
        totalWins: 0,
        totalBonusSpins: 0,
        totalBonusTickets: 0,
        totalTicketsIssued: 0,
        totalTicketsSpent: 0,
        updatedAt: nowTs,
      }),
    ),
  );
}

export async function seedPrize(
  db: Firestore,
  eventId: string,
  prizeId: string,
  overrides: Record<string, unknown> = {},
): Promise<void> {
  const initialStock =
    typeof overrides.initialStock === 'number' ? overrides.initialStock : 10;
  await spinPrizeDoc(db, eventId, prizeId).set({
    id: prizeId,
    name: `Prize ${prizeId}`,
    description: 'Test prize',
    symbol: 'cherries',
    imageUrl: null,
    rarity: 'common',
    initialStock,
    remainingStock: initialStock,
    awardedCount: 0,
    redeemedCount: 0,
    releasedStock: initialStock,
    maxPerUser: 1,
    weight: 1.0,
    unlockAt: null,
    active: true,
    order: 0,
    updatedAt: Timestamp.now(),
    ...overrides,
  });
}

export async function seedMission(
  db: Firestore,
  eventId: string,
  missionId: string,
  data: Record<string, unknown>,
  secret?: { correctOptionIndex: number; explanation: string },
): Promise<void> {
  await spinMissionDoc(db, eventId, missionId).set({
    id: missionId,
    title: missionId,
    description: '',
    rewardTickets: 1,
    targetCount: 1,
    maxCompletionsPerUser: 1,
    actionLabel: 'Go',
    active: true,
    order: 0,
    startsAt: null,
    endsAt: null,
    config: {},
    updatedAt: Timestamp.now(),
    ...data,
  });
  if (secret) {
    await spinMissionSecretDoc(db, eventId, missionId).set(secret);
  }
}

export async function assertLedgerReconciles(
  db: Firestore,
  eventId: string,
  uid: string,
): Promise<number> {
  const [playerSnap, ledgerSnap] = await Promise.all([
    spinPlayerDoc(db, eventId, uid).get(),
    ticketLedgerCol(db, eventId).where('uid', '==', uid).get(),
  ]);
  expect(playerSnap.exists).toBe(true);
  const playerTickets = playerSnap.data()!.tickets as number;
  const ledgerSum = ledgerSnap.docs.reduce(
    (sum, docSnap) => sum + ((docSnap.data().delta as number) ?? 0),
    0,
  );
  expect(ledgerSum).toBe(playerTickets);
  return playerTickets;
}
