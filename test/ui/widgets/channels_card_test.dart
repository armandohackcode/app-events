import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/home/channels_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the title and the five community channels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ChannelsCard())),
      ),
    );

    expect(find.text(AppStrings.homeChannelsTitle), findsOneWidget);
    expect(find.text(AppStrings.homeChannelWhatsApp), findsOneWidget);
    expect(find.text(AppStrings.homeChannelInstagram), findsOneWidget);
    expect(find.text(AppStrings.homeChannelFacebook), findsOneWidget);
    expect(find.text(AppStrings.homeChannelTikTok), findsOneWidget);
    expect(find.text(AppStrings.homeChannelWeb), findsOneWidget);
  });

  testWidgets('fits a narrow screen without overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ChannelsCard())),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
