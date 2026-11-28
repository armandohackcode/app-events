import 'dart:async';
import 'dart:math';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_screen.dart';
import 'package:app_events/ui/screens/gdg_spin/gdg_spin_screen.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_celebration.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_coin_tray.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_lever.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_my_prizes_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_redeem_qr_dialog.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_tickets_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockSpinRepository extends Mock implements SpinRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _ScreenSpinHarness {
  final _MockSpinRepository repo = _MockSpinRepository();
  final _MockUserRepository userRepo = _MockUserRepository();
  final configController = StreamController<SpinConfig?>.broadcast();
  final prizesController = StreamController<List<SpinPrize>>.broadcast();
  final missionsController = StreamController<List<SpinMission>>.broadcast();
  final playerController = StreamController<SpinPlayer?>.broadcast();
  final winsController = StreamController<List<SpinWin>>.broadcast();
  final claimsController = StreamController<List<SpinMissionClaim>>.broadcast();

  _ScreenSpinHarness() {
    when(
      () => repo.watchConfig(any()),
    ).thenAnswer((_) => configController.stream);
    when(
      () => repo.watchPrizes(any(), activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) => prizesController.stream);
    when(
      () => repo.watchMissions(any(), activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) => missionsController.stream);
    when(
      () => repo.watchPlayer(any(), any()),
    ).thenAnswer((_) => playerController.stream);
    when(
      () => repo.watchMyWins(any(), any()),
    ).thenAnswer((_) => winsController.stream);
    when(
      () => repo.watchMyMissionClaims(any(), any()),
    ).thenAnswer((_) => claimsController.stream);
    when(() => repo.initPlayer(any())).thenAnswer(
      (_) async => const SpinInitPlayerResult(
        player: SpinPlayer(uid: 'u1', tickets: 3, spinsCount: 0),
        initialGranted: true,
      ),
    );
  }

  Future<void> dispose() async {
    await Future.wait([
      configController.close(),
      prizesController.close(),
      missionsController.close(),
      playerController.close(),
      winsController.close(),
      claimsController.close(),
    ]);
  }
}

