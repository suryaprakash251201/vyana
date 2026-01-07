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
  return ApiClient(baseUrl: baseUrl);
}

class ApiClient {
  final String baseUrl;
  final http.Client _client = http.Client();

  ApiClient({required this.baseUrl});

  Uri _uri(String path) {
    // Handle cases where baseUrl might have trailing slash
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl; 
    return Uri.parse('$normalizedBase$path');
  }

  Future<dynamic> get(String path) async {
    final response = await _client.get(_uri(path)).timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    final response = await _client.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 60)); // Increased for AI responses
    return _handleResponse(response);
  }
  
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    final response = await _client.put(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path, {dynamic body}) async {
    final request = http.Request('DELETE', _uri(path));
    request.headers['Content-Type'] = 'application/json';
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 10));
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
  
  // Streaming helper will be handled separately in Chat Repository as it requires different handling
}
