import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _SocialButton(
                label: 'CONNECT WITH GOOGLE',
                icon: Icons.g_mobiledata,
                borderColor: Colors.red.shade400,
              ),
              const SizedBox(height: 12),
              const _SocialButton(
                label: 'SIGN IN WITH APPLE',
                icon: Icons.apple,
              ),
              const SizedBox(height: 24),
              const Center(child: Text('OR')),
              const SizedBox(height: 24),
              const _TextField(label: 'Email'),
              const SizedBox(height: 16),
              const _TextField(
                label: 'Password',
                obscureText: true,
                suffixIcon: Icon(Icons.visibility_outlined),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: replace with real auth via AuthController.
                  Navigator.of(context).pushReplacementNamed(
                    HomeScreen.routeName,
                  );
                },
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
                    onPressed: () {},
                    child: const Text('Forgot password?'),
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
  final String label;
  final bool obscureText;
  final Widget? suffixIcon;

  const _TextField({
    required this.label,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
