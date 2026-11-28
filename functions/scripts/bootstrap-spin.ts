import { getApps, initializeApp } from 'firebase-admin/app';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentReference,
  type Firestore,
} from 'firebase-admin/firestore';

const DEFAULT_PROJECT_ID = 'gdgsucre-events';
const DEFAULT_EVENT_ID = 'Y56VC5x6DdHj7Gianmux';
const STAT_SHARD_COUNT = 5;
const DELETE_BATCH_LIMIT = 400;

export interface BootstrapOptions {
  projectId: string;
  eventId: string;
  dryRun: boolean;
  help: boolean;
}

interface AdminRecord {
  uuid: string;
  name: string;
}

interface StarterMissionEntry {
  id: string;
  data: Record<string, unknown>;
  secret?: Record<string, unknown>;
}

const USAGE_TEXT = `Usage: npm --prefix functions run bootstrap -- [options]

Options:
  --project <id>     Firebase project ID (default: ${DEFAULT_PROJECT_ID})
  --event-id <id>    Event document ID (default: ${DEFAULT_EVENT_ID})
  --dry-run          Preview changes without writing or deleting documents
  -h, --help         Show this help message
`;

/** Parse CLI arguments for the GDG SPIN bootstrap script. */
export function parseCliArgs(argv: readonly string[]): BootstrapOptions {
  let projectId = DEFAULT_PROJECT_ID;
  let eventId = DEFAULT_EVENT_ID;
  let dryRun = false;
  let help = false;

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--dry-run') {
      dryRun = true;
      continue;
    }
    if (arg === '--help' || arg === '-h') {
      help = true;
      continue;
    }
    if (arg === '--project') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('Missing value for --project');
      }
      projectId = value.trim();
      i += 1;
      continue;
    }
    if (arg.startsWith('--project=')) {
      const value = arg.slice('--project='.length).trim();
      if (!value) {
        throw new Error('Missing value for --project');
      }
      projectId = value;
      continue;
    }
    if (arg === '--event-id') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('Missing value for --event-id');
      }
      eventId = value.trim();
      i += 1;
      continue;
    }
    if (arg.startsWith('--event-id=')) {
      const value = arg.slice('--event-id='.length).trim();
      if (!value) {
        throw new Error('Missing value for --event-id');
      }
      eventId = value;
      continue;
    }
    throw new Error(`Unknown argument: ${arg}`);
  }

  return { projectId, eventId, dryRun, help };
}

function isAlreadyExistsError(error: unknown): boolean {
  if (typeof error !== 'object' || error === null) {
    return false;
  }
  const code = (error as { code?: unknown }).code;
  return code === 6 || code === 'already-exists' || code === 'ALREADY_EXISTS';
}

async function createIfMissing(
  ref: DocumentReference,
  data: Record<string, unknown>,
  label: string,
  dryRun: boolean,
): Promise<boolean> {
  const existing = await ref.get();
  if (existing.exists) {
    console.log(`[skip] ${label} already exists`);
    return false;
  }
  if (dryRun) {
    console.log(`[dry-run] Would create ${label}`);
    return true;
  }
  try {
    await ref.create(data);
    console.log(`[create] Created ${label}`);
    return true;
  } catch (error) {
    if (isAlreadyExistsError(error)) {
      console.log(`[skip] ${label} created concurrently`);
      return false;
    }
    throw error;
  }
}

/**
 * Normalize `users-admin` documents so every admin has a canonical document at
 * `users-admin/{uuid}` and legacy auto-ID duplicates are removed only after
 * verifying every admin exists at its canonical path.
 */
