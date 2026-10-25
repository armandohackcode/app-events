import 'package:app_events/ui/widgets/utils/modal_confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<bool?> openModal(WidgetTester tester, String button) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) =>
                    const ModalConfirm(text: 'Delete this sponsor?'),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this sponsor?'), findsOneWidget);

    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('returns true when the user confirms', (tester) async {
    expect(await openModal(tester, 'SI'), isTrue);
    expect(find.byType(ModalConfirm), findsNothing);
  });

  testWidgets('returns false when the user cancels', (tester) async {
    expect(await openModal(tester, 'NO'), isFalse);
  });
}
