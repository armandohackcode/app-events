import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import type { SpinPrize } from '../domain/types';
import { parseSpinConfig, parseSpinPrize } from './converters';
import { spinConfigDoc, spinPrizesCol } from './firestorePaths';
import { writeSpinAuditLog } from './ledger';

export const AUTO_CLOSE_ACTOR_UID = 'system:auto_close';
export const AUTO_CLOSE_ACTOR_NAME = 'GDG SPIN';

/**
 * Returns true when at least one active prize still has physical stock left.
 *
 * Stock that is not released yet (pacing waves, `unlockAt`) still counts:
 * the game stays open because those prizes become winnable later.
 */
export function hasWinnableStock(prizes: readonly SpinPrize[]): boolean {
  return prizes.some((prize) => prize.active && prize.remainingStock > 0);
}

/**
 * Closes the game (`status: 'closed'`) when it is `active` and no active
 * prize has stock left. Runs in its own transaction so the hot spin
 * transaction never takes a write lock on `spinConfig/main`.
 *
 * Returns true only when this call closed the game. Reopening after a
 * restock stays a manual admin action.
 */
export async function closeGameIfPrizesExhausted(
  db: Firestore,
  eventId: string,
  nowMs: number = Date.now(),
): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const configRef = spinConfigDoc(db, eventId);
    const configSnap = await tx.get(configRef);
    if (!configSnap.exists) return false;

    const config = parseSpinConfig(configSnap.data() ?? {});
    if (config.status !== 'active') return false;

    const prizesSnap = await tx.get(
      spinPrizesCol(db, eventId).where('active', '==', true),
    );
    const prizes = prizesSnap.docs.map((docSnap) =>
      parseSpinPrize(docSnap.id, docSnap.data()),
    );
    if (hasWinnableStock(prizes)) return false;

    const nowTs = Timestamp.fromMillis(nowMs);
    tx.update(configRef, {
      status: 'closed',
      updatedAt: nowTs,
      updatedBy: AUTO_CLOSE_ACTOR_UID,
    });

    writeSpinAuditLog(tx, db, eventId, {
      action: 'auto_close_spin',
      actorUid: AUTO_CLOSE_ACTOR_UID,
      actorName: AUTO_CLOSE_ACTOR_NAME,
      targetId: 'main',
      summary: 'GDG SPIN closed automatically: no prizes left in stock',
      metadata: {
        previousStatus: config.status,
        nextStatus: 'closed',
        activePrizeCount: prizes.length,
      },
      createdAt: nowTs,
    });

    return true;
  });
}

/**
 * Best-effort wrapper used after mutations that can deplete stock. A failure
 * here must never fail the mutation that already committed.
 */
export async function tryCloseGameIfPrizesExhausted(
  db: Firestore,
  eventId: string,
  nowMs: number = Date.now(),
): Promise<boolean> {
  try {
    return await closeGameIfPrizesExhausted(db, eventId, nowMs);
  } catch {
    return false;
  }
}
