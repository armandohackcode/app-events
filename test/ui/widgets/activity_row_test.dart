import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/home/activity_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRow(
    WidgetTester tester, {
    String? subtitle,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ActivityRow(
          icon: const Icon(Icons.star),
          iconBackground: AppStyles.colorCardBlue,
          title: 'Schedule',
          subtitle: subtitle,
          onTap: onTap ?? () {},
        ),
      ),
    ),
  );

  testWidgets('shows the title and the subtitle', (tester) async {
    await pumpRow(tester, subtitle: 'Full agenda');

    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Full agenda'), findsOneWidget);
  });

  testWidgets('works without a subtitle', (tester) async {
    await pumpRow(tester);

    expect(find.text('Schedule'), findsOneWidget);
  });

  testWidgets('tapping the row calls onTap', (tester) async {
    var taps = 0;
    await pumpRow(tester, onTap: () => taps++);

    await tester.tap(find.text('Schedule'));

    expect(taps, 1);
  });
}