void main() {
  late _ScreenSpinHarness harness;
  late GdgSpinProvider provider;

  setUp(() {
    harness = _ScreenSpinHarness();
    provider = GdgSpinProvider(harness.repo, random: Random(12));
  });

  tearDown(() async {
    provider.dispose();
    await harness.dispose();
  });

  Widget buildScreen({double width = 390}) => MediaQuery(
    data: MediaQueryData(size: Size(width, 844), disableAnimations: true),
    child: ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: GdgSpinScreen()),
    ),
  );

  Future<void> bindActivePlayer(
    WidgetTester tester, {
    int tickets = 3,
    SpinGameStatus status = SpinGameStatus.active,
    String pauseMessage = '',
    int maxPrizesPerUser = 3,
    int totalPrizesWon = 0,
  }) async {
    await provider.bind(eventId: 'evt-1', uid: 'u1');
    harness.configController.add(
      SpinConfig(
        status: status,
        pauseMessage: pauseMessage,
        maxPrizesPerUser: maxPrizesPerUser,
      ),
    );
    harness.playerController.add(
      SpinPlayer(
        uid: 'u1',
        tickets: tickets,
        spinsCount: 0,
        totalPrizesWon: totalPrizesWon,
      ),
    );
    harness.prizesController.add(const [
      SpinPrize(
        id: 'stickers',
        name: 'GDG Stickers',
        symbol: SpinSymbol.cherries,
        initialStock: 10,
        remainingStock: 8,
        rarity: PrizeRarity.common,
      ),
    ]);
    await tester.pump();
  }

  testWidgets('shows no-active-event banner when unbound', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text(AppStrings.spinBannerNoEventTitle), findsOneWidget);
    expect(find.text(AppStrings.spinBannerNoEventBody), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SpinCoinTray),
        matching: find.text(AppStrings.spinFooterBrand),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows paused, closed, and prize-cap banners accurately', (
    tester,
  ) async {
    await bindActivePlayer(
      tester,
      status: SpinGameStatus.paused,
      pauseMessage: 'Break time — opening soon!',
    );
    await tester.pumpWidget(buildScreen());

    expect(find.text(AppStrings.spinBannerPausedTitle), findsOneWidget);
    expect(find.text('Break time — opening soon!'), findsWidgets);

    harness.configController.add(
      const SpinConfig(status: SpinGameStatus.closed),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(AppStrings.spinBannerClosedTitle), findsOneWidget);

    harness.configController.add(
      const SpinConfig(status: SpinGameStatus.active, maxPrizesPerUser: 1),
    );
    harness.playerController.add(
      const SpinPlayer(uid: 'u1', tickets: 3, totalPrizesWon: 1),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(AppStrings.spinBannerPrizeCapTitle), findsOneWidget);
  });

  testWidgets(
    'shows the sold-out banner and blocks the lever once every prize is gone',
    (tester) async {
      await bindActivePlayer(tester, tickets: 3);
      await tester.pumpWidget(buildScreen());
      expect(find.text(AppStrings.spinBannerSoldOutTitle), findsNothing);
      expect(provider.canPull, isTrue);

      harness.prizesController.add(const [
        SpinPrize(
          id: 'stickers',
          name: 'GDG Stickers',
          symbol: SpinSymbol.cherries,
          initialStock: 10,
          remainingStock: 0,
          rarity: PrizeRarity.common,
        ),
      ]);
      await tester.pump();
      await tester.pump();

      expect(find.text(AppStrings.spinBannerSoldOutTitle), findsOneWidget);
      expect(find.text(AppStrings.spinBannerSoldOutBody), findsOneWidget);
      expect(provider.canPull, isFalse);
    },
  );

  testWidgets(
    'tickets pill displays bound ticket count and opens balance popup',
    (tester) async {
      await bindActivePlayer(tester, tickets: 4);
      await tester.pumpWidget(buildScreen());

      expect(
        find.descendant(
          of: find.byType(SpinTicketsPill),
          matching: find.text(AppStrings.spinTicketCount(4)),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(SpinTicketsPill));
      await tester.pump();

      expect(find.text(AppStrings.spinTicketHeader), findsOneWidget);
      expect(find.text(AppStrings.spinTicketHave(4)), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2700));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.spinTicketHeader), findsNothing);
    },
  );

  testWidgets('tapping lever with zero tickets shows no-tickets message', (
    tester,
  ) async {
    await bindActivePlayer(tester, tickets: 0);
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.byType(SpinLever));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.spinNoTickets), findsOneWidget);
    expect(provider.spins, 0);
  });

  testWidgets('dragging lever calls repository.pull and increments spins', (
    tester,
  ) async {
    await bindActivePlayer(tester, tickets: 3);
    when(
      () => harness.repo.pull(
        eventId: 'evt-1',
        spinRequestId: any(named: 'spinRequestId'),
      ),
    ).thenAnswer(
      (_) async => const SpinPullResult(
        spinRequestId: 'req-1',
        outcomeType: SpinOutcomeType.lose,
        combo: [SpinSymbol.lemon, SpinSymbol.cherries, SpinSymbol.bar],
        ticketsAfter: 2,
        spinsCountAfter: 1,
      ),
    );

    await tester.pumpWidget(buildScreen());

    await tester.drag(find.byType(SpinLever), const Offset(0, 80));
    await tester.pumpAndSettle();

    verify(
      () => harness.repo.pull(
        eventId: 'evt-1',
        spinRequestId: any(named: 'spinRequestId'),
      ),
    ).called(1);
    expect(provider.spins, 1);
    expect(provider.tickets, 2);
  });

  testWidgets('tapping a won prize opens SpinRedeemQrDialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await bindActivePlayer(tester, tickets: 2);
    harness.winsController.add(const [
      SpinWin(
        id: 'w1',
        eventId: 'evt-1',
        uid: 'u1',
        prizeId: 'android',
        prizeName: 'Android Figure',
        prizeSymbol: SpinSymbol.seven,
        prizeRarity: PrizeRarity.legendary,
        code: 'GDG-ABCD23',
        status: SpinWinStatus.pending,
      ),
    ]);
    await tester.pump();

    await tester.pumpWidget(buildScreen());

    final row = find.descendant(
      of: find.byType(SpinMyPrizesCard),
      matching: find.text('GDG-ABCD23'),
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(SpinRedeemQrDialog), findsOneWidget);
    expect(find.text(AppStrings.spinRedeemQrTitle), findsOneWidget);
  });

  testWidgets('stand code dialog redeems code and shows won ticket popup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await bindActivePlayer(tester, tickets: 1);
    when(
      () => harness.repo.redeemTicketCode(eventId: 'evt-1', code: 'CLOUD26'),
    ).thenAnswer(
      (_) async => const SpinRedeemTicketCodeResult(
        label: 'Cloud Stand',
        ticketsAwarded: 2,
        ticketsAfter: 3,
        ticketSerial: 'CLD26001',
      ),
    );

    await tester.pumpWidget(buildScreen());

    final standBtn = find.text(AppStrings.spinHaveStandCode);
    await tester.ensureVisible(standBtn);
    await tester.pumpAndSettle();
    await tester.tap(standBtn);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.spinStandCodeTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'CLOUD26');
    await tester.tap(find.text(AppStrings.spinStandCodeSubmit));
    await tester.pump();
    await tester.pump();

    expect(provider.tickets, 3);
    expect(find.text(AppStrings.spinTicketWon), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2900));
    await tester.pumpAndSettle();
  });

  testWidgets('winning GDG jackpot shows celebration and My Prizes', (
    tester,
  ) async {
    await bindActivePlayer(tester, tickets: 2);
    when(
      () => harness.repo.pull(
        eventId: 'evt-1',
        spinRequestId: any(named: 'spinRequestId'),
      ),
    ).thenAnswer(
      (_) async => const SpinPullResult(
        spinRequestId: 'req-jackpot',
        outcomeType: SpinOutcomeType.prize,
        combo: [SpinSymbol.seven, SpinSymbol.seven, SpinSymbol.seven],
        wonPrize: SpinPullWonPrize(
          winId: 'w-jackpot',
          prizeId: 'android',
          name: 'Android Figure',
          symbol: SpinSymbol.seven,
          rarity: PrizeRarity.legendary,
          code: 'GDG-777AAA',
        ),
        ticketsAfter: 1,
        spinsCountAfter: 1,
      ),
    );

    await tester.pumpWidget(buildScreen());
    await provider.pull();
    provider.reelsStopped();
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
        of: find.byType(SpinMyPrizesCard),
        matching: find.text('GDG-777AAA'),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly across phone and tablet widths at 1.3x scale', (
    tester,
  ) async {
    await bindActivePlayer(tester, tickets: 2);
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
    'admin icon is hidden for normal users and navigates to SpinAdminScreen when isAdmin is true',
    (tester) async {
      final userProvider = UserProvider(harness.userRepo);
      final adminProvider = SpinAdminProvider(harness.repo);
      addTearDown(userProvider.dispose);
      addTearDown(adminProvider.dispose);

      when(
        () => harness.repo.watchAllWins(any(), status: any(named: 'status')),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => harness.repo.watchTicketCodes(any()),
      ).thenAnswer((_) => const Stream<List<SpinTicketCode>>.empty());
      when(() => harness.repo.getDashboard('evt-1')).thenAnswer(
        (_) async => const SpinDashboardStats(
          config: SpinConfig(),
          stats: SpinStatsSummary(),
          prizes: [],
          winCounts: SpinWinCounts(),
        ),
      );
      when(() => harness.userRepo.getAttendees()).thenAnswer((_) async => []);

      await bindActivePlayer(tester, tickets: 2);

      // Normal user: admin icon must be hidden.
      userProvider.isAdmin = false;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: provider),
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: adminProvider),
            ],
            child: const MaterialApp(home: GdgSpinScreen()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.admin_panel_settings_outlined), findsNothing);

      // Admin user: icon appears and opens SpinAdminScreen.
      userProvider.isAdmin = true;
      await tester.pump();

      final adminIcon = find.byIcon(Icons.admin_panel_settings_outlined);
      expect(adminIcon, findsOneWidget);

      await tester.tap(adminIcon);
      await tester.pumpAndSettle();

      expect(find.byType(SpinAdminScreen), findsOneWidget);
      expect(find.text(AppStrings.spinAdminTitle), findsOneWidget);
    },
  );
}
