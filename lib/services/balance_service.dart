import 'package:money_manage/services/api_client.dart';

class BalanceService {
  final ApiClient _apiClient;

  BalanceService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<double> getTotalBalance() async {
    try {
      final now = DateTime.now();
      final formattedDate = now.toString(); // Format: 2025-11-28 19:37:39.123456
      
      final response = await _apiClient.get(
        '/api/v1/transactions/amount/Cash$formattedDate',
      );
      
      if (response['code'] == 1000) {
        return (response['result'] as num).toDouble();
      } else {
        throw Exception('Failed to fetch balance: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error fetching balance: $e');
      rethrow;
    }
  }
}
