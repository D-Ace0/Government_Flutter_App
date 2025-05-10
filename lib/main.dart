import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:governmentapp/pages/citizen/citizen_home_page.dart';
import 'package:governmentapp/pages/citizen/citizen_message.dart';
import 'package:governmentapp/pages/government/government_home_page.dart';
import 'package:governmentapp/pages/government/government_message.dart';
import 'package:governmentapp/pages/login_page.dart';
import 'package:governmentapp/pages/register_page.dart';
import 'package:governmentapp/services/auth/gate.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:governmentapp/themes/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: const AuthGate(),
      routes: {
        '/home': (context) => const CitizenHomePage(),
        '/citizen_message': (context) => const CitizenMessage(),
        '/government_home': (context) => const GovernmentHomePage(),
        '/government_message': (context) => const GovernmentMessage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
      },
    );
  }
}
