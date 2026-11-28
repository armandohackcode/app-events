import 'dart:convert';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_result.dart';

/// Parsed attendee registration batch ready for `adminImportRegistrations`.
class RegistrationParseResult {
  final List<SpinRegistrationRow> rows;
  final int skippedCount;
  final Map<String, int> packageCounts;

  const RegistrationParseResult({
    this.rows = const [],
    this.skippedCount = 0,
    this.packageCounts = const {},
  });
}

final RegExp _basicEmailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

const Set<String> _truthyCheckedInValues = {'true', '1', 'yes', 'y', 'si'};

/// Parses CSV, TSV, or JSON registration input into normalized, deduplicated
/// [SpinRegistrationRow] entries.
RegistrationParseResult parseRegistrationInput(String raw) {
  final trimmed = _stripBom(raw).trim();
  if (trimmed.isEmpty) {
    return const RegistrationParseResult();
  }

  if (trimmed.startsWith('[')) {
    return _parseJsonArray(trimmed);
  }

  return _parseDelimitedText(trimmed);
}

RegistrationParseResult _parseJsonArray(String rawJson) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(rawJson);
  } on FormatException {
    return const RegistrationParseResult(skippedCount: 1);
  }

  if (decoded is! List) {
    return const RegistrationParseResult(skippedCount: 1);
  }

  final deduped = <String, SpinRegistrationRow>{};
  var skippedCount = 0;

  for (final item in decoded) {
    if (item is! Map) {
      skippedCount++;
      continue;
    }

    final lowerMap = <String, dynamic>{
      for (final entry in item.entries)
        entry.key.toString().trim().toLowerCase(): entry.value,
    };

    final rawEmail = _firstMapValue(
      lowerMap,
      AppStrings.spinCsvHeaderEmailAliases,
    );
    final email = _normalizeValidEmail(rawEmail?.toString());
    if (email == null) {
      skippedCount++;
      continue;
    }

    final rawName = _firstMapValue(
      lowerMap,
      AppStrings.spinCsvHeaderNameAliases,
    );
    final rawPackage = _firstMapValue(
      lowerMap,
      AppStrings.spinCsvHeaderPackageAliases,
    );
    final rawCheckedIn = _firstMapValue(
      lowerMap,
      AppStrings.spinCsvHeaderCheckedInAliases,
    );

    final fullName = rawName?.toString().trim() ?? '';
    final pkgText = rawPackage?.toString().trim() ?? '';
    final pkg = pkgText.isEmpty ? AppStrings.spinDefaultPackage : pkgText;
    final checkedIn = _parseCheckedIn(rawCheckedIn);

    deduped[email] = SpinRegistrationRow(
      email: email,
      fullName: fullName,
      package: pkg,
      checkedIn: checkedIn,
    );
  }

  return _buildResult(deduped, skippedCount);
}

RegistrationParseResult _parseDelimitedText(String rawText) {
  final normalized = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final delimiter = _detectDelimiter(normalized);
  final records = _parseDelimitedRecords(normalized, delimiter);
  if (records.isEmpty) {
    return const RegistrationParseResult();
  }

  var emailIdx = 0;
  var nameIdx = 1;
  var packageIdx = 2;
  var checkedInIdx = 3;
  var startRow = 0;

  final firstRow = records.first;
  if (_looksLikeHeader(firstRow)) {
    startRow = 1;
    emailIdx = _findColumnIndex(firstRow, AppStrings.spinCsvHeaderEmailAliases);
    nameIdx = _findColumnIndex(firstRow, AppStrings.spinCsvHeaderNameAliases);
    packageIdx = _findColumnIndex(
      firstRow,
      AppStrings.spinCsvHeaderPackageAliases,
    );
    checkedInIdx = _findColumnIndex(
      firstRow,
      AppStrings.spinCsvHeaderCheckedInAliases,
    );
  }

  final deduped = <String, SpinRegistrationRow>{};
  var skippedCount = 0;

  for (var i = startRow; i < records.length; i++) {
    final row = records[i];
    final email = _normalizeValidEmail(_cellAt(row, emailIdx));
    if (email == null) {
      skippedCount++;
      continue;
    }

    final fullName = (_cellAt(row, nameIdx) ?? '').trim();
    final pkgText = (_cellAt(row, packageIdx) ?? '').trim();
    final pkg = pkgText.isEmpty ? AppStrings.spinDefaultPackage : pkgText;
    final checkedIn = _parseCheckedIn(_cellAt(row, checkedInIdx));

    deduped[email] = SpinRegistrationRow(
      email: email,
      fullName: fullName,
      package: pkg,
      checkedIn: checkedIn,
    );
  }

  return _buildResult(deduped, skippedCount);
}

