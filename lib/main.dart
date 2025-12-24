import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (added for local cache of home screen data)
  // HIVE: initialize Hive and open box 'home_cache'
  await Hive.initFlutter();
  await Hive.openBox('home_cache');
  // HIVE: open box for offline transaction queue
  await Hive.openBox('offline_tx');

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(prefs),
        ),
      ],
      child: const MoneyFinwiseApp(),
    ),
  );
  
  
}
