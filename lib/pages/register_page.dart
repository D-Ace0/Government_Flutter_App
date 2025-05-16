import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/widgets/my_button.dart';
import 'package:governmentapp/widgets/my_dropdown.dart';
import 'package:governmentapp/widgets/my_text_field.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? togglePage;
  const RegisterPage({super.key, this.togglePage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Only these roles are selectable
  final List<String> roles = ['citizen', 'advertiser'];
  String? selectedRole;

  void registerMethod(BuildContext context) async {
    final authservice = AuthService();

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        selectedRole == null) {
      showDialog(
        context: context,
        builder:
            (context) =>
                const AlertDialog(title: Text('Please fill all the fields')),
      );
      return;
    }

    if (passwordController.text.length < 6) {
      showDialog(
        context: context,
        builder:
            (context) => const AlertDialog(
              title: Text('Password must be at least 6 characters long'),
            ),
      );
      return;
    }

    if (confirmPasswordController.text == passwordController.text) {
      try {
        await authservice.registerWithEmailAndPassword(
          emailController.text.trim(),
          passwordController.text.trim(),
          selectedRole!,
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(title: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.messenger_outline_rounded,
                size: 100,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              Text(
                'Let\'s create an account for you',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              MyTextfield(
                hintText: "Email",
                controller: emailController,
                obSecure: false,
              ),
              const SizedBox(height: 10),
              MyTextfield(
                hintText: "Password",
                controller: passwordController,
                obSecure: true,
              ),
              const SizedBox(height: 10),
              MyTextfield(
                hintText: "Confirm Password",
                controller: confirmPasswordController,
                obSecure: true,
              ),
              const SizedBox(height: 10),

              // Role dropdown
              MyDropdownField(
                hintText: 'Select your role',
                value: selectedRole,
                items: roles,
                onChanged: (val) {
                  setState(() {
                    selectedRole = val;
                  });
                },
              ),

              const SizedBox(height: 20),
              MyButton(onTap: () => registerMethod(context), text: 'Register'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.togglePage,
                    child: Text(
                      'Login Now',
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
      ),
    );
  }
}
