import 'package:flutter/material.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart'; // Import the custom widget

class CitizenHomePage extends StatefulWidget {
  const CitizenHomePage({super.key});

  @override
  State<CitizenHomePage> createState() => _CitizenHomePageState();
}

class _CitizenHomePageState extends State<CitizenHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the appropriate page when a tab is clicked
    if (index == 0) {
      // Home tab
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      // Announcements tab
      Navigator.pushReplacementNamed(context, '/citizen_announcements');
    } else if (index == 2) {
      // Polls tab
      Navigator.pushReplacementNamed(context, '/citizen_polls');
    } else if (index == 3) {
      // Report tab
      Navigator.pushReplacementNamed(context, '/citizen_report');
    } else if (index == 4) {
      // Messages tab
      Navigator.pushReplacementNamed(context, '/citizen_message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteGuardWrapper(
      allowedRoles: const ['citizen'],
      child: Scaffold(
        appBar: AppBar(title: const Text("Citizen")),
        drawer: MyDrawer(),
        body: Center(
          child: Text(
            "Selected Tab: $_selectedIndex",
            style: const TextStyle(fontSize: 18),
          ),
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
