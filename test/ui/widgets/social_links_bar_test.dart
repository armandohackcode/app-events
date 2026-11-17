import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/shared/social_links_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SocialNetwork _network(String type, [String link = 'https://example.com']) =>
    SocialNetwork(type: type, link: link);

void main() {
  Future<void> pumpBar(WidgetTester tester, List<SocialNetwork> networks) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SocialLinksBar(networks: networks),
            ),
          ),
        ),
      );

  testWidgets('renders nothing when no network has a link', (tester) async {
    await pumpBar(tester, [_network('GITHUB', ''), _network('INSTAGRAM', ' ')]);

    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('a single network is an oval button with its label', (
    tester,
  ) async {
    await pumpBar(tester, [_network('GITHUB')]);

    expect(find.byType(Tooltip), findsOneWidget);
    expect(find.text('Github'), findsOneWidget);
  });

  testWidgets('two networks share the width as labelled ovals', (tester) async {
    await pumpBar(tester, [_network('INSTAGRAM'), _network('LINKEDIN')]);

    expect(find.byType(Tooltip), findsNWidgets(2));
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Linkedin'), findsOneWidget);
  });

  testWidgets('three or more networks are round buttons without labels', (
    tester,
  ) async {
    await pumpBar(tester, [
      _network('INSTAGRAM'),
      _network('LINKEDIN'),
      _network('TIKTOK'),
      _network('GITHUB'),
    ]);

    expect(find.byType(Tooltip), findsNWidgets(4));
    expect(find.text('Instagram'), findsNothing);
  });

  testWidgets('skips networks without a link when counting', (tester) async {
    await pumpBar(tester, [
      _network('INSTAGRAM'),
      _network('LINKEDIN'),
      _network('TIKTOK', ''),
    ]);

    expect(find.byType(Tooltip), findsNWidgets(2));
    expect(find.text('Instagram'), findsOneWidget);
  });

  testWidgets('network types are matched case-insensitively', (tester) async {
    await pumpBar(tester, [_network('github')]);

    expect(find.text('Github'), findsOneWidget);
  });
}
