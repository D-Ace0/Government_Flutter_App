import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';

class GovernmentHomePage extends StatefulWidget {
  const GovernmentHomePage({super.key});

  @override
  State<GovernmentHomePage> createState() => _GovernmentHomePageState();
}

class _GovernmentHomePageState extends State<GovernmentHomePage> {
  int selectedIndex = 0; // Set to 0 for "Home" tab in the bottom navigation
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _greeting = "Good day";
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setGreeting();
  }

  void _loadUserData() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        // Use displayName if available, or email as fallback
        _userName = user.displayName?.split(' ')[0].toLowerCase() ?? 
                   user.email?.split('@')[0] ?? 
                   "user";
      });
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = "Good morning";
      } else if (hour < 17) {
        _greeting = "Good afternoon";
      } else {
        _greeting = "Good evening";
      }
    });
  }

  void onTap(int index) {
    setState(() {
      selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/government_home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/announcements');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/polls');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/report');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteGuardWrapper(
      allowedRoles: const ['government'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Government Portal'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1C4587), // Dark blue color
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF1C4587),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30,
                      child: Icon(
                        Icons.account_balance,
                        color: Color(0xFF1C4587),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Government Portal",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: selectedIndex == 0,
                onTap: () {
                  Navigator.pop(context);
                  onTap(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign),
                title: const Text('Announcements'),
                selected: selectedIndex == 1,
                onTap: () {
                  Navigator.pop(context);
                  onTap(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.poll),
                title: const Text('Polls'),
                selected: selectedIndex == 2,
                onTap: () {
                  Navigator.pop(context);
                  onTap(2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: const Text('Reports'),
                selected: selectedIndex == 3,
                onTap: () {
                  Navigator.pop(context);
                  onTap(3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Messages'),
                selected: selectedIndex == 4,
                onTap: () {
                  Navigator.pop(context);
                  onTap(4);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                selected: selectedIndex == 5,
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to profile
                  Navigator.pushReplacementNamed(context, '/profile');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Government icon in circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.account_balance,
                      size: 60,
                      color: const Color(0xFF1C4587),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Greeting with name
                Text(
                  "$_greeting, $_userName",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Welcome text
                const Text(
                  "Welcome to the Government Portal",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Description
                const Text(
                  "Manage and oversee government services through the navigation menu",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 64),
                
                // Info icon and text
                const Icon(
                  Icons.info_outline,
                  size: 36,
                  color: Color(0xFF1C4587),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Use the bottom navigation bar or side menu to access features",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onTap,
        ),
      ),
    );
  }
} 