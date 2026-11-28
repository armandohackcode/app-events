import 'package:app_events/domain/models/spin_json_helpers.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinOutcomeType', () {
    test('fromValue maps known values and defaults to lose', () {
      expect(SpinOutcomeType.fromValue('prize'), SpinOutcomeType.prize);
      expect(SpinOutcomeType.fromValue('bonus'), SpinOutcomeType.bonus);
      expect(SpinOutcomeType.fromValue('lose'), SpinOutcomeType.lose);
      expect(SpinOutcomeType.fromValue(null), SpinOutcomeType.lose);
      expect(SpinOutcomeType.fromValue('other'), SpinOutcomeType.lose);
    });
  });

  group('SpinErrorReason', () {
    test('fromValue maps all backend and client codes and falls back', () {
      const backendReasons = [
        'GAME_PAUSED',
        'GAME_CLOSED',
        'INSUFFICIENT_TICKETS',
        'COOLDOWN_ACTIVE',
        'PRIZE_CAP_REACHED',
        'PLAYER_NOT_INITIALIZED',
        'CONFIG_NOT_FOUND',
        'REQUIREMENT_NOT_MET',
        'TICKET_CAP_REACHED',
        'TRIVIA_CLOSED',
        'MISSION_INACTIVE',
        'CODE_DEPLETED',
        'CODE_EXPIRED',
        'CODE_ALREADY_EXISTS',
        'RATE_LIMITED',
        'QUESTION_LIMIT_REACHED',
        'ALREADY_REDEEMED',
        'ALREADY_REVOKED',
        'INVALID_STOCK_ADJUSTMENT',
        'STOCK_IMMUTABLE_ON_UPDATE',
        'MANUAL_GRANT_CAP_REACHED',
        'EVENT_MISMATCH',
        'INVALID_CODE_FORMAT',
        'INVALID_SECRET',
        'UNKNOWN',
        'NETWORK',
        'UNAUTHENTICATED',
        'PERMISSION_DENIED',
        'ALREADY_EXISTS',
        'NOT_FOUND',
      ];

      expect(backendReasons, hasLength(SpinErrorReason.values.length));
      for (final raw in backendReasons) {
        final parsed = SpinErrorReason.fromValue(raw);
        expect(parsed.value, raw);
      }

      expect(
        SpinErrorReason.fromValue('unknown_code'),
        SpinErrorReason.unknown,
      );
      expect(SpinErrorReason.fromValue(null), SpinErrorReason.unknown);
      expect(SpinErrorReason.fromValue(''), SpinErrorReason.unknown);
    });
  });

  group('SpinException & SpinOutcome', () {
    test('SpinException formats readable string', () {
      const ex = SpinException(
        reason: SpinErrorReason.gamePaused,
        code: 'failed-precondition',
        message: 'Paused',
      );
      expect(
        ex.toString(),
        'SpinException(failed-precondition, GAME_PAUSED): Paused',
      );
    });

    test('SpinOutcome subclasses carry expected payloads', () {
      const prize = SpinPrize(
        id: 'mug',
        name: 'Mug',
        symbol: SpinSymbol.bell,
        initialStock: 2,
        remainingStock: 1,
        rarity: PrizeRarity.rare,
      );
      const prizeOutcome = SpinPrizeOutcome(prize);
      const bonusOutcome = SpinBonusOutcome(3);

      expect(prizeOutcome, isA<SpinOutcome>());
      expect(prizeOutcome.prize.id, 'mug');
      expect(bonusOutcome.tickets, 3);
    });
  });

  group('Spin JSON helpers', () {
    test('parseDateTime handles DateTime, epoch ms, ISO string, and map', () {
      final dt = DateTime.utc(2026, 11, 28, 12);
      expect(parseDateTime(dt), dt);
      expect(parseDateTime(dt.millisecondsSinceEpoch), dt);
      expect(parseDateTime(dt.millisecondsSinceEpoch.toDouble()), dt);
      expect(parseDateTime(dt.toIso8601String()), dt);
      expect(
        parseDateTime({'_seconds': dt.millisecondsSinceEpoch ~/ 1000}),
        dt,
      );
      expect(parseDateTime(''), isNull);
      expect(parseDateTime('not-a-date'), isNull);
    });

    test('numeric and collection helpers use fallbacks cleanly', () {
      expect(parseInt('42'), 42);
      expect(parseInt(3.9), 3);
      expect(parseInt(double.nan, fallback: 7), 7);
      expect(parseNullableInt('12'), 12);
      expect(parseNullableInt('bad'), isNull);
      expect(parseDouble('2.5'), 2.5);
      expect(parseDouble(double.infinity, fallback: 1.5), 1.5);
      expect(parseStringIntMap({'a': '2', 'b': 3.7}), {'a': 2, 'b': 3});
      expect(parseStringList(['a', 1, 'b']), ['a', 'b']);
    });
  });

  group('Result DTO models', () {
    test('SpinPullResult round-trips prize and bonus outcomes', () {
      final result = SpinPullResult.fromJson({
        'spinRequestId': 'req-12345678',
        'outcomeType': 'prize',
        'combo': ['star', 'wild', 'star'],
        'wonPrize': {
          'winId': 'win-1',
          'prizeId': 'sparky',
          'name': 'Sparky',
          'symbol': 'star',
          'imageUrl': 'https://example.com/sparky.png',
          'rarity': 'epic',
          'code': 'GDG-7K9P2M',
          'wonAt': '2026-11-28T14:00:00.000Z',
        },
        'bonusTickets': 0,
        'ticketsAfter': 2,
        'spinsCountAfter': 3,
        'reachedPrizeCap': false,
        'ticketSerial': null,
      });

      expect(result.outcomeType, SpinOutcomeType.prize);
      expect(result.combo, [SpinSymbol.star, SpinSymbol.wild, SpinSymbol.star]);
      expect(result.wonPrize?.code, 'GDG-7K9P2M');
      expect(
        SpinPullResult.fromJson(result.toJson()).toJson(),
        result.toJson(),
      );
      expect(SpinPullResult.fromJson({}).outcomeType, SpinOutcomeType.lose);
    });

    test(
      'SpinInitPlayerResult, SpinClaimMissionResult, SpinSubmitTriviaResult, SpinRedeemTicketCodeResult round-trip',
      () {
        final init = SpinInitPlayerResult.fromJson({
          'player': {'uid': 'u-1', 'tickets': 3},
          'initialGranted': true,
          'packageBonusGranted': true,
          'matchedPackage': 'VIP',
        });
        expect(init.player.uid, 'u-1');
        expect(init.matchedPackage, 'VIP');
        expect(
          SpinInitPlayerResult.fromJson(init.toJson()).toJson(),
          init.toJson(),
        );

        final claim = SpinClaimMissionResult.fromJson({
          'granted': true,
          'ticketsAwarded': 1,
          'ticketsAfter': 4,
          'ticketSerial': 'ABCD1234',
        });
        expect(
          SpinClaimMissionResult.fromJson(claim.toJson()).toJson(),
          claim.toJson(),
        );

        final trivia = SpinSubmitTriviaResult.fromJson({
          'correct': true,
          'explanation': 'Correct!',
          'ticketsAwarded': 1,
          'ticketsAfter': 5,
          'ticketSerial': 'TRV56789',
        });
        expect(
          SpinSubmitTriviaResult.fromJson(trivia.toJson()).toJson(),
          trivia.toJson(),
        );

        final redeem = SpinRedeemTicketCodeResult.fromJson({
          'label': 'Cloud Booth',
          'ticketsAwarded': 2,
          'ticketsAfter': 7,
          'ticketSerial': 'COD90123',
        });
        expect(
          SpinRedeemTicketCodeResult.fromJson(redeem.toJson()).toJson(),
          redeem.toJson(),
        );
      },
    );

    test('SpinMissionClaim supports claimedAt and Firestore lastClaimedAt', () {
      final fromFirestore = SpinMissionClaim.fromJson({
        'uid': 'u-1',
        'missionId': 'rate_talk',
        'completions': 2,
        'countedTalkIds': ['spk-1', 'spk-2'],
        'lastClaimedAt': '2026-11-28T15:00:00.000Z',
      });

      expect(fromFirestore.completions, 2);
      expect(fromFirestore.countedTalkIds, ['spk-1', 'spk-2']);
      expect(fromFirestore.claimedAt, DateTime.utc(2026, 11, 28, 15));
      expect(
        SpinMissionClaim.fromJson(fromFirestore.toJson()).toJson(),
        fromFirestore.toJson(),
      );
    });

    test('Admin DTOs and SpinRegistrationRow round-trip cleanly', () {
      const regRow = SpinRegistrationRow(
        email: 'ada@example.com',
        fullName: 'Ada',
        package: 'VIP',
        checkedIn: true,
      );
      expect(
        SpinRegistrationRow.fromJson(regRow.toJson()).toJson(),
        regRow.toJson(),
      );

      final importRes = AdminImportRegistrationsResult.fromJson({
        'importedCount': 10,
        'updatedCount': 2,
        'totalRegistrationsCount': 12,
      });
      expect(
        AdminImportRegistrationsResult.fromJson(importRes.toJson()).toJson(),
        importRes.toJson(),
      );

      final grantRes = AdminGrantTicketsResult.fromJson({
        'targetUid': 'u-1',
        'ticketsAwarded': 2,
        'ticketsAfter': 5,
        'ticketSerial': 'SER12345',
        'idempotentReplay': true,
      });
      expect(
        AdminGrantTicketsResult.fromJson(grantRes.toJson()).toJson(),
        grantRes.toJson(),
      );

      final lookup = AdminLookupWinResult(
        win: const SpinWin(
          id: 'w-1',
          eventId: 'evt-1',
          uid: 'u-1',
          prizeId: 'p-1',
          prizeName: 'Mug',
          prizeSymbol: SpinSymbol.bell,
          code: 'GDG-ABCDEF',
        ),
        prize: const SpinPrize(
          id: 'p-1',
          name: 'Mug',
          symbol: SpinSymbol.bell,
          initialStock: 5,
          remainingStock: 4,
          rarity: PrizeRarity.rare,
        ),
        player: const SpinPlayer(uid: 'u-1', tickets: 2),
      );
      expect(
        AdminLookupWinResult.fromJson(lookup.toJson()).toJson(),
        lookup.toJson(),
      );

      final upsertPrize = const AdminUpsertPrizeResult(
        prize: SpinPrize(
          id: 'p-1',
          name: 'Mug',
          symbol: SpinSymbol.bell,
          initialStock: 5,
          remainingStock: 5,
          rarity: PrizeRarity.rare,
        ),
        created: true,
      );
      expect(
        AdminUpsertPrizeResult.fromJson(upsertPrize.toJson()).toJson(),
        upsertPrize.toJson(),
      );

      final upsertMission = const AdminUpsertMissionResult(
        mission: SpinMission(id: 'm-1', title: 'Trivia', reward: 1),
        created: true,
      );
      expect(
        AdminUpsertMissionResult.fromJson(upsertMission.toJson()).toJson(),
        upsertMission.toJson(),
      );

      final upsertCode = const AdminUpsertTicketCodeResult(
        ticketCode: SpinTicketCode(id: 'c-1', code: 'CLOUD26', label: 'Cloud'),
        created: true,
      );
      expect(
        AdminUpsertTicketCodeResult.fromJson(upsertCode.toJson()).toJson(),
        upsertCode.toJson(),
      );
    });
  });
}
