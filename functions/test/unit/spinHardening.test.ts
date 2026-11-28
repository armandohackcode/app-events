import type { Firestore } from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import { executeAdminAdjustPrizeStock } from '../../src/callables/admin/configAndPrizes';
import { executeAdminUpsertSpinMission } from '../../src/callables/admin/missionsAndCodes';
import { executeAdminImportRegistrations } from '../../src/callables/admin/ticketsAndRegistrations';
import { executeSpinPull } from '../../src/callables/player/spinPull';
import { hashEmail } from '../../src/domain/codes';
import type { CallerIdentity } from '../../src/services/auth';
import { assertIsAdmin } from '../../src/services/auth';
import { closeGameIfPrizesExhausted } from '../../src/services/autoClose';
import {
  spinConfigDoc,
  spinImportLockDoc,
  spinMissionDoc,
  spinPlayerDoc,
  spinPrizeDoc,
  spinRegistrationDoc,
  usersAdminDoc,
} from '../../src/services/firestorePaths';

type StoredRecord = Record<string, unknown>;

interface BatchOp {
  type: 'set' | 'update' | 'delete';
  path: string;
  data?: StoredRecord;
  merge?: boolean;
}

class InMemoryFirestore {
  readonly store = new Map<string, StoredRecord>();
  private autoIdCounter = 0;
  onTxGet?: (path: string) => void | Promise<void>;
  beforeBatchCommit?: (ops: BatchOp[]) => void | Promise<void>;

  get asFirestore(): Firestore {
    return this as unknown as Firestore;
  }

  seedDoc(path: string, data: StoredRecord): void {
    this.store.set(path, { ...data });
  }

  readDoc(path: string): StoredRecord | undefined {
    const val = this.store.get(path);
    return val ? { ...val } : undefined;
  }

  collection(name: string) {
    return this.makeCollectionRef(name);
  }

  doc(path: string) {
    return this.makeDocRef(path);
  }

  batch() {
    const ops: BatchOp[] = [];
    return {
      set: (
        ref: { path: string },
        data: StoredRecord,
        opts?: { merge?: boolean },
      ) => {
        ops.push({ type: 'set', path: ref.path, data: { ...data }, merge: opts?.merge });
      },
      update: (ref: { path: string }, data: StoredRecord) => {
        ops.push({ type: 'update', path: ref.path, data: { ...data } });
      },
      delete: (ref: { path: string }) => {
        ops.push({ type: 'delete', path: ref.path });
      },
      commit: async () => {
        if (this.beforeBatchCommit) {
          await this.beforeBatchCommit([...ops]);
        }
        for (const op of ops) {
          this.applyWriteOp(op);
        }
      },
    };
  }

  async runTransaction<T>(
    fn: (tx: {
      get: (ref: { path: string }) => Promise<ReturnType<InMemoryFirestore['makeSnapshot']>>;
      set: (
        ref: { path: string },
        data: StoredRecord,
        opts?: { merge?: boolean },
      ) => void;
      update: (ref: { path: string }, data: StoredRecord) => void;
      delete: (ref: { path: string }) => void;
    }) => Promise<T>,
  ): Promise<T> {
    const ops: BatchOp[] = [];
    const tx = {
      get: async (ref: { path: string }) => {
        if (this.onTxGet) {
          await this.onTxGet(ref.path);
        }
        // Queries (collection refs with filters) resolve to a query snapshot.
        const maybeQuery = ref as { where?: unknown; get?: () => Promise<unknown> };
        if (typeof maybeQuery.where === 'function' && maybeQuery.get) {
          return (await maybeQuery.get()) as ReturnType<InMemoryFirestore['makeSnapshot']>;
        }
        return this.makeSnapshot(ref.path);
      },
      set: (
        ref: { path: string },
        data: StoredRecord,
        opts?: { merge?: boolean },
      ) => {
        ops.push({ type: 'set', path: ref.path, data: { ...data }, merge: opts?.merge });
      },
      update: (ref: { path: string }, data: StoredRecord) => {
        ops.push({ type: 'update', path: ref.path, data: { ...data } });
      },
      delete: (ref: { path: string }) => {
        ops.push({ type: 'delete', path: ref.path });
      },
    };

    const result = await fn(tx);
    for (const op of ops) {
      this.applyWriteOp(op);
    }
    return result;
  }

