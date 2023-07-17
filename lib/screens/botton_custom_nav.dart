import 'package:app_events/constants.dart';
import 'package:app_events/screens/home.dart';
import 'package:app_events/screens/library_screen.dart';
import 'package:app_events/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
