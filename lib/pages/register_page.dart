import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:governmentapp/widgets/my_button.dart';
import 'package:governmentapp/widgets/my_dropdown.dart';
import 'package:governmentapp/widgets/my_text_field.dart';
import 'package:flutter/gestures.dart';

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

  // Focus nodes for better keyboard navigation
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  final FocusNode roleFocus = FocusNode();
      
  // Only these roles are selectable
  final List<String> roles = const ['citizen', 'advertiser'];
  String? selectedRole;
  bool _isRegistering = false;

  void registerMethod(BuildContext context) async {
    // Don't allow multiple submission attempts
    if (_isRegistering) return;
    
    AppLogger.d("Register button clicked");
    
    setState(() {
      _isRegistering = true;
    });

    final authservice = AuthService();

    // Validate input fields
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        selectedRole == null) {
      AppLogger.w("Empty fields detected");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isRegistering = false;
      });
      return;
    }

    // Validate password length
    if (passwordController.text.length < 6) {
      AppLogger.w("Password too short");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isRegistering = false;
      });
      return;
    }

    // Check if passwords match
    if (confirmPasswordController.text != passwordController.text) {
      AppLogger.w("Passwords don't match");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isRegistering = false;
      });
      return;
    }
    
    // All validation passed, attempt registration
    try {
      AppLogger.d("Attempting registration with: ${emailController.text}, role: $selectedRole");
      
      await authservice.registerWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
        selectedRole!,
      );
      
      AppLogger.i("Registration successful");
      
      // Navigate to the root route after successful registration
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      AppLogger.e("Registration error", e);
      
      // User-friendly error message
      String errorMessage = 'Registration failed. Please try again.';
      
      // Customize error message for common Firebase Auth errors
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered. Try signing in.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    roleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use a value with a small threshold to avoid frequent toggling
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 50;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Use a single AnimatedOpacity instead of multiple AnimatedContainers
                AnimatedOpacity(
                  opacity: isKeyboardVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 50,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Government Portal',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                
                // Welcome message
                Text(
                  'Create an account',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                
                Text(
                  'Sign up to access government services',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179), // ~0.7 opacity
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email field
                Semantics(
                  label: 'Email address field',
                  hint: 'Enter your email address',
                  child: MyTextfield(
                    hintText: "Email",
                    controller: emailController,
                    obSecure: false,
                    focusNode: emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => passwordFocus.requestFocus(),
                    prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password field
                Semantics(
                  label: 'Password field',
                  hint: 'Enter your password',
                  child: MyTextfield(
                    hintText: "Password",
                    controller: passwordController,
                    obSecure: true,
                    focusNode: passwordFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => confirmPasswordFocus.requestFocus(),
                    prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Confirm Password field
                Semantics(
                  label: 'Confirm password field',
                  hint: 'Confirm your password',
                  child: MyTextfield(
                    hintText: "Confirm Password",
                    controller: confirmPasswordController,
                    obSecure: true,
                    focusNode: confirmPasswordFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => roleFocus.requestFocus(),
                    prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // Role dropdown with a more accessible label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Select your role',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
                  ],
                ),

                const SizedBox(height: 32),
                
                // Register button with loading state
                _isRegistering
                  ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                  : MyButton(
                      onTap: () => registerMethod(context),
                      text: 'Create Account',
                    ),
                const SizedBox(height: 24),

                // Login option
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = widget.togglePage,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Terms and privacy notice - simplified approach
                if (!isKeyboardVisible)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      'By registering, you agree to our Terms of Service and Privacy Policy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153), // ~0.6 opacity
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
