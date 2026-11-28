import { beforeEach, describe, expect, it } from 'vitest';
import { nodeCryptoRng, type CryptoRng } from '../../src/domain/pacing';
import { executeSpinInitPlayer } from '../../src/callables/player/initPlayer';
import { executeSpinPull } from '../../src/callables/player/spinPull';
import {
  STAT_SHARD_COUNT,
  spinPrizeDoc,
  spinStatsShardDoc,
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

function fixedRng(floatVal: number): CryptoRng {
  return {
    nextFloat: () => floatVal,
    nextInt: (min: number, maxExclusive: number) =>
      nodeCryptoRng.nextInt(min, maxExclusive),
  };
}

describe('spinPull idempotency (emulator)', () => {
  const db = getEmulatorFirestore();

  beforeEach(async () => {
    await clearEmulatorFirestore();
    await seedAdmin(db, ADMIN_UID);
  });

  it('replays identical win responseSnapshot without double-charging or double-decrementing stock', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        status: 'active',
        defaultInitialTickets: 3,
        rushMode: true,
        payoutMultiplier: 10,
        rushMaxWinProbabilityPerSpin: 1.0,
        bonusProbability: 0,
        spinCooldownMs: 2500,
      },
    });
    await seedPrize(db, TEST_EVENT_ID, 'mug', {
      symbol: 'bell',
      rarity: 'rare',
      initialStock: 5,
      remainingStock: 5,
    });

    const caller = makeCaller('alice');
    await executeSpinInitPlayer(db, caller, { eventId: TEST_EVENT_ID }, { nowMs });

    const reqId = 'idem-win-req-0001';
    const first = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: reqId },
      { nowMs: nowMs + 1000, rng: fixedRng(0.05) },
    );

    expect(first.outcomeType).toBe('prize');
    expect(first.ticketsAfter).toBe(2);
    expect(first.wonPrize?.prizeId).toBe('mug');

    // Replay immediately (even inside cooldown window) with identical spinRequestId
    const second = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: reqId },
      { nowMs: nowMs + 1050, rng: fixedRng(0.99) },
    );

    expect(second).toEqual(first);

    const prizeSnap = await spinPrizeDoc(db, TEST_EVENT_ID, 'mug').get();
    expect(prizeSnap.data()!.remainingStock).toBe(4);
    expect(prizeSnap.data()!.awardedCount).toBe(1);

    const winsSnap = await spinWinsCol(db, TEST_EVENT_ID).get();
    expect(winsSnap.size).toBe(1);

    const shardSnaps = await Promise.all(
      Array.from({ length: STAT_SHARD_COUNT }, (_, i) =>
        spinStatsShardDoc(db, TEST_EVENT_ID, i).get(),
      ),
    );
    const totalSpins = shardSnaps.reduce(
      (sum, s) => sum + parseSpinStatsShard(s.data()).totalSpins,
      0,
    );
    expect(totalSpins).toBe(1);

    const balance = await assertLedgerReconciles(db, TEST_EVENT_ID, 'alice');
    expect(balance).toBe(2);
  });

  it('replays identical bonus responseSnapshot without double-crediting bonus tickets', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        status: 'active',
        defaultInitialTickets: 2,
        bonusProbability: 0.5,
        bonusMinTickets: 2,
        bonusMaxTickets: 2,
        spinCooldownMs: 0,
      },
    });
    // Stock must exist: with no prizes left the game rejects every spin.
    await seedPrize(db, TEST_EVENT_ID, 'stickers');

    const caller = makeCaller('bob');
    await executeSpinInitPlayer(db, caller, { eventId: TEST_EVENT_ID }, { nowMs });

    const reqId = 'idem-bonus-req-0001';
    const first = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: reqId },
      { nowMs: nowMs + 1000, rng: fixedRng(0.1) },
    );
    expect(first.outcomeType).toBe('bonus');
    expect(first.bonusTickets).toBe(2);
    expect(first.ticketsAfter).toBe(3);

    const second = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: reqId },
      { nowMs: nowMs + 2000, rng: fixedRng(0.99) },
    );
    expect(second).toEqual(first);

    const balance = await assertLedgerReconciles(db, TEST_EVENT_ID, 'bob');
    expect(balance).toBe(3);
  });
});
