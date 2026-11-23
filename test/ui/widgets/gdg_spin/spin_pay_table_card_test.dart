import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/providers/gdg_spin_demo_data.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_pay_table_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'sold-out prizes render at 0.5 opacity with grayscale filter and sold-out tag',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpinPayTableCard(
                prizes: [
                  SpinPrize(
                    id: 'stickers',
                    name: 'Stickers',
                    symbol: SpinSymbol.cherries,
                    initialStock: 30,
                    remainingStock: 12,
                    rarity: PrizeRarity.common,
                  ),
                  SpinPrize(
                    id: 'android',
                    name: 'Android Figure',
                    symbol: SpinSymbol.seven,
                    initialStock: 1,
                    remainingStock: 0,
                    rarity: PrizeRarity.legendary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.spinRemaining(12, 30)), findsOneWidget);
      expect(find.text(AppStrings.spinSoldOut), findsOneWidget);
      expect(find.text(AppStrings.spinSoldOut.toUpperCase()), findsOneWidget);

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();
      expect(opacities, [0.5]);

      expect(find.byType(ColorFiltered), findsOneWidget);
    },
  );

  testWidgets('legendary row spells G D G instead of 7 7 7', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpinPayTableCard(
              prizes: [
                SpinPrize(
                  id: 'android',
                  name: 'Android Figure',
                  symbol: SpinSymbol.seven,
                  initialStock: 1,
                  remainingStock: 1,
                  rarity: PrizeRarity.legendary,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final letters = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((s) => s == 'G' || s == 'D')
        .toList();
    expect(letters, ['G', 'D', 'G']);
    expect(find.text('7'), findsNothing);
    expect(find.text(AppStrings.spinWildRowNote), findsOneWidget);
  });

  testWidgets('full demo pay table renders cleanly on narrow screen at 1.3x', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 844),
          textScaler: TextScaler.linear(1.3),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SpinPayTableCard(prizes: GdgSpinDemoData.createPrizes()),
            ),
          ),
        ),
      ),
    );

    for (final prize in GdgSpinDemoData.createPrizes()) {
      expect(find.text(prize.name), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
