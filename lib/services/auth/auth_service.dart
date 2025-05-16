import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:governmentapp/models/user_model.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:governmentapp/utils/logger.dart';
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
    AppLogger.i("AuthService: Attempting login with email: $email");
    try {
      // Log the exact point before Firebase auth call
      AppLogger.d("AuthService: Calling Firebase signInWithEmailAndPassword");
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.i("AuthService: Firebase authentication successful, getting user data");
      await handleLogin(context, userCredential.user!);
      AppLogger.i("AuthService: Login complete, user data set in provider");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.e("AuthService: Firebase auth error: ${e.code} - ${e.message}", e);
      throw Exception(e.message);
    } catch (e) {
      AppLogger.e("AuthService: Unknown error during login", e);
      throw Exception("An unknown error occurred: $e");
    }
  }

  Future<void> handleLogin(BuildContext context, User user) async {
    AppLogger.i("AuthService: Handling login for user ID: ${user.uid}");
    try {
      // this method is responsible for saving the user data such as uid, email and role n the userprovider
      DocumentSnapshot userDoc = await _firestore.collection("Users").doc(user.uid).get();
      if (!userDoc.exists) {
        AppLogger.e("AuthService: User document does not exist in Firestore");
        throw Exception("User profile not found. Please contact support.");
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      AppLogger.i("AuthService: User data retrieved: ${userData['role']}");
      final currentUser = UserModel(uid: userData["uid"], email: userData["email"], role: userData["role"]);

      Provider.of<UserProvider>(context, listen: false).setUser(currentUser);
      AppLogger.i("AuthService: User provider updated with user data");
    } catch (e) {
      AppLogger.e("AuthService: Error in handleLogin", e);
      throw Exception("Error loading user profile: $e");
    }
  }

  // signup method via email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String role,
  ) async {
    AppLogger.i("AuthService: Attempting registration. Email: $email, Role: $role");
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      
      AppLogger.i("AuthService: User created in Firebase Auth, adding to Firestore");
      await _firestore.collection("Users").doc(userCredential.user!.uid).set({
        "email": email,
        "uid": userCredential.user!.uid,
        "role": role,
        "createdAt": DateTime.now(),
      });
      
      AppLogger.i("AuthService: User data saved to Firestore");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.e("AuthService: Firebase auth error during registration: ${e.code} - ${e.message}", e);
      throw Exception(e.message);
    } catch (e) {
      AppLogger.e("AuthService: Unknown error during registration", e);
      throw Exception("An unknown error occurred during registration: $e");
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
  
  // Reset password (forgot password) method
  Future<void> resetPassword(String email) async {
    AppLogger.i("AuthService: Attempting password reset for email: $email");
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.i("AuthService: Password reset email sent successfully");
    } on FirebaseAuthException catch (e) {
      AppLogger.e("AuthService: Firebase auth error during password reset: ${e.code} - ${e.message}", e);
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email address');
        case 'invalid-email':
          throw Exception('Invalid email format');
        default:
          throw Exception(e.message ?? 'Failed to send password reset email');
      }
    } catch (e) {
      AppLogger.e("AuthService: Unknown error during password reset", e);
      throw Exception('Error sending password reset email: $e');
    }
  }
}
