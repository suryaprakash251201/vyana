import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:gap/gap.dart';
import 'package:vyana_flutter/core/sound_service.dart';
import 'package:vyana_flutter/core/api_client.dart';

// State for AI tools
final aiToolsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/tools/list');
    return List<Map<String, dynamic>>.from(response['tools'] ?? []);
  } catch (e) {
    debugPrint('Error fetching AI tools: $e');
    return [];
  }
});

final mcpServersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/mcp/servers');
    return List<Map<String, dynamic>>.from(response['servers'] ?? []);
  } catch (e) {
    debugPrint('Error fetching MCP servers: $e');
    return [];
  }
});

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _sortAZ = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiToolsAsync = ref.watch(aiToolsProvider);
    final mcpServersAsync = ref.watch(mcpServersProvider);
    final isWide = MediaQuery.of(context).size.width > 700;
    final crossAxisCount = isWide ? 4 : 3;

    final appTools = [
      _AppToolItem(
        title: 'Tasks',
        subtitle: 'Plan & finish',
        icon: Icons.check_circle_outline,
        color: AppColors.successGreen,
        onTap: () => context.go('/tasks'),
      ),
      _AppToolItem(
        title: 'Calendar',
        subtitle: 'Your schedule',
        icon: Icons.calendar_today,
        color: AppColors.accentPink,
        onTap: () => context.go('/calendar'),
      ),
      _AppToolItem(
        title: 'Mail',
        subtitle: 'Inbox focus',
        icon: Icons.mail_outline,
        color: Colors.orange,
        onTap: () => context.go('/mail'),
      ),
      _AppToolItem(
        title: 'Reminders',
        subtitle: 'Never miss',
        icon: Icons.alarm,
        color: AppColors.primaryPurple,
        onTap: () => context.go('/reminders'),
      ),
      _AppToolItem(
        title: 'Contacts',
        subtitle: 'People & emails',
        icon: Icons.contacts,
        color: Colors.blueAccent,
        onTap: () => context.go('/contacts'),
      ),
      _AppToolItem(
        title: 'Test Sound',
        subtitle: 'Audio check',
        icon: Icons.volume_up,
        color: Colors.teal,
        onTap: () {
          SoundService.play('sent.mp3');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Playing test sound...')),
          );
        },
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryPurple.withOpacity(0.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Tools',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          aiToolsAsync.when(
                            data: (tools) => _buildPill('${tools.length} AI'),
                            loading: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, __) => _buildPill('0 AI'),
                          )
                        ],
                      ),
                      const Gap(6),
                      Text(
                        'Manage your productivity & AI tools',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const Gap(12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search tools',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        'App Tools',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Gap(8),
                      _buildPill('Quick access'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAppToolCard(context, appTools[index]),
                    childCount: appTools.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        'MCP Connections',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Gap(8),
                      _buildPill('Important'),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: mcpServersAsync.when(
                  data: (servers) {
                    if (servers.isEmpty) {
                      return _buildEmptyState(
                        title: 'No MCP servers available',
                        subtitle: 'Configure servers in the backend to use MCP tools.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: servers.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final server = servers[index];
                        final name = server['display_name'] as String? ?? server['name'] as String? ?? 'MCP Server';
                        final status = (server['status'] as String? ?? 'disconnected').toLowerCase();
                        final description = server['description'] as String? ?? 'Connect to unlock tools.';
                        final toolsCount = server['tools_count'] ?? 0;
                        final icon = server['icon'] as String? ?? '🔌';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(icon, style: const TextStyle(fontSize: 18)),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const Gap(4),
                                    Text(
                                      description,
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Gap(8),
                                    Row(
                                      children: [
                                        _buildStatusChip(status),
                                        const Gap(8),
                                        _buildInfoChip('$toolsCount tools'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => _buildEmptyState(
                    title: 'Failed to load MCP servers',
                    subtitle: 'Check your backend connection and try again.',
                    icon: Icons.error_outline,
                    iconColor: Colors.red.shade300,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Text(
                    'AI Tools',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: aiToolsAsync.when(
                  data: (tools) {
                    if (tools.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      );
                    }

                    final filtered = tools.where((tool) {
                      final name = (tool['name'] as String? ?? '').toLowerCase();
                      final description = (tool['description'] as String? ?? '').toLowerCase();
                      return name.isNotEmpty || description.isNotEmpty;
                    }).toList();

                    if (filtered.isEmpty) {
                      return SliverToBoxAdapter(child: _buildEmptyState());
                    }

                    final grouped = <String, List<Map<String, dynamic>>>{};
                    for (final tool in filtered) {
                      final category = tool['category'] as String? ?? 'Other';
                      grouped.putIfAbsent(category, () => []).add(tool);
                    }

                    final categories = grouped.keys.toList()..sort();
                    final searchText = _searchController.text.trim().toLowerCase();

                    List<Map<String, dynamic>> applyFilters(List<Map<String, dynamic>> list) {
                      var items = list;
                      if (searchText.isNotEmpty) {
                        items = items.where((tool) {
                          final name = (tool['name'] as String? ?? '').toLowerCase();
                          final description = (tool['description'] as String? ?? '').toLowerCase();
                          return name.contains(searchText) || description.contains(searchText);
                        }).toList();
                      }
                      if (_sortAZ) {
                        items.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
                      }
                      return items;
                    }

                    final chipCategories = ['All', ...categories];
                    return SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...chipCategories.map((c) => ChoiceChip(
                                    label: Text(c),
                                    selected: _selectedCategory == c,
                                    onSelected: (_) => setState(() => _selectedCategory = c),
                                  )),
                              FilterChip(
                                label: const Text('Sort A-Z'),
                                selected: _sortAZ,
                                onSelected: (val) => setState(() => _sortAZ = val),
                              )
                            ],
                          ),
                        ),
                        ...categories.map((category) {
                          if (_selectedCategory != 'All' && _selectedCategory != category) {
                            return const SizedBox.shrink();
                          }
                          final categoryTools = applyFilters(grouped[category]!);
                          if (categoryTools.isEmpty) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    '$category (${categoryTools.length})',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ...categoryTools.map((tool) => _buildAIToolCard(
                                      context,
                                      tool['name'] as String,
                                      tool['description'] as String,
                                      category,
                                    )),
                              ],
                            ),
                          );
                        }).toList(),
                      ]),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )),
                  ),
                  error: (_, __) => SliverToBoxAdapter(
                    child: _buildEmptyState(
                      title: 'Failed to load AI tools',
                      subtitle: 'Check your backend connection and try again.',
                      icon: Icons.error_outline,
                      iconColor: Colors.red.shade300,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Gap(20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppToolCard(BuildContext context, _AppToolItem item) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const Gap(12),
              Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const Gap(4),
              Text(
                item.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIToolCard(BuildContext context, String name, String description, String category) {
    final theme = Theme.of(context);
    final displayName = name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForTool(name),
              color: AppColors.primaryPurple,
              size: 20,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    String title = 'No AI tools available',
    String subtitle = 'Connect your backend to load tools.',
    IconData icon = Icons.extension_off,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: iconColor ?? Colors.grey.shade300),
          const Gap(16),
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          const Gap(6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final theme = Theme.of(context);
    final normalized = status.toLowerCase();
    final isConnected = normalized == 'connected';
    final isConnecting = normalized == 'connecting';
    final color = isConnected
        ? AppColors.successGreen
        : isConnecting
            ? AppColors.warmOrange
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        normalized.isEmpty ? 'unknown' : normalized,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getIconForTool(String name) {
    if (name.contains('task')) return Icons.check_circle_outline;
    if (name.contains('calendar') || name.contains('event')) return Icons.event;
    if (name.contains('note')) return Icons.note;
    if (name.contains('email')) return Icons.email;
    if (name.contains('weather') || name.contains('forecast')) return Icons.wb_sunny;
    if (name.contains('search') || name.contains('news')) return Icons.search;
    if (name.contains('calculate')) return Icons.calculate;
    if (name.contains('convert')) return Icons.swap_horiz;
    return Icons.extension;
  }
}

class _AppToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _AppToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
