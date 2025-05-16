import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:governmentapp/widgets/my_button.dart';
import 'package:governmentapp/widgets/my_text_field.dart';
import 'package:flutter/gestures.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final void Function()? togglePage;
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  LoginPage({super.key, this.togglePage});

  void loginMethod(BuildContext context) async {
    final authService = AuthService();
    AppLogger.d("Login button clicked");
    
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      AppLogger.w("Empty fields detected");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    try {
      AppLogger.d("Attempting login with: ${emailController.text}");
      await authService.loginWithEmailAndPassword(
        context,
        emailController.text,
        passwordController.text,
      );
      AppLogger.i("Login successful");
      
      // Navigate to the appropriate home page based on user role
      if (context.mounted) {
        // The AuthGate will handle the redirection based on user role
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      AppLogger.e("Login error", e);
      
      // More user-friendly error message
      String errorMessage = 'Login failed. Please check your credentials and try again.';
      
      // Customize error message for common Firebase Auth errors
      if (e.toString().contains('user-not-found') || 
          e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many login attempts. Please try again later.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _resetPassword(BuildContext context) async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final authService = AuthService();
      AppLogger.d("Attempting password reset for: ${emailController.text}");
      await authService.resetPassword(emailController.text.trim());
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Please check your inbox.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e("Password reset error", e);
      
      String errorMessage = 'Failed to send password reset email. Please try again.';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account found with this email address.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                // Use a single AnimatedOpacity for the logo section instead of multiple AnimatedContainers
                AnimatedOpacity(
                  opacity: isKeyboardVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 64,
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
                  'Welcome back',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                
                Text(
                  'Sign in to access government services',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email field with better accessibility
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
                
                // Password field with better accessibility
                Semantics(
                  label: 'Password field',
                  hint: 'Enter your password',
                  child: MyTextfield(
                    hintText: "Password",
                    controller: passwordController,
                    obSecure: true,
                    focusNode: passwordFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => loginMethod(context),
                    prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _resetPassword(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login button
                MyButton(
                  onTap: () => loginMethod(context),
                  text: 'Sign In',
                ),
                const SizedBox(height: 32),

                // Registration option with better semantics
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                      children: [
                        const TextSpan(text: 'Don\'t have an account? '),
                        TextSpan(
                          text: 'Register Now',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              AppLogger.d("Register Now button pressed");
                              if (togglePage != null) {
                                togglePage!();
                              } else {
                                AppLogger.e("togglePage callback is null");
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Terms and privacy notice - simplified animation
                if (!isKeyboardVisible) 
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      'By signing in, you agree to our Terms of Service and Privacy Policy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
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
