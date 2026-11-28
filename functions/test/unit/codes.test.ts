import { describe, expect, it } from 'vitest';
import {
  CodeParseError,
  PRIZE_CODE_ALPHABET,
  generatePrizeCode,
  generateTicketSerial,
  hashEmail,
  parseStandCodeInput,
  parseWinCodeInput,
  shardIndexForUid,
} from '../../src/domain/codes';

describe('codes, hashing & QR payload helpers', () => {
  it('generates unambiguous Base32 prize codes prefixed with GDG-', () => {
    const allowed = new Set(PRIZE_CODE_ALPHABET.split(''));
    expect(allowed.has('0')).toBe(false);
    expect(allowed.has('O')).toBe(false);
    expect(allowed.has('1')).toBe(false);
    expect(allowed.has('I')).toBe(false);

    const seen = new Set<string>();
    for (let i = 0; i < 200; i += 1) {
      const code = generatePrizeCode();
      expect(code).toMatch(/^GDG-[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$/);
      seen.add(code);
    }
    expect(seen.size).toBeGreaterThan(195);
  });

  it('generates 8-char uppercase hexadecimal ticket serials', () => {
    for (let i = 0; i < 100; i += 1) {
      const serial = generateTicketSerial();
      expect(serial).toMatch(/^[0-9A-F]{8}$/);
    }
  });

  it('parses win QR payloads and raw codes, enforcing eventId match', () => {
    expect(parseWinCodeInput('GDG-7K9P2M', 'evt-1')).toBe('GDG-7K9P2M');
    expect(parseWinCodeInput('  7k9p2m ', 'evt-1')).toBe('GDG-7K9P2M');
    expect(parseWinCodeInput('gdgspin:win:evt-1:gdg-7k9p2m', 'evt-1')).toBe(
      'GDG-7K9P2M',
    );
    expect(parseWinCodeInput('gdgspin:win:evt-1:7K9P2M', 'evt-1')).toBe(
      'GDG-7K9P2M',
    );

    expect(() =>
      parseWinCodeInput('gdgspin:win:other-event:GDG-7K9P2M', 'evt-1'),
    ).toThrowError(CodeParseError);

    try {
      parseWinCodeInput('gdgspin:win:other-event:GDG-7K9P2M', 'evt-1');
    } catch (error) {
      expect((error as CodeParseError).reason).toBe('EVENT_MISMATCH');
    }

    expect(() => parseWinCodeInput('GDG-0O1I23', 'evt-1')).toThrowError(
      CodeParseError,
    );
    expect(() =>
      parseWinCodeInput('gdgspin:code:evt-1:CLOUD26', 'evt-1'),
    ).toThrowError(CodeParseError);
  });

  it('parses stand QR payloads and raw stand codes, enforcing eventId match', () => {
    expect(parseStandCodeInput(' cloud26 ', 'evt-1')).toBe('CLOUD26');
    expect(parseStandCodeInput('gdgspin:code:evt-1:cloud26', 'evt-1')).toBe(
      'CLOUD26',
    );

    try {
      parseStandCodeInput('gdgspin:code:wrong-evt:CLOUD26', 'evt-1');
      expect.unreachable('Expected EVENT_MISMATCH error');
    } catch (error) {
      expect(error).toBeInstanceOf(CodeParseError);
      expect((error as CodeParseError).reason).toBe('EVENT_MISMATCH');
    }

    expect(() =>
      parseStandCodeInput('gdgspin:win:evt-1:GDG-7K9P2M', 'evt-1'),
    ).toThrowError(CodeParseError);
    expect(() => parseStandCodeInput('bad code', 'evt-1')).toThrowError(
      CodeParseError,
    );
  });

  it('normalizes email hashes consistently', () => {
    const h1 = hashEmail('  Ana.Perez@Example.COM ');
    const h2 = hashEmail('ana.perez@example.com');
    expect(h1).toBe(h2);
    expect(h1).toMatch(/^[a-f0-9]{64}$/);
    expect(h1).not.toBe(hashEmail('bob@example.com'));
  });

  it('computes deterministic shard index within bounds', () => {
    const shards = new Set<number>();
    for (let i = 0; i < 50; i += 1) {
      const uid = `user-${i}`;
      const idx = shardIndexForUid(uid, 5);
      expect(idx).toBe(shardIndexForUid(uid, 5));
      expect(idx).toBeGreaterThanOrEqual(0);
      expect(idx).toBeLessThan(5);
      shards.add(idx);
    }
    expect(shards.size).toBeGreaterThan(1);
  });
});
