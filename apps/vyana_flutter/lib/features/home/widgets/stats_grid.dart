import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/core/widgets/gradient_widgets.dart';
import 'package:vyana_flutter/features/tasks/tasks_provider.dart';

class StatsGrid extends StatelessWidget {
  final AsyncValue<List<TaskItem>> tasksAsync;
  final AsyncValue<List<dynamic>> calendarAsync;

  const StatsGrid({
    super.key,
    required this.tasksAsync,
    required this.calendarAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => context.go('/tools/tasks'),
            borderRadius: BorderRadius.circular(20),
            child: _buildStatCard(
              context,
              "Pending Tasks",
              tasksAsync.when(
                data: (tasks) =>
                    tasks.where((t) => !t.isCompleted).length.toString(),
                loading: () => "...",
                error: (_, __) => "0",
              ),
              Icons.task_alt_rounded,
              AppColors.strongGreen,
              theme,
              index: 1,
            ),
          ),
        ),
        const Gap(16),
        Expanded(
          child: InkWell(
            onTap: () => context.go('/tools/calendar'),
            borderRadius: BorderRadius.circular(20),
            child: _buildStatCard(
              context,
              "Today's Events",
              calendarAsync.when(
                data: (events) {
                  if (events.isEmpty) return "0";
                  if (events.length == 1 &&
                      events[0] is Map &&
                      events[0].containsKey('error')) {
                    return "0";
                  }
                  return events.length.toString();
                },
                loading: () => "...",
                error: (_, __) => "0",
              ),
              Icons.calendar_month_rounded,
              AppColors.strongPink,
              theme,
              index: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color, ThemeData theme,
      {int index = 0}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GradientIcon(
                  icon,
                  size: 22,
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
          const Gap(16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF0F172A),
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ).animate(delay: (200 * index).ms).fadeIn().slideY(begin: 0.2, end: 0);
  }
}
