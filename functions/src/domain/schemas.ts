import { z } from 'zod';
import type { EpochMs } from './types';

export const nonEmptyIdSchema = z
  .string()
  .trim()
  .min(1, 'Identifier must not be empty')
  .max(128, 'Identifier exceeds 128 characters');

export const safeDocIdSchema = z
  .string()
  .trim()
  .min(1, 'Document ID must not be empty')
  .max(128, 'Document ID exceeds 128 characters')
  .regex(/^[a-zA-Z0-9_-]+$/, 'Document ID contains invalid characters');

export const spinRequestIdSchema = z
  .string()
  .trim()
  .min(8, 'spinRequestId must be at least 8 characters')
  .max(128, 'spinRequestId exceeds 128 characters')
  .regex(/^[a-zA-Z0-9_-]+$/, 'spinRequestId contains invalid characters');

export const dateInputSchema = z
  .union([z.number().finite(), z.string().trim().min(1).max(64)])
  .transform((val, ctx): EpochMs => {
    if (typeof val === 'number') {
      if (!Number.isFinite(val) || val < 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Epoch timestamp must be a non-negative finite number',
        });
        return z.NEVER;
      }
      return Math.trunc(val);
    }
    const parsed = Date.parse(val);
    if (Number.isNaN(parsed)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Invalid ISO-8601 date string',
      });
      return z.NEVER;
    }
    return parsed;
  });

// ---------------------------------------------------------------------------
// Player Callable Input Schemas (7)
// ---------------------------------------------------------------------------

export const spinInitPlayerSchema = z.object({
  eventId: nonEmptyIdSchema,
});

export const spinPullSchema = z.object({
  eventId: nonEmptyIdSchema,
  spinRequestId: spinRequestIdSchema,
});

export const spinClaimMissionSchema = z.object({
  eventId: nonEmptyIdSchema,
  missionId: safeDocIdSchema,
});

export const spinSubmitTriviaSchema = z.object({
  eventId: nonEmptyIdSchema,
  missionId: safeDocIdSchema,
  selectedIndex: z.number().int().min(0).max(10),
});

export const spinRedeemTicketCodeSchema = z.object({
  eventId: nonEmptyIdSchema,
  code: z.string().trim().min(1).max(256),
});

export const spinSubmitTalkQuestionSchema = z.object({
  eventId: nonEmptyIdSchema,
  speakerUuid: safeDocIdSchema,
  text: z.string().trim().min(10).max(300),
});

export const spinSubmitTalkRatingSchema = z.object({
  eventId: nonEmptyIdSchema,
  speakerUuid: safeDocIdSchema,
  stars: z.number().int().min(1).max(5),
  comment: z.string().trim().max(300).optional().default(''),
});

// ---------------------------------------------------------------------------
// Admin Callable Input Schemas (11)
// ---------------------------------------------------------------------------

export const spinPacingWaveInputSchema = z.object({
  id: safeDocIdSchema,
  label: z.string().trim().min(1).max(80),
  startAt: dateInputSchema,
  releaseRatio: z.number().min(0).max(1),
  spinBudgetShare: z.number().min(0).max(1),
});

