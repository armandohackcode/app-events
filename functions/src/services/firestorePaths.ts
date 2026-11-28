import type {
  CollectionReference,
  DocumentReference,
  Firestore,
} from 'firebase-admin/firestore';

export const STAT_SHARD_COUNT = 5;

export function usersAdminCol(db: Firestore): CollectionReference {
  return db.collection('users-admin');
}

export function usersAdminDoc(db: Firestore, uid: string): DocumentReference {
  return usersAdminCol(db).doc(uid);
}

export function competitorDoc(db: Firestore, uid: string): DocumentReference {
  return db.collection('competitors').doc(uid);
}

export function eventDoc(db: Firestore, eventId: string): DocumentReference {
  return db.collection('events').doc(eventId);
}

export function scheduleCol(db: Firestore, eventId: string): CollectionReference {
  return eventDoc(db, eventId).collection('schedule');
}

export function scheduleDoc(
  db: Firestore,
  eventId: string,
  speakerUuid: string,
): DocumentReference {
  return scheduleCol(db, eventId).doc(speakerUuid);
}

export function workshowCol(
  db: Firestore,
  eventId: string,
  speakerUuid: string,
): CollectionReference {
  return scheduleDoc(db, eventId, speakerUuid).collection('workshow');
}

export function questionsCol(
  db: Firestore,
  eventId: string,
  speakerUuid: string,
): CollectionReference {
  return scheduleDoc(db, eventId, speakerUuid).collection('questions');
}

export function questionDoc(
  db: Firestore,
  eventId: string,
  speakerUuid: string,
  questionId: string,
): DocumentReference {
  return questionsCol(db, eventId, speakerUuid).doc(questionId);
}

export function ratingsCol(
  db: Firestore,
  eventId: string,
  speakerUuid: string,
): CollectionReference {
  return scheduleDoc(db, eventId, speakerUuid).collection('ratings');
}

export function ratingDoc(
  db: Firestore,
  eventId: string,
  speakerUuid: string,
  uid: string,
): DocumentReference {
  return ratingsCol(db, eventId, speakerUuid).doc(uid);
}

export function spinConfigDoc(db: Firestore, eventId: string): DocumentReference {
  return eventDoc(db, eventId).collection('spinConfig').doc('main');
}

export function spinImportLockDoc(
  db: Firestore,
  eventId: string,
): DocumentReference {
  return eventDoc(db, eventId)
    .collection('spinLocks')
    .doc('importRegistrations');
}

export function spinStatsCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('spinStats');
}

export function spinStatsShardDoc(
  db: Firestore,
  eventId: string,
  shardIndex: number,
): DocumentReference {
  return spinStatsCol(db, eventId).doc(`shard_${shardIndex}`);
}

export function spinPrizesCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('spinPrizes');
}

export function spinPrizeDoc(
  db: Firestore,
  eventId: string,
  prizeId: string,
): DocumentReference {
  return spinPrizesCol(db, eventId).doc(prizeId);
}

export function spinMissionsCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('spinMissions');
}

export function spinMissionDoc(
  db: Firestore,
  eventId: string,
  missionId: string,
): DocumentReference {
  return spinMissionsCol(db, eventId).doc(missionId);
}

export function spinMissionSecretDoc(
  db: Firestore,
  eventId: string,
  missionId: string,
): DocumentReference {
  return eventDoc(db, eventId).collection('spinMissionSecrets').doc(missionId);
}

export function spinPlayersCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('spinPlayers');
}

export function spinPlayerDoc(
  db: Firestore,
  eventId: string,
  uid: string,
): DocumentReference {
  return spinPlayersCol(db, eventId).doc(uid);
}

export function spinWinsCol(db: Firestore, eventId: string): CollectionReference {
  return eventDoc(db, eventId).collection('spinWins');
}

export function spinWinDoc(
  db: Firestore,
  eventId: string,
  winId: string,
): DocumentReference {
  return spinWinsCol(db, eventId).doc(winId);
}

export function spinMissionClaimsCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('spinMissionClaims');
}

export function spinMissionClaimDoc(
  db: Firestore,
  eventId: string,
  uid: string,
  missionId: string,
): DocumentReference {
  return spinMissionClaimsCol(db, eventId).doc(`${uid}_${missionId}`);
}

export function spinTicketCodesCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('spinTicketCodes');
}

export function spinTicketCodeDoc(
  db: Firestore,
  eventId: string,
  codeId: string,
): DocumentReference {
  return spinTicketCodesCol(db, eventId).doc(codeId);
}

export function spinCodeClaimsCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('spinCodeClaims');
}

export function spinCodeClaimDoc(
  db: Firestore,
  eventId: string,
  uid: string,
  codeId: string,
): DocumentReference {
  return spinCodeClaimsCol(db, eventId).doc(`${uid}_${codeId}`);
}

export function spinRegistrationsCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('spinRegistrations');
}

export function spinRegistrationDoc(
  db: Firestore,
  eventId: string,
  emailHash: string,
): DocumentReference {
  return spinRegistrationsCol(db, eventId).doc(emailHash);
}

export function spinLogsCol(db: Firestore, eventId: string): CollectionReference {
  return eventDoc(db, eventId).collection('spinLogs');
}

export function spinLogDoc(
  db: Firestore,
  eventId: string,
  uid: string,
  spinRequestId: string,
): DocumentReference {
  return spinLogsCol(db, eventId).doc(`${uid}_${spinRequestId}`);
}

export function ticketLedgerCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('ticketLedger');
}

export function ticketLedgerDoc(
  db: Firestore,
  eventId: string,
  entryId?: string,
): DocumentReference {
  const col = ticketLedgerCol(db, eventId);
  return entryId ? col.doc(entryId) : col.doc();
}

export function spinAuditLogsCol(
  db: Firestore,
  eventId: string,
): CollectionReference {
  return eventDoc(db, eventId).collection('spinAuditLogs');
}

export function spinAuditLogDoc(
  db: Firestore,
  eventId: string,
  auditId?: string,
): DocumentReference {
  const col = spinAuditLogsCol(db, eventId);
  return auditId ? col.doc(auditId) : col.doc();
}
