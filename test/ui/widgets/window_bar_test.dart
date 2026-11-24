import 'package:app_events/ui/widgets/shared/window_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the title and the trailing widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WindowBar(title: 'LIBRARY.APP', trailing: Text('trailing')),
        ),
      ),
    );

    expect(find.text('LIBRARY.APP'), findsOneWidget);
    expect(find.text('trailing'), findsOneWidget);
  });

  testWidgets('works without a trailing widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WindowBar(title: 'LIBRARY.APP')),
      ),
    );

    expect(find.text('LIBRARY.APP'), findsOneWidget);
  });

  testWidgets('a long title is cut instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WindowBar(title: 'LONG ' * 40)),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
