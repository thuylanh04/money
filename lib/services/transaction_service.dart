// lib/services/transaction_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:money_manage/services/storage_service.dart';
import 'package:money_manage/models/transaction.dart';
import 'package:money_manage/services/api_client.dart';
import 'package:money_manage/config/env_config.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class TransactionService {
  final ApiClient _client;
  static final TransactionService _instance =
      TransactionService._internal(ApiClient());

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
    required String categoryIdFE,
    required String walletIdFE,
    List<File>? files,
  }) async {
    try {
      final userId = await StorageService.getUid();
      if (userId == null) {
        throw Exception('No user ID found');
      }

      // Get authentication token
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Create transaction payload matching updateTransaction
      final transactionData = {
        "idFE": "",
        "amount": amount,
        "categoryIdFE": categoryIdFE,
        "walletIdFE": walletIdFE,
        "date": DateTime.tryParse(date)?.toIso8601String() ?? date,
        "userIdFE": userId,
        if (note != null && note.isNotEmpty) "note": note,
      };

      final formData = FormData();
      formData.files.add(
        MapEntry(
          "transaction",
          MultipartFile.fromString(
            jsonEncode(transactionData),
            contentType: MediaType("application", "json"),
          ),
        ),
      );

      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          formData.files.add(
            MapEntry(
              "files",
              await MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              ),
            ),
          );
        }
      }

      // Send the request using Dio
      final dio = Dio();
      final response = await dio.post(
        '${EnvConfig.apiBaseUrl}/api/v1/transactions',
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            'ngrok-skip-browser-warning': 'true',
          },
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData['code'] == 1000) {
          return responseData['result'] ?? {};
        } else {
          throw Exception(responseData?['message']?.toString() ??
              'Failed to create transaction');
        }
      } else {
        throw Exception('Failed to create transaction: ${response.statusCode}');
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
        throw Exception(
            response?['message']?.toString() ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      print('Error in getUserTransactions: $e');
      rethrow;
    }
  }

  /// Fetch a single transaction by idFE from the API and return a [Transaction].
  /// Enriches the returned transaction with category group info when available.
  Future<Transaction> transactionDetail(String transactionId) async {
    try {
      // Load categories first for enrichment
      final categories = await getCategories();

      final response = await _client.get('/api/v1/transactions/$transactionId');

      if (response is Map<String, dynamic> && response['code'] == 1000) {
        final Map<String, dynamic> json = response['result'] ?? {};
        final transaction = Transaction.fromJson(json);

        final categoryInfo = categories[transaction.categoryIdFE];
        if (categoryInfo != null) {
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
      } else {
        throw Exception(
            response?['message']?.toString() ?? 'Failed to fetch transaction');
      }
    } catch (e) {
      print('Error in transactionDetail: $e');
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
    List<File>? files,
    String? token,
  }) async {
    final dio = Dio();

    final authToken = token ?? await StorageService.getToken();
    if (authToken == null || authToken.isEmpty) {
      throw Exception('No authentication token found');
    }

    final userId = await StorageService.getUid();
    if (userId == null) {
      throw Exception('No user ID found');
    }

    final String url =
        "https://5d194e0ab2b2.ngrok-free.app/api/v1/transactions";

    final transactionData = {
      "idFE": transactionId,
      "amount": amount,
      "categoryIdFE": categoryIdFE,
      "walletIdFE": walletIdFE,
      "date": date.toIso8601String(),
      "userIdFE": userId,
      if (note != null && note.isNotEmpty) "note": note,
    };

    final transactionJson = jsonEncode(transactionData);

    final formData = FormData();

    formData.files.add(
      MapEntry(
        "transaction",
        MultipartFile.fromString(
          transactionJson,
          contentType: MediaType("application", "json"),
        ),
      ),
    );

    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        formData.files.add(
          MapEntry(
            "files",
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split("/").last,
            ),
          ),
        );
      }
    }

    try {
      final response = await dio.put(
        url,
        data: formData,
        options: Options(
          headers: {"Authorization": "Bearer $authToken"},
          contentType: "multipart/form-data",
        ),
      );

      // ✅ Convert response.data sang Transaction
      if (response.data is Map<String, dynamic> &&
          response.data['code'] == 1000) {
        return Transaction.fromJson(response.data['result'] ?? {});
      } else {
        throw Exception(response.data?['message']?.toString() ??
            'Failed to update transaction');
      }
    } on DioException catch (e) {
      print("DIO ERROR == ${e.response?.data}");
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
        throw Exception(
            response?['message']?.toString() ?? 'Failed to delete transaction');
      }
    } catch (e) {
      print('Error in deleteTransaction: $e');
      rethrow;
    }
  }
}
