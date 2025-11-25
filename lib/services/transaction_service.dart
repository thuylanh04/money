import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:money_manage/config/env_config.dart';
import 'package:money_manage/models/transaction.dart';

class TransactionService {
  static const String _baseUrl = 'https://e34b199081e2.ngrok-free.app/api/v1';
  
  static Future<Map<String, dynamic>?> createTransaction({
    required double amount,
    required String date,
    String? note,
    String? image,
    required String categoryIdFE,
    required String walletIdFE,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': EnvConfig.apiAuthHeader,
        },
        body: json.encode({
          'amount': amount,
          'date': date,
          'note': note,
          'image': image,
          'categoryIdFE': categoryIdFE,
          'walletIdFE': walletIdFE,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['code'] == 1000) {
          return responseData['result'];
        } else {
          print('API Error: ${responseData['message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('Failed to create transaction: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating transaction: $e');
      return null;
    }
  }

  /// Fetches the list of transactions from the API
  static Future<List<Transaction>> getTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': EnvConfig.apiAuthHeader,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['code'] == 1000) {
          final List<dynamic> transactionsData = data['result'] ?? [];
          return transactionsData
              .map<Transaction>((json) => Transaction.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        } else {
          print('API Error: ${data['message'] ?? 'Unknown error'}');
          return [];
        }
      } else {
        print('Failed to fetch transactions: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }
}
