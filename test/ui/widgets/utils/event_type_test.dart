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

    test('labels breaks, lunch and networking', () {
      expect(eventTypeLabel('break'), AppStrings.eventTypeBreak);
      expect(eventTypeLabel('lunch'), AppStrings.eventTypeLunch);
      expect(eventTypeLabel('networking'), AppStrings.eventTypeNetworking);
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
        eventTypeIcon(EventTypeSpeaker.breakTime.value),
        eventTypeIcon(EventTypeSpeaker.lunch.value),
        eventTypeIcon(EventTypeSpeaker.networking.value),
      };
      expect(icons.length, 6);
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

  group('eventTypeColor', () {
    test('uses a different tag color for conference, workshop and panel', () {
      final colors = {
        eventTypeColor('conference'),
        eventTypeColor('workshop'),
        eventTypeColor('panel'),
      };
      expect(colors.length, 3);
    });

    test('text over a dark tag is light and over a light tag is dark', () {
      expect(
        eventTypeForegroundColor('workshop'),
        isNot(eventTypeForegroundColor('conference')),
      );
    });
  });
}
