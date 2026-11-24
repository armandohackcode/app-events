import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/library_screen/resource_category_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpTiles(
    WidgetTester tester, {
    String? selectedType,
    ValueChanged<String?>? onSelected,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ResourceCategoryTiles(
          selectedType: selectedType,
          onSelected: onSelected ?? (_) {},
        ),
      ),
    ),
  );

  testWidgets('shows the title and the swipe hint', (tester) async {
    await pumpTiles(tester);

    expect(find.text(AppStrings.resourceLibraryExplore), findsOneWidget);
    expect(find.text(AppStrings.resourceLibrarySwipeHint), findsOneWidget);
  });

  testWidgets('shows All, Mobile and AI tiles', (tester) async {
    await pumpTiles(tester);

    expect(find.text(AppStrings.organizersFilterAll), findsOneWidget);
    expect(find.text(AppStrings.technologyMobile), findsOneWidget);
    expect(find.text(AppStrings.technologyAI), findsOneWidget);
  });

  testWidgets('tapping a tile reports its technology', (tester) async {
    String? received = 'unset';
    await pumpTiles(tester, onSelected: (type) => received = type);

    await tester.tap(find.text(AppStrings.technologyMobile));

    expect(received, AppStrings.technologyMobile);
  });

  testWidgets('tapping All reports null', (tester) async {
    String? received = 'unset';
    await pumpTiles(
      tester,
      selectedType: AppStrings.technologyMobile,
      onSelected: (type) => received = type,
    );

    await tester.tap(find.text(AppStrings.organizersFilterAll));

    expect(received, isNull);
  });

  testWidgets('scrolls sideways to reach the last tile', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpTiles(tester);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.technologyUIUX), findsOneWidget);
  });
}
