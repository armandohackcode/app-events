import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/shared/live_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the LIVE text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: LiveBadge())),
      ),
    );

    expect(find.text(AppStrings.homeLiveBadge), findsOneWidget);
  });
}
