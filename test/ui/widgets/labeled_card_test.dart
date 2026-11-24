import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/labeled_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    String label = 'About',
    String body = 'Card body',
    bool speechTail = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: LabeledCard(
            label: label,
            labelColor: AppStyles.colorBaseYellow,
            labelTextColor: AppStyles.fontColor,
            color: AppStyles.cardColor,
            speechTail: speechTail,
            child: Text(body),
          ),
        ),
      ),
    ),
  );

  testWidgets('shows the label and the content', (tester) async {
    await pumpCard(tester);

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Card body'), findsOneWidget);
  });

  testWidgets('draws the speech tail only when asked', (tester) async {
    int tails() => find
        .byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_TailPainter',
        )
        .evaluate()
        .length;

    await pumpCard(tester);
    expect(tails(), 0);

    await pumpCard(tester, speechTail: true);
    expect(tails(), 1);
  });

  testWidgets('long label and content do not overflow at 320 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpCard(
      tester,
      label: 'A very long label ' * 10,
      body: 'Long content ' * 200,
      speechTail: true,
    );

    expect(tester.takeException(), isNull);
  });
}
