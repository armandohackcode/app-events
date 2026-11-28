import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinTicketCode', () {
    test(
      'fromJson uses safe defaults for empty map and normalizes code to uppercase',
      () {
        final empty = SpinTicketCode.fromJson({});
        expect(empty.id, '');
        expect(empty.code, '');
        expect(empty.label, '');
        expect(empty.rewardTickets, 1);
        expect(empty.maxTotalUses, 1);
        expect(empty.usedCount, 0);
        expect(empty.maxUsesPerUser, 1);
        expect(empty.active, isFalse);

        final normalized = SpinTicketCode.fromJson({'code': 'cloud26'});
        expect(normalized.code, 'CLOUD26');
      },
    );

    test('qrPayload builds event-scoped QR string', () {
      const code = SpinTicketCode(
        id: 'c-1',
        code: 'CLOUD26',
        label: 'Google Cloud Booth',
      );
      expect(code.qrPayload('evt-1'), 'gdgspin:code:evt-1:CLOUD26');
    });

    test('round-trip toJson and fromJson preserves all fields', () {
      final original = SpinTicketCode(
        id: 'c-1',
        code: 'CLOUD26',
        label: 'Google Cloud Booth',
        rewardTickets: 2,
        maxTotalUses: 100,
        usedCount: 25,
        maxUsesPerUser: 1,
        active: true,
        startsAt: DateTime.utc(2026, 11, 28, 9),
        endsAt: DateTime.utc(2026, 11, 28, 18),
        createdAt: DateTime.utc(2026, 11, 28, 8),
        createdBy: 'admin-1',
      );

      final json = original.toJson();
      final restored = SpinTicketCode.fromJson(json);

      expect(restored.toJson(), json);
    });

    test('copyWith updates given fields and clears nullable fields', () {
      final original = SpinTicketCode(
        id: 'c-1',
        code: 'CLOUD26',
        label: 'Google Cloud Booth',
        startsAt: DateTime.utc(2026, 11, 28, 9),
        endsAt: DateTime.utc(2026, 11, 28, 18),
        createdAt: DateTime.utc(2026, 11, 28, 8),
      );

      final updated = original.copyWith(
        active: true,
        clearStartsAt: true,
        clearEndsAt: true,
        clearCreatedAt: true,
      );

      expect(updated.active, isTrue);
      expect(updated.startsAt, isNull);
      expect(updated.endsAt, isNull);
      expect(updated.createdAt, isNull);
    });
  });
}
