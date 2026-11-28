import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _MockSpinRepository extends Mock implements SpinRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _AdminScreenHarness {
  final _MockSpinRepository spinRepo = _MockSpinRepository();
  final _MockUserRepository userRepo = _MockUserRepository();

  final configController = StreamController<SpinConfig?>.broadcast();
  final prizesController = StreamController<List<SpinPrize>>.broadcast();
  final missionsController = StreamController<List<SpinMission>>.broadcast();
  final winsController = StreamController<List<SpinWin>>.broadcast();
  final codesController = StreamController<List<SpinTicketCode>>.broadcast();

  _AdminScreenHarness() {
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
      () => spinRepo.watchAllWins(any(), status: any(named: 'status')),
    ).thenAnswer((_) => winsController.stream);
    when(
      () => spinRepo.watchTicketCodes(any()),
    ).thenAnswer((_) => codesController.stream);
    when(() => userRepo.getAttendees()).thenAnswer(
      (_) async => [
        UserCompetitor(
          uuid: 'u1',
          name: 'Ada Lovelace',
          photoUrl: '',
          profession: 'Engineer',
          aboutMe: '',
          tokenAuthorization: '',
          score: 10,
          socialNetwork: const [],
          friends: const [],
        ),
      ],
    );
  }

  Future<void> dispose() async {
    await Future.wait([
      configController.close(),
      prizesController.close(),
      missionsController.close(),
      winsController.close(),
      codesController.close(),
    ]);
  }
}

