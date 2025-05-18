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
      child: SafeArea(
        child: Column(
          children: [
            // Header
            DrawerHeader(
              child: Icon(
                Icons.message,
                color: Theme.of(context).colorScheme.primary,
                size: 40,
              ),
            ),

            // Scrollable menu items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Home section
                    if (role == 'citizen')
                      _buildMenuItem(
                        context,
                        "H O M E",
                        Icons.home,
                        () => Navigator.pushNamed(context, '/citizen_home'),
                      ),
                    if (role == 'advertiser')
                      _buildMenuItem(
                        context,
                        "H O M E",
                        Icons.home,
                        () => Navigator.pushNamed(context, '/advertiser_home'),
                      ),
                    if (role == 'government')
                      _buildMenuItem(
                        context,
                        "H O M E",
                        Icons.home,
                        () => Navigator.pushNamed(context, '/government_home'),
                      ),

                    // Citizen specific items
                    if (role == 'citizen') ...[
                      _buildMenuItem(
                        context,
                        "R E P O R T",
                        Icons.report,
                        () => Navigator.pushNamed(context, '/citizen_report'),
                      ),
                      _buildMenuItem(
                        context,
                        "M Y  R E P O R T S",
                        Icons.history,
                        () => Navigator.pushNamed(
                            context, '/citizen_report_history'),
                      ),
                      _buildMenuItem(
                        context,
                        "A N N O U N C E M E N T S",
                        Icons.announcement,
                        () => Navigator.pushNamed(
                            context, '/citizen_announcements'),
                      ),
                      _buildMenuItem(
                        context,
                        "M E S S A G E S",
                        Icons.message,
                        () => Navigator.pushNamed(context, '/citizen_message'),
                      ),
                      _buildMenuItem(
                        context,
                        "P O L L S",
                        Icons.poll,
                        () => Navigator.pushNamed(context, '/citizen_polls'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: ListTile(
                          title: Text("P H O N E  D I R E C T O R Y"),
                          leading: Icon(
                            Icons.phone,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                                context, '/citizen_phone_directory');
                          },
                        ),
                      ),
                    ],

                    // Government specific items
                    if (role == 'government') ...[
                      _buildMenuItem(
                        context,
                        "M A N A G E  R E P O R T S",
                        Icons.report_problem,
                        () => Navigator.pushNamed(context, '/report'),
                      ),
                      _buildMenuItem(
                        context,
                        "A N N O U N C E M E N T S",
                        Icons.announcement,
                        () => Navigator.pushNamed(context, '/announcements'),
                      ),
                      _buildMenuItem(
                        context,
                        "P O L L S",
                        Icons.poll,
                        () => Navigator.pushNamed(context, '/polls'),
                      ),
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
                      _buildMenuItem(
                        context,
                        "A D V E R T I S E M E N T S",
                        Icons.title,
                        () => Navigator.pushNamed(
                            context, '/government_advertisements_management'),
                      ),
                      _buildMenuItem(
                        context,
                        "M E S S A G E S",
                        Icons.message,
                        () =>
                            Navigator.pushNamed(context, '/government_message'),
                      ),
                    ],

                    // Common items
                    _buildMenuItem(
                      context,
                      "P R O F I L E",
                      Icons.person,
                      () => Navigator.pushNamed(context, '/profile'),
                    ),
                    _buildMenuItem(
                      context,
                      "S E T T I N G S",
                      Icons.settings,
                      () => Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
              ),
            ),

            // Logout button (fixed at bottom)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: _buildMenuItem(
                context,
                "L O G O U T",
                Icons.logout,
                () => logOut(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: ListTile(
        title: Text(title),
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: onTap,
      ),
    );
  }
}
