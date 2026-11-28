import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_pay_table_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const samplePrizes = [
    SpinPrize(
      id: 'stickers',
      name: 'GDG Stickers',
      symbol: SpinSymbol.cherries,
      initialStock: 30,
      remainingStock: 12,
      rarity: PrizeRarity.common,
    ),
    SpinPrize(
      id: 'mug',
      name: 'GDG Mug',
      symbol: SpinSymbol.bell,
      imageUrl: 'https://example.com/mug.png',
      initialStock: 5,
      remainingStock: 4,
      rarity: PrizeRarity.rare,
    ),
    SpinPrize(
      id: 'sparky',
      name: 'Sparky Plush',
      symbol: SpinSymbol.star,
      initialStock: 2,
      remainingStock: 1,
      rarity: PrizeRarity.epic,
    ),
    SpinPrize(
      id: 'android',
      name: 'Android Figure',
      symbol: SpinSymbol.seven,
      initialStock: 1,
      remainingStock: 1,
      rarity: PrizeRarity.legendary,
    ),
  ];

  testWidgets('shows empty state when no active prizes exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: SpinPayTableCard(prizes: [])),
        ),
      ),
    );

    expect(find.text(AppStrings.spinPayTableEmpty), findsOneWidget);
  });

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

  testWidgets(
    'renders optional prize imageUrl thumbnail alongside 3-symbol combo',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpinPayTableCard(prizes: samplePrizes),
            ),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.text('GDG Mug'), findsOneWidget);
    },
  );

  testWidgets('pay table renders cleanly on narrow screen at 1.3x', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(320, 844),
          textScaler: TextScaler.linear(1.3),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: SpinPayTableCard(prizes: samplePrizes),
            ),
          ),
        ),
      ),
    );

    for (final prize in samplePrizes) {
      expect(find.text(prize.name), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
