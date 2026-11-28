import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';
import {
  executeAdminAdjustPrizeStock,
  executeAdminUpdateSpinConfig,
  executeAdminUpsertSpinPrize,
} from './callables/admin/configAndPrizes';
import {
  executeAdminUpsertSpinMission,
  executeAdminUpsertTicketCode,
} from './callables/admin/missionsAndCodes';
import {
  executeAdminGrantTickets,
  executeAdminImportRegistrations,
} from './callables/admin/ticketsAndRegistrations';
import {
  executeAdminGetSpinDashboard,
  executeAdminLookupWinByCode,
  executeAdminRedeemWin,
  executeAdminRevokeWin,
} from './callables/admin/winsAndDashboard';
import { executeSpinInitPlayer } from './callables/player/initPlayer';
import {
  executeSpinClaimMission,
  executeSpinSubmitTrivia,
} from './callables/player/missions';
import { executeSpinPull } from './callables/player/spinPull';
import {
  executeSpinSubmitTalkQuestion,
  executeSpinSubmitTalkRating,
} from './callables/player/talkInteractions';
import { executeSpinRedeemTicketCode } from './callables/player/ticketCodes';
import { requireAuth } from './services/auth';

export const REGION = 'us-central1' as const;

if (getApps().length === 0) {
  initializeApp();
}

setGlobalOptions({ region: REGION });

const db = getFirestore();

// ---------------------------------------------------------------------------
// Player Callables (7)
// ---------------------------------------------------------------------------

export const spinInitPlayer = onCall({ region: REGION }, (request) =>
  executeSpinInitPlayer(db, requireAuth(request.auth), request.data),
);

export const spinPull = onCall({ region: REGION }, (request) =>
  executeSpinPull(db, requireAuth(request.auth), request.data),
);

export const spinClaimMission = onCall({ region: REGION }, (request) =>
  executeSpinClaimMission(db, requireAuth(request.auth), request.data),
);

export const spinSubmitTrivia = onCall({ region: REGION }, (request) =>
  executeSpinSubmitTrivia(db, requireAuth(request.auth), request.data),
);

export const spinRedeemTicketCode = onCall({ region: REGION }, (request) =>
  executeSpinRedeemTicketCode(db, requireAuth(request.auth), request.data),
);

export const spinSubmitTalkQuestion = onCall({ region: REGION }, (request) =>
  executeSpinSubmitTalkQuestion(db, requireAuth(request.auth), request.data),
);

export const spinSubmitTalkRating = onCall({ region: REGION }, (request) =>
  executeSpinSubmitTalkRating(db, requireAuth(request.auth), request.data),
);

// ---------------------------------------------------------------------------
// Admin Callables (11)
// ---------------------------------------------------------------------------

export const adminUpdateSpinConfig = onCall({ region: REGION }, (request) =>
  executeAdminUpdateSpinConfig(db, requireAuth(request.auth), request.data),
);

export const adminUpsertSpinPrize = onCall({ region: REGION }, (request) =>
  executeAdminUpsertSpinPrize(db, requireAuth(request.auth), request.data),
);

export const adminAdjustPrizeStock = onCall({ region: REGION }, (request) =>
  executeAdminAdjustPrizeStock(db, requireAuth(request.auth), request.data),
);

export const adminUpsertSpinMission = onCall({ region: REGION }, (request) =>
  executeAdminUpsertSpinMission(db, requireAuth(request.auth), request.data),
);

export const adminUpsertTicketCode = onCall({ region: REGION }, (request) =>
  executeAdminUpsertTicketCode(db, requireAuth(request.auth), request.data),
);

export const adminGrantTickets = onCall({ region: REGION }, (request) =>
  executeAdminGrantTickets(db, requireAuth(request.auth), request.data),
);

export const adminImportRegistrations = onCall({ region: REGION }, (request) =>
  executeAdminImportRegistrations(db, requireAuth(request.auth), request.data),
);

export const adminLookupWinByCode = onCall({ region: REGION }, (request) =>
  executeAdminLookupWinByCode(db, requireAuth(request.auth), request.data),
);

export const adminRedeemWin = onCall({ region: REGION }, (request) =>
  executeAdminRedeemWin(db, requireAuth(request.auth), request.data),
);

export const adminRevokeWin = onCall({ region: REGION }, (request) =>
  executeAdminRevokeWin(db, requireAuth(request.auth), request.data),
);

export const adminGetSpinDashboard = onCall({ region: REGION }, (request) =>
  executeAdminGetSpinDashboard(db, requireAuth(request.auth), request.data),
);
