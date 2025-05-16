import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:governmentapp/models/user_model.dart';
import 'package:governmentapp/routers/role_router.dart';
import 'package:governmentapp/services/auth/login_or_register.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _populateUser(BuildContext context, User user) async {
    final doc =
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(user.uid)
            .get();
    final data = doc.data();

    if (data != null) {
      final userModel = UserModel(
        uid: data['uid'],
        email: data['email'],
        role: data['role'],
      );

      Provider.of<UserProvider>(context, listen: false).setUser(userModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder(
            future: _populateUser(context, snapshot.data!),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.done) {
                return const RoleRouter();
              } else {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          );
        } else {
          return const LoginOrRegister();
        }
      },
    );
  }
}
