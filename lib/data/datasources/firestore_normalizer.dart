import 'package:app_events/domain/models/spin_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Recursively normalizes Firestore and Cloud Functions maps into JSON-safe
/// `Map<String, dynamic>` structures (converting `Timestamp` and `DateTime`
/// instances to UTC ISO-8601 strings).
Map<String, dynamic> normalizeFirestoreMap(Map<Object?, Object?> raw) {
  return {
    for (final entry in raw.entries)
      '${entry.key}': _normalizeFirestoreValue(entry.value),
  };
}

dynamic _normalizeFirestoreValue(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toUtc().toIso8601String();
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is Map) {
    return normalizeFirestoreMap(value);
  }
  if (value is List) {
    return value.map(_normalizeFirestoreValue).toList(growable: false);
  }
  return value;
}

/// Maps a [FirebaseFunctionsException] into a typed [SpinException], extracting
/// `details['reason']` when provided by the backend.
SpinException mapFunctionsException(FirebaseFunctionsException error) {
  String? rawReason;
  final details = error.details;
  if (details is Map) {
    final reasonValue = details['reason'];
    if (reasonValue is String && reasonValue.isNotEmpty) {
      rawReason = reasonValue;
    }
  }

  var reason = rawReason != null
      ? SpinErrorReason.fromValue(rawReason)
      : SpinErrorReason.unknown;

  if (reason == SpinErrorReason.unknown) {
    reason = switch (error.code) {
      'unauthenticated' => SpinErrorReason.unauthenticated,
      'permission-denied' => SpinErrorReason.permissionDenied,
      'already-exists' => SpinErrorReason.alreadyExists,
      'not-found' => SpinErrorReason.notFound,
      'unavailable' || 'deadline-exceeded' => SpinErrorReason.network,
      _ => SpinErrorReason.unknown,
    };
  }

  return SpinException(
    reason: reason,
    code: error.code,
    message: error.message ?? error.code,
  );
}

/// Executes a Cloud Functions callable returning a normalized map, converting
/// [FirebaseFunctionsException] into [SpinException].
Future<Map<String, dynamic>> callFunctionsMap(
  FirebaseFunctions functions,
  String name,
  Map<String, dynamic> payload,
) async {
  try {
    final result = await functions.httpsCallable(name).call<dynamic>(payload);
    final data = result.data;
    if (data is Map) {
      return normalizeFirestoreMap(data);
    }
    return const {};
  } on FirebaseFunctionsException catch (e) {
    throw mapFunctionsException(e);
  }
}
