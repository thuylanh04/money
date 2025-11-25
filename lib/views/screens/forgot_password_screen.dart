import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgot-password';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final email = _emailController.text;
    if (!Validators.isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    // TODO: call AuthController.resetPassword / send email.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('If this email exists, you will receive reset instructions.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot password'),
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
                const Text(
                  'Enter your email address and we will send you instructions to reset your password.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('SEND'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
