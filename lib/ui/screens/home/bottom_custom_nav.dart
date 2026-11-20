import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/home/home.dart';
import 'package:app_events/ui/screens/resources/library_screen.dart';
import 'package:app_events/ui/screens/user/profile_screen.dart';
import 'package:app_events/ui/widgets/shared/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomCustomNav extends StatefulWidget {
  const BottomCustomNav({super.key});

  @override
  State<BottomCustomNav> createState() => _BottomCustomNavState();
}

class _BottomCustomNavState extends State<BottomCustomNav> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    Home(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final auth = Provider.of<SignInSocialNetworkProvider>(
        context,
        listen: false,
      );
      final data = Provider.of<UserProvider>(context, listen: false);
      if (data.userCompetitor == null) {
        await data.validateIsAdmin(auth.userInfo.uid);
      }
    });
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.homeBackgroundColor,
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: FloatingNavBar(
        items: const [
          FloatingNavItem(
            icon: AppAssetsPath.iconHome,
            label: AppStrings.navBarHome,
          ),
          FloatingNavItem(
            icon: AppAssetsPath.iconLibrary,
            label: AppStrings.navBarLibrary,
          ),
          FloatingNavItem(
            icon: AppAssetsPath.iconProfile,
            label: AppStrings.navBarProfile,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
