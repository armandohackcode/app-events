import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/talk_rating.dart';
import 'package:app_events/domain/repositories/talk_interaction_repository.dart';
import 'package:app_events/ui/providers/talk_interaction_provider.dart';
import 'package:app_events/ui/widgets/schedule_screen/talk_rating_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockTalkInteractionRepository extends Mock
    implements TalkInteractionRepository {}

void main() {
  late _MockTalkInteractionRepository repository;
  late TalkInteractionProvider provider;

  setUp(() {
    repository = _MockTalkInteractionRepository();
    provider = TalkInteractionProvider(repository);
  });

  tearDown(() => provider.dispose());

  Widget wrap(Widget child) => MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );

  testWidgets('requires selecting at least 1 star before submitting', (
    tester,
  ) async {
    when(
      () => repository.watchMyRating('evt-1', 'spk-1', 'u1'),
    ).thenAnswer((_) => const Stream<TalkRating?>.empty());

    await tester.pumpWidget(
      wrap(
        const TalkRatingCard(eventId: 'evt-1', speakerUuid: 'spk-1', uid: 'u1'),
      ),
    );

    await tester.tap(find.text(AppStrings.talkRatingSubmit));
    await tester.pump();

    expect(find.text(AppStrings.talkRatingSelectStars), findsOneWidget);
    verifyNever(
      () => repository.submitRating(
        eventId: any(named: 'eventId'),
        speakerUuid: any(named: 'speakerUuid'),
        stars: any(named: 'stars'),
        comment: any(named: 'comment'),
      ),
    );
  });

  testWidgets(
    'selects stars, submits comment, and shows ticket popup when rewarded',
    (tester) async {
      when(
        () => repository.watchMyRating('evt-1', 'spk-1', 'u1'),
      ).thenAnswer((_) => const Stream<TalkRating?>.empty());
      when(
        () => repository.submitRating(
          eventId: 'evt-1',
          speakerUuid: 'spk-1',
          stars: 5,
          comment: 'Great live demo',
        ),
      ).thenAnswer(
        (_) async => const TalkRatingSubmitResult(
          saved: true,
          missionRewarded: true,
          ticketsAwarded: 1,
          ticketsAfter: 3,
          ticketSerial: 'RT990011',
        ),
      );

      await tester.pumpWidget(
        wrap(
          const TalkRatingCard(
            eventId: 'evt-1',
            speakerUuid: 'spk-1',
            uid: 'u1',
          ),
        ),
      );

      // Tap the 5th outline star icon.
      await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
      await tester.pump();
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));

      await tester.enterText(find.byType(TextField), 'Great live demo');
      await tester.tap(find.text(AppStrings.talkRatingSubmit));
      await tester.pump();
      await tester.pump();

      expect(find.text(AppStrings.talkRatingSaved), findsOneWidget);
      expect(find.text(AppStrings.talkRatingUpdate), findsOneWidget);
      expect(find.text(AppStrings.spinTicketWon), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2900));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('pre-fills existing rating from watchMyRating stream', (
    tester,
  ) async {
    final controller = StreamController<TalkRating?>.broadcast();
    addTearDown(controller.close);

    when(
      () => repository.watchMyRating('evt-1', 'spk-1', 'u1'),
    ).thenAnswer((_) => controller.stream);

    await tester.pumpWidget(
      wrap(
        const TalkRatingCard(eventId: 'evt-1', speakerUuid: 'spk-1', uid: 'u1'),
      ),
    );

    controller.add(
      const TalkRating(uid: 'u1', stars: 4, comment: 'Very informative'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.text('Very informative'), findsOneWidget);
    expect(find.text(AppStrings.talkRatingUpdate), findsOneWidget);
  });
}
