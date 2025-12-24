import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasInternet() async {
  try {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  } catch (e) {
    print('Connectivity check failed: $e');
    return false;
  }
}
