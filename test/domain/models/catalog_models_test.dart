import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/resource_library.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/models/treasure_hunt_model.dart';
import 'package:flutter_test/flutter_test.dart';

// Small read-only catalog models (organizers, sponsors, library, treasure hunt).
void main() {
  group('Organizer', () {
    test('fromJson applies defaults for link, team and lead', () {
      final organizer = Organizer.fromJson({
        'id': 1,
        'type': 2,
        'name': 'Lead',
        'photoUrl': 'https://img/o.png',
      });

      expect(organizer.link, '');
      expect(organizer.team, isEmpty);
      expect(organizer.lead, isFalse);
    });

    test('round-trip preserves data', () {
      final json = {
        'id': 1,
        'type': 1,
        'name': 'Org',
        'photoUrl': '',
        'link': 'https://github.com/org',
        'team': ['Mobile'],
        'lead': true,
      };

      expect(Organizer.fromJson(json).toJson(), json);
    });
  });

  group('Sponsor', () {
    test('round-trip preserves data including nullable id', () {
      final json = {
        'id': null,
        'name': 'Google',
        'photoUrl': 'https://img/s.png',
        'link': 'https://google.com',
      };

      expect(Sponsor.fromJson(json).toJson(), json);
    });

    test('sponsorFromJson decodes a JSON list', () {
      final sponsors = sponsorFromJson(
        '[{"id":"1","name":"A","photoUrl":"","link":""}]',
      );

      expect(sponsors.single.name, 'A');
    });
  });

  group('ResourceLibrary', () {
    test('fromJson defaults keywords to an empty list', () {
      final resource = ResourceLibrary.fromJson({
        'title': 'Docs',
        'link': 'https://docs.flutter.dev',
        'type': 'Mobile',
      });

      expect(resource.keywords, isEmpty);
    });

    test('copyWith keeps keywords', () {
      final resource = ResourceLibrary(
        title: 'Docs',
        link: 'https://docs.flutter.dev',
        type: 'Mobile',
        keywords: ['flutter'],
      );

      expect(resource.copyWith(title: 'New').keywords, ['flutter']);
    });
  });

  group('TreasureHuntModel', () {
    test('round-trip preserves data', () {
      final json = {
        'uuid': 't-1',
        'title': 'Find the logo',
        'imgPath': 'assets/img/treasure_bunt/1.png',
        'question': 'Where?',
        'answer': 'Here',
        'description': 'Clue',
      };

      expect(TreasureHuntModel.fromJson(json).toJson(), json);
    });
  });
}
