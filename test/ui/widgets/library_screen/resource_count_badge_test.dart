import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/library_screen/resource_count_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the number of resources and its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ResourceCountBadge(count: 12))),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text(AppStrings.resourceLibraryCountLabel), findsOneWidget);
  });

  testWidgets('shows zero when there are no resources', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ResourceCountBadge(count: 0))),
    );

    expect(find.text('0'), findsOneWidget);
  });
}