  private applyWriteOp(op: BatchOp): void {
    if (op.type === 'delete') {
      this.store.delete(op.path);
      return;
    }
    if (op.type === 'set') {
      const incoming = op.data ?? {};
      if (op.merge) {
        const current = this.store.get(op.path) ?? {};
        this.store.set(op.path, { ...current, ...incoming });
      } else {
        this.store.set(op.path, { ...incoming });
      }
      return;
    }
    const existing = this.store.get(op.path);
    if (!existing) {
      throw new Error(`Document not found for update: ${op.path}`);
    }
    this.store.set(op.path, { ...existing, ...(op.data ?? {}) });
  }

  private makeSnapshot(path: string) {
    const raw = this.store.get(path);
    const segments = path.split('/');
    const id = segments[segments.length - 1] ?? '';
    return {
      exists: raw !== undefined,
      id,
      ref: this.makeDocRef(path),
      data: () => (raw ? { ...raw } : undefined),
    };
  }

  private makeDocRef(path: string) {
    const segments = path.split('/');
    const id = segments[segments.length - 1] ?? '';
    return {
      id,
      path,
      collection: (sub: string) => this.makeCollectionRef(`${path}/${sub}`),
      get: () => Promise.resolve(this.makeSnapshot(path)),
      set: (data: StoredRecord, opts?: { merge?: boolean }) => {
        this.applyWriteOp({ type: 'set', path, data, merge: opts?.merge });
        return Promise.resolve();
      },
      update: (data: StoredRecord) => {
        this.applyWriteOp({ type: 'update', path, data });
        return Promise.resolve();
      },
      delete: () => {
        this.applyWriteOp({ type: 'delete', path });
        return Promise.resolve();
      },
    };
  }

  private makeCollectionRef(
    colPath: string,
    filters: Array<{ field: string; value: unknown }> = [],
  ) {
    const listSnaps = () => {
      const prefix = `${colPath}/`;
      const matched: Array<ReturnType<InMemoryFirestore['makeSnapshot']>> = [];
      for (const [docPath, data] of this.store.entries()) {
        if (!docPath.startsWith(prefix)) continue;
        const remainder = docPath.slice(prefix.length);
        if (remainder.includes('/')) continue;
        const passes = filters.every((f) => data[f.field] === f.value);
        if (passes) {
          matched.push(this.makeSnapshot(docPath));
        }
      }
      return matched;
    };

    return {
      path: colPath,
      doc: (id?: string) => {
        const docId = id ?? `auto-${++this.autoIdCounter}`;
        return this.makeDocRef(`${colPath}/${docId}`);
      },
      where: (field: string, _op: string, value: unknown) =>
        this.makeCollectionRef(colPath, [...filters, { field, value }]),
      limit: (_count: number) => this.makeCollectionRef(colPath, filters),
      select: (..._fields: string[]) => ({
        get: () => {
          const docs = listSnaps();
          return Promise.resolve({ docs, empty: docs.length === 0, size: docs.length });
        },
      }),
      count: () => ({
        get: () =>
          Promise.resolve({
            data: () => ({ count: listSnaps().length }),
          }),
      }),
      get: () => {
        const docs = listSnaps();
        return Promise.resolve({ docs, empty: docs.length === 0, size: docs.length });
      },
    };
  }
}

const ADMIN_CALLER: CallerIdentity = {
  uid: 'admin-1',
  email: 'admin@example.com',
  displayName: 'Admin',
  photoUrl: '',
};

const PLAYER_CALLER: CallerIdentity = {
  uid: 'user-1',
  email: 'player@example.com',
  displayName: 'Ada',
  photoUrl: '',
};

