import 'package:app_events/ui/widgets/shared/title_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the given title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TitlePill(text: 'Section')),
      ),
    );

    expect(find.text('Section'), findsOneWidget);
  });
}