RegistrationParseResult _buildResult(
  Map<String, SpinRegistrationRow> deduped,
  int skippedCount,
) {
  final packageCounts = <String, int>{};
  for (final row in deduped.values) {
    packageCounts[row.package] = (packageCounts[row.package] ?? 0) + 1;
  }
  return RegistrationParseResult(
    rows: deduped.values.toList(growable: false),
    skippedCount: skippedCount,
    packageCounts: Map<String, int>.unmodifiable(packageCounts),
  );
}

String _stripBom(String value) {
  final bom = String.fromCharCode(0xFEFF);
  return value.startsWith(bom) ? value.substring(1) : value;
}

String _detectDelimiter(String text) {
  final lines = text.split('\n');
  final sample = lines.firstWhere(
    (line) => line.trim().isNotEmpty,
    orElse: () => '',
  );
  var tabs = 0;
  var semicolons = 0;
  var commas = 0;
  var inQuotes = false;

  for (var i = 0; i < sample.length; i++) {
    final ch = sample[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (inQuotes) continue;
    if (ch == '\t') tabs++;
    if (ch == ';') semicolons++;
    if (ch == ',') commas++;
  }

  if (tabs > 0 && tabs >= semicolons && tabs >= commas) return '\t';
  if (semicolons > commas) return ';';
  return ',';
}

List<List<String>> _parseDelimitedRecords(String text, String delimiter) {
  final records = <List<String>>[];
  var currentRow = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  var fieldStarted = false;

  void finishField() {
    currentRow.add(buffer.toString());
    buffer.clear();
    fieldStarted = false;
  }

  void finishRow() {
    finishField();
    final hasNonEmptyCell = currentRow.any((cell) => cell.trim().isNotEmpty);
    if (hasNonEmptyCell) {
      records.add(currentRow);
    }
    currentRow = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(ch);
      }
      continue;
    }

    if (ch == '"' && !fieldStarted && buffer.toString().trim().isEmpty) {
      buffer.clear();
      inQuotes = true;
      fieldStarted = true;
      continue;
    }

    if (ch == delimiter) {
      finishField();
      continue;
    }

    if (ch == '\n') {
      finishRow();
      continue;
    }

    fieldStarted = true;
    buffer.write(ch);
  }

  if (inQuotes || fieldStarted || buffer.isNotEmpty || currentRow.isNotEmpty) {
    finishRow();
  }

  return records;
}

bool _looksLikeHeader(List<String> row) {
  var matchesAlias = false;
  for (final cell in row) {
    final normalized = cell.trim().toLowerCase();
    if (normalized.contains('@')) return false;
    if (AppStrings.spinCsvHeaderEmailAliases.contains(normalized) ||
        AppStrings.spinCsvHeaderNameAliases.contains(normalized) ||
        AppStrings.spinCsvHeaderPackageAliases.contains(normalized) ||
        AppStrings.spinCsvHeaderCheckedInAliases.contains(normalized)) {
      matchesAlias = true;
    }
  }
  return matchesAlias;
}

int _findColumnIndex(List<String> headers, List<String> aliases) {
  for (var i = 0; i < headers.length; i++) {
    final normalized = headers[i].trim().toLowerCase();
    if (aliases.contains(normalized)) {
      return i;
    }
  }
  return -1;
}

String? _cellAt(List<String> row, int index) {
  if (index < 0 || index >= row.length) return null;
  return row[index];
}

dynamic _firstMapValue(Map<String, dynamic> map, List<String> aliases) {
  for (final alias in aliases) {
    if (map.containsKey(alias)) return map[alias];
  }
  return null;
}

String? _normalizeValidEmail(String? raw) {
  if (raw == null) return null;
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty || normalized.length > 254) return null;
  if (!_basicEmailRegex.hasMatch(normalized)) return null;
  return normalized;
}

bool _parseCheckedIn(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    return _truthyCheckedInValues.contains(raw.trim().toLowerCase());
  }
  return false;
}