describe('Backend concurrency and atomicity hardening', () => {
  it('executeSpinPull observes concurrent pause inside transaction instead of stale Phase 1 read', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    const eventId = 'evt-1';

    memDb.seedDoc(spinConfigDoc(db, eventId).path, {
      status: 'active',
      pauseMessage: 'Paused mid-flight by admin',
      ticketCostPerSpin: 1,
    });
    memDb.seedDoc(spinPlayerDoc(db, eventId, PLAYER_CALLER.uid).path, {
      uid: PLAYER_CALLER.uid,
      displayName: 'Ada',
      tickets: 3,
      spinsCount: 0,
      winsByRarity: { common: 0, rare: 0, epic: 0, legendary: 0 },
      winsByPrize: {},
    });

    // After Phase 1 reads complete and tx reads spinLogDoc, another admin pauses the game.
    memDb.onTxGet = (path) => {
      if (path.includes('/spinLogs/')) {
        memDb.seedDoc(spinConfigDoc(db, eventId).path, {
          status: 'paused',
          pauseMessage: 'Paused mid-flight by admin',
          ticketCostPerSpin: 1,
        });
      }
    };

    await expect(
      executeSpinPull(db, PLAYER_CALLER, {
        eventId,
        spinRequestId: 'spin-req-1',
      }),
    ).rejects.toMatchObject({
      code: 'failed-precondition',
      details: { reason: 'GAME_PAUSED' },
    });

    const playerAfter = memDb.readDoc(spinPlayerDoc(db, eventId, PLAYER_CALLER.uid).path);
    expect(playerAfter?.tickets).toBe(3);
  });

  it('executeAdminAdjustPrizeStock atomically changes releasedStock with releasedDelta without overwriting concurrent metadata', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    const eventId = 'evt-1';
    const prizeId = 'prize-1';

    memDb.seedDoc(usersAdminDoc(db, ADMIN_CALLER.uid).path, {
      uuid: ADMIN_CALLER.uid,
      name: 'Staff Admin',
    });
    memDb.seedDoc(spinPrizeDoc(db, eventId, prizeId).path, {
      id: prizeId,
      name: 'Original Name',
      description: 'Original Description',
      symbol: 'star',
      imageUrl: null,
      rarity: 'epic',
      initialStock: 10,
      remainingStock: 10,
      awardedCount: 0,
      redeemedCount: 0,
      releasedStock: 4,
      maxPerUser: 1,
      weight: 1.5,
      unlockAt: null,
      active: true,
      order: 2,
    });

    // Simulate concurrent metadata update right as the stock transaction reads the doc.
    memDb.onTxGet = (path) => {
      if (path === spinPrizeDoc(db, eventId, prizeId).path) {
        const current = memDb.readDoc(path) ?? {};
        memDb.seedDoc(path, {
          ...current,
          name: 'Updated Name By Admin B',
          weight: 3.0,
          order: 5,
        });
      }
    };

    const res = await executeAdminAdjustPrizeStock(
      db,
      ADMIN_CALLER,
      {
        eventId,
        prizeId,
        delta: 0,
        releasedDelta: 1,
        reason: 'Release 1 unit',
      },
      { nowMs: 1_700_000_000_000 },
    );

    expect(res.prize.releasedStock).toBe(5);
    expect(res.prize.initialStock).toBe(10);
    expect(res.prize.remainingStock).toBe(10);
    expect(res.prize.name).toBe('Updated Name By Admin B');
    expect(res.prize.weight).toBe(3.0);
    expect(res.prize.order).toBe(5);
  });

  it('executeAdminUpsertSpinMission supports partial active toggle without clobbering concurrent edits', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    const eventId = 'evt-1';
    const missionId = 'mission-1';

    memDb.seedDoc(usersAdminDoc(db, ADMIN_CALLER.uid).path, {
      uuid: ADMIN_CALLER.uid,
      name: 'Staff Admin',
    });
    memDb.seedDoc(spinMissionDoc(db, eventId, missionId).path, {
      id: missionId,
      type: 'profile_complete',
      title: 'Concurrent Edited Title',
      description: 'Concurrent Edited Description',
      rewardTickets: 4,
      targetCount: 1,
      maxCompletionsPerUser: 1,
      actionLabel: null,
      active: false,
      order: 1,
      startsAt: null,
      endsAt: null,
      config: {},
    });

    const res = await executeAdminUpsertSpinMission(
      db,
      ADMIN_CALLER,
      {
        eventId,
        mission: { id: missionId, active: true },
      },
      { nowMs: 1_700_000_000_000 },
    );

    expect(res.created).toBe(false);
    expect(res.mission.active).toBe(true);
    expect(res.mission.title).toBe('Concurrent Edited Title');
    expect(res.mission.description).toBe('Concurrent Edited Description');
    expect(res.mission.rewardTickets).toBe(4);
  });

  it('executeAdminImportRegistrations enforces replaceAll lock, takes over expired lock, and cleans up on errors', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    const eventId = 'evt-1';
    const nowMs = 1_700_000_000_000;

    memDb.seedDoc(usersAdminDoc(db, ADMIN_CALLER.uid).path, {
      uuid: ADMIN_CALLER.uid,
      name: 'Staff Admin',
    });
    memDb.seedDoc(spinConfigDoc(db, eventId).path, {
      status: 'paused',
      registeredAttendeesCount: 1,
    });
    const staleHash = hashEmail('stale@example.com');
    memDb.seedDoc(spinRegistrationDoc(db, eventId, staleHash).path, {
      emailNormalized: 'stale@example.com',
      fullName: 'Stale',
      package: 'VIP',
      checkedIn: false,
    });

    // Lock must live outside spinConfig (which is signed-in readable) so owner/actorUid stay server-only.
    expect(spinImportLockDoc(db, eventId).path).toBe(
      `events/${eventId}/spinLocks/importRegistrations`,
    );

    // Active non-expired lock rejects concurrent replaceAll with aborted.
    memDb.seedDoc(spinImportLockDoc(db, eventId).path, {
      owner: 'other-worker',
      actorUid: ADMIN_CALLER.uid,
      acquiredAtMs: nowMs - 10_000,
      expiresAtMs: nowMs + 60_000,
    });

    await expect(
      executeAdminImportRegistrations(
        db,
        ADMIN_CALLER,
        {
          eventId,
          rows: [
            {
              email: 'ada@example.com',
              fullName: 'Ada Lovelace',
              package: 'VIP',
              checkedIn: true,
            },
          ],
          replaceAll: true,
        },
        { nowMs },
      ),
    ).rejects.toMatchObject({ code: 'aborted' });
    expect(memDb.readDoc(spinRegistrationDoc(db, eventId, staleHash).path)).toBeDefined();

    // Expired lock is safely overridden, stale rows removed, and lock deleted in finally.
    memDb.seedDoc(spinImportLockDoc(db, eventId).path, {
      owner: 'crashed-worker',
      actorUid: ADMIN_CALLER.uid,
      acquiredAtMs: nowMs - 200_000,
      expiresAtMs: nowMs - 1_000,
    });

    const okResult = await executeAdminImportRegistrations(
      db,
      ADMIN_CALLER,
      {
        eventId,
        rows: [
          {
            email: 'ada@example.com',
            fullName: 'Ada Lovelace',
            package: 'VIP',
            checkedIn: true,
          },
        ],
        replaceAll: true,
      },
      { nowMs },
    );

    expect(okResult.importedCount).toBe(1);
    expect(okResult.totalRegistrationsCount).toBe(1);
    expect(memDb.readDoc(spinRegistrationDoc(db, eventId, staleHash).path)).toBeUndefined();
    expect(memDb.readDoc(spinImportLockDoc(db, eventId).path)).toBeUndefined();

    // Failure during batch commit still releases our lock in finally.
    memDb.beforeBatchCommit = () => {
      throw new Error('Simulated batch failure');
    };
    await expect(
      executeAdminImportRegistrations(
        db,
        ADMIN_CALLER,
        {
          eventId,
          rows: [
            {
              email: 'grace@example.com',
              fullName: 'Grace Hopper',
              package: 'Standard',
              checkedIn: false,
            },
          ],
          replaceAll: true,
        },
        { nowMs },
      ),
    ).rejects.toThrow('Simulated batch failure');
    expect(memDb.readDoc(spinImportLockDoc(db, eventId).path)).toBeUndefined();

    // Lock overtaken by another owner before finally is NOT deleted by previous worker.
    const takeoverOwner = 'newer-worker';
    memDb.beforeBatchCommit = () => {
      memDb.seedDoc(spinImportLockDoc(db, eventId).path, {
        owner: takeoverOwner,
        actorUid: ADMIN_CALLER.uid,
        acquiredAtMs: nowMs + 1,
        expiresAtMs: nowMs + 120_000,
      });
      throw new Error('Timed out before commit');
    };

    await expect(
      executeAdminImportRegistrations(
        db,
        ADMIN_CALLER,
        {
          eventId,
          rows: [
            {
              email: 'grace@example.com',
              fullName: 'Grace Hopper',
              package: 'Standard',
              checkedIn: false,
            },
          ],
          replaceAll: true,
        },
        { nowMs },
      ),
    ).rejects.toThrow('Timed out before commit');

    expect(memDb.readDoc(spinImportLockDoc(db, eventId).path)?.owner).toBe(
      takeoverOwner,
    );
  });
});

