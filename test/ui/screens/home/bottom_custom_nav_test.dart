import 'dart:math';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/live_activity_provider.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/activities/activities_screen.dart';
import 'package:app_events/ui/screens/home/bottom_custom_nav.dart';
import 'package:app_events/ui/widgets/shared/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockOtherRepository extends Mock implements OtherRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSpinRepository extends Mock implements SpinRepository {}

class _MockEventRepository extends Mock implements EventRepository {}

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  testWidgets(
    'BottomCustomNav exposes 4 destinations and switches to Activities',
    (tester) async {
      final otherRepo = _MockOtherRepository();
      final userRepo = _MockUserRepository();
      final authRepo = _MockAuthRepository();
      final spinRepo = _MockSpinRepository();
      final eventRepo = _MockEventRepository();

      when(() => otherRepo.getSponsors()).thenAnswer((_) async => <Sponsor>[]);
      when(() => otherRepo.getTreasureHuntItems()).thenAnswer((_) async => []);
      when(() => userRepo.validateIsAdmin('u1')).thenAnswer((_) async => false);
      when(() => userRepo.getUserInfo('u1')).thenAnswer((_) async => null);
      when(
        () => eventRepo.getEventsStream(),
      ).thenAnswer((_) => Stream.value(<Event>[]));

      final otherProvider = OtherProvider(otherRepo);
      final userProvider = UserProvider(userRepo);
      final authProvider = SignInSocialNetworkProvider(
        authRepo,
        userProvider,
      )..userInfo = const AuthUser(uid: 'u1', displayName: 'Ada', photoUrl: '');
      final spinProvider = GdgSpinProvider(spinRepo, random: Random(1));
      final liveProvider = LiveActivityProvider(
        eventRepo,
        _MockScheduleRepository(),
      );
      addTearDown(() {
        otherProvider.dispose();
        userProvider.dispose();
        authProvider.dispose();
        spinProvider.dispose();
        liveProvider.dispose();
      });

      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 844),
            disableAnimations: true,
          ),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: otherProvider),
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: authProvider),
              ChangeNotifierProvider.value(value: spinProvider),
              ChangeNotifierProvider.value(value: liveProvider),
            ],
            child: const MaterialApp(home: BottomCustomNav()),
          ),
        ),
      );
      await tester.pump();

      final navBar = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
      expect(navBar.items, hasLength(4));
      expect(find.text(AppStrings.navBarActivities), findsOneWidget);
      expect(find.text(AppStrings.homeTournamentGDG), findsNothing);
      expect(find.text(AppStrings.homeTreasureBunt), findsNothing);

      await tester.tap(find.text(AppStrings.navBarActivities));
      await tester.pumpAndSettle();

      expect(find.byType(ActivitiesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
