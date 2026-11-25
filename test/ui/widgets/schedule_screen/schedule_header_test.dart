import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, int count) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ScheduleHeader(count: count)),
    ),
  );

  testWidgets('shows the title and the plural count', (tester) async {
    await pumpHeader(tester, 5);

    expect(find.text(AppStrings.scheduleSchedule), findsOneWidget);
    expect(find.text('5 ${AppStrings.scheduleActivityPlural}'), findsOneWidget);
  });

  testWidgets('uses the singular for one activity', (tester) async {
    await pumpHeader(tester, 1);

    expect(
      find.text('1 ${AppStrings.scheduleActivitySingular}'),
      findsOneWidget,
    );
  });

  testWidgets('shows zero activities with the plural', (tester) async {
    await pumpHeader(tester, 0);

    expect(find.text('0 ${AppStrings.scheduleActivityPlural}'), findsOneWidget);
  });
}
