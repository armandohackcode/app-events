import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { Timestamp } from 'firebase-admin/firestore';
import { executeAdminUpsertTicketCode } from '../../src/callables/admin/missionsAndCodes';
import { executeSpinInitPlayer } from '../../src/callables/player/initPlayer';
import { executeSpinPull } from '../../src/callables/player/spinPull';
import { executeSpinRedeemTicketCode } from '../../src/callables/player/ticketCodes';
import {
  STAT_SHARD_COUNT,
  spinLogsCol,
  spinPrizeDoc,
  spinStatsShardDoc,
  spinTicketCodeDoc,
  spinWinsCol,
} from '../../src/services/firestorePaths';
import { parseSpinStatsShard } from '../../src/services/converters';
import {
  ADMIN_UID,
  TEST_EVENT_ID,
  assertLedgerReconciles,
  clearEmulatorFirestore,
  getEmulatorFirestore,
  makeCaller,
  seedAdmin,
  seedPrize,
  seedSpinBaseline,
} from './helpers';

describe('concurrency & atomic stock stress tests (emulator)', () => {
  const db = getEmulatorFirestore();

  beforeAll(() => {
    // Ensure emulator connection is initialized
  });

  beforeEach(async () => {
    await clearEmulatorFirestore();
    await seedAdmin(db, ADMIN_UID);
  });

  it('guarantees exactly 1 winner out of 20 simultaneous spinPull calls against stock = 1', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        status: 'active',
        defaultInitialTickets: 2,
        rushMode: true,
        payoutMultiplier: 1000,
        rushMaxWinProbabilityPerSpin: 1.0,
        rushBypassUnlockAt: false,
        bonusProbability: 0,
        spinCooldownMs: 0,
        estimatedTotalSpinsOverride: 20,
      },
    });

    // Locked stock keeps the game open, so the 19 other spins resolve as
    // losses instead of being rejected by the auto-close rule.
    await seedPrize(db, TEST_EVENT_ID, 'locked-later', {
      unlockAt: Timestamp.fromMillis(Date.parse('2030-01-01T00:00:00Z')),
      order: 1,
    });
    await seedPrize(db, TEST_EVENT_ID, 'android', {
      name: 'Android Figure',
      symbol: 'seven',
      rarity: 'legendary',
      initialStock: 1,
      remainingStock: 1,
      releasedStock: 1,
    });

    const userIds = Array.from({ length: 20 }, (_, i) => `concurrent-user-${i}`);
    await Promise.all(
      userIds.map((uid) =>
        executeSpinInitPlayer(
          db,
          makeCaller(uid),
          { eventId: TEST_EVENT_ID },
          { nowMs },
        ),
      ),
    );

    const results = await Promise.all(
      userIds.map((uid, idx) =>
        executeSpinPull(
          db,
          makeCaller(uid),
          {
            eventId: TEST_EVENT_ID,
            spinRequestId: `req-stress-${idx.toString().padStart(4, '0')}`,
          },
          { nowMs: nowMs + 1000 },
        ),
      ),
    );

    const winners = results.filter((r) => r.outcomeType === 'prize');
    const losers = results.filter((r) => r.outcomeType === 'lose');

    expect(winners).toHaveLength(1);
    expect(losers).toHaveLength(19);
    expect(winners[0].wonPrize).not.toBeNull();
    expect(winners[0].wonPrize!.prizeId).toBe('android');

    const prizeSnap = await spinPrizeDoc(db, TEST_EVENT_ID, 'android').get();
    expect(prizeSnap.exists).toBe(true);
    const prizeData = prizeSnap.data()!;
    expect(prizeData.remainingStock).toBe(0);
    expect(prizeData.awardedCount).toBe(1);
    expect(prizeData.initialStock).toBe(1);

    const winsSnap = await spinWinsCol(db, TEST_EVENT_ID).get();
    expect(winsSnap.size).toBe(1);
    expect(winsSnap.docs[0].id).toBe(winners[0].wonPrize!.winId);

    const logsSnap = await spinLogsCol(db, TEST_EVENT_ID).get();
    expect(logsSnap.size).toBe(20);

    const shardSnaps = await Promise.all(
      Array.from({ length: STAT_SHARD_COUNT }, (_, i) =>
        spinStatsShardDoc(db, TEST_EVENT_ID, i).get(),
      ),
    );
    const totalSpins = shardSnaps.reduce(
      (sum, s) => sum + parseSpinStatsShard(s.data()).totalSpins,
      0,
    );
    const totalWins = shardSnaps.reduce(
      (sum, s) => sum + parseSpinStatsShard(s.data()).totalWins,
      0,
    );
    expect(totalSpins).toBe(20);
    expect(totalWins).toBe(1);

    for (const uid of userIds) {
      const balance = await assertLedgerReconciles(db, TEST_EVENT_ID, uid);
      expect(balance).toBe(1);
    }
  });

  it('rerolls cleanly onto a second prize when the first prize depletes concurrently', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        status: 'active',
        defaultInitialTickets: 1,
        rushMode: true,
        payoutMultiplier: 1000,
        rushMaxWinProbabilityPerSpin: 1.0,
        bonusProbability: 0,
        spinCooldownMs: 0,
        estimatedTotalSpinsOverride: 20,
      },
    });

    await seedPrize(db, TEST_EVENT_ID, 'p-rare', {
      symbol: 'bell',
      rarity: 'rare',
      initialStock: 1,
      remainingStock: 1,
      weight: 10,
    });
    await seedPrize(db, TEST_EVENT_ID, 'p-common', {
      symbol: 'cherries',
      rarity: 'common',
      initialStock: 10,
      remainingStock: 10,
      weight: 1,
    });

    const userIds = Array.from({ length: 10 }, (_, i) => `reroll-user-${i}`);
    await Promise.all(
      userIds.map((uid) =>
        executeSpinInitPlayer(
          db,
          makeCaller(uid),
          { eventId: TEST_EVENT_ID },
          { nowMs },
        ),
      ),
    );

    const results = await Promise.all(
      userIds.map((uid, idx) =>
        executeSpinPull(
          db,
          makeCaller(uid),
          {
            eventId: TEST_EVENT_ID,
            spinRequestId: `req-reroll-${idx.toString().padStart(4, '0')}`,
          },
          { nowMs: nowMs + 1000 },
        ),
      ),
    );

    const rareWins = results.filter((r) => r.wonPrize?.prizeId === 'p-rare');
    const commonWins = results.filter((r) => r.wonPrize?.prizeId === 'p-common');
    expect(rareWins).toHaveLength(1);
    expect(rareWins.length + commonWins.length).toBe(10);

    const rareSnap = await spinPrizeDoc(db, TEST_EVENT_ID, 'p-rare').get();
    expect(rareSnap.data()!.remainingStock).toBe(0);
    expect(rareSnap.data()!.awardedCount).toBe(1);

    const commonSnap = await spinPrizeDoc(db, TEST_EVENT_ID, 'p-common').get();
    expect(commonSnap.data()!.remainingStock).toBe(1);
    expect(commonSnap.data()!.awardedCount).toBe(9);
  });

  it('allows only 1 winner out of 10 simultaneous stand code claims with maxTotalUses = 1', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, { eventId: TEST_EVENT_ID, nowMs });

    const createdCode = await executeAdminUpsertTicketCode(
      db,
      makeCaller(ADMIN_UID),
      {
        eventId: TEST_EVENT_ID,
        codeConfig: {
          id: 'single-use-stand',
          code: 'LIMITED1',
          label: 'Exclusive Stand',
          rewardTickets: 2,
          maxTotalUses: 1,
          maxUsesPerUser: 1,
          active: true,
        },
      },
      { nowMs },
    );

    const userIds = Array.from({ length: 10 }, (_, i) => `code-user-${i}`);
    const settled = await Promise.allSettled(
      userIds.map((uid) =>
        executeSpinRedeemTicketCode(
          db,
          makeCaller(uid),
          { eventId: TEST_EVENT_ID, code: 'LIMITED1' },
          { nowMs: nowMs + 500 },
        ),
      ),
    );

    const succeeded = settled.filter((s) => s.status === 'fulfilled');
    const failed = settled.filter((s) => s.status === 'rejected');

    expect(succeeded).toHaveLength(1);
    expect(failed).toHaveLength(9);

    const codeSnap = await spinTicketCodeDoc(
      db,
      TEST_EVENT_ID,
      createdCode.ticketCode.id,
    ).get();
    expect(codeSnap.data()!.usedCount).toBe(1);
  });
});