export const spinConfigPatchSchema = z
  .object({
    status: z.enum(['paused', 'active', 'closed']).optional(),
    pauseMessage: z.string().trim().max(300).optional(),
    ticketCostPerSpin: z.number().int().min(1).max(20).optional(),
    defaultInitialTickets: z.number().int().min(0).max(50).optional(),
    packageTicketBonus: z
      .record(z.string().trim().min(1).max(80), z.number().int().min(0).max(50))
      .optional(),
    matchRegistrationByEmail: z.boolean().optional(),
    registeredAttendeesCount: z.number().int().min(0).max(100000).optional(),
    expectedSpinsPerAttendee: z.number().min(0.1).max(100).optional(),
    estimatedTotalSpinsOverride: z
      .number()
      .int()
      .min(1)
      .max(1000000)
      .nullable()
      .optional(),
    pacingMode: z
      .enum(['time_paced', 'dynamic_spins', 'manual_waves'])
      .optional(),
    pacingStartAt: dateInputSchema.nullable().optional(),
    pacingEndAt: dateInputSchema.nullable().optional(),
    pacingCurveGamma: z.number().min(0.1).max(5.0).optional(),
    pacingWaves: z.array(spinPacingWaveInputSchema).max(20).optional(),
    rushMode: z.boolean().optional(),
    rushBypassUnlockAt: z.boolean().optional(),
    payoutMultiplier: z.number().min(0.01).max(20).optional(),
    maxWinProbabilityPerSpin: z.number().gt(0).max(1).optional(),
    rushMaxWinProbabilityPerSpin: z.number().gt(0).max(1).optional(),
    maxPrizesPerUser: z.number().int().min(0).max(100).optional(),
    allowPlayAfterCap: z.boolean().optional(),
    maxWinsByRarity: z
      .object({
        common: z.number().int().min(0).max(100).optional(),
        rare: z.number().int().min(0).max(100).optional(),
        epic: z.number().int().min(0).max(100).optional(),
        legendary: z.number().int().min(0).max(100).optional(),
      })
      .optional(),
    minSpinsBetweenWins: z.number().int().min(0).max(100).optional(),
    bonusProbability: z.number().min(0).max(0.5).optional(),
    bonusMinTickets: z.number().int().min(1).max(20).optional(),
    bonusMaxTickets: z.number().int().min(1).max(20).optional(),
    maxBonusWinsPerUser: z.number().int().min(0).max(50).optional(),
    wildReplacementChance: z.number().min(0).max(1).optional(),
    spinCooldownMs: z.number().int().min(0).max(300000).optional(),
    maxTotalEarnedTicketsPerUser: z.number().int().min(0).max(500).optional(),
    maxManualGrantPerAction: z.number().int().min(1).max(100).optional(),
    maxManualTicketsPerUser: z.number().int().min(0).max(500).optional(),
  })
  .strict()
  .superRefine((patch, ctx) => {
    if (Object.keys(patch).length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Config patch must include at least one field',
      });
    }
    if (
      patch.bonusMinTickets !== undefined &&
      patch.bonusMaxTickets !== undefined &&
      patch.bonusMinTickets > patch.bonusMaxTickets
    ) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['bonusMinTickets'],
        message: 'bonusMinTickets must be <= bonusMaxTickets',
      });
    }
    if (
      patch.pacingStartAt !== undefined &&
      patch.pacingStartAt !== null &&
      patch.pacingEndAt !== undefined &&
      patch.pacingEndAt !== null &&
      patch.pacingEndAt <= patch.pacingStartAt
    ) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['pacingEndAt'],
        message: 'pacingEndAt must be after pacingStartAt',
      });
    }
    if (patch.pacingWaves) {
      let budgetSum = 0;
      for (let i = 0; i < patch.pacingWaves.length; i += 1) {
        const wave = patch.pacingWaves[i];
        budgetSum += wave.spinBudgetShare;
        if (i > 0) {
          const prev = patch.pacingWaves[i - 1];
          if (wave.startAt < prev.startAt) {
            ctx.addIssue({
              code: z.ZodIssueCode.custom,
              path: ['pacingWaves', i, 'startAt'],
              message: 'pacingWaves must be sorted in non-decreasing order by startAt',
            });
          }
          if (wave.releaseRatio < prev.releaseRatio) {
            ctx.addIssue({
              code: z.ZodIssueCode.custom,
              path: ['pacingWaves', i, 'releaseRatio'],
              message: 'pacingWaves releaseRatio must be monotonically non-decreasing',
            });
          }
        }
      }
      if (budgetSum > 1.0001) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['pacingWaves'],
          message: 'Sum of pacingWaves spinBudgetShare cannot exceed 1.0',
        });
      }
    }
  });

export const adminUpdateSpinConfigSchema = z.object({
  eventId: nonEmptyIdSchema,
  patch: spinConfigPatchSchema,
});

export const adminUpsertSpinPrizeSchema = z.object({
  eventId: nonEmptyIdSchema,
  prize: z
    .object({
      id: safeDocIdSchema.optional(),
      name: z.string().trim().min(1).max(120),
      description: z.string().trim().max(500).optional().default(''),
      symbol: z.enum(['cherries', 'bell', 'bar', 'star', 'diamond', 'seven']),
      imageUrl: z
        .string()
        .trim()
        .max(2048)
        .nullable()
        .optional()
        .transform((v) => (v && v.length > 0 ? v : null)),
      rarity: z.enum(['common', 'rare', 'epic', 'legendary']),
      initialStock: z.number().int().min(0).max(100000).optional(),
      remainingStock: z.number().int().min(0).max(100000).optional(),
      releasedStock: z.number().int().min(0).max(100000).optional(),
      maxPerUser: z.number().int().min(0).max(100).optional().default(1),
      weight: z.number().gt(0).max(100).optional().default(1.0),
      unlockAt: dateInputSchema.nullable().optional().default(null),
      active: z.boolean().optional().default(true),
      order: z.number().int().min(0).max(1000).optional().default(0),
    })
    .strict(),
});

