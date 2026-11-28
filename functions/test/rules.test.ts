import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type EmulatorConfig,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  increment,
  setLogLevel,
} from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

type CompatFirestore = ReturnType<
  ReturnType<RulesTestEnvironment['authenticatedContext']>['firestore']
>;

const PROJECT_ID = 'demo-gdgsucre-events';
const EVENT_ID = 'Y56VC5x6DdHj7Gianmux';
const SPEAKER_ID = 'speaker-1';
const ALICE_UID = 'alice';
const BOB_UID = 'bob';
const CHARLIE_UID = 'charlie';
const ADMIN_UID = 'admin';

const SPIN_COLLECTIONS = [
  'spinConfig',
  'spinPrizes',
  'spinMissions',
  'spinMissionSecrets',
  'spinPlayers',
  'spinWins',
  'spinMissionClaims',
  'spinCodeClaims',
  'ticketLedger',
  'spinTicketCodes',
  'spinRegistrations',
  'spinStats',
  'spinLogs',
  'spinAuditLogs',
] as const;

const SPIN_EXISTING_DOC_BY_COLLECTION: Record<
  (typeof SPIN_COLLECTIONS)[number],
  string
> = {
  spinConfig: 'main',
  spinPrizes: 'stickers',
  spinMissions: 'trivia_1',
  spinMissionSecrets: 'trivia_1',
  spinPlayers: ALICE_UID,
  spinWins: 'win-alice',
  spinMissionClaims: `${ALICE_UID}_trivia_1`,
  spinCodeClaims: `${ALICE_UID}_code_1`,
  ticketLedger: 'ledger-alice',
  spinTicketCodes: 'code_1',
  spinRegistrations: 'hash_1',
  spinStats: 'shard_0',
  spinLogs: `${BOB_UID}_req-1`,
  spinAuditLogs: 'audit-1',
};

function resolveFirestoreConfig(rules: string): EmulatorConfig {
  const raw = process.env.FIRESTORE_EMULATOR_HOST;
  if (raw) {
    const lastColon = raw.lastIndexOf(':');
    if (lastColon === -1) {
      return { rules, host: raw, port: 8080 };
    }
    const host = raw.slice(0, lastColon) || '127.0.0.1';
    const parsedPort = Number.parseInt(raw.slice(lastColon + 1), 10);
    return {
      rules,
      host,
      port: Number.isNaN(parsedPort) ? 8080 : parsedPort,
    };
  }
  if (process.env.FIREBASE_EMULATOR_HUB) {
    return { rules };
  }
  return { rules, host: '127.0.0.1', port: 8080 };
}

function eventDocPath(collection: string, docId: string): string {
  return `events/${EVENT_ID}/${collection}/${docId}`;
}

function buildCompetitorSeed(
  uid: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    uuid: uid,
    name: uid === ALICE_UID ? 'Alice' : 'Bob',
    photoUrl: '',
    profession: '',
    aboutMe: '',
    tokenAuthorization: `tok-${uid}`,
    score: 0,
    scoreProfile: false,
    currentEventId: EVENT_ID,
    socialNetwork: [],
    friends: [],
    treasures: [],
    badges: [],
    ...overrides,
  };
}

