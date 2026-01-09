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

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiToolsAsync = ref.watch(aiToolsProvider);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tools",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      "Manage your productivity & AI tools",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              
              // App Tools Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "App Tools",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Gap(12),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildAppToolCard(
                      context,
                      "Tasks",
                      Icons.check_circle_outline,
                      AppColors.successGreen,
                      () => context.go('/tasks'),
                    ),
                    _buildAppToolCard(
                      context,
                      "Calendar",
                      Icons.calendar_today,
                      AppColors.accentPink,
                      () => context.go('/calendar'),
                    ),
                    _buildAppToolCard(
                      context,
                      "Mail",
                      Icons.mail_outline,
                      Colors.orange,
                      () => context.go('/mail'),
                    ),
                    _buildAppToolCard(
                      context,
                      "Reminders",
                      Icons.alarm,
                      AppColors.primaryPurple,
                      () => context.go('/reminders'),
                    ),
                    _buildAppToolCard(
                      context,
                      "Test Sound",
                      Icons.volume_up,
                      Colors.teal,
                      () {
                        SoundService.play('sent.mp3');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Playing test sound...")),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const Gap(24),
              
              // AI Tools Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      "AI Tools",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: aiToolsAsync.when(
                        data: (tools) => Text(
                          '${tools.length}',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        loading: () => const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => Text(
                          '0',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),
              
              // AI Tools List
              Expanded(
                child: aiToolsAsync.when(
                  data: (tools) {
                    if (tools.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.extension_off, size: 64, color: Colors.grey.shade300),
                            const Gap(16),
                            Text(
                              'No AI tools available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Group tools by category
                    final grouped = <String, List<Map<String, dynamic>>>{};
                    for (final tool in tools) {
                      final category = tool['category'] as String? ?? 'Other';
                      grouped.putIfAbsent(category, () => []).add(tool);
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final category = grouped.keys.elementAt(index);
                        final categoryTools = grouped[category]!;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                category,
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
                            )),
                            const Gap(16),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const Gap(16),
                        Text(
                          'Failed to load AI tools',
                          style: TextStyle(color: Colors.grey.shade600),
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

  Widget _buildAppToolCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
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
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Gap(12),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIToolCard(BuildContext context, String name, String description) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
                  name.replaceAll('_', ' ').split(' ').map((word) => 
                    word[0].toUpperCase() + word.substring(1)
                  ).join(' '),
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
        ],
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
