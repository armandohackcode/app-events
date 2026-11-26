import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/auth_user.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/user/sing_in_screen.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/sign_in/devfest_logo.dart';
import 'package:app_events/ui/widgets/sign_in/event_schedule_badge.dart';
import 'package:app_events/ui/widgets/sign_in/sign_in_card.dart';
import 'package:app_events/ui/widgets/sign_in/sign_in_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserProvider extends Mock implements UserProvider {}

const _testUser = AuthUser(
  uid: 'u-1',
  displayName: 'Ada Lovelace',
  photoUrl: '',
);

void main() {
  late _MockAuthRepository authRepo;
  late _MockUserProvider userProvider;
  late SignInSocialNetworkProvider authProvider;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'GDG Sucre Events',
      packageName: 'com.gdgsucre.app_events',
      version: '1.7.7',
      buildNumber: '8',
      buildSignature: '',
    );

    authRepo = _MockAuthRepository();
    userProvider = _MockUserProvider();

    when(() => authRepo.signInWithGoogle()).thenAnswer((_) async => _testUser);
    when(() => authRepo.signInWithApple()).thenAnswer((_) async => _testUser);
    when(
      () => userProvider.addCompetitor(
        name: any(named: 'name'),
        token: any(named: 'token'),
        photoUrl: any(named: 'photoUrl'),
      ),
    ).thenAnswer((_) async {});

    authProvider = SignInSocialNetworkProvider(authRepo, userProvider);
  });

  tearDown(() => authProvider.dispose());

  Future<void> pumpSignInScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: ChangeNotifierProvider<SignInSocialNetworkProvider>.value(
          value: authProvider,
          child: const MaterialApp(home: SignInScreen()),
        ),
      ),
    );
  }

  testWidgets(
    'Android renders redesigned login without Apple button or Build with AI asset and triggers Google auth',
    (tester) async {
      await pumpSignInScreen(tester);
      await tester.pumpAndSettle();

      expect(find.byType(HomeBackdrop), findsOneWidget);
      expect(find.byType(EventScheduleBadge), findsOneWidget);
      expect(find.text(AppStrings.signInEventSchedule), findsOneWidget);

      expect(find.byType(DevFestLogo), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DevFestLogo),
          matching: find.text(AppStrings.signInEventName),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DevFestLogo),
          matching: find.text(AppStrings.signInCommunityCity),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == AppAssetsPath.titleEvent,
        ),
        findsNothing,
      );

      expect(find.byType(SignInCard), findsOneWidget);
      expect(find.text(AppStrings.signInTitle), findsOneWidget);
      expect(find.text(AppStrings.signInSubtitle), findsOneWidget);
      expect(find.text(AppStrings.signInGoogleButton), findsOneWidget);
      expect(find.text(AppStrings.signInAppleButton), findsNothing);

      expect(find.byType(SignInFooter), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SignInFooter),
          matching: find.byWidgetPredicate(
            (w) =>
                w is SvgPicture &&
                w.bytesLoader is SvgAssetLoader &&
                (w.bytesLoader as SvgAssetLoader).assetName ==
                    AppAssetsPath.gdgIcon,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.signInCommunityName), findsOneWidget);
      expect(find.text(AppStrings.signInVersionLabel('1.7.7')), findsOneWidget);

      await tester.tap(find.text(AppStrings.signInGoogleButton));
      await tester.pump();

      verify(() => authRepo.signInWithGoogle()).called(1);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'iOS displays both Google and Apple buttons and triggers Apple sign-in',
    (tester) async {
      await pumpSignInScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.signInGoogleButton), findsOneWidget);
      expect(find.text(AppStrings.signInAppleButton), findsOneWidget);

      await tester.tap(find.text(AppStrings.signInAppleButton));
      await tester.pump();

      verify(() => authRepo.signInWithApple()).called(1);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'shows loading indicator and hides auth buttons when loadingAuth is true',
    (tester) async {
      authProvider.loadingAuth = true;

      await pumpSignInScreen(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(AppStrings.signInGoogleButton), findsNothing);
      expect(find.text(AppStrings.signInAppleButton), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('opens ModalGDG from info button and closes via Close button', (
    tester,
  ) async {
    await pumpSignInScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.signInGDGAsk));
    await tester.pumpAndSettle();

    expect(find.byType(ModalGDG), findsOneWidget);
    expect(find.text(AppStrings.organizersGDGSucre), findsOneWidget);
    expect(find.text(AppStrings.signInGDGDescription), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ModalGDG),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == AppAssetsPath.logoGdg,
        ),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text(AppStrings.commonWordClose));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.commonWordClose));
    await tester.pumpAndSettle();

    expect(find.byType(ModalGDG), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fits compact 320x568 viewport at 1.3x text scale on iOS without overflow',
    (tester) async {
      await pumpSignInScreen(
        tester,
        size: const Size(320, 568),
        textScale: 1.3,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignInCard), findsOneWidget);
      expect(find.text(AppStrings.signInGoogleButton), findsOneWidget);
      expect(find.text(AppStrings.signInAppleButton), findsOneWidget);
      expect(
        tester.getSize(find.byType(SignInCard)).width,
        lessThanOrEqualTo(420),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'caps card width at 420 on 900x1200 tablet viewport on iOS without overflow',
    (tester) async {
      await pumpSignInScreen(tester, size: const Size(900, 1200));
      await tester.pumpAndSettle();

      expect(find.byType(SignInCard), findsOneWidget);
      expect(
        tester.getSize(find.byType(SignInCard)).width,
        lessThanOrEqualTo(420),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