describe('hashEmail normalization sanity', () => {
  it('stays consistent with registration import keys', () => {
    expect(hashEmail('ADA@EXAMPLE.COM')).toBe(hashEmail('  ada@example.com '));
    expect(Timestamp.fromMillis(1000).toMillis()).toBe(1000);
  });
});

describe('auto-close when prizes run out', () => {
  const eventId = 'evt-1';

  function seedActiveGame(memDb: InMemoryFirestore, db: Firestore): void {
    memDb.seedDoc(spinConfigDoc(db, eventId).path, {
      status: 'active',
      ticketCostPerSpin: 1,
      spinCooldownMs: 0,
      rushMode: true,
      payoutMultiplier: 1000,
      rushMaxWinProbabilityPerSpin: 1,
      bonusProbability: 0,
      minSpinsBetweenWins: 0,
    });
    memDb.seedDoc(spinPlayerDoc(db, eventId, PLAYER_CALLER.uid).path, {
      uid: PLAYER_CALLER.uid,
      displayName: 'Ada',
      tickets: 3,
      spinsCount: 0,
      totalPrizesWon: 0,
      winsByRarity: { common: 0, rare: 0, epic: 0, legendary: 0 },
      winsByPrize: {},
    });
  }

  function seedPrizeDoc(
    memDb: InMemoryFirestore,
    db: Firestore,
    prizeId: string,
    remainingStock: number,
    extra: Record<string, unknown> = {},
  ): void {
    memDb.seedDoc(spinPrizeDoc(db, eventId, prizeId).path, {
      id: prizeId,
      name: `Prize ${prizeId}`,
      symbol: 'cherries',
      rarity: 'common',
      initialStock: Math.max(1, remainingStock),
      remainingStock,
      awardedCount: Math.max(1, remainingStock) - remainingStock,
      releasedStock: Math.max(1, remainingStock),
      maxPerUser: 0,
      weight: 1,
      active: true,
      order: 0,
      ...extra,
    });
  }

  function autoCloseAuditLogs(memDb: InMemoryFirestore): StoredRecord[] {
    return [...memDb.store.entries()]
      .filter(
        ([path, data]) =>
          path.startsWith(`events/${eventId}/spinAuditLogs/`) &&
          data.action === 'auto_close_spin',
      )
      .map(([, data]) => data);
  }

  it('rejects a spin without charging and closes the game when no active prize has stock', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    seedActiveGame(memDb, db);
    seedPrizeDoc(memDb, db, 'stickers', 0);

    await expect(
      executeSpinPull(db, PLAYER_CALLER, {
        eventId,
        spinRequestId: 'spin-sold-out-1',
      }),
    ).rejects.toMatchObject({
      code: 'failed-precondition',
      details: { reason: 'GAME_CLOSED' },
    });

    expect(memDb.readDoc(spinPlayerDoc(db, eventId, PLAYER_CALLER.uid).path)?.tickets).toBe(3);
    expect(memDb.readDoc(spinConfigDoc(db, eventId).path)?.status).toBe('closed');
    expect(autoCloseAuditLogs(memDb)).toHaveLength(1);
  });

  it('closes the game right after a spin wins the last unit of the last prize', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    seedActiveGame(memDb, db);
    seedPrizeDoc(memDb, db, 'android', 1, { rarity: 'legendary', symbol: 'seven' });
    const winningRng = {
      nextFloat: () => 0.01,
      nextInt: (min: number) => min,
    };

    const result = await executeSpinPull(
      db,
      PLAYER_CALLER,
      { eventId, spinRequestId: 'spin-last-unit-1' },
      { rng: winningRng },
    );

    expect(result.outcomeType).toBe('prize');
    expect(memDb.readDoc(spinPrizeDoc(db, eventId, 'android').path)?.remainingStock).toBe(0);
    expect(memDb.readDoc(spinConfigDoc(db, eventId).path)?.status).toBe('closed');

    // The idempotent replay of the winning spin still returns the prize.
    const replay = await executeSpinPull(db, PLAYER_CALLER, {
      eventId,
      spinRequestId: 'spin-last-unit-1',
    });
    expect(replay).toEqual(result);

    // A new spin is rejected and does not charge a ticket.
    await expect(
      executeSpinPull(db, PLAYER_CALLER, {
        eventId,
        spinRequestId: 'spin-after-close-1',
      }),
    ).rejects.toMatchObject({ details: { reason: 'GAME_CLOSED' } });
    expect(memDb.readDoc(spinPlayerDoc(db, eventId, PLAYER_CALLER.uid).path)?.tickets).toBe(2);
  });

  it('keeps the game open while any active prize still has stock, even if not released yet', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    seedActiveGame(memDb, db);
    seedPrizeDoc(memDb, db, 'stickers', 0);
    seedPrizeDoc(memDb, db, 'android', 1, {
      unlockAt: Timestamp.fromMillis(Date.parse('2030-01-01T00:00:00Z')),
    });
    seedPrizeDoc(memDb, db, 'retired', 5, { active: false });

    expect(await closeGameIfPrizesExhausted(db, eventId)).toBe(false);
    expect(memDb.readDoc(spinConfigDoc(db, eventId).path)?.status).toBe('active');
  });

  it('only auto-closes an active game, never a paused one', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    seedActiveGame(memDb, db);
    memDb.seedDoc(spinConfigDoc(db, eventId).path, { status: 'paused' });
    seedPrizeDoc(memDb, db, 'stickers', 0);

    expect(await closeGameIfPrizesExhausted(db, eventId)).toBe(false);
    expect(memDb.readDoc(spinConfigDoc(db, eventId).path)?.status).toBe('paused');
  });

  it('closes the game when an admin adjusts the last prize stock down to zero', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    seedActiveGame(memDb, db);
    memDb.seedDoc(usersAdminDoc(db, ADMIN_CALLER.uid).path, {
      uuid: ADMIN_CALLER.uid,
      name: 'Staff Admin',
    });
    seedPrizeDoc(memDb, db, 'stickers', 2);

    await executeAdminAdjustPrizeStock(db, ADMIN_CALLER, {
      eventId,
      prizeId: 'stickers',
      delta: -2,
      reason: 'Box damaged',
    });

    expect(memDb.readDoc(spinConfigDoc(db, eventId).path)?.status).toBe('closed');
  });
});

describe('admin registry self-healing', () => {
  it('copies a legacy auto-ID users-admin doc to users-admin/{uid} so rules recognize the admin', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;
    memDb.seedDoc('users-admin/legacy-auto-id', {
      uuid: ADMIN_CALLER.uid,
      name: 'Legacy Admin',
    });

    const actor = await assertIsAdmin(db, ADMIN_CALLER.uid);

    expect(actor).toEqual({ uid: ADMIN_CALLER.uid, name: 'Legacy Admin' });
    expect(memDb.readDoc(usersAdminDoc(db, ADMIN_CALLER.uid).path)).toEqual({
      uuid: ADMIN_CALLER.uid,
      name: 'Legacy Admin',
    });
  });

  it('still rejects callers that are not in users-admin', async () => {
    const memDb = new InMemoryFirestore();
    const db = memDb.asFirestore;

    await expect(assertIsAdmin(db, 'stranger')).rejects.toMatchObject({
      code: 'permission-denied',
    });
    expect(memDb.readDoc(usersAdminDoc(db, 'stranger').path)).toBeUndefined();
  });
});
