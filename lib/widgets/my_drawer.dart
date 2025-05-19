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
    final theme = Theme.of(context);
    
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with logo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0D47A1), // Darker blue
                            const Color(0xFF1976D2), // Lighter blue
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 40,
                            child: Icon(
                              Icons.account_balance,
                              size: 40,
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Government Portal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Role badge
                    if (role == 'citizen')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'citizen',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Main menu items
                    if (role == 'citizen') ...[
                      // Home
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.home_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Home'),
                        onTap: () {
                          Navigator.pushNamed(context, '/citizen_home');
                        },
                      ),
                      
                      // REPORTS section
                      Padding(
                        padding: const EdgeInsets.only(left: 25, top: 20, bottom: 8),
                        child: Text(
                          'REPORTS',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      // Create Report
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.report_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Create Report'),
                        onTap: () {
                          Navigator.pushNamed(context, '/citizen_report');
                        },
                      ),
                      
                      // My Reports
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.history,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('My Reports'),
                        onTap: () {
                          Navigator.pushNamed(context, '/citizen_report_history');
                        },
                      ),
                      
                      // COMMUNICATION section
                      Padding(
                        padding: const EdgeInsets.only(left: 25, top: 20, bottom: 8),
                        child: Text(
                          'COMMUNICATION',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      // Announcements
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.campaign_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Announcements'),
                        onTap: () {
                          Navigator.pushNamed(context, '/citizen_announcements');
                        },
                      ),
                      
                      // Messages
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.message_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Messages'),
                        onTap: () {
                          Navigator.pushNamed(context, '/citizen_message');
                        },
                      ),
                      
                      // Polls
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.poll_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Polls'),
                        onTap: () {
                          Navigator.pushNamed(context, '/citizen_polls');
                        },
                      ),
                      
                      // Phone Directory
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.phone_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Phone Directory'),
                        onTap: () {
                          Navigator.pushNamed(context, '/citizen_phone_directory');
                        },
                      ),
                      
                      // ACCOUNT section
                      Padding(
                        padding: const EdgeInsets.only(left: 25, top: 20, bottom: 8),
                        child: Text(
                          'ACCOUNT',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      // Profile
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Profile'),
                        onTap: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                      
                      // Settings
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.settings_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Settings'),
                        onTap: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ],
                    
                    // Government role menu
                    if (role == 'government') ...[
                      // Role badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              color: const Color(0xFF0D47A1),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'government',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Home
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.home_outlined,
                          color: const Color(0xFF0D47A1),
                        ),
                        title: const Text(
                          "Home",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/government_home');
                        },
                      ),
                      
                      // REPORTS section
                      Padding(
                        padding: const EdgeInsets.only(left: 25, top: 20, bottom: 8),
                        child: Text(
                          'REPORTS',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      // Manage Reports
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.report_problem_outlined,
                          color: const Color(0xFF0D47A1),
                        ),
                        title: const Text(
                          "Manage Reports",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/report');
                        },
                      ),

                      // COMMUNICATION section
                      Padding(
                        padding: const EdgeInsets.only(left: 25, top: 20, bottom: 8),
                        child: Text(
                          'COMMUNICATION',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      // Announcements
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.campaign_outlined,
                          color: const Color(0xFF0D47A1),
                        ),
                        title: const Text(
                          "Announcements",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/announcements');
                        },
                      ),

                      // Messages
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.message_outlined,
                          color: const Color(0xFF0D47A1),
                        ),
                        title: const Text(
                          "Messages",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/government_message');
                        },
                      ),

                      // Polls
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.poll_outlined,
                          color: const Color(0xFF0D47A1),
                        ),
                        title: const Text(
                          "Polls",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/polls');
                        },
                      ),

                      // MANAGEMENT section
                      Padding(
                        padding: const EdgeInsets.only(left: 25, top: 20, bottom: 8),
                        child: Text(
                          'MANAGEMENT',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      // Phones
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.phone_outlined,
                          color: const Color(0xFF0D47A1),
                        ),
                        title: const Text(
                          "Phone Directory",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/government_phone_management');
                        },
                      ),

                      // Advertisements
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.ad_units_outlined,
                          color: const Color(0xFF0D47A1),
                        ),
                        title: const Text(
                          "Advertisements",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/government_advertisements_management');
                        },
                      ),
                      
                      // ACCOUNT section
                      Padding(
                        padding: const EdgeInsets.only(left: 25, top: 20, bottom: 8),
                        child: Text(
                          'ACCOUNT',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      // Profile
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.person_outline,
                          color: const Color(0xFF0D47A1),
                        ),
                        title: const Text(
                          "Profile",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                      
                      // Settings
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.settings_outlined,
                          color: const Color(0xFF0D47A1),
                        ),
                        title: const Text(
                          "Settings",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ],
                    
                    // Advertiser role menu
                    if (role == 'advertiser') ...[
                      // Role badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'advertiser',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.home_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text("Home"),
                        onTap: () {
                          Navigator.pushNamed(context, '/advertiser_home');
                        },
                      ),
                      
                      // ACCOUNT section
                      Padding(
                        padding: const EdgeInsets.only(left: 25, top: 20, bottom: 8),
                        child: Text(
                          'ACCOUNT',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.settings_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text("Settings"),
                        onTap: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                      
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                        leading: Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text("Profile"),
                        onTap: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Logout button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ElevatedButton.icon(
                onPressed: () => logOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: role == 'government' 
                      ? const Color(0xFF0D47A1)
                      : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'LOGOUT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
