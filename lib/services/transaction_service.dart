// lib/services/transaction_service.dart
import 'package:money_manage/services/storage_service.dart';
import 'package:money_manage/models/transaction.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TransactionService {
  static const String _baseUrl = 'https://3c8ea52a8aa1.ngrok-free.app/api/v1';

  static Future<Map<String, dynamic>> createTransaction({
    required double amount,
    required String date,
    String? note,
    String? image,
    required String categoryIdFE,
    required String walletIdFE,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'amount': amount,
          'date': date,
          if (note != null) 'note': note,
          if (image != null) 'image': image,
          'categoryIdFE': categoryIdFE,
          'walletIdFE': walletIdFE,
        }),
      );

      print('Create Transaction Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['code'] == 1000) {
          return responseData['result'] as Map<String, dynamic>;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create transaction');
        }
      } else {
        throw Exception('Failed to create transaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createTransaction: $e');
      rethrow;
    }
  }

  static Future<List<Transaction>> getUserTransactions() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('Get Transactions Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['code'] == 1000) {
          final List<dynamic> transactionsData = responseData['result'];
          return transactionsData.map((json) => Transaction.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch transactions');
        }
      } else {
        throw Exception('Failed to fetch transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getUserTransactions: $e');
      rethrow;
    }
  }

  // ... rest of the TransactionService class
}