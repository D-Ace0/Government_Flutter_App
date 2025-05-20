import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:governmentapp/models/user_model.dart';
import 'package:governmentapp/routers/role_router.dart';
import 'package:governmentapp/services/auth/login_or_register.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _populateUser(BuildContext context, User user) async {
    AppLogger.i("AuthGate: Populating user data for ${user.email}");
    try {
      final doc = await FirebaseFirestore.instance.collection("Users").doc(user.uid).get();
      final data = doc.data();

      if (data != null) {
        AppLogger.i("AuthGate: Retrieved user data with role: ${data['role']}");
        final userModel = UserModel(
          uid: data['uid'],
          email: data['email'],
          role: (data['role'] as String).toLowerCase(),
        );

        Provider.of<UserProvider>(context, listen: false).setUser(userModel);
        AppLogger.i("AuthGate: User data set in provider");
      } else {
        AppLogger.e("AuthGate: User document exists but data is null");
      }
    } catch (e) {
      AppLogger.e("AuthGate: Error populating user data", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.d("AuthGate: Building AuthGate widget");
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          AppLogger.d("AuthGate: Auth state waiting");
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          AppLogger.i("AuthGate: User authenticated, populating user data");
          _populateUser(context, snapshot.data!);
          return const RoleRouter(); // uses Provider now
        } else {
          AppLogger.i("AuthGate: No user authenticated, showing login/register");
          return const LoginOrRegister();
        }
      },
    );
  }
}
