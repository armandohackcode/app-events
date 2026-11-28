import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinWinStatus', () {
    test('fromValue maps known values and defaults to pending', () {
      expect(SpinWinStatus.fromValue('pending'), SpinWinStatus.pending);
      expect(SpinWinStatus.fromValue('redeemed'), SpinWinStatus.redeemed);
      expect(SpinWinStatus.fromValue('revoked'), SpinWinStatus.revoked);
      expect(SpinWinStatus.fromValue(null), SpinWinStatus.pending);
      expect(SpinWinStatus.fromValue('unknown'), SpinWinStatus.pending);
    });
  });

  group('SpinWin', () {
    test('fromJson uses safe defaults for empty map', () {
      final win = SpinWin.fromJson({});

      expect(win.id, '');
      expect(win.eventId, '');
      expect(win.uid, '');
      expect(win.prizeSymbol, SpinSymbol.lemon);
      expect(win.prizeRarity, PrizeRarity.common);
      expect(win.status, SpinWinStatus.pending);
      expect(win.returnedToStock, isFalse);
      expect(win.wonAt, isNull);
    });

    test('qrPayload builds expected event-scoped QR string', () {
      const win = SpinWin(
        id: 'w-1',
        eventId: 'evt-1',
        uid: 'u-1',
        prizeId: 'sparky',
        prizeName: 'Sparky',
        prizeSymbol: SpinSymbol.star,
        code: 'GDG-7K9P2M',
      );

      expect(win.qrPayload, 'gdgspin:win:evt-1:GDG-7K9P2M');
    });

    test('round-trip toJson and fromJson preserves all fields', () {
      final original = SpinWin(
        id: 'w-1',
        eventId: 'evt-1',
        uid: 'u-1',
        winnerName: 'Ada',
        winnerPhotoUrl: 'https://example.com/ada.jpg',
        prizeId: 'sparky',
        prizeName: 'Sparky',
        prizeSymbol: SpinSymbol.star,
        prizeImageUrl: 'https://example.com/sparky.png',
        prizeRarity: PrizeRarity.epic,
        code: 'GDG-7K9P2M',
        status: SpinWinStatus.revoked,
        spinRequestId: 'req-12345678',
        wonAt: DateTime.utc(2026, 11, 28, 12),
        redeemedAt: DateTime.utc(2026, 11, 28, 12, 30),
        redeemedByUid: 'admin-1',
        redeemedByName: 'Staff',
        revokedAt: DateTime.utc(2026, 11, 28, 13),
        revokedByUid: 'admin-2',
        revokeReason: 'Duplicate check',
        returnedToStock: true,
      );

      final json = original.toJson();
      final restored = SpinWin.fromJson(json);

      expect(restored.toJson(), json);
    });

    test('copyWith clears nullable fields when flags are set', () {
      final original = SpinWin(
        id: 'w-1',
        eventId: 'evt-1',
        uid: 'u-1',
        prizeId: 'sparky',
        prizeName: 'Sparky',
        prizeSymbol: SpinSymbol.star,
        code: 'GDG-7K9P2M',
        prizeImageUrl: 'https://example.com/sparky.png',
        wonAt: DateTime.utc(2026, 11, 28, 12),
        redeemedAt: DateTime.utc(2026, 11, 28, 12, 30),
        redeemedByUid: 'admin-1',
        redeemedByName: 'Staff',
        revokedAt: DateTime.utc(2026, 11, 28, 13),
        revokedByUid: 'admin-2',
        revokeReason: 'Test',
      );

      final updated = original.copyWith(
        status: SpinWinStatus.redeemed,
        clearPrizeImageUrl: true,
        clearWonAt: true,
        clearRedeemedAt: true,
        clearRedeemedByUid: true,
        clearRedeemedByName: true,
        clearRevokedAt: true,
        clearRevokedByUid: true,
        clearRevokeReason: true,
      );

      expect(updated.status, SpinWinStatus.redeemed);
      expect(updated.prizeImageUrl, isNull);
      expect(updated.wonAt, isNull);
      expect(updated.redeemedAt, isNull);
      expect(updated.redeemedByUid, isNull);
      expect(updated.redeemedByName, isNull);
      expect(updated.revokedAt, isNull);
      expect(updated.revokedByUid, isNull);
      expect(updated.revokeReason, isNull);
    });
  });
}
