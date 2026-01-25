import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vyana_flutter/features/settings/settings_provider.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final settingsAsync = ref.watch(settingsProvider);
  // Default to empty if loading, handle gracefully in UI or wait for load
  final baseUrl = settingsAsync.value?.backendUrl ?? '';
  final client = ApiClient(baseUrl: baseUrl);
  ref.onDispose(client.dispose);
  return client;
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic details;

  ApiException({this.statusCode, required this.message, this.details});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message, details: $details)';
}

class ApiClient {
  final String baseUrl;
  final http.Client _client = http.Client();

  ApiClient({required this.baseUrl});

  String _normalizeBaseUrl(String value) {
    var trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.scheme.isEmpty) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  Uri resolve(String path, {String? fallbackBaseUrl}) {
    final resolvedBase = _normalizeBaseUrl(
      baseUrl.isNotEmpty ? baseUrl : (fallbackBaseUrl ?? ''),
    );
    if (resolvedBase.isEmpty) {
      throw ApiException(message: 'Backend URL is not configured');
    }
    final normalizedBase = resolvedBase.endsWith('/')
        ? resolvedBase.substring(0, resolvedBase.length - 1)
        : resolvedBase;
    return Uri.parse('$normalizedBase$path');
  }

  Future<dynamic> get(String path) async {
    try {
      final response = await _client.get(resolve(path)).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Request timed out');
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final response = await _client.post(
        resolve(path),
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 60)); // Increased for AI responses
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Request timed out');
    }
  }
  
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return _tryDecodeJson(response.body);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'API Error ${response.statusCode}',
        details: _tryDecodeJson(response.body),
      );
    }
  }

  dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    try {
      final response = await _client.put(
        resolve(path),
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Request timed out');
    }
  }

  Future<dynamic> delete(String path, {dynamic body}) async {
    try {
      final request = http.Request('DELETE', resolve(path));
      request.headers['Content-Type'] = 'application/json';
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Request timed out');
    }
  }
  
  // Streaming helper will be handled separately in Chat Repository as it requires different handling

  void dispose() {
    _client.close();
  }
}
