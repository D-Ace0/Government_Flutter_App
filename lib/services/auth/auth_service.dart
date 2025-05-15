import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:governmentapp/models/user_model.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:provider/provider.dart';

class AuthService{
  // instance of FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // instance of FirebaseFirestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // login method via email and password
  Future<UserCredential> loginWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await handleLogin(context, userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> handleLogin(BuildContext context ,User user) async {
    // this method is responsible for saving the user data such as uid, email and role n the userprovider
    DocumentSnapshot userDoc = await _firestore.collection("Users").doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final currentUser = UserModel(uid: userData["uid"], email: userData["email"], role: userData["role"]);

    Provider.of<UserProvider>(context, listen: false).setUser(currentUser);
  }

  // signup method via email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String role,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        "email": email,
        "uid": userCredential.user!.uid,
        "role": role,
        "createdAt": DateTime.now(),
      });
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // signout method
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // get current user method
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // get user role method
  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot userDoc = await _firestore.collection('Users').doc(uid).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    return userData?['role'];
  }
  
  // change password method
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      
      // Get user credentials to verify current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      // Reauthenticate user with current password
      await user.reauthenticateWithCredential(credential);
      
      // Update to new password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw Exception('Current password is incorrect');
        case 'requires-recent-login':
          throw Exception('Please log in again before changing your password');
        default:
          throw Exception(e.message ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }
}
