import 'package:app_events/ui/widgets/shared/time_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the clock icon and the time range', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TimePill(text: '09:45 - 10:45')),
      ),
    );

    expect(find.text('09:45 - 10:45'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });

  testWidgets('a long text is cut instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(200, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 120, child: TimePill(text: '09:45 ' * 30)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
