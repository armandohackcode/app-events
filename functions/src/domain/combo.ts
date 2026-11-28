import type { SpinSymbol } from './types';

/**
 * Pure combo rules mirroring `lib/domain/models/spin_combo.dart` and
 * `GdgSpinProvider.fillSymbols`.
 *
 * The `wild` symbol never replaces `seven`, `lemon`, or `mysteryBox`.
 */

export const WILDABLE_SYMBOLS: ReadonlySet<SpinSymbol> = new Set<SpinSymbol>([
  'cherries',
  'bell',
  'bar',
  'star',
  'diamond',
]);

export const WINNING_PRIZE_SYMBOLS: ReadonlySet<SpinSymbol> =
  new Set<SpinSymbol>([
    'cherries',
    'bell',
    'bar',
    'star',
    'diamond',
    'seven',
  ]);

/** Exact 12-symbol reel fill distribution from Phase 1. */
export const FILL_SYMBOLS: readonly SpinSymbol[] = [
  'cherries',
  'cherries',
  'lemon',
  'lemon',
  'bell',
  'bar',
  'star',
  'diamond',
  'diamond',
  'wild',
  'mysteryBox',
  'seven',
];

export interface ComboRng {
  nextFloat(): number;
  nextInt(min: number, maxExclusive: number): number;
}

/**
 * Returns true when a 3-symbol row would look like a win to the player.
 * Mirrors `SpinCombo.looksLikeWin` in `lib/domain/models/spin_combo.dart`.
 */
export function looksLikeWin(combo: readonly SpinSymbol[]): boolean {
  if (combo.length !== 3) return false;
  const [a, b, c] = combo;
  if (a === b && b === c) return true;

  let wildCount = 0;
  for (const symbol of combo) {
    if (symbol === 'wild') wildCount += 1;
  }

  if (wildCount >= 2) return true;
  if (wildCount === 1) {
    const nonWilds = combo.filter((s) => s !== 'wild');
    if (
      nonWilds.length === 2 &&
      nonWilds[0] === nonWilds[1] &&
      WILDABLE_SYMBOLS.has(nonWilds[0])
    ) {
      return true;
    }
  }
  return false;
}

/**
 * Returns true when the first two reels can still form a winning or bonus
 * line on the third reel.
 * Mirrors `SpinCombo.canStillWin` in `lib/domain/models/spin_combo.dart`.
 */
export function canStillWin(first: SpinSymbol, second: SpinSymbol): boolean {
  if (first === second && first !== 'lemon') return true;
  if (first === 'wild' && WILDABLE_SYMBOLS.has(second)) return true;
  if (second === 'wild' && WILDABLE_SYMBOLS.has(first)) return true;
  return false;
}

/**
 * Builds a 3-symbol winning combo for a prize symbol, substituting at most
 * one random slot with `wild` when allowed by `WILDABLE_SYMBOLS`.
 */
export function buildWinCombo(
  symbol: SpinSymbol,
  wildReplacementChance: number,
  rng: ComboRng,
): [SpinSymbol, SpinSymbol, SpinSymbol] {
  const combo: [SpinSymbol, SpinSymbol, SpinSymbol] = [symbol, symbol, symbol];
  if (
    WILDABLE_SYMBOLS.has(symbol) &&
    wildReplacementChance > 0 &&
    rng.nextFloat() < wildReplacementChance
  ) {
    const slot = rng.nextInt(0, 3);
    combo[slot] = 'wild';
  }
  return combo;
}

/** Builds the 3-symbol bonus combo (`mysteryBox` x3). */
export function buildBonusCombo(): [SpinSymbol, SpinSymbol, SpinSymbol] {
  return ['mysteryBox', 'mysteryBox', 'mysteryBox'];
}

/**
 * Generates a losing 3-symbol combo guaranteed to fail `looksLikeWin`.
 * Retries up to 100 times with CSPRNG before falling back to a fixed safe line.
 */
export function buildLoseCombo(
  rng: ComboRng,
): [SpinSymbol, SpinSymbol, SpinSymbol] {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    const candidate: [SpinSymbol, SpinSymbol, SpinSymbol] = [
      FILL_SYMBOLS[rng.nextInt(0, FILL_SYMBOLS.length)],
      FILL_SYMBOLS[rng.nextInt(0, FILL_SYMBOLS.length)],
      FILL_SYMBOLS[rng.nextInt(0, FILL_SYMBOLS.length)],
    ];
    if (!looksLikeWin(candidate)) {
      return candidate;
    }
  }
  return ['lemon', 'cherries', 'bar'];
}
