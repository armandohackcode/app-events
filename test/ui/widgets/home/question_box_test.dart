import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/widgets/home/question_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('asks for the speaker by name', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: QuestionBox(speakerName: 'Grace')),
      ),
    );

    expect(
      find.text('${AppStrings.homeLiveQuestionHintPrefix}Grace...'),
      findsOneWidget,
    );
  });
}
