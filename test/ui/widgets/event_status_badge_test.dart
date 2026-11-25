import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/ui/widgets/shared/event_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final labels = {
    EventStatus.upcoming: AppStrings.eventStatusUpcoming,
    EventStatus.active: AppStrings.eventStatusActive,
    EventStatus.finished: AppStrings.eventStatusFinished,
  };

  for (final MapEntry(key: status, value: label) in labels.entries) {
    testWidgets('shows the label for ${status.name}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: EventStatusBadge(status: status)),
      );

      expect(find.text(label), findsOneWidget);
    });
  }
}
