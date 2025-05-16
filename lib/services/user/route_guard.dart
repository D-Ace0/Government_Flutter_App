import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:governmentapp/services/user/user_provider.dart';

/// A navigation observer that controls access to routes based on user roles.
class RouteGuard extends NavigatorObserver {
  final BuildContext context;
  final Map<String, List<String>> _protectedRoutes = {
    // Government routes
    '/government_home': ['government'],
    '/government_message': ['government'],
    '/announcements': ['government'],
    '/polls': ['government'],
    
    // Citizen routes
    '/home': ['citizen'],
    '/citizen_message': ['citizen'],
    '/citizen_announcements': ['citizen'],
    '/citizen_polls': ['citizen'],
    '/citizen_report': ['citizen'],
    
    // Advertiser routes (if any)
    // '/advertiser_dashboard': ['advertiser'],
    
    // Shared routes - accessible by all roles
    '/profile': ['government', 'citizen', 'advertiser'],
  };

  RouteGuard(this.context);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _checkAccess(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _checkAccess(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _checkAccess(Route<dynamic> route) {
    // Get route name if it's a named route
    final settings = route.settings;
    final routeName = settings.name;
    
    if (routeName == null || !_protectedRoutes.containsKey(routeName)) {
      // Not a protected route, allow access
      return;
    }
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.user?.role;
    
    if (userRole == null || !_protectedRoutes[routeName]!.contains(userRole)) {
      // User doesn't have access to this route
      debugPrint('Access denied to route: $routeName. User role: $userRole');
      
      // Navigate to appropriate home page based on role
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (userRole == 'government') {
          Navigator.of(context).pushReplacementNamed('/government_home');
        } else if (userRole == 'citizen') {
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (userRole == 'advertiser') {
          // Handle advertiser route
          // Navigator.of(context).pushReplacementNamed('/advertiser_home');
        } else {
          // Fallback - go to login
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    }
  }
} 