import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/library_screen/resource_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    String title = 'Flutter documentation',
    String link = 'https://www.docs.flutter.dev/get-started',
    String type = 'Mobile',
    String? description = 'Guides, widgets and API references.',
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ResourceCard(
            title: title,
            link: link,
            type: type,
            description: description,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    ),
  );

  testWidgets('shows type, title, description, site and open action', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('MOBILE'), findsOneWidget);
    expect(find.text('Flutter documentation'), findsOneWidget);
    expect(find.text('Guides, widgets and API references.'), findsOneWidget);
    expect(find.text('docs.flutter.dev'), findsOneWidget);
    expect(find.text(AppStrings.resourceLibraryOpen), findsOneWidget);
  });

  testWidgets('hides the description when there is none', (tester) async {
    await pumpCard(tester, description: null);

    expect(find.text('Guides, widgets and API references.'), findsNothing);
    expect(find.text('Flutter documentation'), findsOneWidget);
  });

  testWidgets('hides the description when it is blank', (tester) async {
    await pumpCard(tester, description: '   ');

    expect(tester.takeException(), isNull);
    expect(find.text('   '), findsNothing);
  });

  testWidgets('shows the whole link when it has no host', (tester) async {
    await pumpCard(tester, link: 'not a link');

    expect(find.text('not a link'), findsOneWidget);
  });

  testWidgets('tapping the card calls onTap', (tester) async {
    var taps = 0;
    await pumpCard(tester, onTap: () => taps++);

    await tester.tap(find.text('Flutter documentation'));

    expect(taps, 1);
  });

  testWidgets('long title, description and type do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final long = List.filled(40, 'extraordinarily').join(' ');
    await pumpCard(
      tester,
      title: long,
      description: long,
      type: 'Artificial intelligence and machine learning',
      link: 'https://${List.filled(10, 'subdomain').join('.')}.example.com',
    );

    expect(tester.takeException(), isNull);
  });
}
