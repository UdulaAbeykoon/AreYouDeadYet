import 'package:death_app/screens/home_screen.dart';
import 'package:death_app/screens/people_screen.dart';
import 'package:death_app/screens/settings_auth_wrapper.dart';
import 'package:flutter/material.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 1; // Default to Home (Center)

  final List<Widget> _screens = const [
    SettingsAuthWrapper(),
    HomeScreen(),
    PeopleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'PEOPLE',
            ),
          ],
        ),
      ),
    );
  }
}
