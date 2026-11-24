import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('eventTypeLabel', () {
    test('turns each stored type into its capitalized label', () {
      expect(
        eventTypeLabel(EventTypeSpeaker.conference.value),
        AppStrings.eventTypeConference,
      );
      expect(
        eventTypeLabel(EventTypeSpeaker.workshop.value),
        AppStrings.eventTypeWorkshop,
      );
      expect(
        eventTypeLabel(EventTypeSpeaker.panel.value),
        AppStrings.eventTypePanel,
      );
    });

    test('ignores the case of the stored type', () {
      expect(eventTypeLabel('CONFERENCE'), AppStrings.eventTypeConference);
    });

    test('shows an unknown type with its first letter uppercase', () {
      expect(eventTypeLabel('coffee'), 'Coffee');
    });

    test('keeps an empty type empty', () {
      expect(eventTypeLabel(''), '');
    });
  });

  group('eventTypeIcon', () {
    test('uses a different icon for each known type', () {
      final icons = {
        eventTypeIcon(EventTypeSpeaker.conference.value),
        eventTypeIcon(EventTypeSpeaker.workshop.value),
        eventTypeIcon(EventTypeSpeaker.panel.value),
      };
      expect(icons.length, 3);
    });

    test('falls back to a generic icon for an unknown type', () {
      expect(eventTypeIcon('coffee'), Icons.event_note_rounded);
    });
  });

  group('technologyIcon', () {
    test('has an icon for each technology area of the app', () {
      for (final area in ['Mobile', 'IA', 'Cloud', 'Web', 'UI/UX']) {
        expect(technologyIcon(area), isNot(Icons.label_outline_rounded));
      }
    });

    test('falls back to a generic icon for an unknown area', () {
      expect(technologyIcon('Other'), Icons.label_outline_rounded);
    });
  });
}
