// cspell:ignore diseno escenografia logistica acreditacion colead
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/utils/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foldAccents', () {
    test(
      'folds Spanish vowels, tilde-n, and uppercase characters to ASCII lowercase',
      () {
        expect(foldAccents(AppStrings.organizersTeamDesign), 'diseno');
        expect(foldAccents(AppStrings.organizersTeamStaging), 'escenografia');
        expect(foldAccents(AppStrings.organizersTeamLogistics), 'logistica');
        expect(
          foldAccents(AppStrings.organizersTeamAccreditation),
          'acreditacion',
        );
      },
    );
  });

  group('normalizeLookupKey', () {
    test(
      'trims outer whitespace, collapses internal spaces, and folds accents',
      () {
        expect(normalizeLookupKey('  Audio   y   Video  '), 'audio y video');
        expect(
          normalizeLookupKey(
            '  ${AppStrings.organizersTeamDesign.toUpperCase()}  ',
          ),
          'diseno',
        );
      },
    );
  });

  group('role tag detection', () {
    test(
      'isCoLeadRoleTag matches Co-lead variants regardless of casing or hyphen',
      () {
        expect(isCoLeadRoleTag('Co-lead'), isTrue);
        expect(isCoLeadRoleTag('CO LEAD'), isTrue);
        expect(isCoLeadRoleTag('colead'), isTrue);
        expect(isCoLeadRoleTag('Lead'), isFalse);
        expect(isCoLeadRoleTag('App'), isFalse);
      },
    );

    test('isRoleOnlyTag detects Lead and Co-lead but excludes team names', () {
      expect(isRoleOnlyTag('Lead'), isTrue);
      expect(isRoleOnlyTag('  LEAD  '), isTrue);
      expect(isRoleOnlyTag('Co-lead'), isTrue);
      expect(isRoleOnlyTag(AppStrings.organizersTeamApp), isFalse);
      expect(isRoleOnlyTag(AppStrings.organizersTeamWeb), isFalse);
    });
  });
}
