import 'package:app_events/config/di/service_locator.dart';
import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/config/theme/app_theme.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/domain/repositories/resource_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/resources_provider.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/firebase_options.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/home/bottom_custom_nav.dart';
import 'package:app_events/ui/screens/user/sing_in_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  List<SingleChildWidget> _listProviders(BuildContext context) {
    return <SingleChildWidget>[
      ChangeNotifierProvider(create: (_) => sl<SignInSocialNetworkProvider>()),
      ChangeNotifierProvider(create: (_) => sl<UserProvider>()),
      ChangeNotifierProvider(
        create: (_) => OtherProvider(sl<OtherRepository>()),
      ),
      ChangeNotifierProvider(
        create: (_) => ScheduleProvider(sl<ScheduleRepository>()),
      ),
      ChangeNotifierProvider(
        create: (_) => ResourcesProvider(sl<ResourceRepository>()),
      ),
    ];
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _listProviders(context),
      child: MaterialApp(
        title: AppStrings.titleApp,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
        theme: AppTheme().getTheme(),
        home: const _ValidateStateAuth(),
      ),
    );
  }
}

class _ValidateStateAuth extends StatefulWidget {
  const _ValidateStateAuth();

  @override
  State<_ValidateStateAuth> createState() => __ValidateStateAuthState();
}

class __ValidateStateAuthState extends State<_ValidateStateAuth> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final auth = Provider.of<SignInSocialNetworkProvider>(
        context,
        listen: false,
      );
      final data = Provider.of<UserProvider>(context, listen: false);

      auth.loadingValidate = true;
      await Permission.camera.request();
      await auth.validateToken();
      if (auth.isAuth) {
        await data.validateIsAdmin(auth.userInfo.uid);
      }
      auth.loadingValidate = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    if (auth.loadingValidate) {
      return Scaffold(
        backgroundColor: AppStyles.colorAppbar,
        body: Center(
          child: Image.asset(
            AppAssetsPath.loadingAnimation,
            width: MediaQuery.of(context).size.width * 0.65,
          ),
        ),
      );
    } else {
      if (auth.isAuth) {
        return const BottomCustomNav();
      } else {
        return const SignInScreen();
      }
    }
  }
}
