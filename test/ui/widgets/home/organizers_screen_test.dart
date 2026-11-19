import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/widgets/home/organizers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockOtherRepository extends Mock implements OtherRepository {}

Organizer _makeOrganizer({
  required int id,
  required String name,
  List<String> team = const [],
  bool lead = false,
}) => Organizer(
  id: id,
  type: 1,
  name: name,
  photoUrl: '',
  link: '',
  team: team,
  lead: lead,
);

void main() {
  late _MockOtherRepository otherRepo;
  late OtherProvider otherProvider;

  setUp(() {
    otherRepo = _MockOtherRepository();
    otherProvider = OtherProvider(otherRepo);
  });

  tearDown(() {
    otherProvider.dispose();
  });

  Widget wrapScreen({Size size = const Size(390, 844), double scale = 1.0}) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: true,
        textScaler: TextScaler.linear(scale),
      ),
      child: ChangeNotifierProvider.value(
        value: otherProvider,
        child: const MaterialApp(home: OrganizersScreen()),
      ),
    );
  }

  testWidgets(
    'groups organizers, shows LEAD/CO-LEAD badges and initials fallback',
    (tester) async {
      final sample = [
        _makeOrganizer(id: 1, name: 'Ada Lovelace', lead: true),
        _makeOrganizer(id: 2, name: 'Grace Hopper', team: ['Co-lead']),
        _makeOrganizer(id: 3, name: 'Alan Turing', team: ['UI UX Design']),
        _makeOrganizer(id: 4, name: 'Linus Torvalds', team: ['Mobile']),
        _makeOrganizer(id: 5, name: 'Margaret Hamilton', team: ['Marketing']),
      ];
      when(() => otherRepo.getOrganizer()).thenAnswer((_) async => sample);

      await tester.pumpWidget(wrapScreen());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.organizersGDGSucre), findsOneWidget);
      expect(find.text(AppStrings.organizersTagLead), findsOneWidget);
      expect(find.text(AppStrings.organizersTagCoLead), findsOneWidget);
      expect(find.text(AppStrings.organizersSectionDesign), findsOneWidget);
      expect(find.text(AppStrings.organizersSectionCommunity), findsOneWidget);
      expect(find.text('AL'), findsOneWidget);
      expect(find.text('GH'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Linus Torvalds'), findsOneWidget);
    },
  );

  testWidgets(
    'filters by search query and category chips, and clears empty state',
    (tester) async {
      final sample = [
        _makeOrganizer(id: 1, name: 'Ada Lovelace', lead: true),
        _makeOrganizer(id: 2, name: 'Linus Torvalds', team: ['Web']),
        _makeOrganizer(id: 3, name: 'Margaret Hamilton', team: ['Marketing']),
      ];
      when(() => otherRepo.getOrganizer()).thenAnswer((_) async => sample);

      await tester.pumpWidget(wrapScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.organizersFilterDevelopment).first);
      await tester.pumpAndSettle();

      expect(find.text('Linus Torvalds'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsNothing);
      expect(find.text('Margaret Hamilton'), findsNothing);

      await tester.tap(find.text(AppStrings.organizersFilterAll));
      await tester.pumpAndSettle();
      expect(find.text('Ada Lovelace'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'no-match-term');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.organizersEmptySearch), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Ada Lovelace'), findsOneWidget);
    },
  );

  testWidgets(
    'collapses large groups to 7 plus counter and expands on tap without overflow',
    (tester) async {
      final devs = List.generate(
        9,
        (i) => _makeOrganizer(
          id: i + 10,
          name: 'Developer Member $i',
          team: ['Mobile'],
        ),
      );
      when(() => otherRepo.getOrganizer()).thenAnswer((_) async => devs);

      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapScreen(size: const Size(320, 844), scale: 1.3),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.organizersMoreCount(2)), findsOneWidget);
      expect(find.text('Developer Member 8'), findsNothing);

      final moreTile = find.text(AppStrings.organizersSeeAll);
      await tester.ensureVisible(moreTile);
      await tester.pumpAndSettle();
      await tester.tap(moreTile);
      await tester.pumpAndSettle();

      expect(find.text('Developer Member 8'), findsOneWidget);
      expect(find.text(AppStrings.organizersSeeLess), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
