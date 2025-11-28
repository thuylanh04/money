// lib/services/transaction_service.dart
import 'package:money_manage/services/storage_service.dart';
import 'package:money_manage/models/transaction.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TransactionService {
  static const String _baseUrl = 'https://a2793545963a.ngrok-free.app/api/v1';

  // Cache for categories
  static Map<String, Map<String, dynamic>>? _categoriesCache;

  // Get all categories and cache them
  static Future<Map<String, Map<String, dynamic>>> getCategories() async {
    if (_categoriesCache != null) {
      return _categoriesCache!;
    }

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['code'] == 1000) {
          final List<dynamic> categories = responseData['result'];
          _categoriesCache = {};

          for (var category in categories) {
            _categoriesCache![category['idFE']] = {
              'name': category['categoryname'],
              'groupId': category['groupIdFE'],
              'groupType': _getGroupType(category['groupIdFE'])
            };
          }

          return _categoriesCache!;
        }
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      print('Error loading categories: $e');
      rethrow;
    }
  }

  // Helper to determine group type from groupIdFE
  static String _getGroupType(String? groupIdFE) {
    if (groupIdFE == null) return 'expense';

    if (groupIdFE.startsWith('Income')) {
      return 'income';
    } else if (groupIdFE.startsWith('Expense')) {
      return 'expense';
    } else if (groupIdFE.startsWith('Debt-Loan')) {
      return 'debt';
    }
    return 'expense'; // Default to expense
  }

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

      // Load categories first
      final categories = await getCategories();
      
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
          return transactionsData.map<Transaction>((json) {
            final transaction = Transaction.fromJson(json);
            final categoryInfo = categories[transaction.categoryIdFE];
            if (categoryInfo != null) {
              // Create a new Transaction with the group information
              return Transaction(
                idFE: transaction.idFE,
                amount: transaction.amount,
                date: transaction.date,
                note: transaction.note,
                image: transaction.image,
                categoryIdFE: transaction.categoryIdFE,
                walletIdFE: transaction.walletIdFE,
                categoryName: transaction.categoryName,
                walletName: transaction.walletName,
                groupIdFE: categoryInfo['groupId'],
                groupType: categoryInfo['groupType'],
              );
            }
            return transaction;
          }).toList();
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