import 'package:money_manage/models/wallet.dart';
import 'package:money_manage/services/api_client.dart';

class WalletService {
  final ApiClient _client;

  WalletService(this._client);

  /// GET /api/v1/wallets to fetch all wallets
  Future<List<Wallet>> getWallets() async {
    try {
      final data = await _client.get('/api/v1/wallets');
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
      print('Error fetching wallets: $e');
      return <Wallet>[];
    }
  }
}
