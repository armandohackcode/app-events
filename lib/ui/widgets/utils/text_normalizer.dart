/// Text normalization helpers used to group and filter labels regardless of
/// Spanish accents, casing, or repeated whitespace.
String foldAccents(String text) {
  const replacements = {
    '\u00e1': 'a',
    '\u00e0': 'a',
    '\u00e4': 'a',
    '\u00e2': 'a',
    '\u00e9': 'e',
    '\u00e8': 'e',
    '\u00eb': 'e',
    '\u00ea': 'e',
    '\u00ed': 'i',
    '\u00ec': 'i',
    '\u00ef': 'i',
    '\u00ee': 'i',
    '\u00f3': 'o',
    '\u00f2': 'o',
    '\u00f6': 'o',
    '\u00f4': 'o',
    '\u00fa': 'u',
    '\u00f9': 'u',
    '\u00fc': 'u',
    '\u00fb': 'u',
    '\u00f1': 'n',
  };
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(replacements[ch] ?? ch);
  }
  return buffer.toString();
}

/// Normalizes [raw] into a lowercase, accent-free, single-spaced lookup key.
String normalizeLookupKey(String raw) {
  return foldAccents(raw.trim()).replaceAll(RegExp(r'\s+'), ' ');
}

final RegExp _coLeadPattern = RegExp(r'^co[- ]?lead$');

/// Returns true when [raw] represents a Co-Lead role tag rather than a team.
bool isCoLeadRoleTag(String raw) =>
    _coLeadPattern.hasMatch(normalizeLookupKey(raw));

/// Returns true when [raw] is a leadership role label (`Lead` or `Co-Lead`).
bool isRoleOnlyTag(String raw) {
  final normalized = normalizeLookupKey(raw);
  return normalized == 'lead' || isCoLeadRoleTag(normalized);
}
