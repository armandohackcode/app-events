import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/bloc/sign_in_social_network.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/screens/home.dart';
import 'package:app_events/screens/library_screen.dart';
import 'package:app_events/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class BottonCustomNav extends StatefulWidget {
  const BottonCustomNav({super.key});

  @override
  State<BottonCustomNav> createState() => _BottonCustomNavState();
}

class _BottonCustomNavState extends State<BottonCustomNav> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    Home(),
    LibraryScreen(),
    ProfileScreen(),
    // Text(
    //   'Index 3: Settings',
    //   style: optionStyle,
    // ),
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final auth =
          Provider.of<SignInSocialNetworkProvider>(context, listen: false);
      final data = Provider.of<DataCenter>(context, listen: false);
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
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: false,
        // showSelectedLabels: false,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/img/icon_home.svg'),
            label: 'Inicio',
            // backgroundColor: Colors.red,
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/img/icon_library.svg'),
            label: 'Biblioteca',
            // backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/img/icon_profile.svg'),
            label: 'Perfil',
            // backgroundColor: Colors.purple,
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.settings),
          //   label: 'Turs',
          //   // backgroundColor: Colors.pink,
          // ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppStyles.fontColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
