import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:governmentapp/pages/citizen/citizen_home_page.dart';
import 'package:governmentapp/pages/citizen/citizen_message.dart';
import 'package:governmentapp/pages/citizen/citizen_announcements_page.dart';
import 'package:governmentapp/pages/citizen/citizen_polls_page.dart';
import 'package:governmentapp/pages/government/announcement_management_page.dart';
import 'package:governmentapp/pages/government/government_home_page.dart';
import 'package:governmentapp/pages/government/government_message.dart';
import 'package:governmentapp/pages/government/poll_management_page.dart';
import 'package:governmentapp/pages/login_page.dart';
import 'package:governmentapp/pages/profile_page.dart';
import 'package:governmentapp/pages/register_page.dart';
import 'package:governmentapp/services/auth/gate.dart';
import 'package:governmentapp/services/user/route_guard.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:governmentapp/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/performance_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Apply performance optimizations
  PerformanceUtils.applyAppOptimizations();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final navigatorKey = GlobalKey<NavigatorState>();
    
    // Create a route guard with the current context
    final routeGuard = RouteGuard(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeGuard],
      home: const AuthGate(),
      routes: {
        '/home': (context) => const CitizenHomePage(),
        '/citizen_message': (context) => const CitizenMessage(),
        '/citizen_announcements': (context) => const CitizenAnnouncementsPage(),
        '/citizen_polls': (context) => const CitizenPollsPage(),
        '/government_home': (context) => const GovernmentHomePage(),
        '/government_message': (context) => const GovernmentMessage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/announcements': (context) => const AnnouncementManagementPage(),
        '/polls': (context) => const PollManagementPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
