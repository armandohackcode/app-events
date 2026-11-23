import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/activities/activity_ranking_card.dart';
import 'package:app_events/ui/widgets/activities/activity_spin_card.dart';
import 'package:app_events/ui/widgets/activities/activity_treasure_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('ActivityRankingCard triggers onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(ActivityRankingCard(onTap: () => taps++)));

    await tester.tap(find.text(AppStrings.homeTournamentGDG));

    expect(taps, 1);
  });

  testWidgets(
    'ActivitySpinCard shows tickets, G D G mini reels, and triggers onTap',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(ActivitySpinCard(tickets: 4, onTap: () => taps++)),
      );

      expect(find.text(AppStrings.spinTicketCount(4)), findsOneWidget);
      final miniLetters = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(SpinMiniMachine),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .where((s) => s == 'G' || s == 'D')
          .toList();
      // 3 letters in compact SpinSign (G, D, G) + 3 letters in mini reels (G, D, G).
      expect(miniLetters, ['G', 'D', 'G', 'G', 'D', 'G']);

      await tester.tap(find.text(AppStrings.playLabel));
      await tester.pumpAndSettle();

      expect(taps, 1);
    },
  );

  testWidgets(
    'ActivityTreasureCard shows segmented progress and triggers onTap',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(ActivityTreasureCard(found: 3, total: 10, onTap: () => taps++)),
      );

      expect(
        find.text(AppStrings.activitiesTreasureProgress(3, 10)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ActivityTreasureCard),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxHeight == 12 &&
                w.decoration is BoxDecoration,
          ),
        ),
        findsNWidgets(10),
      );

      await tester.tap(find.text(AppStrings.activitiesTreasureAction));
      await tester.pumpAndSettle();

      expect(taps, 1);
    },
  );

  testWidgets('ActivityTreasureCard hides progress when total is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(ActivityTreasureCard(found: 3, total: null, onTap: () {})),
    );

    expect(
      find.text(AppStrings.activitiesTreasureProgress(3, 10)),
      findsNothing,
    );
  });
}
