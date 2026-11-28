import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { hashEmail } from '../../domain/codes';
import { spinInitPlayerSchema } from '../../domain/schemas';
import type { SpinInitPlayerResponseDto, SpinPlayer } from '../../domain/types';
import type { CallerIdentity } from '../../services/auth';
import {
  buildEmptySpinPlayerRecord,
  parseInput,
  parseSpinConfig,
  parseSpinPlayer,
  throwSpinError,
  toSpinPlayerDto,
} from '../../services/converters';
import {
  competitorDoc,
  spinConfigDoc,
  spinPlayerDoc,
  spinRegistrationDoc,
} from '../../services/firestorePaths';
import { incrementStatsShard, writeTicketLedgerEntry } from '../../services/ledger';

export interface InitPlayerExecutionOptions {
  nowMs?: number;
}

export async function executeSpinInitPlayer(
  db: Firestore,
  caller: CallerIdentity,
  rawInput: unknown,
  options: InitPlayerExecutionOptions = {},
): Promise<SpinInitPlayerResponseDto> {
  const input = parseInput(spinInitPlayerSchema, rawInput);
  const nowMs = options.nowMs ?? Date.now();
  const nowTs = Timestamp.fromMillis(nowMs);

  const txResult = await db.runTransaction(async (tx) => {
    const configRef = spinConfigDoc(db, input.eventId);
    const playerRef = spinPlayerDoc(db, input.eventId, caller.uid);
    const competitorRef = competitorDoc(db, caller.uid);

    const configSnap = await tx.get(configRef);
    if (!configSnap.exists) {
      throwSpinError(
        'failed-precondition',
        'Spin configuration has not been initialized for this event.',
        'CONFIG_NOT_FOUND',
      );
    }
    const config = parseSpinConfig(configSnap.data() ?? {});

    const playerSnap = await tx.get(playerRef);
    const competitorSnap = await tx.get(competitorRef);
    const competitorData = competitorSnap.exists
      ? (competitorSnap.data() ?? {})
      : {};

    const existingPlayer: SpinPlayer = playerSnap.exists
      ? parseSpinPlayer(caller.uid, playerSnap.data() ?? {})
      : parseSpinPlayer(
          caller.uid,
          buildEmptySpinPlayerRecord({
            uid: caller.uid,
            displayName: '',
            email: '',
            nowTs,
          }),
        );

    const competitorName =
      typeof competitorData.name === 'string' ? competitorData.name.trim() : '';
    const displayName =
      caller.displayName ||
      competitorName ||
      existingPlayer.displayName ||
      'Asistente';
    const email = caller.email || existingPlayer.email;

    const regRef =
      config.matchRegistrationByEmail && email.trim().length > 0
        ? spinRegistrationDoc(db, input.eventId, hashEmail(email))
        : null;
    const regSnap = regRef ? await tx.get(regRef) : null;

    let tickets = existingPlayer.tickets;
    let totalTicketsEarned = existingPlayer.totalTicketsEarned;
    let initialTicketsGranted = existingPlayer.initialTicketsGranted;
    let packageBonusGranted = existingPlayer.packageBonusGranted;
    let matchedPackage = existingPlayer.matchedPackage;

    let initialGrantedThisCall = false;
    let packageBonusGrantedThisCall = false;
    let ticketsIssuedDelta = 0;

    if (!initialTicketsGranted) {
      initialTicketsGranted = true;
      initialGrantedThisCall = true;
      const initialTickets = config.defaultInitialTickets;
      if (initialTickets > 0) {
        tickets += initialTickets;
        totalTicketsEarned += initialTickets;
        ticketsIssuedDelta += initialTickets;
        writeTicketLedgerEntry(tx, db, input.eventId, {
          uid: caller.uid,
          delta: initialTickets,
          balanceAfter: tickets,
          source: 'initial',
          referenceId: input.eventId,
          note: 'Tickets iniciales del evento',
          actorUid: caller.uid,
          createdAt: nowTs,
          docId: `init_${caller.uid}`,
        });
      }
    }

    if (!packageBonusGranted && regSnap && regSnap.exists) {
      const regData = regSnap.data() ?? {};
      const pkg =
        typeof regData.package === 'string' ? regData.package.trim() : '';
      matchedPackage = pkg || null;
      packageBonusGranted = true;
      packageBonusGrantedThisCall = true;

      const rawBonus =
        pkg && typeof config.packageTicketBonus[pkg] === 'number'
          ? config.packageTicketBonus[pkg]
          : 0;
      const packageBonus = Math.max(0, Math.trunc(rawBonus));
      if (packageBonus > 0) {
        tickets += packageBonus;
        totalTicketsEarned += packageBonus;
        ticketsIssuedDelta += packageBonus;
        writeTicketLedgerEntry(tx, db, input.eventId, {
          uid: caller.uid,
          delta: packageBonus,
          balanceAfter: tickets,
          source: 'package_bonus',
          referenceId: pkg,
          note: `Bonus paquete ${pkg}`,
          actorUid: caller.uid,
          createdAt: nowTs,
          docId: `pkg_${caller.uid}`,
        });
      }
    }

    const updatedPlayer: SpinPlayer = {
      ...existingPlayer,
      displayName,
      email,
      tickets,
      totalTicketsEarned,
      initialTicketsGranted,
      packageBonusGranted,
      matchedPackage,
      createdAtMs: existingPlayer.createdAtMs ?? nowMs,
      updatedAtMs: nowMs,
    };

    if (!playerSnap.exists) {
      tx.set(playerRef, {
        ...buildEmptySpinPlayerRecord({
          uid: caller.uid,
          displayName,
          email,
          nowTs,
        }),
        tickets,
        totalTicketsEarned,
        initialTicketsGranted,
        packageBonusGranted,
        matchedPackage,
      });
    } else if (
      initialGrantedThisCall ||
      packageBonusGrantedThisCall ||
      displayName !== existingPlayer.displayName ||
      email !== existingPlayer.email
    ) {
      tx.update(playerRef, {
        displayName,
        email,
        tickets,
        totalTicketsEarned,
        initialTicketsGranted,
        packageBonusGranted,
        matchedPackage,
        updatedAt: nowTs,
      });
    }

    return {
      response: {
        player: toSpinPlayerDto(updatedPlayer),
        initialGranted: initialGrantedThisCall,
        packageBonusGranted: packageBonusGrantedThisCall,
        matchedPackage,
      } satisfies SpinInitPlayerResponseDto,
      ticketsIssuedDelta,
    };
  });

  if (txResult.ticketsIssuedDelta > 0) {
    try {
      await incrementStatsShard(db, input.eventId, caller.uid, {
        totalTicketsIssued: txResult.ticketsIssuedDelta,
      });
    } catch {
      // Non-blocking stats shard increment.
    }
  }

  return txResult.response;
}
