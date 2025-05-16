import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:governmentapp/pages/citizen/citizen_message.dart';
import 'package:governmentapp/pages/citizen/citizen_announcements_page.dart';
import 'package:governmentapp/pages/citizen/citizen_polls_page.dart';
import 'package:governmentapp/pages/government/announcement_management_page.dart';
import 'package:governmentapp/pages/government/government_message.dart';
import 'package:governmentapp/pages/government/poll_management_page.dart';
import 'package:governmentapp/pages/government/government_home_page.dart';
import 'package:governmentapp/pages/home_page.dart';
import 'package:governmentapp/pages/login_register_wrapper.dart';
import 'package:governmentapp/pages/profile_page.dart';
import 'package:governmentapp/pages/notifications_page.dart';
import 'package:governmentapp/services/auth/gate.dart';
import 'package:governmentapp/services/notification/notification_service.dart';
import 'package:governmentapp/services/user/route_guard.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:governmentapp/themes/theme_provider.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/performance_utils.dart';
import 'package:governmentapp/pages/government/government_report_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  AppLogger.init();
  AppLogger.i('Application starting...');
  
  // Apply performance optimizations
  PerformanceUtils.applyAppOptimizations();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  AppLogger.i('Notification service initialized');
  
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
    // Create a route guard with the current context
    final routeGuard = RouteGuard(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      navigatorKey: NotificationService().navigatorKey,  // Use the navigatorKey from NotificationService
      navigatorObservers: [routeGuard],
      routes: {
        '/': (context) => const AuthGate(), // Root route
        '/home': (context) => const HomePage(), // Common home page for all users
        '/citizen_message': (context) => const CitizenMessage(),
        '/citizen_announcements': (context) => const CitizenAnnouncementsPage(),
        '/citizen_polls': (context) => const CitizenPollsPage(),
        '/government_message': (context) => const GovernmentMessage(),
        '/login': (context) => const LoginRegisterWrapper(initialPage: 'login'),
        '/register': (context) => const LoginRegisterWrapper(initialPage: 'register'),
        '/announcements': (context) => const AnnouncementManagementPage(),
        '/polls': (context) => const PollManagementPage(),
        '/profile': (context) => const ProfilePage(),
        '/notifications': (context) => const NotificationsPage(),
        '/government_home': (context) => const GovernmentHomePage(),
        '/report': (context) => const GovernmentReportPage(),
        '/messages': (context) => const GovernmentMessage(),
      },
    );
  }
}
