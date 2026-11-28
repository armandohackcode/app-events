/// Pure Dart JSON parsing helpers for GDG SPIN domain models.
///
/// Data layer adapters normalize Firestore `Timestamp` values into ISO-8601
/// UTC strings before invoking `fromJson`, keeping `lib/domain/` free of
/// Firebase SDK dependencies.
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is double && value.isFinite) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  if (value is Map) {
    final seconds = parseNullableInt(value['seconds'] ?? value['_seconds']);
    if (seconds != null) {
      final nanoseconds =
          parseNullableInt(value['nanoseconds'] ?? value['_nanoseconds']) ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + nanoseconds ~/ 1000000,
        isUtc: true,
      );
    }
  }
  return null;
}

/// Converts a nullable [DateTime] to a UTC ISO-8601 string.
String? toIsoStringOrNull(DateTime? value) => value?.toUtc().toIso8601String();

/// Safely parses an integer from JSON values, returning [fallback] if invalid.
int parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num && value.isFinite) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

/// Safely parses a nullable integer from JSON values.
int? parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num && value.isFinite) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// Safely parses a double from JSON values, returning [fallback] if invalid.
double parseDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) return value.isFinite ? value : fallback;
  if (value is num) {
    final asDouble = value.toDouble();
    return asDouble.isFinite ? asDouble : fallback;
  }
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null && parsed.isFinite) return parsed;
  }
  return fallback;
}

/// Safely parses a boolean from JSON values, returning [fallback] if invalid.
bool parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  return fallback;
}

/// Safely parses a non-null string from JSON values.
String parseString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  return fallback;
}

/// Safely parses a nullable non-empty string from JSON values.
String? parseNullableString(dynamic value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

/// Safely parses a `Map<String, int>` from dynamic JSON values.
Map<String, int> parseStringIntMap(dynamic value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries) '${entry.key}': parseInt(entry.value),
  };
}

/// Safely parses a `List<String>` from dynamic JSON values.
List<String> parseStringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

/// Safely normalizes a dynamic JSON map to `Map<String, dynamic>`.
Map<String, dynamic> parseDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return {for (final entry in value.entries) '${entry.key}': entry.value};
  }
  return const {};
}
