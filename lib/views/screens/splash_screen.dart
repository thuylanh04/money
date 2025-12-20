import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for AuthProvider to finish initializing
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if user is authenticated
    if (authProvider.isAuthenticated) {
      // User is logged in, go to home screen
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } else {
      // User is not logged in, check if it's first launch
      final isFirstLaunch = await _checkFirstLaunch();
      if (!mounted) return;
      
      if (isFirstLaunch) {
        Navigator.of(context).pushReplacementNamed(OnboardingScreen.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    }
  }
  
  Future<bool> _checkFirstLaunch() async {
    // You can use SharedPreferences to check if it's the first launch
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    if (isFirstLaunch) {
      await prefs.setBool('is_first_launch', false);
    }
    return isFirstLaunch;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.savings, color: Colors.white, size: 72),
            SizedBox(height: 16),
            Text(
              'Money — Finwise',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