async function seedBaselineData(testEnv: RulesTestEnvironment): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const now = Timestamp.now();

    await db.doc(`users-admin/${ADMIN_UID}`).set({
      uuid: ADMIN_UID,
      name: 'Admin Staff',
    });

    await db.doc(`events/${EVENT_ID}`).set({
      id: EVENT_ID,
      title: 'DevFest Sucre 2026',
      description: 'Annual GDG Sucre conference',
      startDate: '2026-11-28T09:00:00.000',
      endDate: '2026-11-28T17:30:00.000',
      locationUrl: 'https://maps.example.com',
      imageUrl: '',
      status: 'upcoming',
    });

    await db.doc(`events/${EVENT_ID}/schedule/${SPEAKER_ID}`).set({
      uuid: SPEAKER_ID,
      title: 'Cloud Run Workshop',
      description: 'Hands-on session',
      name: 'Speaker Uno',
      profession: 'GDE',
      aboutMe: 'Speaker bio',
      photoUrl: '',
      technologyType: 'Cloud',
      type: 'workshop',
      color: '#4285F4',
      schedule: '10:00',
      position: 0,
      current: 5,
      limit: 30,
      openDate: '',
      SocialNetwork: [],
    });

    await db
      .doc(`events/${EVENT_ID}/schedule/${SPEAKER_ID}/questions/q-1`)
      .set({
        id: 'q-1',
        uid: BOB_UID,
        authorName: 'Bob',
        authorPhotoUrl: '',
        text: 'How do cold starts behave on Cloud Run?',
        answered: false,
        hidden: false,
        createdAt: now,
      });

    await db
      .doc(`events/${EVENT_ID}/schedule/${SPEAKER_ID}/ratings/${ALICE_UID}`)
      .set({
        uid: ALICE_UID,
        stars: 5,
        comment: 'Great session',
        createdAt: now,
        updatedAt: now,
      });

    await db
      .doc(`events/${EVENT_ID}/schedule/${SPEAKER_ID}/ratings/${BOB_UID}`)
      .set({
        uid: BOB_UID,
        stars: 4,
        comment: 'Very helpful',
        createdAt: now,
        updatedAt: now,
      });

    await db.doc('organizers/org-1').set({
      name: 'GDG Sucre',
      type: 'organizer',
    });

    await db.doc('sponsors/sponsor-1').set({
      name: 'Google Cloud',
      photoUrl: '',
    });

    await db.doc('resource-library/res-1').set({
      title: 'Firebase Docs',
      keywords: ['firebase'],
    });

    await db.doc('speedRunBuild/challenge-1').set({
      id: 'challenge-1',
      title: 'Build UI',
      position: 0,
    });

    await db.doc('treasure-hunt/item-1').set({
      uuid: 'item-1',
      name: 'Android Pin',
    });

    await db.doc(`competitors/${ALICE_UID}`).set(buildCompetitorSeed(ALICE_UID));
    await db
      .doc(`competitors/${BOB_UID}`)
      .set(buildCompetitorSeed(BOB_UID, { score: 30, profession: 'Dev' }));

    await db.doc(eventDocPath('spinConfig', 'main')).set({
      status: 'paused',
      ticketCostPerSpin: 1,
    });

    await db.doc(eventDocPath('spinPrizes', 'stickers')).set({
      id: 'stickers',
      name: 'Stickers GDG',
      active: true,
      order: 0,
      initialStock: 10,
      remainingStock: 10,
      awardedCount: 0,
      redeemedCount: 0,
    });

    await db.doc(eventDocPath('spinMissions', 'trivia_1')).set({
      id: 'trivia_1',
      type: 'trivia',
      title: 'Trivia del break',
      active: true,
      order: 0,
      rewardTickets: 1,
    });

    await db.doc(eventDocPath('spinMissionSecrets', 'trivia_1')).set({
      correctOptionIndex: 0,
      explanation: 'Firebase AI Logic',
    });

    await db.doc(eventDocPath('spinPlayers', ALICE_UID)).set({
      uid: ALICE_UID,
      tickets: 2,
      spinsCount: 0,
    });

    await db.doc(eventDocPath('spinPlayers', BOB_UID)).set({
      uid: BOB_UID,
      tickets: 5,
      spinsCount: 1,
    });

    await db.doc(eventDocPath('spinWins', 'win-alice')).set({
      id: 'win-alice',
      eventId: EVENT_ID,
      uid: ALICE_UID,
      prizeId: 'stickers',
      code: 'GDG-AAA111',
      status: 'pending',
      wonAt: now,
    });

    await db.doc(eventDocPath('spinWins', 'win-bob')).set({
      id: 'win-bob',
      eventId: EVENT_ID,
      uid: BOB_UID,
      prizeId: 'stickers',
      code: 'GDG-BBB222',
      status: 'pending',
      wonAt: now,
    });

    await db.doc(eventDocPath('spinMissionClaims', `${ALICE_UID}_trivia_1`)).set({
      uid: ALICE_UID,
      missionId: 'trivia_1',
    });

    await db.doc(eventDocPath('spinMissionClaims', `${BOB_UID}_trivia_1`)).set({
      uid: BOB_UID,
      missionId: 'trivia_1',
    });

    await db.doc(eventDocPath('spinCodeClaims', `${ALICE_UID}_code_1`)).set({
      uid: ALICE_UID,
      codeId: 'code_1',
      code: 'CLOUD26',
    });

    await db.doc(eventDocPath('spinCodeClaims', `${BOB_UID}_code_1`)).set({
      uid: BOB_UID,
      codeId: 'code_1',
      code: 'CLOUD26',
    });

    await db.doc(eventDocPath('ticketLedger', 'ledger-alice')).set({
      uid: ALICE_UID,
      delta: 2,
      balanceAfter: 2,
      source: 'initial',
      createdAt: now,
    });

    await db.doc(eventDocPath('ticketLedger', 'ledger-bob')).set({
      uid: BOB_UID,
      delta: 2,
      balanceAfter: 2,
      source: 'initial',
      createdAt: now,
    });

    await db.doc(eventDocPath('spinTicketCodes', 'code_1')).set({
      id: 'code_1',
      code: 'CLOUD26',
      rewardTickets: 1,
      active: true,
    });

    await db.doc(eventDocPath('spinRegistrations', 'hash_1')).set({
      emailNormalized: 'alice@example.com',
      package: 'Standard',
    });

    await db.doc(eventDocPath('spinStats', 'shard_0')).set({
      totalSpins: 1,
      totalWins: 0,
    });

    await db.doc(eventDocPath('spinLogs', `${BOB_UID}_req-1`)).set({
      uid: BOB_UID,
      spinRequestId: 'req-1',
      outcomeType: 'lose',
    });

    await db.doc(eventDocPath('spinAuditLogs', 'audit-1')).set({
      action: 'update_config',
      actorUid: ADMIN_UID,
    });
  });
}

