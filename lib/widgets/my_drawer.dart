import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';

class MyDrawer extends StatelessWidget {
  final String role;
  const MyDrawer({super.key, required this.role});

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
              // report list tile
              if (role == 'citizen')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("R E P O R T"),
                    leading: Icon(
                      Icons.report,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/citizen_report');
                    },
                  ),
                ),

              // citizen report history
              if (role == 'citizen')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("M Y  R E P O R T S"),
                    leading: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/citizen_report_history');
                    },
                  ),
                ),

              // government report page
              if (role == 'government')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("R E P O R T S"),
                    leading: Icon(
                      Icons.report_problem,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/report');
                    },
                  ),
                ),

              // home list tile
              if (role == 'citizen')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("H O M E"),
                    leading: Icon(
                      Icons.home,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/citizen_home');
                    },
                  ),
                ),
              if (role == 'advertiser')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("H O M E"),
                    leading: Icon(
                      Icons.home,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/advertiser_home');
                    },
                  ),
                ),
              if (role == 'government')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("H O M E"),
                    leading: Icon(
                      Icons.home,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/government_home');
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

              if (role == 'government')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("A N N O U N C E M E N T S"),
                    leading: Icon(
                      Icons.announcement,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/announcements');
                    },
                  ),
                ),

              if (role == 'government')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("P O L L S"),
                    leading: Icon(
                      Icons.poll,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/polls');
                    },
                  ),
                ),

              if (role == 'government')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("P H O N E S"),
                    leading: Icon(
                      Icons.phone,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                          context, '/government_phone_management');
                    },
                  ),
                ),

              if (role == 'government')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("A D V E R T I S E M E N T S"),
                    leading: Icon(
                      Icons.title,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                          context, '/government_advertisements_management');
                    },
                  ),
                ),
              if (role == 'government')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("M E S S A G E S"),
                    leading: Icon(
                      Icons.message,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/government_message');
                    },
                  ),
                ),
              if (role == 'citizen')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("A N N O U N C E M E N T S"),
                    leading: Icon(
                      Icons.announcement,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/citizen_announcements');
                    },
                  ),
                ),
              if (role == 'citizen')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("M E S S A G E S"),
                    leading: Icon(
                      Icons.message,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/citizen_message');
                    },
                  ),
                ),
              if (role == 'citizen')
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ListTile(
                    title: Text("P O L L S"),
                    leading: Icon(
                      Icons.poll,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/citizen_polls');
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListTile(
                  title: Text("P R O F I L E"),
                  leading: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 20.0),
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
