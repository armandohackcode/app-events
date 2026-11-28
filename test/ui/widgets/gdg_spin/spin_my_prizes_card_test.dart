import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_my_prizes_card.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_redeem_qr_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _MockSpinRepository extends Mock implements SpinRepository {}

void main() {
  SpinWin makeWin({
    String id = 'w1',
    SpinWinStatus status = SpinWinStatus.pending,
    String? revokeReason,
  }) => SpinWin(
    id: id,
    eventId: 'evt-1',
    uid: 'u1',
    prizeId: 'sparky',
    prizeName: 'Sparky Plush',
    prizeSymbol: SpinSymbol.star,
    prizeRarity: PrizeRarity.epic,
    code: 'GDG-7K9P2M',
    status: status,
    revokeReason: revokeReason,
  );

  testWidgets('shows empty state when player has no wins', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpinMyPrizesCard(prizes: [])),
      ),
    );

    expect(find.text(AppStrings.spinMyPrizesEmpty), findsOneWidget);
  });

  testWidgets('renders status badges and invokes onPrizeTap', (tester) async {
    SpinWin? tapped;
    final wins = [
      makeWin(id: 'w1', status: SpinWinStatus.pending),
      makeWin(id: 'w2', status: SpinWinStatus.redeemed),
      makeWin(id: 'w3', status: SpinWinStatus.revoked),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpinMyPrizesCard(
              prizes: wins,
              onPrizeTap: (win) => tapped = win,
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.spinStatusPending), findsOneWidget);
    expect(find.text(AppStrings.spinStatusRedeemed), findsOneWidget);
    expect(find.text(AppStrings.spinStatusRevoked), findsOneWidget);
    expect(find.text(AppStrings.spinTapToShowQr), findsOneWidget);

    await tester.tap(find.text(AppStrings.spinStatusPending));
    expect(tapped?.id, 'w1');
  });

  testWidgets('SpinRedeemQrDialog renders standalone without provider', (
    tester,
  ) async {
    final win = makeWin(status: SpinWinStatus.pending);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpinRedeemQrDialog(winId: win.id, initialWin: win),
        ),
      ),
    );

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('GDG-7K9P2M'), findsOneWidget);
    expect(find.text(AppStrings.spinStatusPending), findsOneWidget);
    expect(find.text(AppStrings.spinRedeemQrHint), findsOneWidget);
  });

  testWidgets(
    'SpinRedeemQrDialog updates live when win transitions pending -> redeemed',
    (tester) async {
      final repo = _MockSpinRepository();
      final winsController = StreamController<List<SpinWin>>.broadcast();
      addTearDown(winsController.close);

      when(
        () => repo.watchConfig(any()),
      ).thenAnswer((_) => const Stream<SpinConfig?>.empty());
      when(
        () => repo.watchPrizes(any(), activeOnly: any(named: 'activeOnly')),
      ).thenAnswer((_) => const Stream<List<SpinPrize>>.empty());
      when(
        () => repo.watchMissions(any(), activeOnly: any(named: 'activeOnly')),
      ).thenAnswer((_) => const Stream<List<SpinMission>>.empty());
      when(
        () => repo.watchPlayer(any(), any()),
      ).thenAnswer((_) => const Stream<SpinPlayer?>.empty());
      when(
        () => repo.watchMyWins(any(), any()),
      ).thenAnswer((_) => winsController.stream);
      when(
        () => repo.watchMyMissionClaims(any(), any()),
      ).thenAnswer((_) => const Stream<List<SpinMissionClaim>>.empty());
      when(() => repo.initPlayer(any())).thenAnswer(
        (_) async => const SpinInitPlayerResult(
          player: SpinPlayer(uid: 'u1', tickets: 2),
        ),
      );

      final provider = GdgSpinProvider(repo);
      addTearDown(provider.dispose);
      await provider.bind(eventId: 'evt-1', uid: 'u1');

      final initialWin = makeWin(status: SpinWinStatus.pending);
      winsController.add([initialWin]);
      await tester.pump();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: SpinRedeemQrDialog(
                winId: initialWin.id,
                initialWin: initialWin,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text(AppStrings.spinStatusPending), findsOneWidget);

      winsController.add([makeWin(status: SpinWinStatus.redeemed)]);
      await tester.pump();
      await tester.pump();

      expect(find.byType(QrImageView), findsNothing);
      expect(find.text(AppStrings.spinStatusRedeemed), findsOneWidget);
      expect(find.text(AppStrings.spinRedeemQrCompleted), findsOneWidget);
    },
  );
}
