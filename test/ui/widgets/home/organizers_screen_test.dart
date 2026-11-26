import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/home/organizers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockOtherRepository extends Mock implements OtherRepository {}

class _MockUserProvider extends Mock implements UserProvider {}

Organizer _makeOrganizer({
  String? id,
  required String name,
  List<String> team = const [],
  int type = 1,
}) => Organizer(
  id: id,
  type: type,
  name: name,
  photoUrl: '',
  link: '',
  team: team,
);

void main() {
  late _MockOtherRepository otherRepo;
  late OtherProvider otherProvider;
  late _MockUserProvider userProvider;

  setUp(() {
    otherRepo = _MockOtherRepository();
    otherProvider = OtherProvider(otherRepo);
    userProvider = _MockUserProvider();
    when(() => userProvider.isAdmin).thenReturn(false);
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
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<OtherProvider>.value(value: otherProvider),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ],
        child: const MaterialApp(home: OrganizersScreen()),
      ),
    );
  }

  testWidgets(
    'groups dynamically by real teams, excludes role tags from chips, and shows LEAD/CO-LEAD',
    (tester) async {
      final sample = [
        _makeOrganizer(id: '1', name: 'Ada Lovelace', team: ['App'], type: 2),
        _makeOrganizer(
          id: '2',
          name: 'Grace Hopper',
          team: ['Co-lead', 'Web'],
          type: 1,
        ),
        _makeOrganizer(
          id: '3',
          name: 'Alan Turing',
          team: [AppStrings.organizersTeamDesign.replaceAll('\u00f1', 'n')],
          type: 1,
        ),
        _makeOrganizer(id: '4', name: 'Linus Torvalds', team: ['IA']),
        _makeOrganizer(
          id: '5',
          name: 'Margaret Hamilton',
          team: ['Marketing', 'Sponsors'],
        ),
      ];
      when(() => otherRepo.getOrganizer()).thenAnswer((_) async => sample);

      await tester.pumpWidget(wrapScreen());
      await tester.pumpAndSettle();

      // Community channels match Home (WhatsApp, Instagram, Facebook, TikTok, Web)
      expect(find.text(AppStrings.homeChannelWhatsApp), findsOneWidget);
      expect(find.text(AppStrings.homeChannelFacebook), findsOneWidget);
      expect(find.text(AppStrings.homeChannelTikTok), findsOneWidget);

      // Role badges shown; role tags do not create a "Co-lead" team chip
      expect(find.text(AppStrings.organizersTagLead), findsOneWidget);
      expect(find.text(AppStrings.organizersTagCoLead), findsOneWidget);
      expect(find.text('Co-lead'), findsNothing);

      // Teams with members appear (known teams normalized + new dynamic "IA" team)
      expect(find.text(AppStrings.organizersTeamApp), findsNWidgets(2));
      expect(find.text(AppStrings.organizersTeamDesign), findsNWidgets(2));
      // Web appears in channel label + filter chip + section header
      expect(find.text(AppStrings.organizersTeamWeb), findsNWidgets(3));
      expect(find.text('IA'), findsNWidgets(2));

      // Empty teams (e.g. Logistics, Accreditation) are not rendered
      expect(find.text(AppStrings.organizersTeamLogistics), findsNothing);
      expect(find.text(AppStrings.organizersTeamAccreditation), findsNothing);

      // Multi-team member appears in both Marketing and Sponsors
      expect(find.text('Margaret Hamilton'), findsNWidgets(2));

      // Initials fallback
      expect(find.text('AL'), findsOneWidget);
      expect(find.text('GH'), findsOneWidget);
    },
  );

  testWidgets(
    'combines team filter and search query cleanly, and resets with Todos',
    (tester) async {
      final sample = [
        _makeOrganizer(id: '1', name: 'Ada Lovelace', team: ['App']),
        _makeOrganizer(id: '2', name: 'Linus Torvalds', team: ['Web']),
        _makeOrganizer(id: '3', name: 'Grace Hopper', team: ['Web']),
        _makeOrganizer(id: '4', name: 'Margaret Hamilton', team: ['Marketing']),
      ];
      when(() => otherRepo.getOrganizer()).thenAnswer((_) async => sample);

      await tester.pumpWidget(wrapScreen());
      await tester.pumpAndSettle();

      // Filter by Web (target the filter chip InkWell, not the channel label)
      final webChip = find.ancestor(
        of: find.text(AppStrings.organizersTeamWeb),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(webChip);
      await tester.pumpAndSettle();
      await tester.tap(webChip);
      await tester.pumpAndSettle();

      expect(find.text('Linus Torvalds'), findsOneWidget);
      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsNothing);
      expect(find.text('Margaret Hamilton'), findsNothing);

      // Combine with search inside Web
      await tester.enterText(find.byType(TextField), 'Grace');
      await tester.pumpAndSettle();
      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('Linus Torvalds'), findsNothing);

      // Empty state when search has no match
      await tester.enterText(find.byType(TextField), 'no-match-term');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.organizersEmptySearch), findsOneWidget);

      // Clear search and return to All
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      final allChip = find.text(AppStrings.organizersFilterAll);
      await tester.ensureVisible(allChip);
      await tester.pumpAndSettle();
      await tester.tap(allChip);
      await tester.pumpAndSettle();
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Margaret Hamilton'), findsOneWidget);
    },
  );

  testWidgets(
    'renders filter chips in a horizontal strip and aligns names across LEAD and regular tiles',
    (tester) async {
      final sample = [
        _makeOrganizer(id: '1', name: 'Lead Member', team: ['App']),
        _makeOrganizer(id: '2', name: 'Regular Member', team: ['App']),
      ];
      when(() => otherRepo.getOrganizer()).thenAnswer((_) async => sample);

      await tester.pumpWidget(wrapScreen());
      await tester.pumpAndSettle();

      final horizontalFilterScroll = find.ancestor(
        of: find.text(AppStrings.organizersFilterAll),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      );
      expect(horizontalFilterScroll, findsOneWidget);

      final leadNameDy = tester.getTopLeft(find.text('Lead Member')).dy;
      final regularNameDy = tester.getTopLeft(find.text('Regular Member')).dy;
      expect(leadNameDy, regularNameDy);
    },
  );

  testWidgets(
    'collapses large groups to 7 plus counter and expands on tap without overflow',
    (tester) async {
      final devs = List.generate(
        9,
        (i) => _makeOrganizer(
          id: (i + 10).toString(),
          name: 'Developer Member $i',
          team: ['App'],
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

  testWidgets('handles empty organizer list and organizers without a team', (
    tester,
  ) async {
    when(() => otherRepo.getOrganizer()).thenAnswer((_) async => []);

    await tester.pumpWidget(wrapScreen());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.organizersEmptyState), findsOneWidget);

    otherProvider.organizers = [
      _makeOrganizer(id: '99', name: 'Lead Without Team', type: 2),
    ];
    await tester.pumpAndSettle();

    expect(find.text('Lead Without Team'), findsOneWidget);
    expect(find.text(AppStrings.organizersFilterLeadership), findsNWidgets(2));
  });
}
