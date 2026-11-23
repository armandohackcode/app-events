import 'dart:math';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/gdg_spin_screen.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_celebration.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_lever.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_my_prizes_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_tickets_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late GdgSpinProvider provider;

  setUp(() {
    provider = GdgSpinProvider(random: Random(12));
  });

  tearDown(() {
    provider.dispose();
  });

  Widget buildScreen({double width = 390}) => MediaQuery(
    data: MediaQueryData(size: Size(width, 844), disableAnimations: true),
    child: ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: GdgSpinScreen()),
    ),
  );

  testWidgets('tickets pill displays current ticket count', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(
      find.descendant(
        of: find.byType(SpinTicketsPill),
        matching: find.text(AppStrings.spinTicketCount(3)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping lever with zero tickets shows no-tickets message', (
    tester,
  ) async {
    provider.tickets = 0;
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.byType(SpinLever));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.spinNoTickets), findsOneWidget);
    expect(provider.spins, 0);
  });

  testWidgets('dragging lever 80 px triggers a spin', (tester) async {
    await tester.pumpWidget(buildScreen());

    await tester.drag(find.byType(SpinLever), const Offset(0, 80));
    await tester.pumpAndSettle();

    expect(provider.spins, 1);
  });

  testWidgets('tapping tickets pill opens balance popup and auto-closes', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.byType(SpinTicketsPill));
    await tester.pump();

    expect(find.text(AppStrings.spinTicketHeader), findsOneWidget);
    expect(find.text(AppStrings.spinTicketHave(3)), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.spinTicketHeader), findsNothing);
  });

  testWidgets('completing a mission awards a ticket and shows won popup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildScreen());

    final askButton = find.text(AppStrings.askLabel);
    await tester.ensureVisible(askButton);
    await tester.pumpAndSettle();
    await tester.tap(askButton);
    await tester.pump();

    expect(provider.tickets, 4);
    expect(find.text(AppStrings.spinTicketWon), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2900));
    await tester.pumpAndSettle();
  });

  testWidgets('demo reload adds 5 tickets when balance is zero', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    provider.tickets = 0;
    await tester.pumpWidget(buildScreen());

    final demoBtn = find.text(AppStrings.spinDemoReload);
    expect(demoBtn, findsOneWidget);
    await tester.ensureVisible(demoBtn);
    await tester.pumpAndSettle();

    await tester.tap(demoBtn);
    await tester.pumpAndSettle();

    expect(provider.tickets, 5);
    expect(find.text(AppStrings.spinDemoReloaded), findsOneWidget);
  });

  testWidgets('animations run and dispose cleanly when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: GdgSpinScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    await tester.drag(find.byType(SpinLever), const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 3));

    expect(provider.spins, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly across phone and tablet widths at 1.3x scale', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [320.0, 360.0, 390.0, 430.0, 768.0]) {
      await tester.binding.setSurfaceSize(Size(width, 844));
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 844),
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.3),
          ),
          child: ChangeNotifierProvider.value(
            value: provider,
            child: const MaterialApp(home: GdgSpinScreen()),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'winning GDG jackpot shows GDG emblem in celebration and My Prizes',
    (tester) async {
      final legendary = const SpinPrize(
        id: 'android',
        name: AppStrings.spinPrizeAndroid,
        symbol: SpinSymbol.seven,
        initialStock: 1,
        remainingStock: 1,
        rarity: PrizeRarity.legendary,
      );
      provider.lastOutcome = SpinPrizeOutcome(legendary);
      provider.phase = SpinPhase.win;
      provider.message = SpinMessage.win;
      provider.myPrizes.add(
        const WonPrize(
          prizeId: 'android',
          name: AppStrings.spinPrizeAndroid,
          symbol: SpinSymbol.seven,
          code: 'GDG-ABCD',
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(SpinCelebration),
          matching: find.text(AppStrings.spinWinTitle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SpinCelebration),
          matching: find.text('G'),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: find.byType(SpinCelebration),
          matching: find.text('D'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SpinMyPrizesCard),
          matching: find.text('GDG-ABCD'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SpinMyPrizesCard),
          matching: find.text('D'),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    },
  );
}
