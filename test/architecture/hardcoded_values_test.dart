import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// UI code must not hardcode texts, colors, asset paths or URLs: they live in
// lib/config/theme (AppStrings, AppStyles, AppAssetsPath, AppLinks) so the
// app's look, copy and links are configured in one place.
// The same patterns are checked by .claude/hooks/dart-post-edit.sh.
// ---------------------------------------------------------------------------

class _Rule {
  final String name;
  final RegExp pattern;
  final String fix;
  const _Rule(this.name, this.pattern, this.fix);
}

final _rules = [
  _Rule(
    'text',
    // A literal that starts the Text, except '' and AppStrings interpolations.
    RegExp(r'''\bText\(\s*['"](?!['"]|\$\{)'''),
    'use an AppStrings constant',
  ),
  _Rule(
    'label',
    RegExp(
      r'''\b(labelText|hintText|helperText|tooltip|semanticLabel|semanticsLabel)\s*:\s*['"](?!['"]|\$\{)''',
    ),
    'use an AppStrings constant',
  ),
  _Rule(
    'color',
    RegExp(
      r'\bColor\(0x|\bColor\.from(ARGB|RGBO)\(|\bColors\.(?!transparent\b)\w+',
    ),
    'use an AppStyles color (Colors.transparent is allowed)',
  ),
  _Rule('asset', RegExp(r'''['"]assets/'''), 'use an AppAssetsPath constant'),
  _Rule('url', RegExp(r'''['"]https?://'''), 'use an AppLinks constant'),
];

final _comment = RegExp(r'^\s*//');

Iterable<File> _uiFiles() => [
  File('lib/main.dart'),
  ...Directory('lib/ui').listSync(recursive: true).whereType<File>(),
].where((f) => f.path.endsWith('.dart'));

void main() {
  for (final rule in _rules) {
    test('UI code has no hardcoded ${rule.name}s', () {
      final violations = <String>[];
      for (final file in _uiFiles()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (_comment.hasMatch(lines[i])) continue;
          if (rule.pattern.hasMatch(lines[i])) {
            violations.add('${file.path}:${i + 1}  ${lines[i].trim()}');
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'Move them to lib/config/theme: ${rule.fix}',
      );
    });
  }
}