export const adminAdjustPrizeStockSchema = z
  .object({
    eventId: nonEmptyIdSchema,
    prizeId: safeDocIdSchema,
    delta: z
      .number()
      .int()
      .refine((v) => Math.abs(v) <= 10000, 'Stock delta out of range')
      .optional()
      .default(0),
    releasedDelta: z
      .number()
      .int()
      .refine((v) => Math.abs(v) <= 10000, 'Released delta out of range')
      .optional(),
    reason: z.string().trim().min(1).max(300),
  })
  .superRefine((input, ctx) => {
    const hasStockDelta = input.delta !== 0;
    const hasReleasedDelta =
      input.releasedDelta !== undefined && input.releasedDelta !== 0;
    if (!hasStockDelta && !hasReleasedDelta) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['delta'],
        message: 'Stock delta or releasedDelta must be non-zero',
      });
    }
  });

const adminFullSpinMissionPayloadSchema = z
  .object({
    id: safeDocIdSchema.optional(),
    type: z.enum([
      'profile_complete',
      'workshop_register',
      'ask_speaker',
      'rate_talk',
      'trivia',
    ]),
    title: z.string().trim().min(1).max(120),
    description: z.string().trim().max(500).optional().default(''),
    rewardTickets: z.number().int().min(1).max(20),
    targetCount: z.number().int().min(1).max(50).optional().default(1),
    maxCompletionsPerUser: z
      .number()
      .int()
      .min(1)
      .max(20)
      .optional()
      .default(1),
    actionLabel: z
      .string()
      .trim()
      .max(50)
      .nullable()
      .optional()
      .transform((v) => (v && v.length > 0 ? v : null)),
    active: z.boolean(),
    order: z.number().int().min(0).max(1000).optional().default(0),
    startsAt: dateInputSchema.nullable().optional().default(null),
    endsAt: dateInputSchema.nullable().optional().default(null),
    config: z
      .object({
        question: z.string().trim().min(1).max(500).optional(),
        options: z
          .array(z.string().trim().min(1).max(200))
          .min(2)
          .max(4)
          .optional(),
        minAboutMeLength: z.number().int().min(0).max(1000).optional(),
      })
      .passthrough()
      .optional()
      .default({}),
  })
  .strict();

const adminToggleMissionActivePayloadSchema = z
  .object({
    id: safeDocIdSchema,
    active: z.boolean(),
  })
  .strict();

export const adminUpsertSpinMissionSchema = z
  .object({
    eventId: nonEmptyIdSchema,
    mission: z.union([
      adminFullSpinMissionPayloadSchema,
      adminToggleMissionActivePayloadSchema,
    ]),
    secret: z
      .object({
        correctOptionIndex: z.number().int().min(0).max(3),
        explanation: z.string().trim().max(500).optional().default(''),
      })
      .strict()
      .optional(),
  })
  .superRefine((input, ctx) => {
    const { mission, secret } = input;
    if (!('type' in mission)) {
      if (secret !== undefined) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['secret'],
          message: 'secret cannot be provided when toggling active only',
        });
      }
      return;
    }
    if (
      mission.startsAt !== null &&
      mission.endsAt !== null &&
      mission.endsAt <= mission.startsAt
    ) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['mission', 'endsAt'],
        message: 'endsAt must be after startsAt',
      });
    }
    if (mission.type === 'trivia') {
      if (!mission.config.question || !mission.config.options) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['mission', 'config'],
          message: 'Trivia missions require question and 2-4 options',
        });
      }
      if (
        secret &&
        mission.config.options &&
        secret.correctOptionIndex >= mission.config.options.length
      ) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['secret', 'correctOptionIndex'],
          message: 'correctOptionIndex is out of range for mission options',
        });
      }
    }
  });

