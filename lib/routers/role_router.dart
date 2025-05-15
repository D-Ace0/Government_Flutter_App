import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:governmentapp/pages/home_page.dart';
import 'package:governmentapp/services/user/user_provider.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // All users now go to the same home page
    return const HomePage();
  }
}
