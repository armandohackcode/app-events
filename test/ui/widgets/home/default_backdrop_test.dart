import 'dart:async';
import 'dart:math';

import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/config/theme/app_theme.dart';
import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/resource_library.dart';
import 'package:app_events/domain/models/treasure_hunt_model.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/domain/repositories/resource_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:app_events/domain/repositories/speed_run_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/resources_provider.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/speed_run_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/activities/activities_screen.dart';
import 'package:app_events/ui/screens/events/events_screen.dart';
import 'package:app_events/ui/screens/gdg_spin/gdg_spin_screen.dart';
import 'package:app_events/ui/screens/resources/library_screen.dart';
import 'package:app_events/ui/screens/schedule/schedule_detail.dart';
import 'package:app_events/ui/screens/schedule/schedule_screen.dart';
import 'package:app_events/ui/screens/speed_run/add_challenge_screen.dart';
import 'package:app_events/ui/screens/speed_run/challenge_detail_screen.dart';
import 'package:app_events/ui/screens/speed_run/speed_run_screen.dart';
import 'package:app_events/ui/screens/user/attendees_screen.dart';
import 'package:app_events/ui/screens/user/delete_account.dart';
import 'package:app_events/ui/screens/user/profile_screen.dart';
import 'package:app_events/ui/screens/user/sing_in_screen.dart';
import 'package:app_events/ui/widgets/events/add_event.dart';
import 'package:app_events/ui/widgets/events/edit_event.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/home/organizers_screen.dart';
import 'package:app_events/ui/widgets/home/ranking_data.dart';
import 'package:app_events/ui/widgets/home/treasure_bunt.dart';
import 'package:app_events/ui/widgets/library_screen/add_resource.dart';
import 'package:app_events/ui/widgets/profile/edit_profile.dart';
import 'package:app_events/ui/widgets/schedule_screen/add_schedule.dart';
import 'package:app_events/ui/widgets/schedule_screen/edit_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fixtures.dart';

class _MockOtherRepository extends Mock implements OtherRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockResourceRepository extends Mock implements ResourceRepository {}

class _MockEventRepository extends Mock implements EventRepository {}

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockSpeedRunRepository extends Mock implements SpeedRunRepository {}

