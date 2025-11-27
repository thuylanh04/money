import 'package:money_manage/models/wallet.dart';
import 'package:money_manage/services/api_client.dart';
import 'package:money_manage/services/storage_service.dart';

class WalletService {
  final ApiClient _client;

  WalletService(this._client);

  /// GET /api/v1/wallets/user/{userId} to fetch wallets for the logged-in user
  Future<List<Wallet>> getUserWallets() async {
    try {
      // Get the stored user ID
      final userId = await StorageService.getUid();
      if (userId == null || userId.isEmpty) {
        print('No user ID found in storage');
        return <Wallet>[];
      }

      // Call the API with the user's ID
      final data = await _client.get('/api/v1/wallets/user/$userId');
      
      if (data == null || data is! Map<String, dynamic>) {
        return <Wallet>[];
      }

      final result = data['result'];
      if (result is List) {
        return result
            .whereType<Map<String, dynamic>>()
            .map(Wallet.fromJson)
            .toList();
      }

      return <Wallet>[];
    } catch (e) {
      print('Error fetching user wallets: $e');
      return <Wallet>[];
    }
  }

  /// GET /api/v1/wallets to fetch all wallets (kept for backward compatibility)
  Future<List<Wallet>> getWallets() async {
    return getUserWallets(); // Default to user's wallets
  }
}
