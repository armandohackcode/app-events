import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { beforeEach, describe, expect, it } from 'vitest';
import { executeAdminImportRegistrations } from '../../src/callables/admin/ticketsAndRegistrations';
import { executeAdminUpsertTicketCode } from '../../src/callables/admin/missionsAndCodes';
import { executeSpinInitPlayer } from '../../src/callables/player/initPlayer';
import {
  executeSpinClaimMission,
  executeSpinSubmitTrivia,
} from '../../src/callables/player/missions';
import {
  executeSpinSubmitTalkQuestion,
  executeSpinSubmitTalkRating,
} from '../../src/callables/player/talkInteractions';
import { executeSpinRedeemTicketCode } from '../../src/callables/player/ticketCodes';
import {
  competitorDoc,
  ratingDoc,
  scheduleDoc,
  spinMissionClaimDoc,
  workshowCol,
} from '../../src/services/firestorePaths';
import {
  ADMIN_UID,
  TEST_EVENT_ID,
  assertLedgerReconciles,
  clearEmulatorFirestore,
  getEmulatorFirestore,
  makeCaller,
  seedAdmin,
  seedMission,
  seedSpinBaseline,
} from './helpers';

async function expectHttpsError(
  fn: () => Promise<unknown>,
  expectedCode: string,
  expectedReason?: string,
): Promise<void> {
  try {
    await fn();
    expect.unreachable(`Expected HttpsError(${expectedCode}, ${expectedReason})`);
  } catch (error) {
    expect(error).toBeInstanceOf(HttpsError);
    const httpsErr = error as HttpsError;
    expect(httpsErr.code).toBe(expectedCode);
    if (expectedReason) {
      expect((httpsErr.details as { reason?: string } | undefined)?.reason).toBe(
        expectedReason,
      );
    }
  }
}

