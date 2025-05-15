import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:governmentapp/services/user/user_provider.dart';

/// A widget that protects its child based on user role
class RouteGuardWrapper extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;
  final Widget? fallbackWidget;

  const RouteGuardWrapper({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.user?.role;

    if (userRole != null && allowedRoles.contains(userRole)) {
      return child;
    }

    // User doesn't have permission - either show fallback or redirect
    if (fallbackWidget != null) {
      return fallbackWidget!;
    }

    // Redirect based on role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userRole == 'government') {
        Navigator.of(context).pushReplacementNamed('/government_home');
      } else if (userRole == 'citizen') {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (userRole == 'advertiser') {
        // Add advertiser route when available
      } else {
        // Fallback to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    // Show loading while redirecting
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 