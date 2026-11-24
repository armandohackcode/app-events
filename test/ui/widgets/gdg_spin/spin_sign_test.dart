import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_bulb_ring.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_sign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {bool disableAnimations = true}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('full SpinSign renders all GDG SPIN tiles and semantics label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const SpinSign(bulbMode: SpinBulbMode.spinning)),
    );

    expect(find.text('G'), findsNWidgets(2));
    expect(find.text('D'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.bySemanticsLabel(AppStrings.spinTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SpinSign animates smoothly across modes and disposes cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SpinSign(), disableAnimations: false));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpWidget(
      wrap(
        const SpinSign(bulbMode: SpinBulbMode.win),
        disableAnimations: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact SpinSign scales down cleanly inside narrow spaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const SizedBox(width: 140, child: SpinSign(compact: true))),
    );

    expect(find.text('G'), findsNWidgets(2));
    expect(find.text('D'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
