import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Architecture tests: enforce the Clean Architecture rules described in the
// README by inspecting the imports of every file under lib/.
// They run with `flutter test` (and therefore in CI and in the Claude hooks).
// ---------------------------------------------------------------------------

class _LayerRule {
  final String layer;
  final List<String> forbidden;
  final String reason;
  const _LayerRule(this.layer, this.forbidden, this.reason);
}

const _rules = [
  _LayerRule(
    'lib/domain/',
    [
      'package:flutter/',
      'package:cloud_firestore/',
      'package:firebase_',
      'package:provider/',
      'package:app_events/data/',
      'package:app_events/ui/',
      'package:app_events/config/',
      'dart:io',
    ],
    'domain must be pure Dart and must not depend on any implementation',
  ),
  _LayerRule(
    'lib/data/',
    [
      'package:flutter/material.dart',
      'package:flutter/widgets.dart',
      'package:flutter/cupertino.dart',
      'package:provider/',
      'package:app_events/ui/',
      'package:app_events/config/',
    ],
    'data implements domain contracts and must not know about the UI',
  ),
  _LayerRule('lib/ui/', [
    'package:cloud_firestore/',
    'package:firebase_',
    'package:app_events/data/',
    'package:app_events/config/di/',
  ], 'ui talks only to abstract repositories injected from main.dart'),
];

/// Known violations, kept so CI stays green while the debt is paid.
/// Format: `'file|import'`. Never add entries here: fix the code instead.
/// When a violation is fixed, remove its entry (the test enforces it).
const _knownViolations = <String>{};

final _importPattern = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

Map<String, List<String>> _importsByFile() {
  final result = <String, List<String>>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    final path = file.path.replaceAll(r'\', '/');
    result[path] = file
        .readAsLinesSync()
        .map((l) => _importPattern.firstMatch(l)?.group(1))
        .whereType<String>()
        .toList();
  }
  return result;
}

List<String> _abstractClasses(String dir, String suffix) {
  final pattern = RegExp('abstract (?:interface )?class (\\w+$suffix)\\b');
  return Directory(dir)
      .listSync()
      .whereType<File>()
      .expand((f) => pattern.allMatches(f.readAsStringSync()))
      .map((m) => m.group(1)!)
      .toList();
}

void main() {
  final imports = _importsByFile();

  group('Layer dependencies', () {
    for (final rule in _rules) {
      test('${rule.layer} respects its boundaries', () {
        final violations = <String>[];
        imports.forEach((file, fileImports) {
          if (!file.startsWith(rule.layer)) return;
          for (final import in fileImports) {
            final isForbidden = rule.forbidden.any(import.startsWith);
            if (isForbidden && !_knownViolations.contains('$file|$import')) {
              violations.add('$file imports $import');
            }
          }
        });
        expect(violations, isEmpty, reason: rule.reason);
      });
    }

    test('known violations baseline has no stale entries', () {
      final stale = _knownViolations.where((entry) {
        final [file, import] = entry.split('|');
        return !(imports[file]?.contains(import) ?? false);
      }).toList();
      expect(
        stale,
        isEmpty,
        reason: 'These violations were fixed: remove them from the baseline',
      );
    });
  });

  group('Dependency injection', () {
    final serviceLocator = File(
      'lib/config/di/service_locator.dart',
    ).readAsStringSync();

    for (final (dir, suffix) in [
      ('lib/domain/repositories', 'Repository'),
      ('lib/domain/datasources', 'Datasource'),
    ]) {
      test('every $suffix contract is registered in the service locator', () {
        final contracts = _abstractClasses(dir, suffix);
        expect(contracts, isNotEmpty);
        final missing = contracts
            .where((c) => !serviceLocator.contains('registerLazySingleton<$c>'))
            .toList();
        expect(missing, isEmpty, reason: 'Register them in service_locator');
      });
    }

    test('every repository contract has an implementation in data/', () {
      final implementations = Directory('lib/data/repositories')
          .listSync()
          .whereType<File>()
          .map((f) => f.readAsStringSync())
          .join('\n');
      final missing = _abstractClasses(
        'lib/domain/repositories',
        'Repository',
      ).where((c) => !implementations.contains('implements $c')).toList();
      expect(missing, isEmpty);
    });
  });
}
