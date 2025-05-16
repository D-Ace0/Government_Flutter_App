import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:governmentapp/pages/citizen/citizen_home_page.dart';
import 'package:governmentapp/pages/advertiser/advertiser_home_page.dart';
import 'package:governmentapp/pages/government/government_home_page.dart';
import 'package:governmentapp/services/user/user_provider.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user.isAdmin) {
          return const GovernmentHomePage();
        } else if (user.isAdvertiser) {
          return AdvertiserHomePage();
        } else {
          return const CitizenHomePage();
        }
      },
    );
  }
}
