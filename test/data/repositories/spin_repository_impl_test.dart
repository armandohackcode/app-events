import 'package:app_events/data/repositories/spin_repository_impl.dart';
import 'package:app_events/domain/datasources/spin_datasource.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpinDatasource extends Mock implements SpinDatasource {}

void main() {
  late _MockSpinDatasource datasource;
  late SpinRepositoryImpl repository;

  const eventId = 'evt-1';

  setUp(() {
    datasource = _MockSpinDatasource();
    repository = SpinRepositoryImpl(datasource);
  });

  test('delegates all stream calls with exact arguments', () async {
    const config = SpinConfig();
    const prize = SpinPrize(
      id: 'p1',
      name: 'Mug',
      symbol: SpinSymbol.bell,
      initialStock: 2,
      remainingStock: 2,
      rarity: PrizeRarity.rare,
    );
    const mission = SpinMission(id: 'm1', title: 'Trivia', reward: 1);
    const player = SpinPlayer(uid: 'u1');
    const win = SpinWin(
      id: 'w1',
      eventId: eventId,
      uid: 'u1',
      prizeId: 'p1',
      prizeName: 'Mug',
      prizeSymbol: SpinSymbol.bell,
      code: 'GDG-123456',
    );
    const claim = SpinMissionClaim(uid: 'u1', missionId: 'm1');
    const code = SpinTicketCode(id: 'c1', code: 'CLOUD26', label: 'Cloud');

    when(
      () => datasource.watchConfig(eventId),
    ).thenAnswer((_) => Stream.value(config));
    when(
      () => datasource.watchPrizes(eventId, activeOnly: false),
    ).thenAnswer((_) => Stream.value([prize]));
    when(
      () => datasource.watchMissions(eventId, activeOnly: true),
    ).thenAnswer((_) => Stream.value([mission]));
    when(
      () => datasource.watchPlayer(eventId, 'u1'),
    ).thenAnswer((_) => Stream.value(player));
    when(
      () => datasource.watchMyWins(eventId, 'u1'),
    ).thenAnswer((_) => Stream.value([win]));
    when(
      () => datasource.watchMyMissionClaims(eventId, 'u1'),
    ).thenAnswer((_) => Stream.value([claim]));
    when(
      () => datasource.watchAllWins(eventId, status: SpinWinStatus.pending),
    ).thenAnswer((_) => Stream.value([win]));
    when(
      () => datasource.watchTicketCodes(eventId),
    ).thenAnswer((_) => Stream.value([code]));

    expect(await repository.watchConfig(eventId).first, config);
    expect(await repository.watchPrizes(eventId, activeOnly: false).first, [
      prize,
    ]);
    expect(await repository.watchMissions(eventId, activeOnly: true).first, [
      mission,
    ]);
    expect(await repository.watchPlayer(eventId, 'u1').first, player);
    expect(await repository.watchMyWins(eventId, 'u1').first, [win]);
    expect(await repository.watchMyMissionClaims(eventId, 'u1').first, [claim]);
    expect(
      await repository
          .watchAllWins(eventId, status: SpinWinStatus.pending)
          .first,
      [win],
    );
    expect(await repository.watchTicketCodes(eventId).first, [code]);
  });

  test(
    'delegates all player and admin future calls with exact arguments',
    () async {
      const initRes = SpinInitPlayerResult(player: SpinPlayer(uid: 'u1'));
      const pullRes = SpinPullResult(
        spinRequestId: 'req-1',
        outcomeType: SpinOutcomeType.lose,
        combo: [SpinSymbol.lemon, SpinSymbol.cherries, SpinSymbol.bar],
      );
      const claimRes = SpinClaimMissionResult(granted: true);
      const triviaRes = SpinSubmitTriviaResult(correct: true);
      const redeemRes = SpinRedeemTicketCodeResult(label: 'Cloud');
      const config = SpinConfig(status: SpinGameStatus.active);
      const prize = SpinPrize(
        id: 'p1',
        name: 'Mug',
        symbol: SpinSymbol.bell,
        initialStock: 2,
        remainingStock: 2,
        rarity: PrizeRarity.rare,
      );
      const upsertPrizeRes = AdminUpsertPrizeResult(
        prize: prize,
        created: true,
      );
      const upsertMissionRes = AdminUpsertMissionResult(
        mission: SpinMission(id: 'm1', title: 'Ask', reward: 1),
        created: true,
      );
      const upsertCodeRes = AdminUpsertTicketCodeResult(
        ticketCode: SpinTicketCode(id: 'c1', code: 'CLOUD26', label: 'Cloud'),
        created: true,
      );
      const grantRes = AdminGrantTicketsResult(
        targetUid: 'u1',
        ticketsAwarded: 2,
      );
      const importRes = AdminImportRegistrationsResult(importedCount: 1);
      const win = SpinWin(
        id: 'w1',
        eventId: eventId,
        uid: 'u1',
        prizeId: 'p1',
        prizeName: 'Mug',
        prizeSymbol: SpinSymbol.bell,
        code: 'GDG-123456',
      );
      const lookupRes = AdminLookupWinResult(win: win);
      const dashboard = SpinDashboardStats(
        config: config,
        stats: SpinStatsSummary(),
        prizes: [prize],
        winCounts: SpinWinCounts(),
      );

      when(
        () => datasource.initPlayer(eventId),
      ).thenAnswer((_) async => initRes);
      when(
        () => datasource.pull(eventId: eventId, spinRequestId: 'req-1'),
      ).thenAnswer((_) async => pullRes);
      when(
        () => datasource.claimMission(eventId: eventId, missionId: 'm1'),
      ).thenAnswer((_) async => claimRes);
      when(
        () => datasource.submitTrivia(
          eventId: eventId,
          missionId: 'm1',
          selectedIndex: 0,
        ),
      ).thenAnswer((_) async => triviaRes);
      when(
        () => datasource.redeemTicketCode(eventId: eventId, code: 'CLOUD26'),
      ).thenAnswer((_) async => redeemRes);
      when(
        () => datasource.updateConfig(
          eventId: eventId,
          patch: {'status': 'active'},
        ),
      ).thenAnswer((_) async => config);
      when(
        () => datasource.upsertPrize(
          eventId: eventId,
          prizeData: {'name': 'Mug'},
          imagePath: '/tmp/mug.png',
        ),
      ).thenAnswer((_) async => upsertPrizeRes);
      when(
        () => datasource.adjustPrizeStock(
          eventId: eventId,
          prizeId: 'p1',
          delta: 1,
          reason: 'Restock',
        ),
      ).thenAnswer((_) async => prize);
      when(
        () => datasource.upsertMission(
          eventId: eventId,
          missionData: {'title': 'Ask'},
          correctOptionIndex: 0,
          explanation: 'Yes',
        ),
      ).thenAnswer((_) async => upsertMissionRes);
      when(
        () => datasource.upsertTicketCode(
          eventId: eventId,
          codeData: {'code': 'CLOUD26'},
        ),
      ).thenAnswer((_) async => upsertCodeRes);
      when(
        () => datasource.grantTickets(
          eventId: eventId,
          targetUid: 'u1',
          amount: 2,
          reason: 'Help',
          requestId: 'req-grant',
        ),
      ).thenAnswer((_) async => grantRes);
      when(
        () => datasource.importRegistrations(
          eventId: eventId,
          rows: const [SpinRegistrationRow(email: 'a@b.c', package: 'VIP')],
          replaceAll: true,
        ),
      ).thenAnswer((_) async => importRes);
      when(
        () => datasource.lookupWinByCode(
          eventId: eventId,
          codeOrQr: 'GDG-123456',
        ),
      ).thenAnswer((_) async => lookupRes);
      when(
        () => datasource.redeemWin(eventId: eventId, winId: 'w1'),
      ).thenAnswer((_) async => win);
      when(
        () => datasource.revokeWin(
          eventId: eventId,
          winId: 'w1',
          returnToStock: true,
          reason: 'Mistake',
        ),
      ).thenAnswer((_) async => win);
      when(
        () => datasource.getDashboard(eventId),
      ).thenAnswer((_) async => dashboard);
      when(
        () => datasource.uploadPrizeImage(
          eventId: eventId,
          prizeId: 'p1',
          imagePath: '/tmp/mug.png',
        ),
      ).thenAnswer((_) async => 'https://example.com/mug.png');

      expect(await repository.initPlayer(eventId), initRes);
      expect(
        await repository.pull(eventId: eventId, spinRequestId: 'req-1'),
        pullRes,
      );
      expect(
        await repository.claimMission(eventId: eventId, missionId: 'm1'),
        claimRes,
      );
      expect(
        await repository.submitTrivia(
          eventId: eventId,
          missionId: 'm1',
          selectedIndex: 0,
        ),
        triviaRes,
      );
      expect(
        await repository.redeemTicketCode(eventId: eventId, code: 'CLOUD26'),
        redeemRes,
      );
      expect(
        await repository.updateConfig(
          eventId: eventId,
          patch: {'status': 'active'},
        ),
        config,
      );
      expect(
        await repository.upsertPrize(
          eventId: eventId,
          prizeData: {'name': 'Mug'},
          imagePath: '/tmp/mug.png',
        ),
        upsertPrizeRes,
      );
      expect(
        await repository.adjustPrizeStock(
          eventId: eventId,
          prizeId: 'p1',
          delta: 1,
          reason: 'Restock',
        ),
        prize,
      );
      expect(
        await repository.upsertMission(
          eventId: eventId,
          missionData: {'title': 'Ask'},
          correctOptionIndex: 0,
          explanation: 'Yes',
        ),
        upsertMissionRes,
      );
      expect(
        await repository.upsertTicketCode(
          eventId: eventId,
          codeData: {'code': 'CLOUD26'},
        ),
        upsertCodeRes,
      );
      expect(
        await repository.grantTickets(
          eventId: eventId,
          targetUid: 'u1',
          amount: 2,
          reason: 'Help',
          requestId: 'req-grant',
        ),
        grantRes,
      );
      expect(
        await repository.importRegistrations(
          eventId: eventId,
          rows: const [SpinRegistrationRow(email: 'a@b.c', package: 'VIP')],
          replaceAll: true,
        ),
        importRes,
      );
      expect(
        await repository.lookupWinByCode(
          eventId: eventId,
          codeOrQr: 'GDG-123456',
        ),
        lookupRes,
      );
      expect(await repository.redeemWin(eventId: eventId, winId: 'w1'), win);
      expect(
        await repository.revokeWin(
          eventId: eventId,
          winId: 'w1',
          returnToStock: true,
          reason: 'Mistake',
        ),
        win,
      );
      expect(await repository.getDashboard(eventId), dashboard);
      expect(
        await repository.uploadPrizeImage(
          eventId: eventId,
          prizeId: 'p1',
          imagePath: '/tmp/mug.png',
        ),
        'https://example.com/mug.png',
      );
    },
  );

  test('propagates datasource errors asynchronously', () {
    when(
      () => datasource.pull(eventId: eventId, spinRequestId: 'req-1'),
    ).thenAnswer(
      (_) async => throw const SpinException(
        reason: SpinErrorReason.gamePaused,
        code: 'failed-precondition',
        message: 'Paused',
      ),
    );

    expect(
      repository.pull(eventId: eventId, spinRequestId: 'req-1'),
      throwsA(isA<SpinException>()),
    );
  });
}
