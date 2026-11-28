import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_registration_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseRegistrationInput', () {
    test('returns empty result for blank input', () {
      final result = parseRegistrationInput('   \n  ');

      expect(result.rows, isEmpty);
      expect(result.skippedCount, 0);
      expect(result.packageCounts, isEmpty);
    });

    test(
      'parses CSV with English header, normalizes email, and counts packages',
      () {
        const csv = '''
email,fullName,package,checkedIn
  ANA@Example.com , Ana Perez , VIP , true
bob@example.com,Bob Builder,,false
''';
        final result = parseRegistrationInput(csv);

        expect(result.skippedCount, 0);
        expect(result.rows, hasLength(2));
        expect(result.rows[0].email, 'ana@example.com');
        expect(result.rows[0].fullName, 'Ana Perez');
        expect(result.rows[0].package, 'VIP');
        expect(result.rows[0].checkedIn, isTrue);
        expect(result.rows[1].email, 'bob@example.com');
        expect(result.rows[1].package, AppStrings.spinDefaultPackage);
        expect(result.packageCounts, {
          'VIP': 1,
          AppStrings.spinDefaultPackage: 1,
        });
      },
    );

    test(
      'parses reordered localized header with semicolon delimiter and quoted values',
      () {
        final colName = AppStrings.spinCsvHeaderNameAliases.first;
        final colPkg = AppStrings.spinCsvHeaderPackageAliases.first;
        final csv =
            '$colPkg;email;$colName\n'
            'Standard;jane@example.com;"Doe, ""Jane"""\n'
            'VIP;sam@example.com;"Smith; Sam"\n';

        final result = parseRegistrationInput(csv);

        expect(result.skippedCount, 0);
        expect(result.rows, hasLength(2));
        expect(result.rows[0].email, 'jane@example.com');
        expect(result.rows[0].fullName, 'Doe, "Jane"');
        expect(result.rows[0].package, 'Standard');
        expect(result.rows[1].fullName, 'Smith; Sam');
        expect(result.packageCounts, {'Standard': 1, 'VIP': 1});
      },
    );

    test('parses CSV without headers using positional columns', () {
      const csv = 'ada@example.com,Ada Lovelace,VIP\ngrace@example.com,Grace';

      final result = parseRegistrationInput(csv);

      expect(result.rows, hasLength(2));
      expect(result.rows[0].email, 'ada@example.com');
      expect(result.rows[0].fullName, 'Ada Lovelace');
      expect(result.rows[0].package, 'VIP');
      expect(result.rows[1].email, 'grace@example.com');
      expect(result.rows[1].fullName, 'Grace');
      expect(result.rows[1].package, AppStrings.spinDefaultPackage);
    });

    test(
      'parses JSON array, skips invalid emails, and deduplicates last-wins',
      () {
        const jsonInput = '''
[
  {"email": "ADA@example.com", "fullName": "Ada Old", "package": "Standard"},
  {"email": "not-an-email", "fullName": "Bad Row", "package": "VIP"},
  {"email": "ada@example.com", "fullName": "Ada New", "package": "VIP", "checkedIn": true},
  {"email": "linus@example.com", "fullName": "Linus", "package": ""}
]
''';

        final result = parseRegistrationInput(jsonInput);

        expect(result.skippedCount, 1);
        expect(result.rows, hasLength(2));
        expect(result.rows[0].email, 'ada@example.com');
        expect(result.rows[0].fullName, 'Ada New');
        expect(result.rows[0].package, 'VIP');
        expect(result.rows[0].checkedIn, isTrue);
        expect(result.rows[1].package, AppStrings.spinDefaultPackage);
        expect(result.packageCounts, {
          'VIP': 1,
          AppStrings.spinDefaultPackage: 1,
        });
      },
    );

    test('handles malformed JSON array gracefully without throwing', () {
      final result = parseRegistrationInput('[{"email": "broken"');

      expect(result.rows, isEmpty);
      expect(result.skippedCount, 1);
    });
  });
}
