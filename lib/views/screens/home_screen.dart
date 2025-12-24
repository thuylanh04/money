import 'package:flutter/material.dart';

import 'home_content.dart';
import 'account_screen.dart';
import 'analysis_screen.dart';
import 'transaction_detail_screen.dart';
import 'transactions_screen.dart';
import 'chatbot_screen.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  // Add this method to handle back button press
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // Nếu không phải tab Home, chuyển về tab Home
      setState(() => _currentIndex = 0);
      return false; // không thoát app
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;

      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 0,
          width: MediaQuery.of(context).size.width,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: Colors.black87,
              child: const Text(
                'Press again to exit app',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      );

      overlay?.insert(overlayEntry);
      Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());

      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeContent(),
      const TransactionsScreen(),
      const AnalysisScreen(),
      const AccountScreen(),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(child: pages[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          selectedItemColor: AppTheme.primaryGreen,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              label: 'Analysis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GestureDetector(
            onLongPress: () {
              // Open chatbot on long press
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              );
            },
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(TransactionDetailScreen.routeName);
              },
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)], // phỏng đoán
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Limited time offer',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            '-80%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Get the most out of Money Finwise Premium',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
