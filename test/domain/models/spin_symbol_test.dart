import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinSymbol', () {
    test('fromValue maps every enum value by name', () {
      for (final symbol in SpinSymbol.values) {
        expect(SpinSymbol.fromValue(symbol.value), symbol);
      }
    });

    test('fromValue falls back to lemon for null or unknown values', () {
      expect(SpinSymbol.fromValue(null), SpinSymbol.lemon);
      expect(SpinSymbol.fromValue('unknown'), SpinSymbol.lemon);
      expect(SpinSymbol.fromValue('SEVEN'), SpinSymbol.lemon);
    });
  });
}