export async function normalizeUsersAdmin(
  db: Firestore,
  dryRun: boolean,
): Promise<{ ensured: number; deleted: number; skippedInvalid: number }> {
  const collectionRef = db.collection('users-admin');
  const snapshot = await collectionRef.get();

  const adminsByUuid = new Map<string, AdminRecord>();
  const existingCanonicalIds = new Set<string>();
  const canonicalDataByUuid = new Map<string, Record<string, unknown>>();
  const legacyRefs: DocumentReference[] = [];
  let skippedInvalid = 0;

  for (const docSnap of snapshot.docs) {
    const data: Record<string, unknown> = docSnap.data();
    const rawUuid = data.uuid;
    if (typeof rawUuid !== 'string' || rawUuid.trim().length === 0) {
      skippedInvalid += 1;
      console.warn(
        `[warn] Skipping users-admin/${docSnap.id}: missing or invalid string uuid`,
      );
      continue;
    }

    const uuid = rawUuid.trim();
    const rawName = data.name;
    const name = typeof rawName === 'string' ? rawName : '';

    if (docSnap.id === uuid) {
      existingCanonicalIds.add(uuid);
      canonicalDataByUuid.set(uuid, data);
      adminsByUuid.set(uuid, { uuid, name });
    } else {
      legacyRefs.push(docSnap.ref);
      const current = adminsByUuid.get(uuid);
      if (!current || (!current.name && name)) {
        adminsByUuid.set(uuid, { uuid, name });
      }
    }
  }

  let ensured = 0;
  for (const [uuid, record] of adminsByUuid) {
    const existingData = canonicalDataByUuid.get(uuid);
    const alreadyValid =
      existingCanonicalIds.has(uuid) &&
      existingData !== undefined &&
      existingData.uuid === uuid &&
      typeof existingData.name === 'string';

    if (alreadyValid) {
      console.log(`[skip] users-admin/${uuid} already normalized`);
      continue;
    }

    if (dryRun) {
      console.log(
        `[dry-run] Would ensure users-admin/${uuid} (${JSON.stringify(record)})`,
      );
      ensured += 1;
      continue;
    }

    await collectionRef.doc(uuid).set(record, { merge: true });
    console.log(`[ensure] Ensured canonical users-admin/${uuid}`);
    ensured += 1;
  }

  // Verify every admin uuid is readable at users-admin/{uuid} before any delete.
  if (!dryRun && adminsByUuid.size > 0) {
    const expectedUuids = Array.from(adminsByUuid.keys());
    const canonicalRefs = expectedUuids.map((uuid) => collectionRef.doc(uuid));
    const verifiedSnaps = await db.getAll(...canonicalRefs);
    for (let i = 0; i < verifiedSnaps.length; i += 1) {
      const snap = verifiedSnaps[i];
      const expectedUuid = expectedUuids[i];
      const snapData: Record<string, unknown> | undefined = snap.data();
      if (!snap.exists || snapData?.uuid !== expectedUuid) {
        throw new Error(
          `Verification failed: users-admin/${expectedUuid} is missing or mismatched; aborting legacy cleanup.`,
        );
      }
    }
    console.log(
      `[verify] Verified ${verifiedSnaps.length} canonical users-admin docs before cleanup`,
    );
  }

  let deleted = 0;
  if (legacyRefs.length > 0) {
    if (dryRun) {
      for (const ref of legacyRefs) {
        console.log(`[dry-run] Would delete legacy users-admin/${ref.id}`);
      }
      deleted = legacyRefs.length;
    } else {
      for (let i = 0; i < legacyRefs.length; i += DELETE_BATCH_LIMIT) {
        const chunk = legacyRefs.slice(i, i + DELETE_BATCH_LIMIT);
        const batch = db.batch();
        for (const ref of chunk) {
          batch.delete(ref);
        }
        await batch.commit();
        deleted += chunk.length;
      }
      console.log(
        `[cleanup] Deleted ${deleted} legacy auto-ID users-admin doc(s)`,
      );
    }
  }

  return { ensured, deleted, skippedInvalid };
}

