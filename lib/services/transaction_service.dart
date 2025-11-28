// lib/services/transaction_service.dart
import 'package:money_manage/services/storage_service.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/api_client.dart';
import 'package:intl/intl.dart';

class TransactionService {
  final ApiClient _client;
  static final TransactionService _instance = TransactionService._internal(ApiClient());

  factory TransactionService() => _instance;
  
  static TransactionService get instance => _instance;

  TransactionService._internal(this._client);

  // Cache for categories
  Map<String, Map<String, dynamic>>? _categoriesCache;

  // Get all categories and cache them
  Future<Map<String, Map<String, dynamic>>> getCategories() async {
    if (_categoriesCache != null) {
      return _categoriesCache!;
    }

    try {
      final response = await _client.get('/api/v1/categories');
      
      if (response is Map<String, dynamic> && response['code'] == 1000) {
        final List<dynamic> categories = response['result'] ?? [];
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
      
      throw Exception('Failed to load categories');
    } catch (e) {
      print('Error loading categories: $e');
      rethrow;
    }
  }

  // Helper to determine group type from groupIdFE
  String _getGroupType(String? groupIdFE) {
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

  Future<Map<String, dynamic>> createTransaction({
    required double amount,
    required String date,
    String? note,
    String? image,
    required String categoryIdFE,
    required String walletIdFE,
  }) async {
    try {
      final userId = await StorageService.getUid();
      if (userId == null) {
        throw Exception('No user ID found');
      }

      final now = DateTime.now();
      final formattedDate = DateFormat('EEE MMM dd HH:mm:ss zzz yyyy').format(now);
      final idFE = '${userId}${formattedDate}';

      final response = await _client.post(
        '/api/v1/transactions',
        body: {
          'idFE': idFE,
          'amount': amount,
          'date': date,
          if (note != null) 'note': note,
          if (image != null) 'image': image,
          'categoryIdFE': categoryIdFE,
          'walletIdFE': walletIdFE,
          'userIdFE': userId,
        },
      );

      if (response is Map<String, dynamic> && response['code'] == 1000) {
        return response['result'] ?? {};
      } else {
        throw Exception(response?['message']?.toString() ?? 'Failed to create transaction');
      }
    } catch (e) {
      print('Error in createTransaction: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> getUserTransactions() async {
    try {
      final userId = await StorageService.getUid();
      if (userId == null) {
        throw Exception('No user ID found');
      }

      // Load categories first
      final categories = await getCategories();
      
      final response = await _client.get('/api/v1/transactions/user/$userId');
      
      if (response is Map<String, dynamic> && response['code'] == 1000) {
        final List<dynamic> transactionsData = response['result'] ?? [];
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
        throw Exception(response?['message']?.toString() ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      print('Error in getUserTransactions: $e');
      rethrow;
    }
  }

  Future<Transaction> updateTransaction({
    required String transactionId,
    required double amount,
    required String categoryIdFE,
    String? note,
    required DateTime date,
    required String walletIdFE,
  }) async {
    try {
      final userId = await StorageService.getUid();
      if (userId == null) {
        throw Exception('No user ID found');
      }

      final response = await _client.put(
        '/api/v1/transactions/$transactionId',
        body: {
          'amount': amount,
          'categoryIdFE': categoryIdFE,
          if (note != null && note.isNotEmpty) 'note': note,
          'date': date.toIso8601String(),
          'walletIdFE': walletIdFE,
          'userIdFE': userId,
        },
      );

      if (response is Map<String, dynamic> && response['code'] == 1000) {
        return Transaction.fromJson(response['result'] ?? {});
      } else {
        throw Exception(response?['message']?.toString() ?? 'Failed to update transaction');
      }
    } catch (e) {
      print('Error in updateTransaction: $e');
      rethrow;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    try {
      final response = await _client.delete(
        '/api/v1/transactions/$transactionId',
      );

      if (response is Map<String, dynamic> && response['code'] == 1000) {
        return true;
      } else {
        throw Exception(response?['message']?.toString() ?? 'Failed to delete transaction');
      }
    } catch (e) {
      print('Error in deleteTransaction: $e');
      rethrow;
    }
  }
}