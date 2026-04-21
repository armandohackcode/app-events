import 'package:app_events/domain/models/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventStatus', () {
    test('fromValue returns correct status for known values', () {
      expect(EventStatus.fromValue('upcoming'), EventStatus.upcoming);
      expect(EventStatus.fromValue('active'), EventStatus.active);
      expect(EventStatus.fromValue('finished'), EventStatus.finished);
    });

    test('fromValue defaults to upcoming for unknown values', () {
      expect(EventStatus.fromValue(null), EventStatus.upcoming);
      expect(EventStatus.fromValue(''), EventStatus.upcoming);
      expect(EventStatus.fromValue('unknown'), EventStatus.upcoming);
    });

    test('value returns correct string representation', () {
      expect(EventStatus.upcoming.value, 'upcoming');
      expect(EventStatus.active.value, 'active');
      expect(EventStatus.finished.value, 'finished');
    });
  });

  group('Event.fromJson', () {
    final validJson = {
      'id': 'evt-1',
      'title': 'GDG DevFest 2025',
      'description': 'Gran evento de Google',
      'startDate': '2025-11-15T00:00:00.000',
      'endDate': '2025-11-15T23:59:00.000',
      'locationUrl': 'https://maps.google.com/test',
      'imageUrl': 'https://storage.example.com/event.jpg',
      'status': 'upcoming',
    };

    test('parses all fields correctly', () {
      final event = Event.fromJson(validJson);

      expect(event.id, 'evt-1');
      expect(event.title, 'GDG DevFest 2025');
      expect(event.description, 'Gran evento de Google');
      expect(event.startDate, DateTime.parse('2025-11-15T00:00:00.000'));
      expect(event.endDate, DateTime.parse('2025-11-15T23:59:00.000'));
      expect(event.locationUrl, 'https://maps.google.com/test');
      expect(event.imageUrl, 'https://storage.example.com/event.jpg');
      expect(event.status, EventStatus.upcoming);
    });

    test('uses defaults for missing optional fields', () {
      final minimal = {
        'id': 'evt-2',
        'title': 'Minimal',
        'description': null,
        'startDate': '2025-01-01T00:00:00.000',
        'endDate': '2025-01-02T00:00:00.000',
        'locationUrl': null,
        'imageUrl': null,
        'status': null,
      };
      final event = Event.fromJson(minimal);

      expect(event.description, '');
      expect(event.locationUrl, '');
      expect(event.imageUrl, '');
      expect(event.status, EventStatus.upcoming);
    });

    test('parses active and finished statuses', () {
      final activeJson = Map<String, dynamic>.from(validJson)
        ..['status'] = 'active';
      final finishedJson = Map<String, dynamic>.from(validJson)
        ..['status'] = 'finished';

      expect(Event.fromJson(activeJson).status, EventStatus.active);
      expect(Event.fromJson(finishedJson).status, EventStatus.finished);
    });
  });

  group('Event.toJson', () {
    final event = Event(
      id: 'evt-1',
      title: 'GDG DevFest 2025',
      description: 'Gran evento',
      startDate: DateTime(2025, 11, 15),
      endDate: DateTime(2025, 11, 15, 23, 59),
      locationUrl: 'https://maps.google.com/test',
      imageUrl: 'https://storage.example.com/event.jpg',
      status: EventStatus.active,
    );

    test('serialises all fields', () {
      final json = event.toJson();

      expect(json['id'], 'evt-1');
      expect(json['title'], 'GDG DevFest 2025');
      expect(json['description'], 'Gran evento');
      expect(json['locationUrl'], 'https://maps.google.com/test');
      expect(json['imageUrl'], 'https://storage.example.com/event.jpg');
      expect(json['status'], 'active');
    });

    test('round-trip fromJson → toJson preserves data', () {
      final json = event.toJson();
      final restored = Event.fromJson(json);

      expect(restored.id, event.id);
      expect(restored.title, event.title);
      expect(restored.description, event.description);
      expect(restored.startDate, event.startDate);
      expect(restored.endDate, event.endDate);
      expect(restored.locationUrl, event.locationUrl);
      expect(restored.imageUrl, event.imageUrl);
      expect(restored.status, event.status);
    });
  });

  group('Event.copyWith', () {
    final original = Event(
      id: 'evt-1',
      title: 'Original',
      description: 'Desc',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 1, 2),
      locationUrl: '',
      imageUrl: '',
      status: EventStatus.upcoming,
    );

    test('returns new instance with only changed fields updated', () {
      final updated = original.copyWith(title: 'Updated', status: EventStatus.active);

      expect(updated.title, 'Updated');
      expect(updated.status, EventStatus.active);
      // unchanged fields
      expect(updated.id, original.id);
      expect(updated.description, original.description);
      expect(updated.startDate, original.startDate);
      expect(updated.endDate, original.endDate);
    });

    test('copyWith without arguments returns equivalent event', () {
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.status, original.status);
    });

    test('copyWith imageUrl replaces existing value', () {
      final withImage = original.copyWith(imageUrl: 'https://img.example.com/a.jpg');
      expect(withImage.imageUrl, 'https://img.example.com/a.jpg');
    });
  });
}