function buildInitialSpinConfig(): Record<string, unknown> {
  const eventStart = Timestamp.fromDate(new Date('2026-11-28T09:00:00-04:00'));
  const afternoonStart = Timestamp.fromDate(
    new Date('2026-11-28T13:30:00-04:00'),
  );
  const closingStart = Timestamp.fromDate(
    new Date('2026-11-28T16:30:00-04:00'),
  );
  const eventEnd = Timestamp.fromDate(new Date('2026-11-28T17:30:00-04:00'));

  return {
    status: 'paused',
    pauseMessage: 'GDG SPIN abre en unos minutos. ¡Prepárate!',
    ticketCostPerSpin: 1,
    defaultInitialTickets: 2,
    packageTicketBonus: {
      'Entrada libre': 0,
      Standard: 1,
      VIP: 3,
    },
    matchRegistrationByEmail: true,
    registeredAttendeesCount: 250,
    expectedSpinsPerAttendee: 4,
    estimatedTotalSpinsOverride: null,
    pacingMode: 'time_paced',
    pacingStartAt: eventStart,
    pacingEndAt: eventEnd,
    pacingCurveGamma: 1.0,
    pacingWaves: [
      {
        id: 'morning',
        label: 'Mañana',
        startAt: eventStart,
        releaseRatio: 0.35,
        spinBudgetShare: 0.35,
      },
      {
        id: 'afternoon',
        label: 'Tarde',
        startAt: afternoonStart,
        releaseRatio: 0.8,
        spinBudgetShare: 0.45,
      },
      {
        id: 'closing',
        label: 'Cierre',
        startAt: closingStart,
        releaseRatio: 1.0,
        spinBudgetShare: 0.2,
      },
    ],
    rushMode: false,
    rushBypassUnlockAt: true,
    payoutMultiplier: 1.0,
    maxWinProbabilityPerSpin: 0.45,
    rushMaxWinProbabilityPerSpin: 0.85,
    maxPrizesPerUser: 3,
    allowPlayAfterCap: false,
    maxWinsByRarity: {
      common: 2,
      rare: 1,
      epic: 1,
      legendary: 1,
    },
    minSpinsBetweenWins: 1,
    bonusProbability: 0.06,
    bonusMinTickets: 1,
    bonusMaxTickets: 3,
    maxBonusWinsPerUser: 2,
    wildReplacementChance: 0.35,
    spinCooldownMs: 2500,
    maxTotalEarnedTicketsPerUser: 15,
    maxManualGrantPerAction: 5,
    maxManualTicketsPerUser: 10,
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: 'bootstrap-spin',
  };
}

