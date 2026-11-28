import {
  FieldValue,
  Timestamp,
  type Firestore,
  type Transaction,
  type WriteBatch,
} from 'firebase-admin/firestore';
import { shardIndexForUid } from '../domain/codes';
import type { TicketLedgerSource } from '../domain/types';
import {
  STAT_SHARD_COUNT,
  spinAuditLogDoc,
  spinStatsShardDoc,
  ticketLedgerDoc,
} from './firestorePaths';

export interface WriteTicketLedgerParams {
  uid: string;
  delta: number;
  balanceAfter: number;
  source: TicketLedgerSource;
  referenceId: string;
  note: string;
  actorUid: string;
  createdAt?: Timestamp;
  docId?: string;
}

export function writeTicketLedgerEntry(
  writer: Transaction | WriteBatch,
  db: Firestore,
  eventId: string,
  params: WriteTicketLedgerParams,
): void {
  const ref = ticketLedgerDoc(db, eventId, params.docId);
  const payload = {
    uid: params.uid,
    delta: params.delta,
    balanceAfter: params.balanceAfter,
    source: params.source,
    referenceId: params.referenceId,
    note: params.note,
    actorUid: params.actorUid,
    createdAt: params.createdAt ?? Timestamp.now(),
  };

  if ('commit' in writer) {
    writer.set(ref, payload);
  } else {
    writer.set(ref, payload);
  }
}

export interface WriteSpinAuditLogParams {
  action: string;
  actorUid: string;
  actorName: string;
  targetId: string | null;
  summary: string;
  metadata?: Record<string, unknown>;
  createdAt?: Timestamp;
}

export function writeSpinAuditLog(
  writer: Transaction | WriteBatch,
  db: Firestore,
  eventId: string,
  params: WriteSpinAuditLogParams,
): void {
  const ref = spinAuditLogDoc(db, eventId);
  const payload = {
    action: params.action,
    actorUid: params.actorUid,
    actorName: params.actorName,
    targetId: params.targetId,
    summary: params.summary,
    metadata: params.metadata ?? {},
    createdAt: params.createdAt ?? Timestamp.now(),
  };

  if ('commit' in writer) {
    writer.set(ref, payload);
  } else {
    writer.set(ref, payload);
  }
}

export async function saveSpinAuditLog(
  db: Firestore,
  eventId: string,
  params: WriteSpinAuditLogParams,
): Promise<void> {
  const ref = spinAuditLogDoc(db, eventId);
  await ref.set({
    action: params.action,
    actorUid: params.actorUid,
    actorName: params.actorName,
    targetId: params.targetId,
    summary: params.summary,
    metadata: params.metadata ?? {},
    createdAt: params.createdAt ?? Timestamp.now(),
  });
}

export interface StatShardDelta {
  totalSpins?: number;
  totalWins?: number;
  totalBonusSpins?: number;
  totalBonusTickets?: number;
  totalTicketsIssued?: number;
  totalTicketsSpent?: number;
}

/**
 * Atomically increments the user's assigned `spinStats/shard_{k}` document
 * using `FieldValue.increment`. Safe even if the shard document does not yet exist.
 */
export async function incrementStatsShard(
  db: Firestore,
  eventId: string,
  uid: string,
  delta: StatShardDelta,
): Promise<void> {
  const shardIdx = shardIndexForUid(uid, STAT_SHARD_COUNT);
  const ref = spinStatsShardDoc(db, eventId, shardIdx);

  const updateData: Record<string, unknown> = {
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (delta.totalSpins) {
    updateData.totalSpins = FieldValue.increment(delta.totalSpins);
  }
  if (delta.totalWins) {
    updateData.totalWins = FieldValue.increment(delta.totalWins);
  }
  if (delta.totalBonusSpins) {
    updateData.totalBonusSpins = FieldValue.increment(delta.totalBonusSpins);
  }
  if (delta.totalBonusTickets) {
    updateData.totalBonusTickets = FieldValue.increment(delta.totalBonusTickets);
  }
  if (delta.totalTicketsIssued) {
    updateData.totalTicketsIssued = FieldValue.increment(
      delta.totalTicketsIssued,
    );
  }
  if (delta.totalTicketsSpent) {
    updateData.totalTicketsSpent = FieldValue.increment(delta.totalTicketsSpent);
  }

  await ref.set(updateData, { merge: true });
}
