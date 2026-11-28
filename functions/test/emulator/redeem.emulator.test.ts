import { HttpsError } from 'firebase-functions/v2/https';
import { beforeEach, describe, expect, it } from 'vitest';
import { nodeCryptoRng, type CryptoRng } from '../../src/domain/pacing';
import {
  executeAdminAdjustPrizeStock,
  executeAdminUpdateSpinConfig,
  executeAdminUpsertSpinPrize,
} from '../../src/callables/admin/configAndPrizes';
import {
  executeAdminUpsertSpinMission,
  executeAdminUpsertTicketCode,
} from '../../src/callables/admin/missionsAndCodes';
import {
  executeAdminGrantTickets,
  executeAdminImportRegistrations,
} from '../../src/callables/admin/ticketsAndRegistrations';
import {
  executeAdminGetSpinDashboard,
  executeAdminLookupWinByCode,
  executeAdminRedeemWin,
  executeAdminRevokeWin,
} from '../../src/callables/admin/winsAndDashboard';
import { executeSpinInitPlayer } from '../../src/callables/player/initPlayer';
import { executeSpinPull } from '../../src/callables/player/spinPull';
import {
  spinAuditLogsCol,
  spinConfigDoc,
  spinMissionSecretDoc,
  spinPlayerDoc,
  spinPrizeDoc,
  spinWinDoc,
} from '../../src/services/firestorePaths';
import {
  ADMIN_UID,
  TEST_EVENT_ID,
  assertLedgerReconciles,
  clearEmulatorFirestore,
  getEmulatorFirestore,
  makeCaller,
  seedAdmin,
  seedSpinBaseline,
} from './helpers';

function fixedRng(floatVal: number): CryptoRng {
  return {
    nextFloat: () => floatVal,
    nextInt: (min: number, maxExclusive: number) =>
      nodeCryptoRng.nextInt(min, maxExclusive),
  };
}

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

