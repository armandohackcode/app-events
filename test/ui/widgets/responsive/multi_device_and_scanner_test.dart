import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_celebration.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_counters.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_lever.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_pay_table_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_ticket_popup.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_tickets_pill.dart';
import 'package:app_events/ui/widgets/utils/qr_scan_content.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('Responsive and accessibility hardening across device screen sizes', () {
    testWidgets('customSnackbar fits 320px width without RenderFlex overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => customSnackbar(
                  context,
                  'A very long error or confirmation message that would overflow a fixed percentage SizedBox on 320px.',
                ),
                child: const Text(AppStrings.commonWordYes),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    for (final entry in <String, ({Size size, double textScale})>{
      'small portrait 320x568': (size: const Size(320, 568), textScale: 1.0),
      'landscape 640x360': (size: const Size(640, 360), textScale: 1.0),
      'accessibility 2.0x text': (size: const Size(320, 568), textScale: 2.0),
    }.entries) {
      testWidgets('SpinTicketPopup renders cleanly in ${entry.key}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(entry.value.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: entry.value.size,
              textScaler: TextScaler.linear(entry.value.textScale),
              disableAnimations: true,
            ),
            child: const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SpinTicketPopup(tickets: 1234, serial: 'GDG-7K9P2M'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(AppStrings.spinTicketHeader), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'Spin widgets handle tight landscape, tiny height, and 2.0x text without overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 480));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const prize = SpinPrize(
          id: 'p1',
          name: 'Ultra Collectible GDG Cloud Summit Hoodie Edition',
          symbol: SpinSymbol.diamond,
          initialStock: 10,
          remainingStock: 4,
          rarity: PrizeRarity.legendary,
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 480),
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SpinTicketsPill(tickets: 9999),
                      const SpinCounters(
                        tickets: 999,
                        spins: 888,
                        message: SpinMessage.pullHint,
                        phase: SpinPhase.idle,
                      ),
                      SpinPayTableCard(prizes: const [prize]),
                      SpinLever(
                        height: 136,
                        canPull: true,
                        tickets: 3,
                        onPull: () {},
                        onBlockedPull: () {},
                      ),
                      SizedBox(
                        height: 220,
                        child: Stack(
                          children: [
                            SpinCelebration(
                              phase: SpinPhase.win,
                              outcome: const SpinPrizeOutcome(prize),
                              onFinished: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('QRScanContent permissions and lifecycle cleanup', () {
    testWidgets(
      'shows denied view with retry button and recovers to scanner on permission grant',
      (tester) async {
        var status = PermissionStatus.denied;
        await tester.pumpWidget(
          MaterialApp(
            home: QRScanContent(
              checkCameraPermission: () async => status,
              requestCameraPermission: () async => status,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(AppStrings.scanCameraPermissionDenied),
          findsOneWidget,
        );
        expect(find.text(AppStrings.scanCameraPermissionBody), findsOneWidget);
        expect(find.text(AppStrings.spinRetryAction), findsOneWidget);
        expect(find.byTooltip(AppStrings.scanToggleFlashTooltip), findsNothing);

        status = PermissionStatus.granted;
        await tester.tap(find.text(AppStrings.spinRetryAction));
        await tester.pumpAndSettle();

        expect(
          find.byTooltip(AppStrings.scanToggleFlashTooltip),
          findsOneWidget,
        );
        expect(
          find.byTooltip(AppStrings.scanFlipCameraTooltip),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows open-settings button when permanently denied and re-checks on app resume',
      (tester) async {
        var status = PermissionStatus.permanentlyDenied;
        var openedSettings = false;

        await tester.pumpWidget(
          MaterialApp(
            home: QRScanContent(
              checkCameraPermission: () async => status,
              requestCameraPermission: () async => status,
              openSettings: () async {
                openedSettings = true;
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.scanOpenSettings), findsOneWidget);
        await tester.tap(find.text(AppStrings.scanOpenSettings));
        await tester.pumpAndSettle();
        expect(openedSettings, isTrue);

        // User grants permission in OS settings and returns to the app.
        status = PermissionStatus.granted;
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        expect(
          find.byTooltip(AppStrings.scanToggleFlashTooltip),
          findsOneWidget,
        );

        // Pop cleanly via back button without errors across PopScope & dispose.
        await tester.tap(find.byTooltip(AppStrings.scanBackTooltip));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
