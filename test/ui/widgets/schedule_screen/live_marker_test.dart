import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/schedule_screen/live_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpMarker(WidgetTester tester, {required bool active}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: LiveMarker(active: active, child: const Text('card')),
            ),
          ),
        ),
      );

  testWidgets('shows the LIVE badge when active', (tester) async {
    await pumpMarker(tester, active: true);

    expect(find.text('card'), findsOneWidget);
    expect(find.text(AppStrings.homeLiveBadge), findsOneWidget);
  });

  testWidgets('shows only the child when not active', (tester) async {
    await pumpMarker(tester, active: false);

    expect(find.text('card'), findsOneWidget);
    expect(find.text(AppStrings.homeLiveBadge), findsNothing);
  });
}
