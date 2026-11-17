import 'package:app_events/ui/widgets/home/particle_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpField(
    WidgetTester tester, {
    VoidCallback? onPressed,
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: ParticleField(
            child: Center(
              child: ElevatedButton(
                onPressed: onPressed ?? () {},
                child: const Text('Child'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // Unmounting stops the field's ticker, which would otherwise stay pending.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('draws its child and keeps animating without errors', (
    tester,
  ) async {
    await pumpField(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Child'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('does not block taps on its child', (tester) async {
    var taps = 0;
    await pumpField(tester, onPressed: () => taps++);

    await tester.tap(find.text('Child'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(taps, 1);
    await unmount(tester);
  });

  testWidgets('draws still when animations are disabled', (tester) async {
    await pumpField(tester, disableAnimations: true);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Child'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
