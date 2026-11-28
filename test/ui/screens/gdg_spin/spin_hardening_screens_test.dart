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
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_screen.dart';
import 'package:app_events/ui/screens/gdg_spin/gdg_spin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockSpinRepository extends Mock implements SpinRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockSpinRepository spinRepo;
  late _MockUserRepository userRepo;
  late StreamController<SpinConfig?> configController;
  late StreamController<List<SpinPrize>> prizesController;
  late StreamController<List<SpinMission>> missionsController;
  late StreamController<SpinPlayer?> playerController;
  late StreamController<List<SpinWin>> winsController;
  late StreamController<List<SpinMissionClaim>> claimsController;
  late StreamController<List<SpinTicketCode>> codesController;

  setUp(() {
    spinRepo = _MockSpinRepository();
    userRepo = _MockUserRepository();
    configController = StreamController<SpinConfig?>.broadcast();
    prizesController = StreamController<List<SpinPrize>>.broadcast();
    missionsController = StreamController<List<SpinMission>>.broadcast();
    playerController = StreamController<SpinPlayer?>.broadcast();
    winsController = StreamController<List<SpinWin>>.broadcast();
    claimsController = StreamController<List<SpinMissionClaim>>.broadcast();
    codesController = StreamController<List<SpinTicketCode>>.broadcast();

    when(
      () => spinRepo.watchConfig(any()),
    ).thenAnswer((_) => configController.stream);
    when(
      () => spinRepo.watchPrizes(any(), activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) => prizesController.stream);
    when(
      () => spinRepo.watchMissions(any(), activeOnly: any(named: 'activeOnly')),
    ).thenAnswer((_) => missionsController.stream);
    when(
      () => spinRepo.watchPlayer(any(), any()),
    ).thenAnswer((_) => playerController.stream);
    when(
      () => spinRepo.watchMyWins(any(), any()),
    ).thenAnswer((_) => winsController.stream);
    when(
      () => spinRepo.watchAllWins(any(), status: any(named: 'status')),
    ).thenAnswer((_) => winsController.stream);
    when(
      () => spinRepo.watchMyMissionClaims(any(), any()),
    ).thenAnswer((_) => claimsController.stream);
    when(
      () => spinRepo.watchTicketCodes(any()),
    ).thenAnswer((_) => codesController.stream);
    when(() => spinRepo.initPlayer(any())).thenAnswer(
      (_) async => const SpinInitPlayerResult(
        player: SpinPlayer(uid: 'u1', tickets: 3, spinsCount: 0),
        initialGranted: true,
      ),
    );
    when(() => spinRepo.getDashboard('evt-1')).thenAnswer(
      (_) async => const SpinDashboardStats(
        config: SpinConfig(
          status: SpinGameStatus.paused,
          pauseMessage: 'Initial Pause',
          pacingMode: SpinPacingMode.manualWaves,
          packageTicketBonus: {'VIP': 3},
        ),
        stats: SpinStatsSummary(totalSpins: 10, totalWins: 2),
        prizes: [],
        winCounts: SpinWinCounts(),
      ),
    );
    when(() => userRepo.getAttendees()).thenAnswer(
      (_) async => [
        UserCompetitor(
          uuid: 'u1',
          name: 'Ada Lovelace',
          photoUrl: '',
          profession:
              'Principal Distributed Systems and Mobile Reliability Architect',
          aboutMe: '',
          tokenAuthorization: '',
          score: 10,
          socialNetwork: const [],
          friends: const [],
        ),
      ],
    );
  });

  tearDown(() async {
    await Future.wait([
      configController.close(),
      prizesController.close(),
      missionsController.close(),
      playerController.close(),
      winsController.close(),
      claimsController.close(),
      codesController.close(),
    ]);
  });

  group('GdgSpinScreen freeze protection and iOS/landscape responsiveness', () {
    testWidgets(
      'blocks accidental back navigation during requesting/spinning and settles on forced unmount',
      (tester) async {
        final provider = GdgSpinProvider(spinRepo, random: Random(3));
        addTearDown(provider.dispose);

        await provider.bind(eventId: 'evt-1', uid: 'u1');
        configController.add(const SpinConfig(status: SpinGameStatus.active));
        playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 3, spinsCount: 0),
        );

        final pullCompleter = Completer<SpinPullResult>();
        when(
          () => spinRepo.pull(
            eventId: 'evt-1',
            spinRequestId: any(named: 'spinRequestId'),
          ),
        ).thenAnswer((_) => pullCompleter.future);

        final navKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: ChangeNotifierProvider.value(
              value: provider,
              child: MaterialApp(
                navigatorKey: navKey,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const GdgSpinScreen(),
                        ),
                      ),
                      child: const Text(AppStrings.commonWordYes),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text(AppStrings.commonWordYes));
        await tester.pumpAndSettle();
        expect(find.byType(GdgSpinScreen), findsOneWidget);

        // Start pull -> SpinPhase.requesting blocks pop and shows feedback.
        unawaited(provider.pull());
        await tester.pump();
        expect(provider.phase, SpinPhase.requesting);

        await navKey.currentState!.maybePop();
        await tester.pump();
        expect(find.byType(GdgSpinScreen), findsOneWidget);
        expect(find.text(AppStrings.spinWaitSpinFinish), findsOneWidget);

        // Complete request -> SpinPhase.spinning still blocks pop, and watchdog settles after timeout.
        pullCompleter.complete(
          const SpinPullResult(
            spinRequestId: 'req-1',
            outcomeType: SpinOutcomeType.lose,
            combo: [SpinSymbol.lemon, SpinSymbol.bar, SpinSymbol.cherries],
            ticketsAfter: 2,
            spinsCountAfter: 1,
          ),
        );
        await tester.pump();
        expect(provider.phase, SpinPhase.spinning);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        // Force route replacement while still spinning settles cleanly via dispose/notifyViewSettled.
        navKey.currentState!.pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
        );
        await tester.pumpAndSettle();

        expect(provider.phase, SpinPhase.idle);
        expect(provider.tickets, 2);
        expect(provider.spins, 1);
      },
    );

    testWidgets(
      'renders cleanly in iOS landscape 844x390 with 1.5x text scaling',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(844, 390));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final provider = GdgSpinProvider(spinRepo, random: Random(5));
        addTearDown(provider.dispose);
        await provider.bind(eventId: 'evt-1', uid: 'u1');
        configController.add(const SpinConfig(status: SpinGameStatus.active));
        playerController.add(
          const SpinPlayer(uid: 'u1', tickets: 5, spinsCount: 2),
        );
        prizesController.add(const [
          SpinPrize(
            id: 'p1',
            name: 'Sparky Plush',
            symbol: SpinSymbol.star,
            initialStock: 10,
            remainingStock: 6,
            rarity: PrizeRarity.epic,
          ),
        ]);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(844, 390),
              textScaler: TextScaler.linear(1.5),
              disableAnimations: true,
            ),
            child: ChangeNotifierProvider.value(
              value: provider,
              child: const MaterialApp(home: GdgSpinScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  group('SpinAdminScreen concurrency, role unbind, and multi-device layout', () {
    testWidgets(
      'unbinds SpinAdminProvider when isAdmin flips from true to false',
      (tester) async {
        final adminProvider = SpinAdminProvider(spinRepo);
        final userProvider = UserProvider(userRepo)..isAdmin = true;
        addTearDown(() {
          adminProvider.dispose();
          userProvider.dispose();
        });

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: adminProvider),
                ChangeNotifierProvider.value(value: userProvider),
              ],
              child: const MaterialApp(
                home: SpinAdminScreen(
                  eventId: 'evt-1',
                  eventTitle: 'DevFest 2026',
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        configController.add(const SpinConfig(status: SpinGameStatus.paused));
        await tester.pumpAndSettle();
        expect(adminProvider.isBound, isTrue);

        userProvider.isAdmin = false;
        await tester.pump();
        await tester.pump();

        expect(adminProvider.isBound, isFalse);
        expect(find.text(AppStrings.spinAdminAccessDenied), findsOneWidget);
      },
    );

    testWidgets(
      'protects dirty Control and Tickets forms from remote overwrites and allows manual reload',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final adminProvider = SpinAdminProvider(spinRepo);
        final userProvider = UserProvider(userRepo)..isAdmin = true;
        addTearDown(() {
          adminProvider.dispose();
          userProvider.dispose();
        });

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: adminProvider),
                ChangeNotifierProvider.value(value: userProvider),
              ],
              child: const MaterialApp(
                home: SpinAdminScreen(
                  eventId: 'evt-1',
                  eventTitle: 'DevFest 2026',
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        configController.add(
          const SpinConfig(
            status: SpinGameStatus.paused,
            pauseMessage: 'Initial Pause',
            packageTicketBonus: {'VIP': 3},
          ),
        );
        await tester.pumpAndSettle();

        // Edit Control tab form -> becomes dirty.
        final pauseField = find.byType(TextField).first;
        await tester.enterText(pauseField, 'Local Draft Message');
        await tester.pump();

        // Remote config arrives -> draft is preserved and banner appears.
        configController.add(
          const SpinConfig(
            status: SpinGameStatus.active,
            pauseMessage: 'Remote Pause Message',
            packageTicketBonus: {'VIP': 5},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Local Draft Message'), findsOneWidget);
        expect(
          find.text(AppStrings.spinAdminRemoteConfigUpdated),
          findsOneWidget,
        );

        await tester.tap(find.text(AppStrings.spinAdminReloadConfig));
        await tester.pumpAndSettle();

        expect(find.text('Remote Pause Message'), findsOneWidget);
        expect(
          find.text(AppStrings.spinAdminRemoteConfigUpdated),
          findsNothing,
        );

        // Switch to Tickets tab and repeat dirty protection on package bonus.
        final ticketsTab = find.text(AppStrings.spinAdminTabTickets);
        await tester.ensureVisible(ticketsTab);
        await tester.tap(ticketsTab);
        await tester.pumpAndSettle();

        final pkgField = find.widgetWithText(
          TextField,
          AppStrings.spinAdminPackageNameHint,
        );
        await tester.enterText(pkgField.first, 'VIP_LOCAL');
        await tester.pump();

        configController.add(
          const SpinConfig(
            status: SpinGameStatus.active,
            pauseMessage: 'Remote Pause Message',
            packageTicketBonus: {'SUPER_VIP': 8},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('VIP_LOCAL'), findsOneWidget);
        expect(
          find.text(AppStrings.spinAdminRemoteConfigUpdated),
          findsOneWidget,
        );

        await tester.tap(find.text(AppStrings.spinAdminReloadConfig));
        await tester.pumpAndSettle();

        expect(find.text('SUPER_VIP'), findsOneWidget);
        expect(
          find.text(AppStrings.spinAdminRemoteConfigUpdated),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders all SpinAdmin tabs without overflow on 320px portrait and 1.5x text scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final adminProvider = SpinAdminProvider(spinRepo);
        final userProvider = UserProvider(userRepo)..isAdmin = true;
        addTearDown(() {
          adminProvider.dispose();
          userProvider.dispose();
        });

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.5),
              disableAnimations: true,
            ),
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: adminProvider),
                ChangeNotifierProvider.value(value: userProvider),
              ],
              child: const MaterialApp(
                home: SpinAdminScreen(
                  eventId: 'evt-1',
                  eventTitle: 'DevFest 2026 Ultra Long Event Title',
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        configController.add(
          const SpinConfig(
            status: SpinGameStatus.paused,
            packageTicketBonus: {'VIP': 3},
          ),
        );
        winsController.add(const [
          SpinWin(
            id: 'w1',
            eventId: 'evt-1',
            uid: 'u1',
            winnerName: 'Ada Lovelace',
            prizeId: 'p1',
            prizeName: 'Sparky Plush',
            prizeSymbol: SpinSymbol.star,
            code: 'GDG-7K9P2M',
            status: SpinWinStatus.redeemed,
          ),
        ]);
        await tester.pumpAndSettle();

        // Check Tickets tab with long profession autocomplete.
        final ticketsTab = find.text(AppStrings.spinAdminTabTickets);
        await tester.ensureVisible(ticketsTab);
        await tester.tap(ticketsTab);
        await tester.pumpAndSettle();

        // Check Redeem tab with already redeemed banner.
        final redeemTab = find.text(AppStrings.spinAdminTabRedeem);
        await tester.ensureVisible(redeemTab);
        await tester.tap(redeemTab);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ada Lovelace · GDG-7K9P2M'));
        await tester.pumpAndSettle();
        expect(
          find.text(AppStrings.spinAdminAlreadyRedeemedBanner),
          findsOneWidget,
        );
      },
    );
  });
}
