import { createHash, randomBytes, randomInt } from 'node:crypto';
import type { SpinErrorReason } from './types';

/** Unambiguous 32-character Base32 alphabet (excludes 0/O/1/I). */
export const PRIZE_CODE_ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
export const PRIZE_CODE_PREFIX = 'GDG-';
export const PRIZE_CODE_RANDOM_LEN = 6;

const RAW_PRIZE_CODE_REGEX = /^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$/;
const PREFIXED_PRIZE_CODE_REGEX =
  /^GDG-[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$/;

export interface CodeRng {
  nextInt(min: number, maxExclusive: number): number;
}

export class CodeParseError extends Error {
  readonly reason: SpinErrorReason;

  constructor(reason: SpinErrorReason, message: string) {
    super(message);
    this.name = 'CodeParseError';
    this.reason = reason;
  }
}

/**
 * Generates a CSPRNG prize redemption code formatted as `GDG-XXXXXX`.
 */
export function generatePrizeCode(rng?: CodeRng): string {
  let suffix = '';
  for (let i = 0; i < PRIZE_CODE_RANDOM_LEN; i += 1) {
    const idx = rng
      ? rng.nextInt(0, PRIZE_CODE_ALPHABET.length)
      : randomInt(0, PRIZE_CODE_ALPHABET.length);
    suffix += PRIZE_CODE_ALPHABET[idx];
  }
  return `${PRIZE_CODE_PREFIX}${suffix}`;
}

/**
 * Generates an 8-character uppercase hexadecimal ticket serial using CSPRNG.
 */
export function generateTicketSerial(rng?: CodeRng): string {
  if (rng) {
    let hex = '';
    for (let i = 0; i < 4; i += 1) {
      hex += rng.nextInt(0, 256).toString(16).padStart(2, '0');
    }
    return hex.toUpperCase();
  }
  return randomBytes(4).toString('hex').toUpperCase();
}

/**
 * Normalizes and hashes an email address with SHA-256 hex digest.
 */
export function hashEmail(email: string): string {
  return createHash('sha256')
    .update(email.trim().toLowerCase(), 'utf8')
    .digest('hex');
}

/**
 * Deterministically assigns a user UID to a stats shard index in `[0, shardCount)`.
 */
export function shardIndexForUid(uid: string, shardCount = 5): number {
  if (!Number.isInteger(shardCount) || shardCount < 1) {
    throw new Error('shardCount must be a positive integer');
  }
  const digest = createHash('sha256').update(uid, 'utf8').digest();
  return digest.readUInt32BE(0) % shardCount;
}

/**
 * Parses and normalizes a win redemption code or QR payload:
 * - `gdgspin:win:{eventId}:{code}`
 * - `GDG-XXXXXX`
 * - `XXXXXX`
 *
 * Returns normalized `GDG-XXXXXX`. Rejects mismatched eventId when `expectedEventId` is given.
 */
export function parseWinCodeInput(
  input: string,
  expectedEventId?: string,
): string {
  const trimmed = input.trim();
  if (!trimmed) {
    throw new CodeParseError('INVALID_CODE_FORMAT', 'Prize code is empty.');
  }

  let rawCode = trimmed;
  if (trimmed.toLowerCase().startsWith('gdgspin:')) {
    const parts = trimmed.split(':');
    if (
      parts.length !== 4 ||
      parts[0].toLowerCase() !== 'gdgspin' ||
      parts[1].toLowerCase() !== 'win' ||
      !parts[2] ||
      !parts[3]
    ) {
      throw new CodeParseError(
        'INVALID_CODE_FORMAT',
        'Invalid prize QR payload format.',
      );
    }
    const payloadEventId = parts[2];
    if (expectedEventId && payloadEventId !== expectedEventId) {
      throw new CodeParseError(
        'EVENT_MISMATCH',
        'Prize QR belongs to a different event.',
      );
    }
    rawCode = parts[3];
  }

  const normalized = rawCode.trim().toUpperCase();
  if (PREFIXED_PRIZE_CODE_REGEX.test(normalized)) {
    return normalized;
  }
  if (RAW_PRIZE_CODE_REGEX.test(normalized)) {
    return `${PRIZE_CODE_PREFIX}${normalized}`;
  }

  throw new CodeParseError(
    'INVALID_CODE_FORMAT',
    'Invalid prize code format. Expected GDG-XXXXXX.',
  );
}

/**
 * Parses and normalizes a stand/sponsor ticket code or QR payload:
 * - `gdgspin:code:{eventId}:{code}`
 * - raw code string
 *
 * Rejects mismatched eventId when `expectedEventId` is given.
 */
export function parseStandCodeInput(
  input: string,
  expectedEventId?: string,
): string {
  const trimmed = input.trim();
  if (!trimmed) {
    throw new CodeParseError('INVALID_CODE_FORMAT', 'Ticket code is empty.');
  }

  let rawCode = trimmed;
  if (trimmed.toLowerCase().startsWith('gdgspin:')) {
    const parts = trimmed.split(':');
    if (
      parts.length < 4 ||
      parts[0].toLowerCase() !== 'gdgspin' ||
      parts[1].toLowerCase() !== 'code' ||
      !parts[2]
    ) {
      throw new CodeParseError(
        'INVALID_CODE_FORMAT',
        'Invalid stand QR payload format.',
      );
    }
    const payloadEventId = parts[2];
    if (expectedEventId && payloadEventId !== expectedEventId) {
      throw new CodeParseError(
        'EVENT_MISMATCH',
        'Ticket QR belongs to a different event.',
      );
    }
    rawCode = parts.slice(3).join(':');
  }

  const normalized = rawCode.trim().toUpperCase();
  if (!normalized || /\s/.test(normalized) || normalized.length > 64) {
    throw new CodeParseError(
      'INVALID_CODE_FORMAT',
      'Invalid ticket code format.',
    );
  }
  return normalized;
}
