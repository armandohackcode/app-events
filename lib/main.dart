import 'package:app_events/domain/bloc/data_center.dart';
import 'package:app_events/domain/bloc/sign_in_social_network.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/config/theme/app_theme.dart';
import 'package:app_events/ui/screens/botton_custom_nav.dart';
import 'package:app_events/ui/screens/sing_in_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  List<SingleChildWidget> _listProvider(BuildContext context) {
    return <SingleChildWidget>[
      ChangeNotifierProvider(
          create: (context) => SignInSocialNetworkProvider()),
      ChangeNotifierProvider(create: (context) => DataCenter()),
    ];
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _listProvider(context),
      child: MaterialApp(
        title: 'GDG Sucre Events',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final auth =
          Provider.of<SignInSocialNetworkProvider>(context, listen: false);
      final data = Provider.of<DataCenter>(context, listen: false);

      auth.loadingValidate = true;
      await Permission.camera.request();
      await auth.validateToken();
      if (auth.isAuth) {
        await data.validateIsAdmin(auth.userInfo.uid);
      }
      auth.loadingValidate = false;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    if (auth.loadingValidate) {
      return Scaffold(
        backgroundColor: AppStyles.colorAppbar,
        body: Center(
            child: Image.asset(
          "assets/img/devfest-animation.gif",
          width: MediaQuery.of(context).size.width * 0.65,
        )),
      );
    } else {
      if (auth.isAuth) {
        return const BottonCustomNav();
      } else {
        return const SignInScreen();
      }
    }
  }
}
