import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';

class CitizenHomePage extends StatelessWidget {
  const CitizenHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: Text("Citizen"),
        actions: [
          IconButton(onPressed: authService.signOut, icon: Icon(Icons.logout)),
        ],
      ),
    );
  }
}
