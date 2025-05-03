import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';

class AdvertiserHomePage extends StatelessWidget {
  const AdvertiserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Text("Advertiser"),
        actions: [
          IconButton(onPressed: authService.signOut, icon: Icon(Icons.logout)),
        ],
      ),
    );
  }
}
