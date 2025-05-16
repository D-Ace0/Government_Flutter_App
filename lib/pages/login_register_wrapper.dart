import 'package:flutter/material.dart';
import 'package:governmentapp/pages/login_page.dart';
import 'package:governmentapp/pages/register_page.dart';
import 'package:governmentapp/utils/logger.dart';

class LoginRegisterWrapper extends StatefulWidget {
  final String initialPage;
  
  const LoginRegisterWrapper({
    super.key, 
    required this.initialPage,
  });

  @override
  State<LoginRegisterWrapper> createState() => _LoginRegisterWrapperState();
}

class _LoginRegisterWrapperState extends State<LoginRegisterWrapper> {
  late bool showLoginPage;

  @override
  void initState() {
    super.initState();
    showLoginPage = widget.initialPage == 'login';
    AppLogger.d("LoginRegisterWrapper initialized with page: ${widget.initialPage}");
  }

  void togglePage() {
    AppLogger.d("Toggling page from ${showLoginPage ? 'login' : 'register'} to ${showLoginPage ? 'register' : 'login'}");
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(togglePage: togglePage);
    } else {
      return RegisterPage(togglePage: togglePage);
    }
  }
} 