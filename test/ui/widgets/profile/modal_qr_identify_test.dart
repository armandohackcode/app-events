import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/profile/modal_qr_identify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets(
    'ModalQrIdentify renders pop-brutalist QR card and closes cleanly at 320x844',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 844),
            textScaler: TextScaler.linear(1.3),
          ),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          const ModalQrIdentify(identify: 'attendee-qr-01'),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ModalQrIdentify), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text(AppStrings.profileQrModalTitle), findsOneWidget);
      expect(find.text(AppStrings.organizersGDGSucre), findsOneWidget);
      expect(find.text(AppStrings.profileQrModalHint), findsOneWidget);
      expect(find.text(AppStrings.commonWordClose), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == AppAssetsPath.logoGdg,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == AppAssetsPath.titleEvent,
        ),
        findsNothing,
      );

      await tester.tap(find.text(AppStrings.commonWordClose));
      await tester.pumpAndSettle();

      expect(find.byType(ModalQrIdentify), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
