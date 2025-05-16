import 'package:flutter/material.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isGovernment = userProvider.user?.role == 'government';

    // Navigate to the appropriate page when a tab is clicked
    if (index == 0) {
      // Home tab - stay on this page
      return;
    } else if (index == 1) {
      // Announcements tab
      if (isGovernment) {
        Navigator.pushReplacementNamed(context, '/announcements');
      } else {
        Navigator.pushReplacementNamed(context, '/citizen_announcements');
      }
    } else if (index == 2) {
      // Polls tab
      if (isGovernment) {
        Navigator.pushReplacementNamed(context, '/polls');
      } else {
        Navigator.pushReplacementNamed(context, '/citizen_polls');
      }
    } else if (index == 3) {
      // Report tab for government users, Messages tab for citizens
      if (isGovernment) {
        Navigator.pushReplacementNamed(context, '/report');
      } else {
        Navigator.pushReplacementNamed(context, '/citizen_message');
      }
    } else if (index == 4) {
      // Messages tab for government users, Profile for others
      if (isGovernment) {
        Navigator.pushReplacementNamed(context, '/messages');
      } else {
        Navigator.pushReplacementNamed(context, '/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final userName = user?.email.split('@').first ?? 'User';
    final timeOfDay = _getTimeOfDay();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Portal'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      drawer: MyDrawer(role: 'citizen'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),
              
              // Welcome message
              Text(
                'Good $timeOfDay, $userName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Welcome to the Government Portal',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Role-specific subtext
              Text(
                user?.role == 'government'
                    ? 'Manage and oversee government services through the navigation menu'
                    : 'Access government services through the navigation menu',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Navigation helper text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline, 
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use the bottom navigation bar or side menu to access features',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
  
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }
} 