import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../config/env_config.dart';

class ReceiptData {
  final double amount;
  final String? categoryId;
  final String? note;

  ReceiptData({
    required this.amount,
    this.categoryId,
    this.note,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryIdFE'],
      note: json['note'],
    );
  }
}

abstract class ReceiptService {
  Future<ReceiptData> processReceipt(XFile file);
}

class MockReceiptService implements ReceiptService {
  @override
  Future<ReceiptData> processReceipt(XFile file) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock data - you can customize these values
    return ReceiptData(
      amount: 125000,
      categoryId: 'food', // This should match your category IDs
      note: 'Mua sắm thực phẩm',
    );
  }
}

class ApiReceiptService implements ReceiptService {
  static const String _baseUrl = 'https://e34b199081e2.ngrok-free.app/api/v1';
  
  @override
  Future<ReceiptData> processReceipt(XFile file) async {
    try {
      final uri = Uri.parse('$_baseUrl/receipts/process');
      final request = http.MultipartRequest('POST', uri);
      
      // Add the image file
      request.files.add(await http.MultipartFile.fromPath(
        'receipt',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      // Add headers if needed
      request.headers['Content-Type'] = 'multipart/form-data';
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseData);
        if (jsonData['code'] == 1000) {
          return ReceiptData.fromJson(jsonData['result']);
        } else {
          throw Exception('Failed to process receipt: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to process receipt: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error processing receipt: $e');
    }
  }
}

class ReceiptRepository {
  final ReceiptService _service;

  ReceiptRepository._internal(this._service);

  static final ReceiptRepository _instance = ReceiptRepository._internal(
    MockReceiptService(), // Always use mock for now
  );

  factory ReceiptRepository() => _instance;

  Future<ReceiptData> processReceipt(XFile file) {
    return _service.processReceipt(file);
  }
}
