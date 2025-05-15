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
  final List<String> roles = const ['citizen', 'advertiser'];
  String? selectedRole;
  bool _isRegistering = false;

  void registerMethod(BuildContext context) async {
    // Don't allow multiple submission attempts
    if (_isRegistering) return;
    
    setState(() {
      _isRegistering = true;
    });

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
      setState(() {
        _isRegistering = false;
      });
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
      setState(() {
        _isRegistering = false;
      });
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
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(title: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Passwords do not match'),
        ),
      );
      setState(() {
        _isRegistering = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.messenger_outline_rounded,
                  size: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Let\'s create an account for you',
                  style: TextStyle(
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
                _isRegistering 
                  ? const CircularProgressIndicator() 
                  : MyButton(onTap: () => registerMethod(context), text: 'Register'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.togglePage,
                      child: Text(
                        'Login Now',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }
}