describe('tickets economy, missions, trivia, Q&A, ratings & ledger (emulator)', () => {
  const db = getEmulatorFirestore();

  beforeEach(async () => {
    await clearEmulatorFirestore();
    await seedAdmin(db, ADMIN_UID);
  });

  it('initializes players idempotently with email registration package matching and late bonus grant', async () => {
    const nowMs = Date.parse('2026-11-28T10:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        defaultInitialTickets: 2,
        packageTicketBonus: { 'Entrada libre': 0, Standard: 1, VIP: 3 },
      },
    });

    // Unregistered user gets defaultInitialTickets only
    const bob = makeCaller('bob', { email: 'bob@example.com' });
    const bobInit1 = await executeSpinInitPlayer(
      db,
      bob,
      { eventId: TEST_EVENT_ID },
      { nowMs },
    );
    expect(bobInit1.initialGranted).toBe(true);
    expect(bobInit1.packageBonusGranted).toBe(false);
    expect(bobInit1.player.tickets).toBe(2);

    // Calling again before registration import is idempotent
    const bobInit2 = await executeSpinInitPlayer(
      db,
      bob,
      { eventId: TEST_EVENT_ID },
      { nowMs: nowMs + 1000 },
    );
    expect(bobInit2.initialGranted).toBe(false);
    expect(bobInit2.packageBonusGranted).toBe(false);
    expect(bobInit2.player.tickets).toBe(2);

    // Now admin imports VIP registration for Bob (uppercase + spaces)
    await executeAdminImportRegistrations(
      db,
      makeCaller(ADMIN_UID),
      {
        eventId: TEST_EVENT_ID,
        rows: [
          {
            email: '  BOB@EXAMPLE.COM ',
            fullName: 'Bob VIP',
            package: 'VIP',
            checkedIn: true,
          },
        ],
      },
      { nowMs: nowMs + 2000 },
    );

    // Next spinInitPlayer grants VIP package bonus ONCE
    const bobInit3 = await executeSpinInitPlayer(
      db,
      bob,
      { eventId: TEST_EVENT_ID },
      { nowMs: nowMs + 3000 },
    );
    expect(bobInit3.initialGranted).toBe(false);
    expect(bobInit3.packageBonusGranted).toBe(true);
    expect(bobInit3.matchedPackage).toBe('VIP');
    expect(bobInit3.player.tickets).toBe(5);

    // Calling a 4th time is strictly idempotent
    const bobInit4 = await executeSpinInitPlayer(
      db,
      bob,
      { eventId: TEST_EVENT_ID },
      { nowMs: nowMs + 4000 },
    );
    expect(bobInit4.packageBonusGranted).toBe(false);
    expect(bobInit4.player.tickets).toBe(5);

    await assertLedgerReconciles(db, TEST_EVENT_ID, 'bob');
  });

  it('verifies profile_complete and workshop_register missions and enforces maxTotalEarnedTicketsPerUser', async () => {
    const nowMs = Date.parse('2026-11-28T10:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        defaultInitialTickets: 2,
        maxTotalEarnedTicketsPerUser: 4,
      },
    });

    await seedMission(db, TEST_EVENT_ID, 'profile_complete', {
      type: 'profile_complete',
      title: 'Complete your profile',
      rewardTickets: 1,
      config: { minAboutMeLength: 20 },
    });
    await seedMission(db, TEST_EVENT_ID, 'workshop_register', {
      type: 'workshop_register',
      title: 'Join a workshop',
      rewardTickets: 1,
    });
    await seedMission(db, TEST_EVENT_ID, 'workshop_register_bonus', {
      type: 'workshop_register',
      title: 'Join workshop bonus',
      rewardTickets: 1,
    });

    const alice = makeCaller('alice');
    await executeSpinInitPlayer(db, alice, { eventId: TEST_EVENT_ID }, { nowMs });

    // Incomplete competitor profile
    await competitorDoc(db, 'alice').set({
      uuid: 'alice',
      name: 'Alice',
      profession: '',
      aboutMe: 'Short',
    });

    await expectHttpsError(
      () =>
        executeSpinClaimMission(
          db,
          alice,
          { eventId: TEST_EVENT_ID, missionId: 'profile_complete' },
          { nowMs },
        ),
      'failed-precondition',
      'REQUIREMENT_NOT_MET',
    );

    // Complete profile -> claims once, fails on 2nd claim
    await competitorDoc(db, 'alice').update({
      profession: 'Flutter Engineer',
      aboutMe: 'Building community apps in Sucre for DevFest 2026!',
    });

    const claimProfile = await executeSpinClaimMission(
      db,
      alice,
      { eventId: TEST_EVENT_ID, missionId: 'profile_complete' },
      { nowMs },
    );
    expect(claimProfile.granted).toBe(true);
    expect(claimProfile.ticketsAwarded).toBe(1);
    expect(claimProfile.ticketsAfter).toBe(3);
    expect(claimProfile.ticketSerial).toMatch(/^[0-9A-F]{8}$/);

    await expectHttpsError(
      () =>
        executeSpinClaimMission(
          db,
          alice,
          { eventId: TEST_EVENT_ID, missionId: 'profile_complete' },
          { nowMs },
        ),
      'already-exists',
    );

    // Workshop enrollment
    await scheduleDoc(db, TEST_EVENT_ID, 'speaker-1').set({
      uuid: 'speaker-1',
      title: 'Cloud Run',
    });
    await expectHttpsError(
      () =>
        executeSpinClaimMission(
          db,
          alice,
          { eventId: TEST_EVENT_ID, missionId: 'workshop_register' },
          { nowMs },
        ),
      'failed-precondition',
      'REQUIREMENT_NOT_MET',
    );

    await workshowCol(db, TEST_EVENT_ID, 'speaker-1').doc('alice').set({
      uuid: 'alice',
      name: 'Alice',
      token: 'tok',
      photoUrl: '',
    });

    const claimWorkshop = await executeSpinClaimMission(
      db,
      alice,
      { eventId: TEST_EVENT_ID, missionId: 'workshop_register' },
      { nowMs },
    );
    expect(claimWorkshop.ticketsAwarded).toBe(1);
    expect(claimWorkshop.ticketsAfter).toBe(4);

    // maxTotalEarnedTicketsPerUser = 4 is now reached -> next mission claim is blocked
    await expectHttpsError(
      () =>
        executeSpinClaimMission(
          db,
          alice,
          { eventId: TEST_EVENT_ID, missionId: 'workshop_register_bonus' },
          { nowMs },
        ),
      'failed-precondition',
      'TICKET_CAP_REACHED',
    );

    await assertLedgerReconciles(db, TEST_EVENT_ID, 'alice');
  });

  it('evaluates trivia attempts (1 try, window check, secret verification) and stand codes', async () => {
    const nowMs = Date.parse('2026-11-28T11:00:00-04:00');
    await seedSpinBaseline(db, { eventId: TEST_EVENT_ID, nowMs });

    await seedMission(
      db,
      TEST_EVENT_ID,
      'trivia_am',
      {
        type: 'trivia',
        title: 'Morning Trivia',
        rewardTickets: 2,
        startsAt: Timestamp.fromMillis(nowMs - 60_000),
        endsAt: Timestamp.fromMillis(nowMs + 60_000),
        config: {
          question: 'Which SDK?',
          options: ['Firebase AI Logic', 'Crashlytics', 'Hosting'],
        },
      },
      { correctOptionIndex: 0, explanation: 'Firebase AI Logic is correct.' },
    );

    await seedMission(
      db,
      TEST_EVENT_ID,
      'trivia_closed',
      {
        type: 'trivia',
        title: 'Closed Trivia',
        rewardTickets: 1,
        active: false,
        config: {
          question: 'Closed?',
          options: ['Yes', 'No'],
        },
      },
      { correctOptionIndex: 0, explanation: 'Closed.' },
    );

    const alice = makeCaller('alice');
    const bob = makeCaller('bob');
    await executeSpinInitPlayer(db, alice, { eventId: TEST_EVENT_ID }, { nowMs });
    await executeSpinInitPlayer(db, bob, { eventId: TEST_EVENT_ID }, { nowMs });

    // Inactive trivia -> TRIVIA_CLOSED
    await expectHttpsError(
      () =>
        executeSpinSubmitTrivia(
          db,
          alice,
          { eventId: TEST_EVENT_ID, missionId: 'trivia_closed', selectedIndex: 0 },
          { nowMs },
        ),
      'failed-precondition',
      'TRIVIA_CLOSED',
    );

    // Alice answers correctly
    const aliceRes = await executeSpinSubmitTrivia(
      db,
      alice,
      { eventId: TEST_EVENT_ID, missionId: 'trivia_am', selectedIndex: 0 },
      { nowMs },
    );
    expect(aliceRes.correct).toBe(true);
    expect(aliceRes.ticketsAwarded).toBe(2);
    expect(aliceRes.ticketsAfter).toBe(4);
    expect(aliceRes.ticketSerial).toMatch(/^[0-9A-F]{8}$/);
    expect(aliceRes.explanation).toBe('Firebase AI Logic is correct.');

    // Alice cannot retry trivia
    await expectHttpsError(
      () =>
        executeSpinSubmitTrivia(
          db,
          alice,
          { eventId: TEST_EVENT_ID, missionId: 'trivia_am', selectedIndex: 0 },
          { nowMs },
        ),
      'already-exists',
    );

    // Bob answers wrong -> 0 tickets, still cannot retry
    const bobRes = await executeSpinSubmitTrivia(
      db,
      bob,
      { eventId: TEST_EVENT_ID, missionId: 'trivia_am', selectedIndex: 2 },
      { nowMs },
    );
    expect(bobRes.correct).toBe(false);
    expect(bobRes.ticketsAwarded).toBe(0);
    expect(bobRes.ticketsAfter).toBe(2);
    expect(bobRes.ticketSerial).toBeNull();

    // Stand code creation & redemption via QR payload and window check
    await executeAdminUpsertTicketCode(
      db,
      makeCaller(ADMIN_UID),
      {
        eventId: TEST_EVENT_ID,
        codeConfig: {
          id: 'cloud-stand',
          code: 'CLOUD26',
          label: 'Google Cloud Stand',
          rewardTickets: 2,
          maxTotalUses: 50,
          active: true,
          startsAt: nowMs - 60_000,
          endsAt: nowMs + 60_000,
        },
      },
      { nowMs },
    );

    const redeemRes = await executeSpinRedeemTicketCode(
      db,
      alice,
      {
        eventId: TEST_EVENT_ID,
        code: `gdgspin:code:${TEST_EVENT_ID}:cloud26`,
      },
      { nowMs },
    );
    expect(redeemRes.label).toBe('Google Cloud Stand');
    expect(redeemRes.ticketsAwarded).toBe(2);
    expect(redeemRes.ticketsAfter).toBe(6);

    // Same user cannot redeem twice
    await expectHttpsError(
      () =>
        executeSpinRedeemTicketCode(
          db,
          alice,
          { eventId: TEST_EVENT_ID, code: 'CLOUD26' },
          { nowMs },
        ),
      'already-exists',
    );

    // Expired window rejected for Bob
    await expectHttpsError(
      () =>
        executeSpinRedeemTicketCode(
          db,
          bob,
          { eventId: TEST_EVENT_ID, code: 'CLOUD26' },
          { nowMs: nowMs + 120_000 },
        ),
      'failed-precondition',
      'CODE_EXPIRED',
    );

    // Wrong eventId in QR rejected
    await expectHttpsError(
      () =>
        executeSpinRedeemTicketCode(
          db,
          bob,
          { eventId: TEST_EVENT_ID, code: 'gdgspin:code:other-event:CLOUD26' },
          { nowMs },
        ),
      'invalid-argument',
      'EVENT_MISMATCH',
    );

    await assertLedgerReconciles(db, TEST_EVENT_ID, 'alice');
    await assertLedgerReconciles(db, TEST_EVENT_ID, 'bob');
  });

  it('enforces talk question limits/rate-limit and rating deduplication with countedTalkIds', async () => {
    const nowMs = Date.parse('2026-11-28T12:00:00-04:00');
    await seedSpinBaseline(db, { eventId: TEST_EVENT_ID, nowMs });

    await scheduleDoc(db, TEST_EVENT_ID, 'talk-1').set({
      uuid: 'talk-1',
      title: 'Firebase Architecture',
    });
    await scheduleDoc(db, TEST_EVENT_ID, 'talk-2').set({
      uuid: 'talk-2',
      title: 'Flutter Animations',
    });

    await seedMission(db, TEST_EVENT_ID, 'ask_speaker', {
      type: 'ask_speaker',
      title: 'Ask a speaker',
      rewardTickets: 1,
      targetCount: 1,
      maxCompletionsPerUser: 1,
    });
    await seedMission(db, TEST_EVENT_ID, 'rate_talk', {
      type: 'rate_talk',
      title: 'Rate talks',
      rewardTickets: 1,
      targetCount: 1,
      maxCompletionsPerUser: 2,
    });

    const alice = makeCaller('alice');
    await executeSpinInitPlayer(db, alice, { eventId: TEST_EVENT_ID }, { nowMs });

    // Too-short question rejected
    await expectHttpsError(
      () =>
        executeSpinSubmitTalkQuestion(
          db,
          alice,
          { eventId: TEST_EVENT_ID, speakerUuid: 'talk-1', text: 'Too short' },
          { nowMs },
        ),
      'invalid-argument',
    );

    // Question 1: rewards ask_speaker mission (+1 ticket -> 3)
    const q1 = await executeSpinSubmitTalkQuestion(
      db,
      alice,
      {
        eventId: TEST_EVENT_ID,
        speakerUuid: 'talk-1',
        text: 'How do you handle cold starts in Cloud Functions v2?',
      },
      { nowMs: nowMs + 1000 },
    );
    expect(q1.missionRewarded).toBe(true);
    expect(q1.ticketsAwarded).toBe(1);
    expect(q1.ticketsAfter).toBe(3);

    // Rate limit within 30s rejected
    await expectHttpsError(
      () =>
        executeSpinSubmitTalkQuestion(
          db,
          alice,
          {
            eventId: TEST_EVENT_ID,
            speakerUuid: 'talk-1',
            text: 'Second question too fast within 30 seconds?',
          },
          { nowMs: nowMs + 15_000 },
        ),
      'failed-precondition',
      'RATE_LIMITED',
    );

    // Question 2 & 3 succeed after 30s each without double rewarding ask_speaker
    const q2 = await executeSpinSubmitTalkQuestion(
      db,
      alice,
      {
        eventId: TEST_EVENT_ID,
        speakerUuid: 'talk-1',
        text: 'What region should Firestore and Functions share?',
      },
      { nowMs: nowMs + 35_000 },
    );
    expect(q2.missionRewarded).toBe(false);
    expect(q2.ticketsAwarded).toBe(0);

    await executeSpinSubmitTalkQuestion(
      db,
      alice,
      {
        eventId: TEST_EVENT_ID,
        speakerUuid: 'talk-1',
        text: 'How are transaction retries bounded in Firestore?',
      },
      { nowMs: nowMs + 70_000 },
    );

    // 4th question on same talk rejected with QUESTION_LIMIT_REACHED
    await expectHttpsError(
      () =>
        executeSpinSubmitTalkQuestion(
          db,
          alice,
          {
            eventId: TEST_EVENT_ID,
            speakerUuid: 'talk-1',
            text: 'Fourth question on the exact same talk?',
          },
          { nowMs: nowMs + 105_000 },
        ),
      'failed-precondition',
      'QUESTION_LIMIT_REACHED',
    );

    // Rate talk-1 -> rewards 1st completion (+1 ticket -> 4)
    const r1 = await executeSpinSubmitTalkRating(
      db,
      alice,
      {
        eventId: TEST_EVENT_ID,
        speakerUuid: 'talk-1',
        stars: 5,
        comment: 'Awesome talk!',
      },
      { nowMs: nowMs + 110_000 },
    );
    expect(r1.saved).toBe(true);
    expect(r1.missionRewarded).toBe(true);
    expect(r1.ticketsAwarded).toBe(1);
    expect(r1.ticketsAfter).toBe(4);

    // Re-editing talk-1 updates stars/comment but NEVER double-rewards
    const r1Edit = await executeSpinSubmitTalkRating(
      db,
      alice,
      {
        eventId: TEST_EVENT_ID,
        speakerUuid: 'talk-1',
        stars: 4,
        comment: 'Updated comment',
      },
      { nowMs: nowMs + 115_000 },
    );
    expect(r1Edit.saved).toBe(true);
    expect(r1Edit.missionRewarded).toBe(false);
    expect(r1Edit.ticketsAwarded).toBe(0);
    expect(r1Edit.ticketsAfter).toBe(4);

    const ratingSnap = await ratingDoc(
      db,
      TEST_EVENT_ID,
      'talk-1',
      'alice',
    ).get();
    expect(ratingSnap.data()!.stars).toBe(4);
    expect(ratingSnap.data()!.comment).toBe('Updated comment');

    // Rating distinct talk-2 rewards 2nd completion (+1 ticket -> 5)
    const r2 = await executeSpinSubmitTalkRating(
      db,
      alice,
      {
        eventId: TEST_EVENT_ID,
        speakerUuid: 'talk-2',
        stars: 5,
      },
      { nowMs: nowMs + 120_000 },
    );
    expect(r2.missionRewarded).toBe(true);
    expect(r2.ticketsAwarded).toBe(1);
    expect(r2.ticketsAfter).toBe(5);

    const rateClaimSnap = await spinMissionClaimDoc(
      db,
      TEST_EVENT_ID,
      'alice',
      'rate_talk',
    ).get();
    expect(rateClaimSnap.data()!.countedTalkIds).toEqual(['talk-1', 'talk-2']);
    expect(rateClaimSnap.data()!.completions).toBe(2);

    const balance = await assertLedgerReconciles(db, TEST_EVENT_ID, 'alice');
    expect(balance).toBe(5);
  });
});
