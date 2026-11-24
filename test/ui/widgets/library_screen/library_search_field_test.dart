import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/library_screen/library_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Future<void> pumpField(
    WidgetTester tester, {
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LibrarySearchField(
          controller: controller,
          onSubmitted: onSubmitted ?? (_) {},
          onClear: onClear ?? () {},
        ),
      ),
    ),
  );

  testWidgets('shows the hint and the search icon when empty', (tester) async {
    await pumpField(tester);

    expect(find.text(AppStrings.resourceLibrarySearchHint), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsNothing);
  });

  testWidgets('submitting reports the typed text', (tester) async {
    String? submitted;
    await pumpField(tester, onSubmitted: (value) => submitted = value);

    await tester.enterText(find.byType(TextFormField), 'flutter');
    await tester.testTextInput.receiveAction(TextInputAction.search);

    expect(submitted, 'flutter');
  });

  testWidgets('shows a clear button once there is text and reports it', (
    tester,
  ) async {
    var cleared = 0;
    await pumpField(tester, onClear: () => cleared++);

    await tester.enterText(find.byType(TextFormField), 'flutter');
    await tester.pump();

    expect(find.byIcon(Icons.clear), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));

    expect(cleared, 1);
  });
}