void main() {
  late _AdminScreenHarness harness;
  late SpinAdminProvider adminProvider;
  late UserProvider userProvider;

  setUp(() {
    harness = _AdminScreenHarness();
    adminProvider = SpinAdminProvider(harness.spinRepo);
    userProvider = UserProvider(harness.userRepo);

    when(() => harness.spinRepo.getDashboard('evt-1')).thenAnswer(
      (_) async => const SpinDashboardStats(
        config: SpinConfig(
          status: SpinGameStatus.paused,
          pacingMode: SpinPacingMode.manualWaves,
          packageTicketBonus: {'VIP': 3},
        ),
        stats: SpinStatsSummary(totalSpins: 120, totalWins: 14),
        prizes: [
          SpinPrize(
            id: 'sparky',
            name: 'Sparky Plush',
            symbol: SpinSymbol.star,
            initialStock: 10,
            remainingStock: 6,
            awardedCount: 4,
            redeemedCount: 2,
            releasedStock: 6,
            rarity: PrizeRarity.epic,
          ),
        ],
        winCounts: SpinWinCounts(pending: 2, redeemed: 2, total: 4),
        activePlayersCount: 35,
        registrationsCount: 200,
      ),
    );
  });

  tearDown(() async {
    adminProvider.dispose();
    userProvider.dispose();
    await harness.dispose();
  });

  Widget buildScreen() => MediaQuery(
    data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: adminProvider),
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const MaterialApp(
        home: SpinAdminScreen(eventId: 'evt-1', eventTitle: 'DevFest 2026'),
      ),
    ),
  );

  void seedStreams({
    SpinConfig config = const SpinConfig(
      status: SpinGameStatus.paused,
      pacingMode: SpinPacingMode.manualWaves,
      packageTicketBonus: {'VIP': 3},
    ),
    List<SpinPrize>? prizes,
    List<SpinMission>? missions,
    List<SpinWin>? wins,
    List<SpinTicketCode>? codes,
  }) {
    harness.configController.add(config);
    harness.prizesController.add(
      prizes ??
          const [
            SpinPrize(
              id: 'sparky',
              name: 'Sparky Plush',
              symbol: SpinSymbol.star,
              initialStock: 10,
              remainingStock: 6,
              awardedCount: 4,
              redeemedCount: 2,
              releasedStock: 6,
              rarity: PrizeRarity.epic,
            ),
          ],
    );
    harness.missionsController.add(
      missions ??
          const [
            SpinMission(
              id: 'm1',
              type: SpinMissionType.trivia,
              title: 'Morning Trivia',
              reward: 1,
              active: false,
              triviaQuestion: 'What is Firebase?',
              triviaOptions: ['BaaS', 'OS'],
            ),
          ],
    );
    harness.winsController.add(
      wins ??
          const [
            SpinWin(
              id: 'w1',
              eventId: 'evt-1',
              uid: 'u1',
              winnerName: 'Ada Lovelace',
              prizeId: 'sparky',
              prizeName: 'Sparky Plush',
              prizeSymbol: SpinSymbol.star,
              code: 'GDG-7K9P2M',
              status: SpinWinStatus.pending,
            ),
          ],
    );
    harness.codesController.add(
      codes ??
          const [
            SpinTicketCode(
              id: 'c1',
              code: 'CLOUD26',
              label: 'Cloud Booth',
              rewardTickets: 1,
              maxTotalUses: 100,
              usedCount: 12,
              active: true,
            ),
          ],
    );
  }

  testWidgets('non-admin sees access-denied screen without tabs', (
    tester,
  ) async {
    userProvider.isAdmin = false;

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.spinAdminAccessDenied), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    verifyNever(() => harness.spinRepo.getDashboard(any()));
  });

  testWidgets('admin sees 5 tabs, KPIs, and Rush Final confirmation dialog', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    userProvider.isAdmin = true;
    when(
      () => harness.spinRepo.updateConfig(
        eventId: 'evt-1',
        patch: {'rushMode': true},
      ),
    ).thenAnswer(
      (_) async =>
          const SpinConfig(status: SpinGameStatus.paused, rushMode: true),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pump();
    seedStreams();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.spinAdminTabControl), findsOneWidget);
    expect(find.text(AppStrings.spinAdminTabPrizes), findsOneWidget);
    expect(find.text(AppStrings.spinAdminTabMissions), findsOneWidget);
    expect(find.text(AppStrings.spinAdminTabTickets), findsOneWidget);
    expect(find.text(AppStrings.spinAdminTabRedeem), findsOneWidget);
    expect(find.text('120'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.spinAdminRushConfirmTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.spinAdminRushConfirmAction));
    await tester.pumpAndSettle();

    verify(
      () => harness.spinRepo.updateConfig(
        eventId: 'evt-1',
        patch: {'rushMode': true},
      ),
    ).called(1);
  });

  testWidgets(
    'Prizes tab edits prize without sending stock, adjusts stock, and releases +1 in manualWaves',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      userProvider.isAdmin = true;

      when(
        () => harness.spinRepo.adjustPrizeStock(
          eventId: 'evt-1',
          prizeId: 'sparky',
          delta: 1,
          reason: 'Box found',
        ),
      ).thenAnswer(
        (_) async => const SpinPrize(
          id: 'sparky',
          name: 'Sparky Plush',
          symbol: SpinSymbol.star,
          initialStock: 11,
          remainingStock: 7,
          releasedStock: 6,
          rarity: PrizeRarity.epic,
        ),
      );
      when(
        () => harness.spinRepo.upsertPrize(
          eventId: 'evt-1',
          prizeData: any(named: 'prizeData'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer(
        (_) async => const AdminUpsertPrizeResult(
          prize: SpinPrize(
            id: 'sparky',
            name: 'Sparky Plush',
            symbol: SpinSymbol.star,
            initialStock: 10,
            remainingStock: 6,
            releasedStock: 7,
            rarity: PrizeRarity.epic,
          ),
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();
      seedStreams();
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.spinAdminTabPrizes));
      await tester.pumpAndSettle();

      expect(find.text('Sparky Plush'), findsOneWidget);
      expect(find.text(AppStrings.spinAdminReleaseOne), findsOneWidget);

      await tester.tap(find.text(AppStrings.spinAdminAdjustStock));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, AppStrings.spinAdminStockReasonLabel),
        'Box found',
      );
      await tester.tap(find.text(AppStrings.commonWordSave));
      await tester.pumpAndSettle();

      verify(
        () => harness.spinRepo.adjustPrizeStock(
          eventId: 'evt-1',
          prizeId: 'sparky',
          delta: 1,
          reason: 'Box found',
        ),
      ).called(1);

      await tester.tap(find.text(AppStrings.spinAdminReleaseOne));
      await tester.pumpAndSettle();

      verify(
        () => harness.spinRepo.adjustPrizeStock(
          eventId: 'evt-1',
          prizeId: 'sparky',
          delta: 0,
          releasedDelta: 1,
          reason: AppStrings.spinAdminReleaseOneReason,
        ),
      ).called(1);

      // Edit dialog also omits initialStock & remainingStock.
      await tester.tap(find.text(AppStrings.commonWordEdit));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.spinAdminEditPrize), findsOneWidget);
      expect(find.text(AppStrings.spinAdminPrizeInitialStock), findsNothing);
      final editSaveBtn = find.text(AppStrings.commonWordSave);
      await tester.ensureVisible(editSaveBtn);
      await tester.pumpAndSettle();
      await tester.tap(editSaveBtn);
      await tester.pumpAndSettle();

      final editCaptured =
          verify(
                () => harness.spinRepo.upsertPrize(
                  eventId: 'evt-1',
                  prizeData: captureAny(named: 'prizeData'),
                  imagePath: any(named: 'imagePath'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(editCaptured.containsKey('initialStock'), isFalse);
      expect(editCaptured.containsKey('remainingStock'), isFalse);
    },
  );

  testWidgets('Missions tab toggles active state in 1 tap', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    userProvider.isAdmin = true;

    when(
      () => harness.spinRepo.upsertMission(
        eventId: 'evt-1',
        missionData: any(named: 'missionData'),
        correctOptionIndex: null,
        explanation: null,
      ),
    ).thenAnswer(
      (_) async => const AdminUpsertMissionResult(
        mission: SpinMission(
          id: 'm1',
          type: SpinMissionType.trivia,
          title: 'Morning Trivia',
          reward: 1,
          active: true,
        ),
      ),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pump();
    seedStreams();
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.spinAdminTabMissions));
    await tester.pumpAndSettle();

    expect(find.text('Morning Trivia'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    verify(
      () => harness.spinRepo.upsertMission(
        eventId: 'evt-1',
        missionData: any(
          named: 'missionData',
          that: containsPair('active', true),
        ),
        correctOptionIndex: null,
        explanation: null,
      ),
    ).called(1);
  });

  testWidgets('Tickets tab previews CSV import and opens stand QR modal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    userProvider.isAdmin = true;

    when(
      () => harness.spinRepo.importRegistrations(
        eventId: 'evt-1',
        rows: any(named: 'rows'),
        replaceAll: false,
      ),
    ).thenAnswer(
      (_) async => const AdminImportRegistrationsResult(
        importedCount: 1,
        updatedCount: 0,
        totalRegistrationsCount: 1,
      ),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pump();
    seedStreams();
    await tester.pumpAndSettle();

    final ticketsTab = find.text(AppStrings.spinAdminTabTickets);
    await tester.ensureVisible(ticketsTab);
    await tester.pumpAndSettle();
    await tester.tap(ticketsTab);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.spinAdminImportTag),
      'ada@example.com,Ada,VIP\ninvalid-email,Bad,VIP',
    );
    await tester.pump();

    expect(find.text(AppStrings.spinAdminImportPreview(1, 1)), findsOneWidget);
    expect(find.text('VIP: 1'), findsOneWidget);

    await tester.tap(find.text(AppStrings.spinAdminImportAction));
    await tester.pumpAndSettle();

    verify(
      () => harness.spinRepo.importRegistrations(
        eventId: 'evt-1',
        rows: any(named: 'rows'),
        replaceAll: false,
      ),
    ).called(1);

    final viewQrBtn = find.text(AppStrings.spinAdminViewQr);
    await tester.ensureVisible(viewQrBtn);
    await tester.pumpAndSettle();
    await tester.tap(viewQrBtn);
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(AppStrings.spinAdminShareQr), findsOneWidget);
  });

  testWidgets(
    'Redeem tab looks up pending win, shows already-redeemed alert for redeemed, and revokes win',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      userProvider.isAdmin = true;

      const pendingWin = SpinWin(
        id: 'w1',
        eventId: 'evt-1',
        uid: 'u1',
        winnerName: 'Ada Lovelace',
        prizeId: 'sparky',
        prizeName: 'Sparky Plush',
        prizeSymbol: SpinSymbol.star,
        code: 'GDG-7K9P2M',
        status: SpinWinStatus.pending,
      );
      final redeemedWin = pendingWin.copyWith(
        status: SpinWinStatus.redeemed,
        redeemedByName: 'Staff User',
      );

      when(
        () => harness.spinRepo.lookupWinByCode(
          eventId: 'evt-1',
          codeOrQr: 'GDG-7K9P2M',
        ),
      ).thenAnswer((_) async => const AdminLookupWinResult(win: pendingWin));
      when(
        () => harness.spinRepo.redeemWin(eventId: 'evt-1', winId: 'w1'),
      ).thenAnswer((_) async => redeemedWin);

      await tester.pumpWidget(buildScreen());
      await tester.pump();
      seedStreams();
      await tester.pumpAndSettle();

      final redeemTab = find.text(AppStrings.spinAdminTabRedeem);
      await tester.ensureVisible(redeemTab);
      await tester.pumpAndSettle();
      await tester.tap(redeemTab);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, AppStrings.spinAdminRedeemCodeLabel),
        'GDG-7K9P2M',
      );
      await tester.tap(find.text(AppStrings.spinAdminRedeemSearch));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.spinAdminConfirmRedeem), findsOneWidget);
      await tester.tap(find.text(AppStrings.spinAdminConfirmRedeem));
      await tester.pumpAndSettle();

      verify(
        () => harness.spinRepo.redeemWin(eventId: 'evt-1', winId: 'w1'),
      ).called(1);
      expect(
        find.text(AppStrings.spinAdminAlreadyRedeemedBanner),
        findsOneWidget,
      );

      // Test revoke flow on another pending win from the list.
      const secondWin = SpinWin(
        id: 'w2',
        eventId: 'evt-1',
        uid: 'u2',
        winnerName: 'Grace Hopper',
        prizeId: 'sparky',
        prizeName: 'Sparky Plush',
        prizeSymbol: SpinSymbol.star,
        code: 'GDG-999BBB',
        status: SpinWinStatus.pending,
      );
      when(
        () => harness.spinRepo.revokeWin(
          eventId: 'evt-1',
          winId: 'w2',
          returnToStock: true,
          reason: 'Mistake',
        ),
      ).thenAnswer(
        (_) async => secondWin.copyWith(
          status: SpinWinStatus.revoked,
          revokeReason: 'Mistake',
          returnedToStock: true,
        ),
      );

      harness.winsController.add([secondWin]);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      final secondWinRow = find.text('Grace Hopper · GDG-999BBB');
      await tester.ensureVisible(secondWinRow);
      await tester.pumpAndSettle();
      await tester.tap(secondWinRow);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.spinAdminRevokeAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.spinAdminRevokeConfirmTitle), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, AppStrings.spinAdminRevokeReasonLabel),
        'Mistake',
      );
      await tester.tap(find.text(AppStrings.spinAdminRevokeAction).last);
      await tester.pumpAndSettle();

      verify(
        () => harness.spinRepo.revokeWin(
          eventId: 'evt-1',
          winId: 'w2',
          returnToStock: true,
          reason: 'Mistake',
        ),
      ).called(1);
      expect(find.text(AppStrings.spinRedeemQrRevoked), findsOneWidget);
    },
  );
}
