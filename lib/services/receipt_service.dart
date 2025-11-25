import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../config/env_config.dart';

abstract class ReceiptService {
  Future<void> analyzeReceipt(XFile file);
}

class MockReceiptService implements ReceiptService {
  @override
  Future<void> analyzeReceipt(XFile file) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

class ApiReceiptService implements ReceiptService {
  @override
  Future<void> analyzeReceipt(XFile file) async {
    // TODO: Implement real upload to backend for AI processing.
    await Future.value();
  }
}

class ReceiptRepository {
  late final ReceiptService _service;

  ReceiptRepository._internal(this._service);

  static final ReceiptRepository _instance = ReceiptRepository._internal(
    EnvConfig.useMock ? MockReceiptService() : ApiReceiptService(),
  );

  factory ReceiptRepository() => _instance;

  Future<void> analyzeReceipt(XFile file) {
    return _service.analyzeReceipt(file);
  }
}
