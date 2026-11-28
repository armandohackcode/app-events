import { HttpsError } from 'firebase-functions/v2/https';
import { beforeEach, describe, expect, it } from 'vitest';
import { nodeCryptoRng, type CryptoRng } from '../../src/domain/pacing';
import { executeAdminUpdateSpinConfig } from '../../src/callables/admin/configAndPrizes';
import { executeSpinInitPlayer } from '../../src/callables/player/initPlayer';
import { executeSpinPull } from '../../src/callables/player/spinPull';
import {
  spinConfigDoc,
  spinPlayerDoc,
  spinPrizeDoc,
} from '../../src/services/firestorePaths';
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

async function expectFailedPreconditionReason(
  fn: () => Promise<unknown>,
  expectedReason: string,
): Promise<void> {
  try {
    await fn();
    expect.unreachable(`Expected HttpsError with reason ${expectedReason}`);
  } catch (error) {
    expect(error).toBeInstanceOf(HttpsError);
    const httpsErr = error as HttpsError;
    expect(httpsErr.code).toBe('failed-precondition');
    expect((httpsErr.details as { reason?: string } | undefined)?.reason).toBe(
      expectedReason,
    );
  }
}

describe('caps, cooldowns & status guards (emulator)', () => {
  const db = getEmulatorFirestore();

  beforeEach(async () => {
    await clearEmulatorFirestore();
    await seedAdmin(db, ADMIN_UID);
  });

  it('rejects spins when game is paused or closed and when tickets are exhausted', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        status: 'paused',
        defaultInitialTickets: 1,
      },
    });
    // Stock must exist: with no prizes left the game rejects every spin.
    await seedPrize(db, TEST_EVENT_ID, 'stickers');

    const caller = makeCaller('alice');
    await executeSpinInitPlayer(db, caller, { eventId: TEST_EVENT_ID }, { nowMs });

    await expectFailedPreconditionReason(
      () =>
        executeSpinPull(
          db,
          caller,
          { eventId: TEST_EVENT_ID, spinRequestId: 'req-paused-001' },
          { nowMs: nowMs + 100 },
        ),
      'GAME_PAUSED',
    );

    await executeAdminUpdateSpinConfig(
      db,
      makeCaller(ADMIN_UID),
      { eventId: TEST_EVENT_ID, patch: { status: 'closed' } },
      { nowMs: nowMs + 200 },
    );

    await expectFailedPreconditionReason(
      () =>
        executeSpinPull(
          db,
          caller,
          { eventId: TEST_EVENT_ID, spinRequestId: 'req-closed-001' },
          { nowMs: nowMs + 300 },
        ),
      'GAME_CLOSED',
    );

    await executeAdminUpdateSpinConfig(
      db,
      makeCaller(ADMIN_UID),
      { eventId: TEST_EVENT_ID, patch: { status: 'active' } },
      { nowMs: nowMs + 400 },
    );

    // 1st pull spends last ticket
    const pull1 = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-spend-001' },
      { nowMs: nowMs + 500, rng: fixedRng(0.99) },
    );
    expect(pull1.ticketsAfter).toBe(0);

    // 2nd pull fails with INSUFFICIENT_TICKETS
    await expectFailedPreconditionReason(
      () =>
        executeSpinPull(
          db,
          caller,
          { eventId: TEST_EVENT_ID, spinRequestId: 'req-empty-002' },
          { nowMs: nowMs + 10000 },
        ),
      'INSUFFICIENT_TICKETS',
    );
  });

  it('enforces spinCooldownMs between consecutive pulls', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        status: 'active',
        defaultInitialTickets: 3,
        spinCooldownMs: 2500,
      },
    });
    await seedPrize(db, TEST_EVENT_ID, 'stickers');

    const caller = makeCaller('alice');
    await executeSpinInitPlayer(db, caller, { eventId: TEST_EVENT_ID }, { nowMs });

    await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-cool-0001' },
      { nowMs: nowMs + 1000, rng: fixedRng(0.99) },
    );

    await expectFailedPreconditionReason(
      () =>
        executeSpinPull(
          db,
          caller,
          { eventId: TEST_EVENT_ID, spinRequestId: 'req-cool-0002' },
          { nowMs: nowMs + 2000, rng: fixedRng(0.99) },
        ),
      'COOLDOWN_ACTIVE',
    );

    const okAfterCooldown = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-cool-0003' },
      { nowMs: nowMs + 3500, rng: fixedRng(0.99) },
    );
    expect(okAfterCooldown.spinsCountAfter).toBe(2);
  });

  it('enforces maxPrizesPerUser, maxWinsByRarity, prize.maxPerUser, minSpinsBetweenWins, and maxBonusWinsPerUser', async () => {
    const nowMs = Date.parse('2026-11-28T15:00:00-04:00');
    await seedSpinBaseline(db, {
      eventId: TEST_EVENT_ID,
      nowMs,
      configOverrides: {
        status: 'active',
        defaultInitialTickets: 10,
        rushMode: true,
        payoutMultiplier: 100,
        rushMaxWinProbabilityPerSpin: 1.0,
        maxPrizesPerUser: 2,
        allowPlayAfterCap: false,
        maxWinsByRarity: { common: 2, rare: 1, epic: 1, legendary: 1 },
        minSpinsBetweenWins: 1,
        bonusProbability: 0,
        maxBonusWinsPerUser: 1,
        spinCooldownMs: 0,
      },
    });

    await seedPrize(db, TEST_EVENT_ID, 'mug', {
      symbol: 'bell',
      rarity: 'rare',
      initialStock: 10,
      remainingStock: 10,
      maxPerUser: 1,
      weight: 100,
      order: 0,
    });
    await seedPrize(db, TEST_EVENT_ID, 'shirt', {
      symbol: 'bar',
      rarity: 'rare',
      initialStock: 10,
      remainingStock: 10,
      maxPerUser: 2,
      weight: 1,
      order: 1,
    });
    await seedPrize(db, TEST_EVENT_ID, 'stickers', {
      symbol: 'cherries',
      rarity: 'common',
      initialStock: 10,
      remainingStock: 10,
      maxPerUser: 1,
      weight: 0.5,
      order: 2,
    });

    const caller = makeCaller('alice');
    await executeSpinInitPlayer(db, caller, { eventId: TEST_EVENT_ID }, { nowMs });

    // Spin 1: wins rare mug (weight 100)
    const spin1 = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-cap-0001' },
      { nowMs: nowMs + 100, rng: fixedRng(0.01) },
    );
    expect(spin1.outcomeType).toBe('prize');
    expect(spin1.wonPrize?.prizeId).toBe('mug');

    // Spin 2: blocked from winning any prize due to minSpinsBetweenWins = 1 -> forced lose
    const spin2 = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-cap-0002' },
      { nowMs: nowMs + 200, rng: fixedRng(0.01) },
    );
    expect(spin2.outcomeType).toBe('lose');

    // Spin 3: mug is blocked (prize.maxPerUser = 1) AND shirt is blocked (maxWinsByRarity.rare = 1) -> wins common stickers
    const spin3 = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-cap-0003' },
      { nowMs: nowMs + 300, rng: fixedRng(0.01) },
    );
    expect(spin3.outcomeType).toBe('prize');
    expect(spin3.wonPrize?.prizeId).toBe('stickers');
    expect(spin3.reachedPrizeCap).toBe(true);

    // Spin 4: blocked with PRIZE_CAP_REACHED since allowPlayAfterCap is false
    await expectFailedPreconditionReason(
      () =>
        executeSpinPull(
          db,
          caller,
          { eventId: TEST_EVENT_ID, spinRequestId: 'req-cap-0004' },
          { nowMs: nowMs + 400, rng: fixedRng(0.01) },
        ),
      'PRIZE_CAP_REACHED',
    );

    // Allow play after cap and enable bonusProbability = 1.0 (Wait: schema max is 0.5, so use rng 0.1 < 0.5)
    await executeAdminUpdateSpinConfig(
      db,
      makeCaller(ADMIN_UID),
      {
        eventId: TEST_EVENT_ID,
        patch: {
          allowPlayAfterCap: true,
          bonusProbability: 0.5,
          bonusMinTickets: 1,
          bonusMaxTickets: 1,
          maxBonusWinsPerUser: 1,
        },
      },
      { nowMs: nowMs + 500 },
    );

    // Spin 5: wins bonus (1/1)
    const spin5 = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-cap-0005' },
      { nowMs: nowMs + 600, rng: fixedRng(0.1) },
    );
    expect(spin5.outcomeType).toBe('bonus');
    expect(spin5.bonusTickets).toBe(1);

    // Spin 6: bonus cap reached AND prize cap reached -> must lose
    const spin6 = await executeSpinPull(
      db,
      caller,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-cap-0006' },
      { nowMs: nowMs + 700, rng: fixedRng(0.1) },
    );
    expect(spin6.outcomeType).toBe('lose');

    const playerSnap = await spinPlayerDoc(db, TEST_EVENT_ID, 'alice').get();
    expect(playerSnap.data()!.bonusWinsCount).toBe(1);
    expect(playerSnap.data()!.totalPrizesWon).toBe(2);
    await assertLedgerReconciles(db, TEST_EVENT_ID, 'alice');
  });

  it('auto-closes the game when the last prize unit is won and rejects later spins without charging', async () => {
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
        bonusProbability: 0,
        spinCooldownMs: 0,
      },
    });
    await seedPrize(db, TEST_EVENT_ID, 'android', {
      symbol: 'seven',
      rarity: 'legendary',
      initialStock: 1,
      remainingStock: 1,
      releasedStock: 1,
    });

    const alice = makeCaller('alice');
    const bob = makeCaller('bob');
    await executeSpinInitPlayer(db, alice, { eventId: TEST_EVENT_ID }, { nowMs });
    await executeSpinInitPlayer(db, bob, { eventId: TEST_EVENT_ID }, { nowMs });

    const win = await executeSpinPull(
      db,
      alice,
      { eventId: TEST_EVENT_ID, spinRequestId: 'req-last-unit-01' },
      { nowMs: nowMs + 100, rng: fixedRng(0.01) },
    );
    expect(win.outcomeType).toBe('prize');

    const prizeSnap = await spinPrizeDoc(db, TEST_EVENT_ID, 'android').get();
    expect(prizeSnap.data()!.remainingStock).toBe(0);
    const configSnap = await spinConfigDoc(db, TEST_EVENT_ID).get();
    expect(configSnap.data()!.status).toBe('closed');

    await expectFailedPreconditionReason(
      () =>
        executeSpinPull(
          db,
          bob,
          { eventId: TEST_EVENT_ID, spinRequestId: 'req-after-close-01' },
          { nowMs: nowMs + 200 },
        ),
      'GAME_CLOSED',
    );
    const bobBalance = await assertLedgerReconciles(db, TEST_EVENT_ID, 'bob');
    expect(bobBalance).toBe(2);
  });
});