describe('admin callables, redemption, revocation, stock & dashboard (emulator)', () => {
  const db = getEmulatorFirestore();

  beforeEach(async () => {
    await clearEmulatorFirestore();
    await seedAdmin(db, ADMIN_UID, 'Staff Leader');
  });

  it('rejects non-admin callers with permission-denied on admin callables', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, { eventId: TEST_EVENT_ID, nowMs });

    const nonAdmin = makeCaller('alice');
    await expectHttpsError(
      () =>
        executeAdminUpdateSpinConfig(db, nonAdmin, {
          eventId: TEST_EVENT_ID,
          patch: { status: 'paused' },
        }),
      'permission-denied',
    );
    await expectHttpsError(
      () =>
        executeAdminUpsertSpinPrize(db, nonAdmin, {
          eventId: TEST_EVENT_ID,
          prize: {
            id: 'p1',
            name: 'Stickers',
            symbol: 'cherries',
            rarity: 'common',
            initialStock: 5,
          },
        }),
      'permission-denied',
    );
    await expectHttpsError(
      () =>
        executeAdminGrantTickets(db, nonAdmin, {
          eventId: TEST_EVENT_ID,
          targetUid: 'alice',
          amount: 1,
          reason: 'Self grant attempt',
          requestId: 'req-non-admin-001',
        }),
      'permission-denied',
    );
    await expectHttpsError(
      () =>
        executeAdminGetSpinDashboard(db, nonAdmin, { eventId: TEST_EVENT_ID }),
      'permission-denied',
    );
  });

  it('enforces prize creation, immutable stock on update, stock adjustments, redeem and revoke with returnToStock', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        status: 'active',
        defaultInitialTickets: 4,
        rushMode: true,
        payoutMultiplier: 100,
        rushMaxWinProbabilityPerSpin: 1.0,
        bonusProbability: 0,
        minSpinsBetweenWins: 0,
        spinCooldownMs: 0,
      },
    });

    const admin = makeCaller(ADMIN_UID);

    // Create prize
    const created = await executeAdminUpsertSpinPrize(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        prize: {
          id: 'sparky',
          name: 'Sparky Plush',
          symbol: 'star',
          rarity: 'epic',
          initialStock: 2,
        },
      },
      { nowMs },
    );
    expect(created.created).toBe(true);
    expect(created.prize.remainingStock).toBe(2);
    expect(created.prize.awardedCount).toBe(0);
    expect(created.prize.redeemedCount).toBe(0);

    // Update metadata succeeds without stock fields
    const updatedMeta = await executeAdminUpsertSpinPrize(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        prize: {
          id: 'sparky',
          name: 'Sparky Plush Limited',
          symbol: 'star',
          rarity: 'epic',
          active: true,
        },
      },
      { nowMs: nowMs + 100 },
    );
    expect(updatedMeta.created).toBe(false);
    expect(updatedMeta.prize.name).toBe('Sparky Plush Limited');

    // Direct stock overwrite on update is rejected
    await expectHttpsError(
      () =>
        executeAdminUpsertSpinPrize(db, admin, {
          eventId: TEST_EVENT_ID,
          prize: {
            id: 'sparky',
            name: 'Sparky Plush Limited',
            symbol: 'star',
            rarity: 'epic',
            remainingStock: 99,
          },
        }),
      'invalid-argument',
      'STOCK_IMMUTABLE_ON_UPDATE',
    );

    // Adjust stock +1 -> 3 initial / 3 remaining
    const adjustedUp = await executeAdminAdjustPrizeStock(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        prizeId: 'sparky',
        delta: 1,
        reason: 'Found 1 extra box',
      },
      { nowMs: nowMs + 200 },
    );
    expect(adjustedUp.prize.initialStock).toBe(3);
    expect(adjustedUp.prize.remainingStock).toBe(3);

    // Reject negative resulting stock
    await expectHttpsError(
      () =>
        executeAdminAdjustPrizeStock(db, admin, {
          eventId: TEST_EVENT_ID,
          prizeId: 'sparky',
          delta: -10,
          reason: 'Invalid remove',
        }),
      'failed-precondition',
      'INVALID_STOCK_ADJUSTMENT',
    );

    // Player Alice wins twice
    const alice = makeCaller('alice');
    await executeSpinInitPlayer(db, alice, { eventId: TEST_EVENT_ID }, { nowMs });

    // Allow 2 epic wins for Alice to test both redeem and revoke
    await executeAdminUpdateSpinConfig(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        patch: { maxWinsByRarity: { epic: 2 } },
      },
      { nowMs: nowMs + 250 },
    );
    await executeAdminUpsertSpinPrize(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        prize: {
          id: 'sparky',
          name: 'Sparky Plush Limited',
          symbol: 'star',
          rarity: 'epic',
          maxPerUser: 2,
          active: true,
        },
      },
      { nowMs: nowMs + 260 },
    );

    const win1Pull = await executeSpinPull(
      db,
      alice,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-redeem-001' },
      { nowMs: nowMs + 300, rng: fixedRng(0.01) },
    );
    const win2Pull = await executeSpinPull(
      db,
      alice,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-redeem-002' },
      { nowMs: nowMs + 400, rng: fixedRng(0.01) },
    );

    const win1Id = win1Pull.wonPrize!.winId;
    const win1Code = win1Pull.wonPrize!.code;
    const win2Id = win2Pull.wonPrize!.winId;

    // Lookup by QR payload and raw 6-char code
    const lookupQr = await executeAdminLookupWinByCode(db, admin, {
      eventId: TEST_EVENT_ID,
      codeOrQr: `gdgspin:win:${TEST_EVENT_ID}:${win1Code}`,
    });
    expect(lookupQr.win.id).toBe(win1Id);
    expect(lookupQr.prize?.id).toBe('sparky');
    expect(lookupQr.player?.uid).toBe('alice');

    const lookupRaw = await executeAdminLookupWinByCode(db, admin, {
      eventId: TEST_EVENT_ID,
      codeOrQr: win1Code.replace('GDG-', '').toLowerCase(),
    });
    expect(lookupRaw.win.id).toBe(win1Id);

    // Redeem win 1 once -> 2nd attempt rejected with ALREADY_REDEEMED
    const redeemed = await executeAdminRedeemWin(
      db,
      admin,
      { eventId: TEST_EVENT_ID, winId: win1Id },
      { nowMs: nowMs + 500 },
    );
    expect(redeemed.win.status).toBe('redeemed');
    expect(redeemed.win.redeemedByName).toBe('Staff Leader');

    await expectHttpsError(
      () =>
        executeAdminRedeemWin(db, admin, {
          eventId: TEST_EVENT_ID,
          winId: win1Id,
        }),
      'failed-precondition',
      'ALREADY_REDEEMED',
    );

    // Revoke win 2 with returnToStock: true -> stock restores 1 -> 2, awarded 2 -> 1, player counters decrement
    const revoked = await executeAdminRevokeWin(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        winId: win2Id,
        returnToStock: true,
        reason: 'Attendee left event early',
      },
      { nowMs: nowMs + 600 },
    );
    expect(revoked.win.status).toBe('revoked');
    expect(revoked.win.returnedToStock).toBe(true);

    const prizeAfterRevoke = (
      await spinPrizeDoc(db, TEST_EVENT_ID, 'sparky').get()
    ).data()!;
    expect(prizeAfterRevoke.remainingStock).toBe(2);
    expect(prizeAfterRevoke.awardedCount).toBe(1);
    expect(prizeAfterRevoke.redeemedCount).toBe(1);
    expect(
      prizeAfterRevoke.remainingStock + prizeAfterRevoke.awardedCount,
    ).toBe(prizeAfterRevoke.initialStock);

    const playerAfterRevoke = (
      await spinPlayerDoc(db, TEST_EVENT_ID, 'alice').get()
    ).data() as {
      totalPrizesWon: number;
      winsByRarity: Record<string, number>;
      winsByPrize: Record<string, number>;
    };
    expect(playerAfterRevoke.totalPrizesWon).toBe(1);
    expect(playerAfterRevoke.winsByRarity.epic).toBe(1);
    expect(playerAfterRevoke.winsByPrize.sparky).toBe(1);

    const win2Doc = (await spinWinDoc(db, TEST_EVENT_ID, win2Id).get()).data()!;
    expect(win2Doc.status).toBe('revoked');
  });

  it('handles adminGrantTickets idempotency & caps, batched registration import (450 rows, zero PII in audit logs), missions/codes CRUD, and dashboard', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        maxManualGrantPerAction: 5,
        maxManualTicketsPerUser: 6,
      },
    });

    const admin = makeCaller(ADMIN_UID);

    // Grant 4 tickets to a user who has not called spinInitPlayer yet
    const grant1 = await executeAdminGrantTickets(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        targetUid: 'charlie',
        amount: 4,
        reason: 'Volunteer appreciation',
        requestId: 'grant-req-0001',
      },
      { nowMs },
    );
    expect(grant1.ticketsAwarded).toBe(4);
    expect(grant1.ticketsAfter).toBe(4);
    expect(grant1.idempotentReplay).toBe(false);

    // Replay with same requestId -> idempotent
    const grantReplay = await executeAdminGrantTickets(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        targetUid: 'charlie',
        amount: 4,
        reason: 'Volunteer appreciation',
        requestId: 'grant-req-0001',
      },
      { nowMs: nowMs + 100 },
    );
    expect(grantReplay.idempotentReplay).toBe(true);
    expect(grantReplay.ticketsAfter).toBe(4);
    expect(grantReplay.ticketSerial).toBe(grant1.ticketSerial);

    // Exceed maxManualGrantPerAction
    await expectHttpsError(
      () =>
        executeAdminGrantTickets(db, admin, {
          eventId: TEST_EVENT_ID,
          targetUid: 'charlie',
          amount: 6,
          reason: 'Too many at once',
          requestId: 'grant-req-0002',
        }),
      'failed-precondition',
      'MANUAL_GRANT_CAP_REACHED',
    );

    // Exceed maxManualTicketsPerUser (4 + 3 = 7 > 6)
    await expectHttpsError(
      () =>
        executeAdminGrantTickets(db, admin, {
          eventId: TEST_EVENT_ID,
          targetUid: 'charlie',
          amount: 3,
          reason: 'Exceeds user cap',
          requestId: 'grant-req-0003',
        }),
      'failed-precondition',
      'MANUAL_GRANT_CAP_REACHED',
    );

    // Now Charlie calls spinInitPlayer -> still receives defaultInitialTickets (2) cleanly
    const charlieInit = await executeSpinInitPlayer(
      db,
      makeCaller('charlie', { email: 'charlie@example.com' }),
      { eventId: TEST_EVENT_ID },
      { nowMs: nowMs + 200 },
    );
    expect(charlieInit.initialGranted).toBe(true);
    expect(charlieInit.player.tickets).toBe(6);
    await assertLedgerReconciles(db, TEST_EVENT_ID, 'charlie');

    // Import 450 registrations (> 400 batch size) and ensure zero PII in spinAuditLogs
    const rows = Array.from({ length: 450 }, (_, i) => ({
      email: `attendee${i}@example.com`,
      fullName: `Attendee ${i}`,
      package: i % 10 === 0 ? 'VIP' : 'Standard',
      checkedIn: i % 2 === 0,
    }));
    const importRes = await executeAdminImportRegistrations(
      db,
      admin,
      { eventId: TEST_EVENT_ID, rows, replaceAll: false },
      { nowMs: nowMs + 300 },
    );
    expect(importRes.importedCount).toBe(450);
    expect(importRes.updatedCount).toBe(0);
    expect(importRes.totalRegistrationsCount).toBe(450);

    const cfgSnap = await spinConfigDoc(db, TEST_EVENT_ID).get();
    expect(cfgSnap.data()!.registeredAttendeesCount).toBe(450);

    const auditSnap = await spinAuditLogsCol(db, TEST_EVENT_ID)
      .where('action', '==', 'import_registrations')
      .get();
    expect(auditSnap.size).toBe(1);
    const auditJson = JSON.stringify(auditSnap.docs[0].data());
    expect(auditJson).not.toContain('attendee0@example.com');
    expect(auditJson).not.toContain('Attendee 0');

    // Upsert trivia mission + secret atomically
    const missionRes = await executeAdminUpsertSpinMission(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        mission: {
          id: 'trivia-1',
          type: 'trivia',
          title: 'Break Trivia',
          rewardTickets: 1,
          active: true,
          config: {
            question: 'What is GDG?',
            options: ['Google Developer Group', 'Other'],
          },
        },
        secret: {
          correctOptionIndex: 0,
          explanation: 'Google Developer Group',
        },
      },
      { nowMs: nowMs + 400 },
    );
    expect(missionRes.created).toBe(true);
    const secretSnap = await spinMissionSecretDoc(
      db,
      TEST_EVENT_ID,
      'trivia-1',
    ).get();
    expect(secretSnap.data()!.correctOptionIndex).toBe(0);

    // Upsert ticket code + duplicate code rejection
    await executeAdminUpsertTicketCode(
      db,
      admin,
      {
        eventId: TEST_EVENT_ID,
        codeConfig: {
          id: 'code-a',
          code: 'SPONSOR26',
          label: 'Sponsor A',
          rewardTickets: 1,
          maxTotalUses: 10,
          active: true,
        },
      },
      { nowMs: nowMs + 500 },
    );

    await expectHttpsError(
      () =>
        executeAdminUpsertTicketCode(db, admin, {
          eventId: TEST_EVENT_ID,
          codeConfig: {
            id: 'code-b',
            code: 'sponsor26',
            label: 'Duplicate Sponsor',
            rewardTickets: 1,
            maxTotalUses: 10,
            active: true,
          },
        }),
      'already-exists',
      'CODE_ALREADY_EXISTS',
    );

    // Dashboard aggregation
    const dashboard = await executeAdminGetSpinDashboard(db, admin, {
      eventId: TEST_EVENT_ID,
    });
    expect(dashboard.activePlayersCount).toBe(1);
    expect(dashboard.registrationsCount).toBe(450);
    expect(dashboard.stats.totalTicketsIssued).toBe(6);
    expect(dashboard.winCounts.total).toBe(0);
  });
});
