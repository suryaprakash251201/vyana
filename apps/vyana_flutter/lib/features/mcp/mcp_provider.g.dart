// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for fetching available MCP servers

@ProviderFor(mcpServers)
final mcpServersProvider = McpServersProvider._();

/// Provider for fetching available MCP servers

final class McpServersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MCPServer>>,
          List<MCPServer>,
          FutureOr<List<MCPServer>>
        >
    with $FutureModifier<List<MCPServer>>, $FutureProvider<List<MCPServer>> {
  /// Provider for fetching available MCP servers
  McpServersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpServersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpServersHash();

  @$internal
  @override
  $FutureProviderElement<List<MCPServer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MCPServer>> create(Ref ref) {
    return mcpServers(ref);
  }
}

String _$mcpServersHash() => r'780bf37b8a16c1c949d2fa8d12317c5aa7cd3a4b';

/// Provider for MCP connection actions

@ProviderFor(MCPConnections)
final mCPConnectionsProvider = MCPConnectionsProvider._();

/// Provider for MCP connection actions
final class MCPConnectionsProvider
    extends $NotifierProvider<MCPConnections, AsyncValue<void>> {
  /// Provider for MCP connection actions
  MCPConnectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mCPConnectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mCPConnectionsHash();

  @$internal
  @override
  MCPConnections create() => MCPConnections();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$mCPConnectionsHash() => r'a628c6de3d0a5938748118ece7c57ecdb76414d5';

/// Provider for MCP connection actions

abstract class _$MCPConnections extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
