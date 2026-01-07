import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/mcp/mcp_provider.dart';

/// MCP Connections Screen
/// Allows users to manage their MCP service connections (Zerodha, etc.)
class MCPScreen extends ConsumerWidget {
  const MCPScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final serversAsync = ref.watch(mcpServersProvider);
    final connectionsState = ref.watch(mCPConnectionsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryPurple.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.accentPink],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.extension, color: Colors.white, size: 24),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MCP Connections',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Connect AI to external services',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.invalidate(mcpServersProvider),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),

              // Info Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryPurple, size: 20),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        'MCP (Model Context Protocol) lets Vyana AI access your trading accounts, calendars, and more.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(24),

              // Servers List
              Expanded(
                child: serversAsync.when(
                  data: (servers) {
                    if (servers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                            const Gap(16),
                            Text(
                              'No MCP servers available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const Gap(8),
                            Text(
                              'Make sure the backend is running',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: servers.length,
                      itemBuilder: (context, index) {
                        final server = servers[index];
                        return _MCPServerCard(
                          server: server,
                          isLoading: connectionsState.isLoading,
                          onConnect: () => _handleConnect(context, ref, server),
                          onDisconnect: () => _handleDisconnect(context, ref, server),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const Gap(16),
                        Text('Error loading MCP servers', style: TextStyle(color: Colors.grey.shade600)),
                        const Gap(8),
                        TextButton(
                          onPressed: () => ref.invalidate(mcpServersProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConnect(BuildContext context, WidgetRef ref, MCPServer server) async {
    if (server.name == 'zerodha') {
      // For Zerodha, open OAuth URL in browser
      final authUrl = await ref.read(mCPConnectionsProvider.notifier).getZerodhaAuthUrl();
      if (authUrl != null) {
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          // Show snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Complete authentication in browser, then refresh')),
            );
          }
        }
      }
    } else {
      // Direct connect for other MCPs
      final result = await ref.read(mCPConnectionsProvider.notifier).connect(server.name);
      if (context.mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${server.displayName}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['error']}')),
          );
        }
      }
    }
  }

  Future<void> _handleDisconnect(BuildContext context, WidgetRef ref, MCPServer server) async {
    final result = await ref.read(mCPConnectionsProvider.notifier).disconnect(server.name);
    if (context.mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disconnected from ${server.displayName}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['error']}')),
        );
      }
    }
  }
}

class _MCPServerCard extends StatelessWidget {
  final MCPServer server;
  final bool isLoading;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _MCPServerCard({
    required this.server,
    required this.isLoading,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: server.isConnected 
              ? Colors.green.withOpacity(0.3) 
              : Colors.grey.withOpacity(0.1),
          width: server.isConnected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: server.isConnected 
                      ? Colors.green.withOpacity(0.1)
                      : AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(server.icon, style: const TextStyle(fontSize: 24)),
              ),
              const Gap(16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          server.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(8),
                        _StatusBadge(status: server.status),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      server.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          // Actions
          Row(
            children: [
              if (server.isConnected) ...[
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const Gap(4),
                Text(
                  '${server.toolsCount} tools available',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                ),
              ],
              const Spacer(),
              if (server.isConnected)
                OutlinedButton(
                  onPressed: isLoading ? null : onDisconnect,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Disconnect'),
                )
              else
                FilledButton.icon(
                  onPressed: isLoading ? null : onConnect,
                  icon: server.isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.link, size: 18),
                  label: Text(server.isConnecting ? 'Connecting...' : 'Connect'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'connected':
        color = Colors.green;
        label = 'Connected';
        break;
      case 'connecting':
        color = Colors.orange;
        label = 'Connecting';
        break;
      case 'error':
        color = Colors.red;
        label = 'Error';
        break;
      default:
        color = Colors.grey;
        label = 'Disconnected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
