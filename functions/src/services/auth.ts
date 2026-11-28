import type { Firestore } from 'firebase-admin/firestore';
import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';
import { usersAdminCol, usersAdminDoc } from './firestorePaths';

export interface CallerIdentity {
  uid: string;
  email: string;
  displayName: string;
  photoUrl: string;
}

export interface AdminActor {
  uid: string;
  name: string;
}

/**
 * Extracts and requires an authenticated Firebase Auth caller.
 */
export function requireAuth(auth: CallableRequest['auth']): CallerIdentity {
  if (!auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
  const token = (auth.token ?? {}) as Record<string, unknown>;
  return {
    uid: auth.uid,
    email: typeof token.email === 'string' ? token.email.trim() : '',
    displayName: typeof token.name === 'string' ? token.name.trim() : '',
    photoUrl: typeof token.picture === 'string' ? token.picture.trim() : '',
  };
}

/**
 * Verifies the caller is registered in `users-admin`.
 * Uses O(1) lookup on `users-admin/{uid}` first, falling back to `.where('uuid', '==', uid)`
 * for legacy unmigrated auto-ID docs.
 */
export async function assertIsAdmin(
  db: Firestore,
  uid: string,
): Promise<AdminActor> {
  const canonicalSnap = await usersAdminDoc(db, uid).get();
  if (canonicalSnap.exists) {
    const data = canonicalSnap.data() ?? {};
    const name = typeof data.name === 'string' && data.name.trim()
      ? data.name.trim()
      : 'Admin';
    return { uid, name };
  }

  const fallbackQuery = await usersAdminCol(db)
    .where('uuid', '==', uid)
    .limit(1)
    .get();

  if (fallbackQuery.empty) {
    throw new HttpsError(
      'permission-denied',
      'Admin privileges are required for this operation.',
    );
  }

  const data = fallbackQuery.docs[0].data();
  const name = typeof data.name === 'string' && data.name.trim()
    ? data.name.trim()
    : 'Admin';

  // Self-heal the legacy auto-ID doc into users-admin/{uid}: firestore.rules
  // can only check admins with exists() on that path, so admin-only streams
  // (all wins, stand codes) work even if bootstrap-spin was never run.
  try {
    await usersAdminDoc(db, uid).set({ uuid: uid, name }, { merge: true });
  } catch {
    // Best effort: the caller is already verified as admin.
  }

  return { uid, name };
}