UserCompetitor _competitor(
  String name,
  int score, {
  List<Friend> friends = const [],
}) => UserCompetitor(
  uuid: name,
  name: name,
  photoUrl: '',
  profession: 'Dev',
  aboutMe: '',
  tokenAuthorization: '',
  score: score,
  socialNetwork: const [],
  friends: friends,
  treasures: const [],
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    registerFallbackValue(_competitor('fallback', 0));
  });

  test('AppTheme uses homeBackgroundColor as default scaffold background', () {
    final theme = AppTheme().getTheme();
    expect(theme.scaffoldBackgroundColor, AppStyles.homeBackgroundColor);
    expect(theme.appBarTheme.backgroundColor, AppStyles.homeBackgroundColor);
  });

  testWidgets(
    'All app screens use HomeBackdrop and render cleanly without overflow',
    (tester) async {
      final otherRepo = _MockOtherRepository();
      final userRepo = _MockUserRepository();
      final authRepo = _MockAuthRepository();
      final resourceRepo = _MockResourceRepository();
      final eventRepo = _MockEventRepository();
      final scheduleRepo = _MockScheduleRepository();
      final speedRunRepo = _MockSpeedRunRepository();

      final rankingController = StreamController<List<UserCompetitor>>();
      final eventsController = StreamController<List<Event>>();
      final userController = StreamController<UserCompetitor?>();
      addTearDown(rankingController.close);
      addTearDown(eventsController.close);
      addTearDown(userController.close);

      when(() => otherRepo.getTreasureHuntItems()).thenAnswer(
        (_) async => [
          TreasureHuntModel(
            uuid: 't1',
            title: 'Treasure 1',
            imgPath: 'assets/img/trofeo.png',
            question: 'Q?',
            answer: 'A',
            description: 'D',
          ),
        ],
      );
      when(() => otherRepo.getOrganizer()).thenAnswer(
        (_) async => [
          Organizer(
            id: 1,
            type: 1,
            name: 'Ada Lovelace',
            photoUrl: 'https://example.com/ada.png',
            link: 'https://gdg.community.dev',
            team: ['Mobile', 'Web'],
            lead: true,
          ),
        ],
      );
      when(
        () => otherRepo.getRanking(),
      ).thenAnswer((_) => rankingController.stream);
      when(
        () => resourceRepo.getResources(),
      ).thenAnswer((_) async => <ResourceLibrary>[]);
      when(
        () => eventRepo.getEventsStream(),
      ).thenAnswer((_) => eventsController.stream);
      when(
        () => scheduleRepo.getListSchedule(any()),
      ).thenAnswer((_) async => [makeSpeaker()]);
      when(
        () => speedRunRepo.getChallenges(),
      ).thenAnswer((_) async => [makeChallenge()]);
      when(
        () => userRepo.streamInfoUser(any()),
      ).thenAnswer((_) => userController.stream);
      when(
        () => userRepo.getAttendees(),
      ).thenAnswer((_) async => [_competitor('Ada', 42)]);

      final otherProvider = OtherProvider(otherRepo);
      final userProvider = UserProvider(userRepo)
        ..userCompetitor = _competitor(
          'Ada',
          42,
          friends: [
            Friend(uuid: 'f1', name: 'Grace Hopper', photoUrl: '', token: ''),
          ],
        );
      final authProvider = SignInSocialNetworkProvider(
        authRepo,
        userProvider,
      )..userInfo = const AuthUser(uid: 'u1', displayName: 'Ada', photoUrl: '');
      final spinProvider = GdgSpinProvider(random: Random(1));
      final resourcesProvider = ResourcesProvider(resourceRepo);
      final eventProvider = EventProvider(eventRepo);
      final scheduleProvider = ScheduleProvider(scheduleRepo);
      final speedRunProvider = SpeedRunProvider(speedRunRepo);

      addTearDown(() {
        otherProvider.dispose();
        userProvider.dispose();
        authProvider.dispose();
        spinProvider.dispose();
        resourcesProvider.dispose();
        eventProvider.dispose();
        scheduleProvider.dispose();
        speedRunProvider.dispose();
      });

      Widget wrap(
        Widget screen, {
        Size size = const Size(390, 844),
        double textScale = 1.0,
      }) => MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: otherProvider),
            ChangeNotifierProvider.value(value: userProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: spinProvider),
            ChangeNotifierProvider.value(value: resourcesProvider),
            ChangeNotifierProvider.value(value: eventProvider),
            ChangeNotifierProvider.value(value: scheduleProvider),
            ChangeNotifierProvider.value(value: speedRunProvider),
          ],
          child: MaterialApp(theme: AppTheme().getTheme(), home: screen),
        ),
      );

      final errors = <String>[];
      Future<void> check(
        String label,
        Widget screen, {
        Size size = const Size(390, 844),
        double textScale = 1.0,
        bool settle = true,
      }) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(wrap(screen, size: size, textScale: textScale));
        if (settle) {
          await tester.pumpAndSettle();
        } else {
          await tester.pump();
        }
        final ex = tester.takeException();
        if (ex != null) {
          errors.add('$label exception: $ex');
        }
        if (find.byType(HomeBackdrop).evaluate().isEmpty) {
          errors.add('$label missing HomeBackdrop');
        }
      }

      addTearDown(() => tester.binding.setSurfaceSize(null));

      await check('ActivitiesScreen', const ActivitiesScreen());
      await check('GdgSpinScreen', const GdgSpinScreen());

      await check('RankingData', const RankingData(), settle: false);
      rankingController.add([
        _competitor('First', 100),
        _competitor('Second', 80),
        _competitor('Third', 60),
      ]);
      await tester.pump();
      await tester.pump();
      expect(find.text('First'), findsOneWidget);
      if (tester.takeException() case final ex?) {
        errors.add('RankingData populated exception: $ex');
      }

      await check('TreasureBunt', const TreasureBunt());
      await check(
        'SignInScreen (320x568)',
        const SignInScreen(),
        size: const Size(320, 568),
      );
      await check(
        'ProfileScreen (320x844)',
        const ProfileScreen(),
        size: const Size(320, 844),
      );
      await check(
        'LibraryScreen (1.3x)',
        const LibraryScreen(),
        textScale: 1.3,
      );
      await check('EventsScreen', const EventsScreen(), settle: false);
      await check('AttendeesScreen', const AttendeesScreen());
      await check('SpeedRunScreen', const SpeedRunScreen(), settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.takeException() case final ex?) {
        errors.add('SpeedRunScreen populated exception: $ex');
      }
      await check('DeleteAccount', const DeleteAccount());
      final sampleEvent = makeEvent();
      final sampleSpeaker = makeSpeaker();

      await check('ScheduleScreen', ScheduleScreen(event: sampleEvent));
      await check(
        'ScheduleDetail',
        ScheduleDetail(eventId: 'evt-1', info: sampleSpeaker),
      );
      await check(
        'ChallengeDetailScreen',
        ChallengeDetailScreen(challenge: makeChallenge()),
      );
      await check(
        'OrganizersScreen (320x844, 1.3x)',
        const OrganizersScreen(),
        size: const Size(320, 844),
        textScale: 1.3,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.takeException() case final ex?) {
        errors.add('OrganizersScreen populated exception: $ex');
      }
      await check(
        'QuestionTreasure',
        QuestionTreasure(
          item: TreasureHuntModel(
            uuid: 't1',
            title: 'Treasure 1',
            imgPath: 'assets/img/trofeo.png',
            question: 'Q?',
            answer: 'A',
            description: 'D',
          ),
        ),
      );
      await check('EditProfile', const EditProfile());
      await check('AddEvent', const AddEvent());
      await check('EditEvent', EditEvent(event: sampleEvent));
      await check('AddSchedule', const AddSchedule(eventId: 'evt-1'));
      await check(
        'EditSchedule',
        EditSchedule(eventId: 'evt-1', info: sampleSpeaker),
      );
      await check('AddResource', const AddResource());
      await check('AddChallengeScreen', const AddChallengeScreen());

      expect(errors, isEmpty);
    },
  );
}
