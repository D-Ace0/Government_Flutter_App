import 'package:flutter/material.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:provider/provider.dart';

class RoleGate extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;
  const RoleGate({super.key, required this.child, required this.allowedRoles});

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<UserProvider>(context).user?.role;
    
    return allowedRoles.contains(role) ? child : SizedBox.shrink();
  }
}
