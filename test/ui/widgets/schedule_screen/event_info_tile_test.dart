import 'package:app_events/ui/widgets/schedule_screen/event_info_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpTile(WidgetTester tester, {VoidCallback? onTap}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventInfoTile(
              leading: const Icon(Icons.place),
              title: 'Campus',
              subtitle: 'How to get there',
              onTap: onTap,
            ),
          ),
        ),
      );

  testWidgets('shows leading, title and subtitle without a chevron', (
    tester,
  ) async {
    await pumpTile(tester);

    expect(find.byIcon(Icons.place), findsOneWidget);
    expect(find.text('Campus'), findsOneWidget);
    expect(find.text('How to get there'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('with onTap it shows a chevron and reports the tap', (
    tester,
  ) async {
    var taps = 0;
    await pumpTile(tester, onTap: () => taps++);

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.text('Campus'));

    expect(taps, 1);
  });

  testWidgets('long texts do not overflow at 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventInfoTile(
            leading: const Icon(Icons.place),
            title: 'Very long place name ' * 20,
            subtitle: 'Very long subtitle ' * 20,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
