import { getApps, initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';

const PROJECT_ID = 'gdgsucre-events';
const EVENT_ID = 'Y56VC5x6DdHj7Gianmux';

interface SeedArgs {
  adminUids: string[];
  adminOnly: boolean;
}

function parseArgs(argv: readonly string[]): SeedArgs {
  const adminUids: string[] = [];
  let adminOnly = false;
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--admin-uid' && argv[i + 1]) {
      adminUids.push(argv[i + 1].trim());
      i += 1;
    } else if (arg.startsWith('--admin-uid=')) {
      adminUids.push(arg.slice('--admin-uid='.length).trim());
    } else if (arg === '--admin-only') {
      adminOnly = true;
    }
  }
  return {
    adminUids: adminUids.filter((id) => id.length > 0),
    adminOnly,
  };
}

async function main(): Promise<void> {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error(
      'SAFETY ABORT: FIRESTORE_EMULATOR_HOST is not set. This script only runs against the local Firestore Emulator.',
    );
  }

  const { adminUids, adminOnly } = parseArgs(process.argv.slice(2));

  if (getApps().length === 0) {
    initializeApp({ projectId: PROJECT_ID });
  }
  const db = getFirestore();

  for (const uid of adminUids) {
    await db.collection('users-admin').doc(uid).set(
      {
        uuid: uid,
        name: 'Admin Sandbox',
      },
      { merge: true },
    );
    console.log(`[emulator-seed] Ensured users-admin/${uid}`);
  }

  if (adminOnly) {
    return;
  }

  const now = Date.now();
  const start = new Date(now - 60 * 60 * 1000);
  const end = new Date(now + 8 * 60 * 60 * 1000);

  await db.collection('events').doc(EVENT_ID).set({
    id: EVENT_ID,
    title: 'DevFest Sucre 2026 (Sandbox)',
    description: 'Evento local en Firebase Emulator para pruebas en vivo.',
    startDate: start.toISOString(),
    endDate: end.toISOString(),
    locationUrl: 'https://maps.google.com',
    imageUrl: '',
    status: 'active',
  });

  const eventRef = db.collection('events').doc(EVENT_ID);

  // Live talk & workshop for Q&A, Ratings, and Workshop mission testing
  await eventRef.collection('schedule').doc('speaker-live').set({
    uuid: 'speaker-live',
    title: 'Firebase + Flutter en Producción',
    description: 'Charla en vivo de prueba para Q&A y calificación de estrellas.',
    name: 'GDG Sucre Speaker',
    profession: 'Google Developer Expert',
    aboutMe: 'Charla de prueba en el sandbox local.',
    photoUrl: '',
    technologyType: 'Firebase',
    type: 'Conferencia',
    color: '#4285F4',
    schedule: '10:00 - 11:00',
    position: 0,
    current: 0,
    limit: 0,
    openDate: null,
    SocialNetwork: [],
    isLive: true,
  });

  await eventRef.collection('schedule').doc('speaker-workshop').set({
    uuid: 'speaker-workshop',
    title: 'Taller Cloud Functions ACID',
    description: 'Taller práctico para probar inscripción workshow y misión.',
    name: 'Equipo GDG Sucre',
    profession: 'Cloud Engineer',
    aboutMe: 'Taller de prueba en el sandbox local.',
    photoUrl: '',
    technologyType: 'Cloud',
    type: 'Taller',
    color: '#34A853',
    schedule: '11:30 - 12:30',
    position: 1,
    current: 0,
    limit: 30,
    openDate: null,
    SocialNetwork: [],
    isLive: false,
  });

  // SpinConfig ready to play immediately (editable live from Admin Panel)
  await eventRef.collection('spinConfig').doc('main').set({
    status: 'active',
    pauseMessage: 'GDG SPIN está en pausa. ¡Volvemos enseguida!',
    ticketCostPerSpin: 1,
    defaultInitialTickets: 5,
    packageTicketBonus: {
      'Entrada libre': 0,
      Standard: 1,
      VIP: 3,
    },
    matchRegistrationByEmail: true,
    registeredAttendeesCount: 30,
    expectedSpinsPerAttendee: 4,
    estimatedTotalSpinsOverride: 40,
    pacingMode: 'time_paced',
    pacingStartAt: Timestamp.fromDate(start),
    pacingEndAt: Timestamp.fromDate(end),
    pacingCurveGamma: 1.0,
    pacingWaves: [
      {
        id: 'morning',
        label: 'Mañana',
        startAt: Timestamp.fromDate(start),
        releaseRatio: 0.6,
        spinBudgetShare: 0.5,
      },
      {
        id: 'closing',
        label: 'Cierre',
        startAt: Timestamp.fromDate(new Date(now + 4 * 60 * 60 * 1000)),
        releaseRatio: 1.0,
        spinBudgetShare: 0.5,
      },
    ],
    rushMode: false,
    rushBypassUnlockAt: true,
    payoutMultiplier: 1.5,
    maxWinProbabilityPerSpin: 0.6,
    rushMaxWinProbabilityPerSpin: 0.9,
    maxPrizesPerUser: 5,
    allowPlayAfterCap: false,
    maxWinsByRarity: {
      common: 3,
      rare: 2,
      epic: 1,
      legendary: 1,
    },
    minSpinsBetweenWins: 0,
    bonusProbability: 0.12,
    bonusMinTickets: 1,
    bonusMaxTickets: 3,
    maxBonusWinsPerUser: 3,
    wildReplacementChance: 0.35,
    spinCooldownMs: 1000,
    maxTotalEarnedTicketsPerUser: 25,
    maxManualGrantPerAction: 5,
    maxManualTicketsPerUser: 20,
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: 'emulator-seed',
  });

  for (let i = 0; i < 5; i += 1) {
    await eventRef.collection('spinStats').doc(`shard_${i}`).set({
      totalSpins: 0,
      totalWins: 0,
      totalBonusSpins: 0,
      totalBonusTickets: 0,
      totalTicketsIssued: 0,
      totalTicketsSpent: 0,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  const prizes = [
    {
      id: 'stickers',
      name: 'Stickers GDG',
      description: 'Pack oficial DevFest Sucre 2026',
      symbol: 'cherries',
      rarity: 'common',
      initialStock: 20,
      maxPerUser: 2,
      weight: 1.0,
      order: 0,
    },
    {
      id: 'mug',
      name: 'Taza GDG',
      description: 'Taza edición especial',
      symbol: 'bell',
      rarity: 'rare',
      initialStock: 6,
      maxPerUser: 1,
      weight: 1.0,
      order: 1,
    },
    {
      id: 'shirt',
      name: 'Polera GDG',
      description: 'Polera oficial DevFest',
      symbol: 'bar',
      rarity: 'rare',
      initialStock: 5,
      maxPerUser: 1,
      weight: 1.0,
      order: 2,
    },
    {
      id: 'sparky',
      name: 'Peluche de Sparky',
      description: 'Edición limitada',
      symbol: 'star',
      rarity: 'epic',
      initialStock: 3,
      maxPerUser: 1,
      weight: 1.0,
      order: 3,
    },
    {
      id: 'dash',
      name: 'Peluche de Dash',
      description: 'Edición limitada',
      symbol: 'diamond',
      rarity: 'epic',
      initialStock: 3,
      maxPerUser: 1,
      weight: 1.0,
      order: 4,
    },
    {
      id: 'android',
      name: 'Figura de Android',
      description: 'Premio mayor coleccionable',
      symbol: 'seven',
      rarity: 'legendary',
      initialStock: 1,
      maxPerUser: 1,
      weight: 1.0,
      order: 5,
    },
  ];

  for (const prize of prizes) {
    await eventRef.collection('spinPrizes').doc(prize.id).set({
      ...prize,
      imageUrl: null,
      remainingStock: prize.initialStock,
      awardedCount: 0,
      redeemedCount: 0,
      releasedStock: prize.initialStock,
      unlockAt: null,
      active: true,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  const missions = [
    {
      id: 'profile_complete',
      type: 'profile_complete',
      title: 'Completa tu perfil',
      description: 'Agrega profesión y bio de al menos 200 caracteres.',
      rewardTickets: 1,
      targetCount: 1,
      maxCompletionsPerUser: 1,
      actionLabel: 'Editar perfil',
      active: true,
      order: 0,
      startsAt: null,
      endsAt: null,
      config: { minAboutMeLength: 200 },
    },
    {
      id: 'workshop_register',
      type: 'workshop_register',
      title: 'Inscríbete a un taller',
      description: 'Reserva tu cupo en un taller del cronograma.',
      rewardTickets: 1,
      targetCount: 1,
      maxCompletionsPerUser: 1,
      actionLabel: 'Ver agenda',
      active: true,
      order: 1,
      startsAt: null,
      endsAt: null,
      config: {},
    },
    {
      id: 'ask_speaker',
      type: 'ask_speaker',
      title: 'Haz una pregunta a un speaker',
      description: 'Envía una pregunta en la charla en vivo.',
      rewardTickets: 1,
      targetCount: 1,
      maxCompletionsPerUser: 1,
      actionLabel: 'Preguntar',
      active: true,
      order: 2,
      startsAt: null,
      endsAt: null,
      config: {},
    },
    {
      id: 'rate_talk',
      type: 'rate_talk',
      title: 'Califica una charla',
      description: 'Deja tu calificación de 1 a 5 estrellas.',
      rewardTickets: 1,
      targetCount: 1,
      maxCompletionsPerUser: 1,
      actionLabel: 'Calificar',
      active: true,
      order: 3,
      startsAt: null,
      endsAt: null,
      config: {},
    },
    {
      id: 'trivia_break_am',
      type: 'trivia',
      title: 'Trivia del break (Sandbox)',
      description: 'Responde bien para ganar 1 ticket extra.',
      rewardTickets: 1,
      targetCount: 1,
      maxCompletionsPerUser: 1,
      actionLabel: 'Jugar',
      active: true,
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
    },
  ];

  for (const mission of missions) {
    await eventRef.collection('spinMissions').doc(mission.id).set({
      ...mission,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  await eventRef.collection('spinMissionSecrets').doc('trivia_break_am').set({
    correctOptionIndex: 0,
    explanation:
      'Firebase AI Logic permite invocar modelos Gemini de forma segura desde clientes móviles.',
  });

  await eventRef.collection('spinTicketCodes').doc('stand_demo').set({
    id: 'stand_demo',
    code: 'GDG26',
    label: 'Stand Demo GDG Sucre',
    rewardTickets: 2,
    maxTotalUses: 50,
    usedCount: 0,
    maxUsesPerUser: 1,
    active: true,
    startsAt: null,
    endsAt: null,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: 'emulator-seed',
  });

  console.log(
    `[emulator-seed] Sandbox seeded on ${process.env.FIRESTORE_EMULATOR_HOST} for event ${EVENT_ID}`,
  );
}

main().catch((err: unknown) => {
  console.error('[emulator-seed] Failed:', err);
  process.exitCode = 1;
});
