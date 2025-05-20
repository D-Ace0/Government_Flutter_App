import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  final void Function()? togglePage;

  const LoginPage({super.key, this.togglePage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    // Start animation after a small delay to allow widget to build
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
    
    // Initialize autofocus with delay for smoother experience
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && emailFocus.canRequestFocus) {
        emailFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void loginMethod(BuildContext context) async {
    if (_isLoggingIn) return; // Prevent multiple submissions
    
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
    
    // Provide tactile feedback when login button is pressed
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isLoggingIn = true;
    });
    
    try {
      AppLogger.d("Attempting login with: ${emailController.text}");
      await authService.loginWithEmailAndPassword(
        context,
        emailController.text,
        passwordController.text,
      );
      AppLogger.i("Login successful");
      
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      AppLogger.e("Login error", e);
      
      String errorMessage = 'Login failed. Please check your credentials and try again.';
      
      if (e.toString().contains('user-not-found') || 
          e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many login attempts. Please try again later.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isLoggingIn = false;
        });
      }
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
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 50;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SafeArea(
          bottom: false, // Let content extend below safe area when keyboard appears
          child: Column(
            children: [
              // Top section with background pattern and logo
              if (!isKeyboardVisible || MediaQuery.of(context).size.height > 700)
                Expanded(
                  flex: isKeyboardVisible ? 1 : 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background pattern with bubble circles
                      CustomPaint(
                        size: Size.infinite,
                        painter: BubbleCirclesPainter(
                          color: theme.colorScheme.primary.withAlpha(40),
                        ),
                      ),
                      
                      // Government logo
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Semantics(
                              image: true,
                              label: 'Government portal logo',
                              child: Icon(
                                Icons.account_balance,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            header: true,
                            child: Text(
                              'Government Portal',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              // Bottom section with white card
              Expanded(
                flex: isKeyboardVisible ? 6 : 5,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome text
                        Semantics(
                          header: true,
                          child: Text(
                            'Welcome back',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to access government services',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Email field
                        Semantics(
                          label: 'Email address field',
                          hint: 'Enter your email address',
                          textField: true,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: emailController,
                              focusNode: emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => passwordFocus.requestFocus(),
                              decoration: InputDecoration(
                                hintText: "Email",
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field
                        Semantics(
                          label: 'Password field',
                          hint: 'Enter your password securely',
                          textField: true,
                          child: _PasswordField(
                            controller: passwordController,
                            focusNode: passwordFocus,
                            onSubmitted: (_) => loginMethod(context),
                          ),
                        ),
                        
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: Semantics(
                            button: true,
                            label: 'Forgot password',
                            hint: 'Reset your password via email',
                            child: TextButton(
                              onPressed: () => _resetPassword(context),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Sign in button
                        Semantics(
                          button: true,
                          label: 'Sign in button',
                          hint: 'Double tap to sign in to your account',
                          enabled: !_isLoggingIn,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.login),
                              label: _isLoggingIn
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text('Sign In'),
                              onPressed: _isLoggingIn ? null : () => loginMethod(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Register option
                        Center(
                          child: Semantics(
                            button: true,
                            label: 'Create new account',
                            hint: 'Double tap to register a new account',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                GestureDetector(
                                  onTap: widget.togglePage,
                                  child: Text(
                                    'Register Now',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Terms of service notice
                        if (!isKeyboardVisible)
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Semantics(
                              label: 'Terms and conditions notice',
                              child: Text(
                                'By signing in, you agree to our Terms of Service and Privacy Policy',
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String)? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    this.onSubmitted,
  });

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: "Password",
        prefixIcon: Icon(
          Icons.lock_outline,
          color: theme.colorScheme.primary,
        ),
        suffixIcon: Semantics(
          button: true,
          label: _obscureText ? 'Show password' : 'Hide password',
          child: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
              HapticFeedback.lightImpact();
            },
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
    );
  }
}

// Bubble circles painter for decorative background
class BubbleCirclesPainter extends CustomPainter {
  final Color color;
  
  BubbleCirclesPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    // Draw decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3), 
      size.width * 0.08, 
      paint
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.2), 
      size.width * 0.12, 
      paint
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.6), 
      size.width * 0.07, 
      paint
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7), 
      size.width * 0.09, 
      paint
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
