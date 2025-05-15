import 'package:flutter/material.dart';
import 'package:governmentapp/pages/government/announcement_management_page.dart';
import 'package:governmentapp/pages/government/poll_management_page.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';

class GovernmentHomePage extends StatefulWidget {
  const GovernmentHomePage({super.key});

  @override
  State<GovernmentHomePage> createState() => _GovernmentHomePageState();
}

class _GovernmentHomePageState extends State<GovernmentHomePage> {
  int selectedIndex = 0;

  void onTap(int index) {
    setState(() {
      selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/government_home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/announcements');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/polls');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/government_message');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the main content with route guard to ensure only government users can access
    return RouteGuardWrapper(
      allowedRoles: const ['government'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Government Portal",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          elevation: 0,
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Admin View",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        drawer: const MyDrawer(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              const Text(
                "Welcome to Public Square",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Manage your government communications efficiently",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Dashboard Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      "Active\nAnnouncements",
                      "12",
                      Icons.announcement_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      "Open\nPolls",
                      "4",
                      Icons.poll_outlined,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Section Title
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Action Cards
              _buildActionCard(
                context,
                "Manage Announcements",
                "Create, edit and schedule public announcements",
                Icons.campaign,
                Colors.blue,
                () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const AnnouncementManagementPage()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildActionCard(
                context,
                "Manage Public Polls",
                "Create and analyze citizen polls and surveys",
                Icons.analytics_outlined,
                Colors.green,
                () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const PollManagementPage()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildActionCard(
                context,
                "Message Center",
                "Communicate directly with citizens",
                Icons.message_outlined,
                Colors.purple,
                () => Navigator.pushReplacementNamed(context, '/government_message'),
              ),
              
              const SizedBox(height: 16),
              
              _buildActionCard(
                context,
                "Reports & Analytics",
                "View engagement metrics and citizen feedback",
                Icons.insights_outlined,
                Colors.amber.shade700,
                () {},
              ),
            ],
          ),
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