async function assertWriteDeniedOnAllSpinCollections(
  db: CompatFirestore,
): Promise<void> {
  for (const collectionName of SPIN_COLLECTIONS) {
    const existingDocId = SPIN_EXISTING_DOC_BY_COLLECTION[collectionName];
    await assertFails(
      db.doc(eventDocPath(collectionName, existingDocId)).update({
        tampered: true,
      }),
    );
    await assertFails(
      db.doc(eventDocPath(collectionName, 'client-injected')).set({
        tampered: true,
      }),
    );
  }
}

describe('Firestore security rules', () => {
  let testEnv: RulesTestEnvironment;

  beforeAll(async () => {
    const rulesPath = resolve(__dirname, '../../firestore.rules');
    const rules = readFileSync(rulesPath, 'utf8');
    setLogLevel('silent');
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: resolveFirestoreConfig(rules),
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await seedBaselineData(testEnv);
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  describe('unauthenticated access', () => {
    it('allows reading public catalog collections', async () => {
      const db = testEnv.unauthenticatedContext().firestore();

      await assertSucceeds(db.doc(`events/${EVENT_ID}`).get());
      await assertSucceeds(
        db.doc(`events/${EVENT_ID}/schedule/${SPEAKER_ID}`).get(),
      );
      await assertSucceeds(db.doc('organizers/org-1').get());
      await assertSucceeds(db.doc('sponsors/sponsor-1').get());
      await assertSucceeds(db.doc('resource-library/res-1').get());
      await assertSucceeds(db.doc('speedRunBuild/challenge-1').get());
    });

    it('denies reading competitors, users-admin, treasure-hunt, and all spin collections', async () => {
      const db = testEnv.unauthenticatedContext().firestore();

      await assertFails(db.doc(`competitors/${ALICE_UID}`).get());
      await assertFails(db.doc(`users-admin/${ADMIN_UID}`).get());
      await assertFails(db.doc('treasure-hunt/item-1').get());

      for (const collectionName of SPIN_COLLECTIONS) {
        const docId = SPIN_EXISTING_DOC_BY_COLLECTION[collectionName];
        await assertFails(db.doc(eventDocPath(collectionName, docId)).get());
      }
    });

    it('denies writing to public and private collections', async () => {
      const db = testEnv.unauthenticatedContext().firestore();

      await assertFails(
        db.doc('events/unauth-event').set({ title: 'Unauthorized' }),
      );
      await assertFails(
        db.doc(`competitors/${ALICE_UID}`).update({ score: 500 }),
      );
      await assertWriteDeniedOnAllSpinCollections(db);
    });
  });

  describe('normal authenticated user (alice)', () => {
    it('denies writes on admin/server-owned collections and all GDG SPIN collections', async () => {
      const db = testEnv.authenticatedContext(ALICE_UID).firestore();

      await assertFails(
        db.doc(`users-admin/${ALICE_UID}`).set({
          uuid: ALICE_UID,
          name: 'Self-Promoted Admin',
        }),
      );
      await assertFails(
        db.doc(`events/${EVENT_ID}`).update({ title: 'Hijacked Event' }),
      );
      await assertFails(
        db.doc('events/new-event').set({ title: 'Fake Event' }),
      );
      await assertFails(
        db.doc('sponsors/fake-sponsor').set({ name: 'Fake Sponsor' }),
      );
      await assertFails(
        db.doc('organizers/fake-org').set({ name: 'Fake Organizer' }),
      );
      await assertFails(
        db.doc('resource-library/fake-res').set({ title: 'Fake Resource' }),
      );
      await assertFails(
        db.doc('speedRunBuild/fake-challenge').set({ title: 'Fake Challenge' }),
      );
      await assertFails(
        db.doc('treasure-hunt/fake-item').set({ name: 'Fake Treasure' }),
      );
      await assertFails(
        db
          .doc(`events/${EVENT_ID}/schedule/${SPEAKER_ID}/questions/q-alice`)
          .set({
            id: 'q-alice',
            uid: ALICE_UID,
            text: 'Direct client question bypass',
          }),
      );
      await assertFails(
        db
          .doc(
            `events/${EVENT_ID}/schedule/${SPEAKER_ID}/ratings/${ALICE_UID}`,
          )
          .update({ stars: 1 }),
      );

      await assertWriteDeniedOnAllSpinCollections(db);
    });

    it('denies reading server-only and admin-only spin collections', async () => {
      const db = testEnv.authenticatedContext(ALICE_UID).firestore();

      await assertFails(
        db.doc(eventDocPath('spinMissionSecrets', 'trivia_1')).get(),
      );
      await assertFails(db.doc(eventDocPath('spinTicketCodes', 'code_1')).get());
      await assertFails(
        db.doc(eventDocPath('spinRegistrations', 'hash_1')).get(),
      );
      await assertFails(db.doc(eventDocPath('spinStats', 'shard_0')).get());
      await assertFails(
        db.doc(eventDocPath('spinLogs', `${BOB_UID}_req-1`)).get(),
      );
      await assertFails(db.doc(eventDocPath('spinAuditLogs', 'audit-1')).get());
    });

    it('denies reading another user (bob) private documents', async () => {
      const db = testEnv.authenticatedContext(ALICE_UID).firestore();

      await assertFails(db.doc(eventDocPath('spinPlayers', BOB_UID)).get());
      await assertFails(db.doc(eventDocPath('spinWins', 'win-bob')).get());
      await assertFails(
        db
          .doc(eventDocPath('spinMissionClaims', `${BOB_UID}_trivia_1`))
          .get(),
      );
      await assertFails(
        db.doc(eventDocPath('spinCodeClaims', `${BOB_UID}_code_1`)).get(),
      );
      await assertFails(
        db.doc(eventDocPath('ticketLedger', 'ledger-bob')).get(),
      );
      await assertFails(
        db
          .doc(`events/${EVENT_ID}/schedule/${SPEAKER_ID}/ratings/${BOB_UID}`)
          .get(),
      );
    });

    it('allows reading public spin views, questions, and own player records/queries', async () => {
      const db = testEnv.authenticatedContext(ALICE_UID).firestore();

      await assertSucceeds(db.doc(eventDocPath('spinConfig', 'main')).get());
      await assertSucceeds(db.doc(eventDocPath('spinPrizes', 'stickers')).get());
      await assertSucceeds(
        db.doc(eventDocPath('spinMissions', 'trivia_1')).get(),
      );
      await assertSucceeds(db.doc(eventDocPath('spinPlayers', ALICE_UID)).get());
      await assertSucceeds(db.doc(eventDocPath('spinWins', 'win-alice')).get());
      await assertSucceeds(
        db
          .collection(`events/${EVENT_ID}/spinWins`)
          .where('uid', '==', ALICE_UID)
          .get(),
      );
      await assertSucceeds(
        db
          .doc(eventDocPath('spinMissionClaims', `${ALICE_UID}_trivia_1`))
          .get(),
      );
      await assertSucceeds(
        db.doc(eventDocPath('spinCodeClaims', `${ALICE_UID}_code_1`)).get(),
      );
      await assertSucceeds(
        db.doc(eventDocPath('ticketLedger', 'ledger-alice')).get(),
      );
      await assertSucceeds(
        db
          .collection(`events/${EVENT_ID}/ticketLedger`)
          .where('uid', '==', ALICE_UID)
          .get(),
      );
      await assertSucceeds(
        db
          .collection('users-admin')
          .where('uuid', '==', ALICE_UID)
          .get(),
      );
      await assertFails(db.collection('users-admin').get());
      await assertSucceeds(
        db
          .doc(
            `events/${EVENT_ID}/schedule/${SPEAKER_ID}/ratings/${ALICE_UID}`,
          )
          .get(),
      );
      await assertSucceeds(
        db.doc(`events/${EVENT_ID}/schedule/${SPEAKER_ID}/questions/q-1`).get(),
      );
    });

    it('enforces safe self-service writes on competitors/{uid}', async () => {
      const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
      const charlieDb = testEnv.authenticatedContext(CHARLIE_UID).firestore();

      // Creating own competitor doc succeeds.
      await assertSucceeds(
        charlieDb
          .doc(`competitors/${CHARLIE_UID}`)
          .set(buildCompetitorSeed(CHARLIE_UID)),
      );

      // Profile edit succeeds on own doc.
      await assertSucceeds(
        aliceDb.doc(`competitors/${ALICE_UID}`).update({
          name: 'Alice Updated',
          profession: 'Mobile Engineer',
          aboutMe: 'Building Flutter and Firebase community apps.',
        }),
      );

      // Adding a QR friend (+10 score) succeeds on own doc.
      await assertSucceeds(
        aliceDb.doc(`competitors/${ALICE_UID}`).update({
          score: increment(10),
          friends: [
            {
              uuid: BOB_UID,
              name: 'Bob',
              token: `tok-${BOB_UID}`,
              photoUrl: '',
            },
          ],
        }),
      );

      // Collecting a treasure (+100 score) succeeds on own doc.
      await assertSucceeds(
        aliceDb.doc(`competitors/${ALICE_UID}`).update({
          score: increment(100),
          treasures: ['item-1'],
        }),
      );

      // Writing another competitor's doc is denied.
      await assertFails(
        aliceDb.doc(`competitors/${BOB_UID}`).update({ name: 'Hijacked Bob' }),
      );
      await assertFails(
        aliceDb
          .doc(`competitors/${BOB_UID}`)
          .set(buildCompetitorSeed(BOB_UID)),
      );

      // Modifying own badges is denied.
      await assertFails(
        aliceDb.doc(`competitors/${ALICE_UID}`).update({
          badges: [
            {
              eventId: EVENT_ID,
              eventName: 'DevFest Sucre 2026',
              eventDate: '2026-11-28T09:00:00.000',
              finalScore: 999,
              rank: 1,
              assetPath: 'assets/badge.png',
            },
          ],
        }),
      );

      // Setting an arbitrary huge score (+9999) is denied.
      await assertFails(
        aliceDb.doc(`competitors/${ALICE_UID}`).update({
          score: increment(9999),
        }),
      );
      await assertFails(
        aliceDb.doc(`competitors/${ALICE_UID}`).update({
          score: 9999,
        }),
      );
    });

    it('enforces constrained workshow registration and schedule counter increment', async () => {
      const db = testEnv.authenticatedContext(ALICE_UID).firestore();
      const schedulePath = `events/${EVENT_ID}/schedule/${SPEAKER_ID}`;

      // Increment schedule.current by +1 before creating workshow/{uid} (matches addWorkshop flow).
      await assertSucceeds(
        db.doc(schedulePath).update({
          current: increment(1),
        }),
      );

      await assertSucceeds(
        db.doc(`${schedulePath}/workshow/${ALICE_UID}`).set({
          uuid: ALICE_UID,
          name: 'Alice',
          token: 'tok-alice',
          photoUrl: '',
        }),
      );

      await assertFails(
        db.doc(`${schedulePath}/workshow/${BOB_UID}`).set({
          uuid: BOB_UID,
          name: 'Bob',
          token: 'tok-bob',
          photoUrl: '',
        }),
      );

      // Duplicate seat increment after enrollment is denied.
      await assertFails(
        db.doc(schedulePath).update({
          current: increment(1),
        }),
      );

      await assertFails(
        db.doc(schedulePath).update({
          title: 'Renamed Workshop',
        }),
      );

      await assertFails(
        db.doc(schedulePath).update({
          current: increment(5),
        }),
      );
    });
  });

  describe('admin user (users-admin/{uid})', () => {
    it('allows reading admin spin views and any user spin records', async () => {
      const db = testEnv.authenticatedContext(ADMIN_UID).firestore();

      await assertSucceeds(db.doc(eventDocPath('spinTicketCodes', 'code_1')).get());
      await assertSucceeds(
        db.doc(eventDocPath('spinRegistrations', 'hash_1')).get(),
      );
      await assertSucceeds(db.doc(eventDocPath('spinStats', 'shard_0')).get());
      await assertSucceeds(
        db.doc(eventDocPath('spinLogs', `${BOB_UID}_req-1`)).get(),
      );
      await assertSucceeds(
        db.doc(eventDocPath('spinAuditLogs', 'audit-1')).get(),
      );
      await assertSucceeds(db.doc(eventDocPath('spinPlayers', BOB_UID)).get());
      await assertSucceeds(db.doc(eventDocPath('spinWins', 'win-bob')).get());
      await assertSucceeds(db.collection(`events/${EVENT_ID}/spinWins`).get());
      await assertSucceeds(
        db
          .doc(`events/${EVENT_ID}/schedule/${SPEAKER_ID}/ratings/${BOB_UID}`)
          .get(),
      );
    });

    it('allows writing legacy admin collections (events, sponsors, competitors)', async () => {
      const db = testEnv.authenticatedContext(ADMIN_UID).firestore();

      await assertSucceeds(
        db.doc(`events/${EVENT_ID}`).update({ status: 'active' }),
      );
      await assertSucceeds(
        db.doc('sponsors/sponsor-new').set({
          name: 'New Sponsor',
          photoUrl: '',
        }),
      );
      await assertSucceeds(
        db.doc(`competitors/${BOB_UID}`).update({
          score: 0,
          friends: [],
          treasures: [],
          scoreProfile: false,
          currentEventId: null,
        }),
      );
    });

    it('denies reading and writing spinMissionSecrets', async () => {
      const db = testEnv.authenticatedContext(ADMIN_UID).firestore();

      await assertFails(
        db.doc(eventDocPath('spinMissionSecrets', 'trivia_1')).get(),
      );
      await assertFails(
        db.doc(eventDocPath('spinMissionSecrets', 'trivia_1')).set({
          correctOptionIndex: 1,
        }),
      );
      await assertFails(
        db.doc(eventDocPath('spinMissionSecrets', 'trivia_1')).update({
          correctOptionIndex: 1,
        }),
      );
    });

    it('denies client writes on users-admin and all GDG SPIN collections', async () => {
      const db = testEnv.authenticatedContext(ADMIN_UID).firestore();

      await assertFails(
        db.doc('users-admin/new-admin').set({
          uuid: 'new-admin',
          name: 'New Admin',
        }),
      );
      await assertFails(
        db.doc(`users-admin/${ADMIN_UID}`).update({ name: 'Renamed' }),
      );
      await assertFails(db.doc(`users-admin/${ADMIN_UID}`).delete());

      await assertWriteDeniedOnAllSpinCollections(db);
    });
  });
});
