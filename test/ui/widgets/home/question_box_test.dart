import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/talk_question.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/domain/repositories/talk_interaction_repository.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/talk_interaction_provider.dart';
import 'package:app_events/ui/widgets/home/question_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockTalkInteractionRepository extends Mock
    implements TalkInteractionRepository {}

class _MockSpinRepository extends Mock implements SpinRepository {}

void main() {
  late _MockTalkInteractionRepository repository;
  late TalkInteractionProvider provider;

  setUp(() {
    repository = _MockTalkInteractionRepository();
    provider = TalkInteractionProvider(repository);
  });

  tearDown(() => provider.dispose());

  Widget wrap(Widget child, {GdgSpinProvider? spinProvider}) => MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        if (spinProvider != null)
          ChangeNotifierProvider.value(value: spinProvider),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );

  testWidgets('asks for the speaker by name without requiring providers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: QuestionBox(speakerName: 'Grace')),
      ),
    );

    expect(
      find.text('${AppStrings.homeLiveQuestionHintPrefix}Grace...'),
      findsOneWidget,
    );

    // Tapping send or submitting without event/provider context does not crash.
    await tester.enterText(find.byType(TextField), 'Question without context');
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('validates minimum length of 10 characters before sending', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const QuestionBox(
          speakerName: 'Grace',
          eventId: 'evt-1',
          speakerUuid: 'spk-1',
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Short?');
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();

    expect(find.text(AppStrings.talkQuestionMinLength), findsOneWidget);
    verifyNever(
      () => repository.submitQuestion(
        eventId: any(named: 'eventId'),
        speakerUuid: any(named: 'speakerUuid'),
        text: any(named: 'text'),
      ),
    );
  });

  testWidgets(
    'submits question, clears text, syncs spin tickets, and shows ticket popup when rewarded',
    (tester) async {
      final spinRepo = _MockSpinRepository();
      when(
        () => spinRepo.watchConfig(any()),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchPrizes(any(), activeOnly: any(named: 'activeOnly')),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () =>
            spinRepo.watchMissions(any(), activeOnly: any(named: 'activeOnly')),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchPlayer(any(), any()),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchMyWins(any(), any()),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => spinRepo.watchMyMissionClaims(any(), any()),
      ).thenAnswer((_) => const Stream.empty());
      when(() => spinRepo.initPlayer(any())).thenAnswer(
        (_) async => const SpinInitPlayerResult(
          player: SpinPlayer(uid: 'u1', tickets: 3),
          initialGranted: false,
        ),
      );
      final spinProvider = GdgSpinProvider(spinRepo);
      addTearDown(spinProvider.dispose);
      await spinProvider.bind(eventId: 'evt-1', uid: 'u1');

      when(
        () => repository.submitQuestion(
          eventId: 'evt-1',
          speakerUuid: 'spk-1',
          text: 'How do you manage cold starts on Cloud Run?',
        ),
      ).thenAnswer(
        (_) async => const TalkQuestionSubmitResult(
          questionId: 'q1',
          missionRewarded: true,
          ticketsAwarded: 1,
          ticketsAfter: 4,
          ticketSerial: 'Q1002003',
        ),
      );

      await tester.pumpWidget(
        wrap(
          const QuestionBox(
            speakerName: 'Grace',
            eventId: 'evt-1',
            speakerUuid: 'spk-1',
          ),
          spinProvider: spinProvider,
        ),
      );

      await tester.enterText(
        find.byType(TextField),
        'How do you manage cold starts on Cloud Run?',
      );
      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pump();
      await tester.pump();

      expect(find.text(AppStrings.talkQuestionSent), findsOneWidget);
      expect(find.text(AppStrings.spinTicketWon), findsOneWidget);
      expect(spinProvider.tickets, 4);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, isEmpty);

      await tester.pump(const Duration(milliseconds: 2900));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('shows rate limit feedback when server rejects rapid questions', (
    tester,
  ) async {
    when(
      () => repository.submitQuestion(
        eventId: 'evt-1',
        speakerUuid: 'spk-1',
        text: 'Second rapid question right after first one',
      ),
    ).thenAnswer(
      (_) async => throw const SpinException(
        reason: SpinErrorReason.rateLimited,
        code: 'resource-exhausted',
        message: 'too fast',
      ),
    );

    await tester.pumpWidget(
      wrap(
        const QuestionBox(
          speakerName: 'Grace',
          eventId: 'evt-1',
          speakerUuid: 'spk-1',
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField),
      'Second rapid question right after first one',
    );
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();
    await tester.pump();

    expect(find.text(AppStrings.talkQuestionRateLimited), findsOneWidget);
  });
}
