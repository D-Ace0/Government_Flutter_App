import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:governmentapp/themes/theme_provider.dart';
import 'package:governmentapp/widgets/my_button.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:governmentapp/services/auth/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDarkMode = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = userProvider.user;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Update the _isDarkMode value to match the current theme
    _isDarkMode = themeProvider.isDarkMode;
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user.email.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 36, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // User info card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          // Email
                          Row(
                            children: [
                              const Icon(Icons.email_outlined),
                              const SizedBox(width: 8),
                              const Text(
                                'Email:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(user.email),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Role
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined),
                              const SizedBox(width: 8),
                              const Text(
                                'Role:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  user.role.substring(0, 1).toUpperCase() +
                                      user.role.substring(1),
                                ),
                                backgroundColor: _getRoleColor(user.role),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Account created
                          if (currentUser?.metadata.creationTime != null)
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined),
                                const SizedBox(width: 8),
                                const Text(
                                  'Joined:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(currentUser!.metadata.creationTime!),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Settings card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          // Dark mode switch
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            secondary: const Icon(Icons.dark_mode_outlined),
                            value: _isDarkMode,
                            onChanged: (value) {
                              setState(() {
                                _isDarkMode = value;
                                // Toggle theme using the ThemeProvider
                                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                              });
                            },
                          ),
                          
                          // Notifications switch
                          SwitchListTile(
                            title: const Text('Notifications'),
                            secondary: const Icon(Icons.notifications_outlined),
                            value: true,
                            onChanged: (value) {
                              // Implement notification preferences
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Security card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Security',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          // Change password button
                          ListTile(
                            leading: const Icon(Icons.password_outlined),
                            title: const Text('Change Password'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              _showChangePasswordDialog();
                            },
                          ),
                          
                          // Sign out button
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Sign Out'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              setState(() {
                                _isLoading = true;
                              });
                              
                              await AuthService().signOut();
                              
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'government':
        return Colors.blue;
      case 'citizen':
        return Colors.green;
      case 'advertiser':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isChangingPassword = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isChangingPassword 
                  ? null 
                  : () {
                      Navigator.pop(context);
                    },
              child: const Text('Cancel'),
            ),
            isChangingPassword
                ? const CircularProgressIndicator()
                : MyButton(
                    onTap: () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() {
                          isChangingPassword = true;
                        });
                        
                        try {
                          final authService = AuthService();
                          await authService.changePassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                          );
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            isChangingPassword = false;
                          });
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    text: 'Change Password',
                  ),
          ],
        ),
      ),
    );
  }
} 