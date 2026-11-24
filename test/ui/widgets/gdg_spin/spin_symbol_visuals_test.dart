import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets(
    'SpinSymbol.seven renders G, D, G per slot index and GDG when null',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinSymbolArt(symbol: SpinSymbol.seven, size: 48, slotIndex: 0),
              SpinSymbolArt(symbol: SpinSymbol.seven, size: 48, slotIndex: 1),
              SpinSymbolArt(symbol: SpinSymbol.seven, size: 48, slotIndex: 2),
            ],
          ),
        ),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.map((t) => t.data), ['G', 'D', 'G']);
      for (final text in texts) {
        expect(text.style?.color, AppStyles.onAccentColor);
      }

      final tileColors = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(SpinSymbolArt),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration as BoxDecoration?)?.color)
          .whereType<Color>()
          .toList();
      expect(tileColors, [
        AppStyles.gdgBrandPalette[0],
        AppStyles.gdgBrandPalette[1],
        AppStyles.gdgBrandPalette[2],
      ]);

      await tester.pumpWidget(
        wrap(const SpinSymbolArt(symbol: SpinSymbol.seven, size: 78)),
      );
      final badgeTexts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(badgeTexts.map((t) => t.data), ['G', 'D', 'G']);
      for (final text in badgeTexts) {
        expect(text.style?.color, AppStyles.onAccentColor);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('SpinSymbol.seven clamps out-of-range slot indices safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinSymbolArt(symbol: SpinSymbol.seven, size: 17, slotIndex: -1),
            SpinSymbolArt(symbol: SpinSymbol.seven, size: 17, slotIndex: 99),
          ],
        ),
      ),
    );

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(texts.map((t) => t.data), ['G', 'G']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-seven symbols use existing app assets cleanly', (
    tester,
  ) async {
    const expectedImages = {
      SpinSymbol.bar: AppAssetsPath.androidPed,
      SpinSymbol.cherries: AppAssetsPath.dinoRunIcon,
      SpinSymbol.bell: AppAssetsPath.computerIcon,
      SpinSymbol.star: AppAssetsPath.firePedIcon,
      SpinSymbol.diamond: AppAssetsPath.dashPed,
      SpinSymbol.lemon: AppAssetsPath.treasureBuntImg2,
      SpinSymbol.mysteryBox: AppAssetsPath.trophyIcon,
      SpinSymbol.wild: AppAssetsPath.logoGdg,
    };

    for (final entry in expectedImages.entries) {
      await tester.pumpWidget(
        wrap(SpinSymbolArt(symbol: entry.key, size: 48, slotIndex: 0)),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, entry.value);
      expect(tester.takeException(), isNull);
    }

    expect(SpinSymbol.wild.assetPath, AppAssetsPath.logoGdg);
  });
}
