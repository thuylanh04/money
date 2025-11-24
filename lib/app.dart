import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'views/screens/account_screen.dart';
import 'views/screens/bills_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/onboarding_screen.dart';
import 'views/screens/plans_screen.dart';
import 'views/screens/reports_screen.dart';
import 'views/screens/signup_screen.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/transaction_detail_screen.dart';
import 'views/screens/transactions_screen.dart';

class MoneyFinwiseApp extends StatelessWidget {
  const MoneyFinwiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money — Finwise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      onGenerateRoute: _onGenerateRoute,
      initialRoute: SplashScreen.routeName,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case OnboardingScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );
      case LoginScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case SignUpScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
          settings: settings,
        );
      case HomeScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case TransactionsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const TransactionsScreen(),
          settings: settings,
        );
      case PlansScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const PlansScreen(),
          settings: settings,
        );
      case ReportsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ReportsScreen(),
          settings: settings,
        );
      case BillsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const BillsScreen(),
          settings: settings,
        );
      case AccountScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const AccountScreen(),
          settings: settings,
        );
      case TransactionDetailScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const TransactionDetailScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
