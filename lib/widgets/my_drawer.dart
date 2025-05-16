import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void logOut(BuildContext context) async {
    AuthService authService = AuthService();
    await authService.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              //logo
              DrawerHeader(
                child: Icon(
                  Icons.message,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
              ),

              // home list tile
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListTile(
                  title: Text("H O M E"),
                  leading: Icon(
                    Icons.home,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              // setting tile
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListTile(
                  title: Text("S E T T I N G S"),
                  leading: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ),
            ],
          ),
          // logout tile
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 25),
            child: ListTile(
              title: Text("L O G O U T"),
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () => logOut(context),
            ),
          ),
        ],
      ),
    );
  }
}
