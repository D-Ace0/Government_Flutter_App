import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user/user_provider.dart';
import '../services/auth/auth_service.dart';
import '../services/notification/notification_manager.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isGovernment = userProvider.user?.isAdmin ?? false;
    final isAdvertiser = userProvider.user?.isAdvertiser ?? false;
    final isCitizen = userProvider.user?.isCitizen ?? false;
    final notificationManager = NotificationManager();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userProvider.user?.email ?? ''),
            accountEmail: Text(userProvider.user?.role ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(
                userProvider.user?.email != null 
                    ? userProvider.user!.email.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              if (isGovernment) {
                Navigator.pushReplacementNamed(context, '/government_home');
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          if (isGovernment) ...[
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text('Announcements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/announcements');
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll),
              title: const Text('Polls'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/polls');
              },
            ),
          ],
          if (isCitizen) ...[
            ListTile(
              leading: const Icon(Icons.announcement_outlined),
              title: const Text('Announcements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/citizen_announcements');
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll_outlined),
              title: const Text('Polls'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/citizen_polls');
              },
            ),
          ],
          if (!isAdvertiser)
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Report Problem'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/report');
              },
            ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
              if (isGovernment) {
                Navigator.pushReplacementNamed(context, '/government_message');
              } else {
                Navigator.pushReplacementNamed(context, '/citizen_message');
              }
            },
          ),
          StreamBuilder<int>(
            stream: notificationManager.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              
              return ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                trailing: unreadCount > 0 
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/notifications');
                },
              );
            }
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
