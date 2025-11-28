import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Needed for ngrok: avoid HTML browser warning page on web.
        'ngrok-skip-browser-warning': 'true',
        if (EnvConfig.apiAuthHeader.isNotEmpty)
          'Authorization': EnvConfig.apiAuthHeader,
        ...?headers,
      },
      body: body is String ? body : jsonEncode(body ?? <String, dynamic>{}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed (${response.statusCode})');
    }

    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Needed for ngrok: avoid HTML browser warning page on web.
        'ngrok-skip-browser-warning': 'true',
        if (EnvConfig.apiAuthHeader.isNotEmpty)
          'Authorization': EnvConfig.apiAuthHeader,
        ...?headers,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed (${response.statusCode})');
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (EnvConfig.apiAuthHeader.isNotEmpty)
          'Authorization': EnvConfig.apiAuthHeader,
        ...?headers,
      },
      body: body is String ? body : jsonEncode(body ?? <String, dynamic>{}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed (${response.statusCode})');
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (EnvConfig.apiAuthHeader.isNotEmpty)
          'Authorization': EnvConfig.apiAuthHeader,
        ...?headers,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed (${response.statusCode})');
    }

    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body);
  }
}
