import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vyana_flutter/core/api_client.dart';

part 'mcp_provider.g.dart';

/// Represents an MCP server that can be connected
class MCPServer {
  final String name;
  final String displayName;
  final String icon;
  final String description;
  final String status; // "connected", "disconnected", "connecting", "error"
  final bool requiresApiKey;
  final int toolsCount;

  MCPServer({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.description,
    required this.status,
    required this.requiresApiKey,
    required this.toolsCount,
  });

  factory MCPServer.fromJson(Map<String, dynamic> json) {
    return MCPServer(
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? json['name'] ?? '',
      icon: json['icon'] ?? '🔌',
      description: json['description'] ?? '',
      status: json['status'] ?? 'disconnected',
      requiresApiKey: json['requires_api_key'] ?? false,
      toolsCount: json['tools_count'] ?? 0,
    );
  }

  bool get isConnected => status == 'connected';
  bool get isConnecting => status == 'connecting';
}

/// Provider for fetching available MCP servers
@riverpod
Future<List<MCPServer>> mcpServers(Ref ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get('/mcp/servers');
    final servers = (response['servers'] as List?)?.map((s) => MCPServer.fromJson(s)).toList() ?? [];
    return servers;
  } catch (e) {
    // Return empty list on error (backend might not be running)
    return [];
  }
}

/// Provider for MCP connection actions
@riverpod
class MCPConnections extends _$MCPConnections {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Connect to an MCP server
  Future<Map<String, dynamic>> connect(String name, {String? authToken}) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.post('/mcp/connect', body: {
        'name': name,
        if (authToken != null) 'auth_token': authToken,
      });
      state = const AsyncData(null);
      // Invalidate servers to refresh status
      ref.invalidate(mcpServersProvider);
      return result;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Disconnect from an MCP server
  Future<Map<String, dynamic>> disconnect(String name) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.post('/mcp/disconnect', body: {'name': name});
      state = const AsyncData(null);
      // Invalidate servers to refresh status
      ref.invalidate(mcpServersProvider);
      return result;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get Zerodha OAuth URL
  Future<String?> getZerodhaAuthUrl() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.get('/mcp/zerodha/auth');
      return result['auth_url'];
    } catch (e) {
      return null;
    }
  }

  /// Add a new MCP server
  Future<Map<String, dynamic>> addServer(String name, String url) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.post('/mcp/servers', body: {
        'name': name,
        'url': url,
      });
      state = const AsyncData(null);
      ref.invalidate(mcpServersProvider);
      return result;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return {'success': false, 'error': e.toString()};
    }
  }
}
