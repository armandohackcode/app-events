import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/shared/button_scan.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/utils/qr_scan_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  testWidgets(
    'ButtonScan renders pop-brutalist action and opens QRScanContent cleanly',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final userProvider = UserProvider(_MockUserRepository());
      addTearDown(userProvider.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 844),
            textScaler: TextScaler.linear(1.3),
          ),
          child: ChangeNotifierProvider.value(
            value: userProvider,
            child: const MaterialApp(
              home: Scaffold(floatingActionButton: ButtonScan()),
            ),
          ),
        ),
      );

      expect(find.byType(ButtonScan), findsOneWidget);
      expect(find.byType(HardShadowBox), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.byTooltip(AppStrings.scanActionTooltip), findsOneWidget);

      await tester.tap(find.byType(ButtonScan));
      await tester.pumpAndSettle();

      expect(find.byType(QRScanContent), findsOneWidget);
      expect(find.text(AppStrings.scanTitle), findsOneWidget);
      expect(find.text(AppStrings.scanMessage), findsOneWidget);
      expect(find.byTooltip(AppStrings.scanBackTooltip), findsOneWidget);
      expect(find.byTooltip(AppStrings.scanToggleFlashTooltip), findsOneWidget);
      expect(find.byTooltip(AppStrings.scanFlipCameraTooltip), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
