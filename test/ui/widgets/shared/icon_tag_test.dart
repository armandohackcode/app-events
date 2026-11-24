import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/icon_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the icon and the text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IconTag(
            text: 'IA',
            icon: Icons.auto_awesome_rounded,
            color: AppStyles.colorBaseYellow,
          ),
        ),
      ),
    );

    expect(find.text('IA'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
  });

  testWidgets('a long text is cut instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(200, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: IconTag(
              text: 'Artificial intelligence ' * 10,
              icon: Icons.mic_none_rounded,
              color: AppStyles.colorBaseRed,
              foregroundColor: AppStyles.onAccentColor,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
