import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/ui/widgets/shared/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const items = [
    FloatingNavItem(icon: AppAssetsPath.iconHome, label: 'Home'),
    FloatingNavItem(icon: AppAssetsPath.iconLibrary, label: 'Library'),
    FloatingNavItem(icon: AppAssetsPath.iconProfile, label: 'Profile'),
  ];

  Future<void> pumpBar(
    WidgetTester tester, {
    int currentIndex = 0,
    ValueChanged<int>? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: FloatingNavBar(
          items: items,
          currentIndex: currentIndex,
          onTap: onTap ?? (_) {},
        ),
      ),
    ),
  );

  testWidgets('shows a label for every destination', (tester) async {
    await pumpBar(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('tapping a destination reports its index', (tester) async {
    int? tapped;
    await pumpBar(tester, onTap: (index) => tapped = index);

    await tester.tap(find.text('Profile'));

    expect(tapped, 2);
  });

  testWidgets('only the selected destination is fully opaque', (tester) async {
    await pumpBar(tester, currentIndex: 1);

    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .map((o) => o.opacity)
        .toList();

    expect(opacities, [0.45, 1.0, 0.45]);
  });
}
