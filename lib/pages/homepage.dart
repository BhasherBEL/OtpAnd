import 'package:flutter/material.dart';
import 'package:otpand/pages/journeys.dart';
import 'package:otpand/pages/lines.dart';
import 'package:otpand/pages/settings.dart';
import 'package:otpand/pages/stops.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    Journeys(),
    LinesPage(),
    StopsPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_transit),
            label: 'Journey',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Lines'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Stops',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
