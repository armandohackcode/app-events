import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:app_events/ui/widgets/speed_run/card_challenge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  Future<int> pumpAndTap(WidgetTester tester, SpeedRunChallenge c) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardChallenge(challenge: c, onTap: () => taps++),
        ),
      ),
    );
    await tester.tap(find.text(c.title));
    return taps;
  }

  testWidgets('active challenge is tappable and fully opaque', (tester) async {
    final taps = await pumpAndTap(tester, makeChallenge());

    expect(taps, 1);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1.0);
  });

  testWidgets('inactive challenge is dimmed and ignores taps', (tester) async {
    final taps = await pumpAndTap(
      tester,
      makeChallenge(state: ChallengeState.inactive),
    );

    expect(taps, 0);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
  });
}
