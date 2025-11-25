import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final AuthRepository _authRepository = AuthRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (!Validators.isValidEmail(email) || !Validators.isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email and password.')),
      );
      return;
    }
    _signInWithRepository(email, password);
  }

  Future<void> _signInWithRepository(String email, String password) async {
    try {
      await _authRepository.signIn(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Sign in'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _SocialButton(
                  label: 'CONNECT WITH GOOGLE',
                  icon: Icons.g_mobiledata,
                  borderColor: Colors.red.shade400,
                ),
                // const SizedBox(height: 12),
                // const _SocialButton(
                //   label: 'SIGN IN WITH APPLE',
                //   icon: Icons.apple,
                // ),
                const SizedBox(height: 24),
                const Center(child: Text('OR')),
                const SizedBox(height: 24),
                _TextField(
                  controller: _emailController,
                  label: 'Email',
                ),
                const SizedBox(height: 16),
                _TextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleLogin,
                  child: const Text('SIGN IN'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(SignUpScreen.routeName);
                      },
                      child: const Text('Sign up'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(ForgotPasswordScreen.routeName);
                      },
                      child: const Text('Forgot password?'),
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

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? borderColor;

  const _SocialButton({
    required this.label,
    required this.icon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: AppTheme.textPrimary),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor ?? Colors.black87),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final Widget? suffixIcon;

  const _TextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
