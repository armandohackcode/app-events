import 'package:app_events/ui/widgets/schedule_screen/calendar_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('shows the month and the day number', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CalendarBadge(date: DateTime(2026, 10, 24))),
      ),
    );

    expect(find.text('OCT'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
  });
}
