import 'package:app_events/ui/widgets/gdg_spin/spin_haptics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SpinHaptics.channel, null);
  });

  test(
    'invokes native win pattern and bonus pulse on the haptics channel',
    () async {
      final invokedMethods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SpinHaptics.channel, (call) async {
            invokedMethods.add(call.method);
            return null;
          });

      await SpinHaptics.celebrateWin(isPrize: true);
      await SpinHaptics.celebrateWin(isPrize: false);

      expect(invokedMethods, ['playWinPattern', 'playBonusPulse']);
    },
  );

  test('falls back safely when no native haptics handler exists', () async {
    await expectLater(SpinHaptics.celebrateWin(isPrize: true), completes);
    await expectLater(SpinHaptics.celebrateWin(isPrize: false), completes);
  });
}
