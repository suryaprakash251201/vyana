import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/core/widgets/gradient_widgets.dart';
import 'package:vyana_flutter/features/tasks/tasks_provider.dart';

class UpcomingList extends StatelessWidget {
  final AsyncValue<List<TaskItem>> tasksAsync;

  const UpcomingList({
    super.key,
    required this.tasksAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GradientText(
              "Upcoming",
              gradient: AppColors.primaryGradient,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: () => context.go('/tools/tasks'),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text("See all"),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms),
        const Gap(12),
        tasksAsync.when(
          data: (tasks) {
            final pending =
                tasks.where((t) => !t.isCompleted).take(3).toList();
            if (pending.isEmpty) {
              return _buildEmptyState(
                  theme, 'No pending tasks', 'You\'re all caught up! 🎉');
            }
            return Column(
              children: pending.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                return _buildTaskItem(theme, t, idx);
              }).toList(),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()).animate().fadeIn(),
          error: (_, __) =>
              _buildEmptyState(theme, 'Could not load tasks', 'Pull to refresh'),
        ),
      ],
    );
  }

  Widget _buildTaskItem(ThemeData theme, TaskItem task, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
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
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.radio_button_unchecked,
              size: 20,
              color: AppColors.primaryPurple,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 12, color: Colors.grey.shade500),
                        const Gap(4),
                        Text(
                          _formatDueDateString(task.dueDate!),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    )
    .animate(delay: (400 + (index * 100)).ms)
    .fadeIn()
    .slideX(begin: 0.05);
  }

  Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline,
              size: 48, color: AppColors.successGreen.withOpacity(0.5)),
          const Gap(12),
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const Gap(4),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  String _formatDueDateString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateUtils.dateOnly(now);
      final tomorrow = today.add(const Duration(days: 1));
      final dueDate = DateUtils.dateOnly(date);

      if (dueDate == today) return 'Today';
      if (dueDate == tomorrow) return 'Tomorrow';
      return '${date.day}/${date.month}';
    } catch (_) {
      return dateStr;
    }
  }
}