export const adminUpsertTicketCodeSchema = z
  .object({
    eventId: nonEmptyIdSchema,
    codeConfig: z
      .object({
        id: safeDocIdSchema.optional(),
        code: z
          .string()
          .trim()
          .min(3)
          .max(32)
          .transform((s) => s.toUpperCase())
          .refine(
            (s) => /^[A-Z0-9_-]+$/.test(s),
            'Code may only contain A-Z, 0-9, _ and -',
          ),
        label: z.string().trim().min(1).max(120),
        rewardTickets: z.number().int().min(1).max(20),
        maxTotalUses: z.number().int().min(1).max(100000),
        maxUsesPerUser: z.number().int().min(1).max(10).optional().default(1),
        active: z.boolean(),
        startsAt: dateInputSchema.nullable().optional().default(null),
        endsAt: dateInputSchema.nullable().optional().default(null),
      })
      .strict(),
  })
  .superRefine((input, ctx) => {
    const { startsAt, endsAt } = input.codeConfig;
    if (startsAt !== null && endsAt !== null && endsAt <= startsAt) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['codeConfig', 'endsAt'],
        message: 'endsAt must be after startsAt',
      });
    }
  });

export const adminGrantTicketsSchema = z.object({
  eventId: nonEmptyIdSchema,
  targetUid: safeDocIdSchema,
  amount: z.number().int().min(1).max(100),
  reason: z.string().trim().min(1).max(300),
  requestId: spinRequestIdSchema,
});

export const adminImportRegistrationsSchema = z.object({
  eventId: nonEmptyIdSchema,
  rows: z
    .array(
      z.object({
        email: z.string().trim().email().max(254),
        fullName: z.string().trim().max(150).optional().default(''),
        package: z.string().trim().min(1).max(80),
        checkedIn: z.boolean().optional().default(false),
      }),
    )
    .min(1)
    .max(5000),
  replaceAll: z.boolean().optional().default(false),
});

export const adminLookupWinByCodeSchema = z.object({
  eventId: nonEmptyIdSchema,
  codeOrQr: z.string().trim().min(1).max(256),
});

export const adminRedeemWinSchema = z.object({
  eventId: nonEmptyIdSchema,
  winId: safeDocIdSchema,
});

export const adminRevokeWinSchema = z.object({
  eventId: nonEmptyIdSchema,
  winId: safeDocIdSchema,
  returnToStock: z.boolean(),
  reason: z.string().trim().min(1).max(300),
});

export const adminGetSpinDashboardSchema = z.object({
  eventId: nonEmptyIdSchema,
});

export type SpinInitPlayerInput = z.infer<typeof spinInitPlayerSchema>;
export type SpinPullInput = z.infer<typeof spinPullSchema>;
export type SpinClaimMissionInput = z.infer<typeof spinClaimMissionSchema>;
export type SpinSubmitTriviaInput = z.infer<typeof spinSubmitTriviaSchema>;
export type SpinRedeemTicketCodeInput = z.infer<typeof spinRedeemTicketCodeSchema>;
export type SpinSubmitTalkQuestionInput = z.infer<
  typeof spinSubmitTalkQuestionSchema
>;
export type SpinSubmitTalkRatingInput = z.infer<
  typeof spinSubmitTalkRatingSchema
>;
export type AdminUpdateSpinConfigInput = z.infer<
  typeof adminUpdateSpinConfigSchema
>;
export type AdminUpsertSpinPrizeInput = z.infer<
  typeof adminUpsertSpinPrizeSchema
>;
export type AdminAdjustPrizeStockInput = z.infer<
  typeof adminAdjustPrizeStockSchema
>;
export type AdminUpsertSpinMissionInput = z.infer<
  typeof adminUpsertSpinMissionSchema
>;
export type AdminUpsertTicketCodeInput = z.infer<
  typeof adminUpsertTicketCodeSchema
>;
export type AdminGrantTicketsInput = z.infer<typeof adminGrantTicketsSchema>;
export type AdminImportRegistrationsInput = z.infer<
  typeof adminImportRegistrationsSchema
>;
export type AdminLookupWinByCodeInput = z.infer<
  typeof adminLookupWinByCodeSchema
>;
export type AdminRedeemWinInput = z.infer<typeof adminRedeemWinSchema>;
export type AdminRevokeWinInput = z.infer<typeof adminRevokeWinSchema>;
export type AdminGetSpinDashboardInput = z.infer<
  typeof adminGetSpinDashboardSchema
>;
