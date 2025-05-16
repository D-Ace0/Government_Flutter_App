import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/widgets/my_button.dart';
import 'package:governmentapp/widgets/my_text_field.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final void Function()? togglePage;
  LoginPage({super.key, this.togglePage});

  void loginMethod(BuildContext context) async {
    final authService = AuthService();
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) =>
                AlertDialog(title: const Text('Please fill all the fields')),
      );
      return;
    }
    try {
      await authService.loginWithEmailAndPassword(
        context,
        emailController.text,
        passwordController.text,
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              Icons.messenger_outline_rounded,
              size: 100,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            // welcome back you've been missed
            Text(
              'Welcome back, you\'ve been missed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // TextField for email
            MyTextfield(
              hintText: "Email",
              controller: emailController,
              obSecure: false,
            ),
            const SizedBox(height: 10),
            // TextField for password
            MyTextfield(
              hintText: "Password",
              controller: passwordController,
              obSecure: true,
            ),
            const SizedBox(height: 20),

            // Login
            MyButton(onTap: () => loginMethod(context), text: 'Login'),
            const SizedBox(height: 20),

            // not a member? Register Now
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Not a member? ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: togglePage,
                  child: Text(
                    'Register Now',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