function buildInitialStatShard(): Record<string, unknown> {
  return {
    totalSpins: 0,
    totalWins: 0,
    totalBonusSpins: 0,
    totalBonusTickets: 0,
    totalTicketsIssued: 0,
    totalTicketsSpent: 0,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function buildStarterPrizes(): Array<{
  id: string;
  data: Record<string, unknown>;
}> {
  const sparkyUnlock = Timestamp.fromDate(
    new Date('2026-11-28T11:00:00-04:00'),
  );
  const dashUnlock = Timestamp.fromDate(new Date('2026-11-28T13:30:00-04:00'));
  const androidUnlock = Timestamp.fromDate(
    new Date('2026-11-28T15:00:00-04:00'),
  );

  const specs = [
    {
      id: 'stickers',
      name: 'Stickers GDG',
      description: 'Pack oficial de stickers DevFest Sucre 2026',
      symbol: 'cherries',
      rarity: 'common',
      initialStock: 30,
      maxPerUser: 2,
      weight: 1.0,
      unlockAt: null,
      order: 0,
    },
    {
      id: 'mug',
      name: 'Taza GDG',
      description: 'Taza edición especial GDG Sucre',
      symbol: 'bell',
      rarity: 'rare',
      initialStock: 5,
      maxPerUser: 1,
      weight: 1.0,
      unlockAt: null,
      order: 1,
    },
    {
      id: 'shirt',
      name: 'Polera GDG',
      description: 'Polera oficial DevFest Sucre 2026',
      symbol: 'bar',
      rarity: 'rare',
      initialStock: 4,
      maxPerUser: 1,
      weight: 1.0,
      unlockAt: null,
      order: 2,
    },
    {
      id: 'sparky',
      name: 'Peluche de Sparky',
      description: 'Edición limitada DevFest Sucre 2026',
      symbol: 'star',
      rarity: 'epic',
      initialStock: 2,
      maxPerUser: 1,
      weight: 1.0,
      unlockAt: sparkyUnlock,
      order: 3,
    },
    {
      id: 'dash',
      name: 'Peluche de Dash',
      description: 'Edición limitada DevFest Sucre 2026',
      symbol: 'diamond',
      rarity: 'epic',
      initialStock: 2,
      maxPerUser: 1,
      weight: 1.0,
      unlockAt: dashUnlock,
      order: 4,
    },
    {
      id: 'android',
      name: 'Figura de Android',
      description: 'Premio mayor coleccionable DevFest Sucre 2026',
      symbol: 'seven',
      rarity: 'legendary',
      initialStock: 1,
      maxPerUser: 1,
      weight: 1.0,
      unlockAt: androidUnlock,
      order: 5,
    },
  ];

  return specs.map((spec) => ({
    id: spec.id,
    data: {
      id: spec.id,
      name: spec.name,
      description: spec.description,
      symbol: spec.symbol,
      imageUrl: null,
      rarity: spec.rarity,
      initialStock: spec.initialStock,
      remainingStock: spec.initialStock,
      awardedCount: 0,
      redeemedCount: 0,
      releasedStock: spec.initialStock,
      maxPerUser: spec.maxPerUser,
      weight: spec.weight,
      unlockAt: spec.unlockAt,
      active: true,
      order: spec.order,
      updatedAt: FieldValue.serverTimestamp(),
    },
  }));
}

function buildStarterMissions(): StarterMissionEntry[] {
  return [
    {
      id: 'profile_complete',
      data: {
        id: 'profile_complete',
        type: 'profile_complete',
        title: 'Completa tu perfil',
        description:
          'Agrega tu profesión y una bio de al menos 200 caracteres.',
        rewardTickets: 1,
        targetCount: 1,
        maxCompletionsPerUser: 1,
        actionLabel: 'Editar perfil',
        active: false,
        order: 0,
        startsAt: null,
        endsAt: null,
        config: {
          minAboutMeLength: 200,
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
    },
    {
      id: 'workshop_register',
      data: {
        id: 'workshop_register',
        type: 'workshop_register',
        title: 'Inscríbete a un taller',
        description: 'Reserva tu cupo en un taller del cronograma.',
        rewardTickets: 1,
        targetCount: 1,
        maxCompletionsPerUser: 1,
        actionLabel: 'Ver agenda',
        active: false,
        order: 1,
        startsAt: null,
        endsAt: null,
        config: {},
        updatedAt: FieldValue.serverTimestamp(),
      },
    },
    {
      id: 'ask_speaker',
      data: {
        id: 'ask_speaker',
        type: 'ask_speaker',
        title: 'Haz una pregunta a un speaker',
        description: 'Envía una pregunta durante una charla en vivo.',
        rewardTickets: 1,
        targetCount: 1,
        maxCompletionsPerUser: 1,
        actionLabel: 'Preguntar',
        active: false,
        order: 2,
        startsAt: null,
        endsAt: null,
        config: {},
        updatedAt: FieldValue.serverTimestamp(),
      },
    },
    {
      id: 'rate_talk',
      data: {
        id: 'rate_talk',
        type: 'rate_talk',
        title: 'Califica una charla',
        description: 'Deja tu calificación de 1 a 5 estrellas en una charla.',
        rewardTickets: 1,
        targetCount: 1,
        maxCompletionsPerUser: 1,
        actionLabel: 'Calificar',
        active: false,
        order: 3,
        startsAt: null,
        endsAt: null,
        config: {},
        updatedAt: FieldValue.serverTimestamp(),
      },
    },
    {
      id: 'trivia_break_am',
      data: {
        id: 'trivia_break_am',
        type: 'trivia',
        title: 'Trivia del break de la mañana',
        description: 'Responde bien para ganar 1 ticket extra',
        rewardTickets: 1,
        targetCount: 1,
        maxCompletionsPerUser: 1,
        actionLabel: 'Jugar',
        active: false,
        order: 4,
        startsAt: null,
        endsAt: null,
        config: {
          question:
            '¿Con qué SDK de Firebase se llama a Gemini desde una app móvil?',
          options: [
            'Firebase AI Logic',
            'Firebase Crashlytics',
            'Firebase Hosting',
          ],
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      secret: {
        correctOptionIndex: 0,
        explanation:
          'Firebase AI Logic permite invocar modelos Gemini de forma segura desde clientes móviles.',
      },
    },
  ];
}

/** Seed initial GDG SPIN documents under `events/{eventId}` without overwriting live data. */
export async function seedEventSpinDocs(
  db: Firestore,
  eventId: string,
  dryRun: boolean,
): Promise<{ created: number; skipped: number }> {
  const eventRef = db.collection('events').doc(eventId);
  const eventSnap = await eventRef.get();
  if (!eventSnap.exists) {
    console.warn(
      `[warn] events/${eventId} does not exist yet; subcollections will still be seeded.`,
    );
  }

  let created = 0;
  let skipped = 0;

  const track = async (
    ref: DocumentReference,
    data: Record<string, unknown>,
    label: string,
  ): Promise<void> => {
    const didCreate = await createIfMissing(ref, data, label, dryRun);
    if (didCreate) {
      created += 1;
    } else {
      skipped += 1;
    }
  };

  await track(
    eventRef.collection('spinConfig').doc('main'),
    buildInitialSpinConfig(),
    `events/${eventId}/spinConfig/main`,
  );

  for (let i = 0; i < STAT_SHARD_COUNT; i += 1) {
    const shardId = `shard_${i}`;
    await track(
      eventRef.collection('spinStats').doc(shardId),
      buildInitialStatShard(),
      `events/${eventId}/spinStats/${shardId}`,
    );
  }

  for (const prize of buildStarterPrizes()) {
    await track(
      eventRef.collection('spinPrizes').doc(prize.id),
      prize.data,
      `events/${eventId}/spinPrizes/${prize.id}`,
    );
  }

  for (const mission of buildStarterMissions()) {
    await track(
      eventRef.collection('spinMissions').doc(mission.id),
      mission.data,
      `events/${eventId}/spinMissions/${mission.id}`,
    );
    if (mission.secret) {
      await track(
        eventRef.collection('spinMissionSecrets').doc(mission.id),
        mission.secret,
        `events/${eventId}/spinMissionSecrets/${mission.id}`,
      );
    }
  }

  return { created, skipped };
}

/** Run both `users-admin` normalization and `events/{eventId}` GDG SPIN seeding. */
export async function runBootstrap(options: BootstrapOptions): Promise<void> {
  if (getApps().length === 0) {
    initializeApp({ projectId: options.projectId });
  }
  const db = getFirestore();

  console.log(
    `Running GDG SPIN bootstrap for project="${options.projectId}", event="${options.eventId}", dryRun=${String(options.dryRun)}`,
  );

  const adminResult = await normalizeUsersAdmin(db, options.dryRun);
  const seedResult = await seedEventSpinDocs(
    db,
    options.eventId,
    options.dryRun,
  );

  console.log(
    `Bootstrap finished: users-admin(ensured=${adminResult.ensured}, deleted=${adminResult.deleted}, skippedInvalid=${adminResult.skippedInvalid}), spinDocs(created=${seedResult.created}, skipped=${seedResult.skipped})`,
  );
}

async function main(): Promise<void> {
  const options = parseCliArgs(process.argv.slice(2));
  if (options.help) {
    console.log(USAGE_TEXT);
    return;
  }
  await runBootstrap(options);
}

if (require.main === module) {
  main().catch((error: unknown) => {
    console.error('Bootstrap failed:', error);
    process.exitCode = 1;
  });
}
