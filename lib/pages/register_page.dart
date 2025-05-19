import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:flutter/services.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? togglePage;

  const RegisterPage({super.key, this.togglePage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isRegistering = false;
  String _selectedRole = '';
  final List<String> _roles = ['Citizen', 'Advertiser'];

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
    confirmPasswordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  void registerMethod(BuildContext context) async {
    if (_isRegistering) return; // Prevent multiple submissions
    
    final authService = AuthService();
    AppLogger.d("Register button clicked");
    
    // Validate input fields
    if (emailController.text.isEmpty || 
        passwordController.text.isEmpty || 
        confirmPasswordController.text.isEmpty ||
        _selectedRole.isEmpty) {
      AppLogger.w("Empty fields detected");
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Verify valid role selection (added security check)
    if (_selectedRole.toLowerCase() != 'citizen' && _selectedRole.toLowerCase() != 'advertiser') {
      AppLogger.w("Invalid role selected");
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid role selected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Check if passwords match
    if (passwordController.text != confirmPasswordController.text) {
      AppLogger.w("Passwords do not match");
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Provide tactile feedback when register button is pressed
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isRegistering = true;
    });
    
    try {
      AppLogger.d("Attempting registration with: ${emailController.text}");
      await authService.registerWithEmailAndPassword(
        emailController.text,
        passwordController.text,
        _selectedRole.toLowerCase(),
      );
      AppLogger.i("Registration successful");
      
      if (context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirect to login page
        if (widget.togglePage != null) {
          widget.togglePage!();
        }
      }
    } catch (e) {
      AppLogger.e("Registration error", e);
      
      String errorMessage = 'Registration failed. Please try again.';
      
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already in use. Please use a different email.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format. Please check your email.';
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
          _isRegistering = false;
        });
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
              // Top section with logo
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
                        // Header text
                        Semantics(
                          header: true,
                          child: Text(
                            'Create an account',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign up to access government services',
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
                        const SizedBox(height: 16),
                        
                        // Password field
                        Semantics(
                          label: 'Password field',
                          hint: 'Create your password',
                          textField: true,
                          child: _PasswordField(
                            controller: passwordController,
                            focusNode: passwordFocus,
                            hintText: "Password",
                            onSubmitted: (_) => confirmPasswordFocus.requestFocus(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirm Password field
                        Semantics(
                          label: 'Confirm password field',
                          hint: 'Re-enter your password',
                          textField: true,
                          child: _PasswordField(
                            controller: confirmPasswordController,
                            focusNode: confirmPasswordFocus,
                            hintText: "Confirm Password",
                            onSubmitted: (_) {},
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Role selection dropdown
                        Semantics(
                          label: 'Select your role',
                          hint: 'Choose your account type',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select your role (Citizen or Advertiser)",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedRole.isNotEmpty ? _selectedRole : null,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: theme.colorScheme.primary,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      border: InputBorder.none,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    hint: Text("Select your role"),
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(12),
                                    items: _roles.map((String role) {
                                      return DropdownMenuItem<String>(
                                        value: role,
                                        child: Text(role),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedRole = newValue ?? '';
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Register Button
                        Semantics(
                          button: true,
                          label: 'Create account button',
                          hint: 'Double tap to create your account',
                          enabled: !_isRegistering,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isRegistering ? null : () => registerMethod(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isRegistering
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text('Create Account'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Login option
                        Center(
                          child: Semantics(
                            button: true,
                            label: 'Sign in link',
                            hint: 'Double tap to go to the login page',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                GestureDetector(
                                  onTap: widget.togglePage,
                                  child: Text(
                                    'Sign In',
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
                                'By registering, you agree to our Terms of Service and Privacy Policy',
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
  final String hintText;
  final Function(String)? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
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
      textInputAction: TextInputAction.next,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
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
