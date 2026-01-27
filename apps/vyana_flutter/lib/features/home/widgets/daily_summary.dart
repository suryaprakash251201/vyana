import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/core/widgets/gradient_widgets.dart';
import 'package:vyana_flutter/features/tasks/tasks_provider.dart';
import 'package:vyana_flutter/features/calendar/calendar_screen.dart';
import 'package:vyana_flutter/features/mail/mail_screen.dart';

class DailySummary extends ConsumerWidget {
  final AsyncValue<List<TaskItem>> tasksAsync;
  final AsyncValue<List<dynamic>> calendarAsync;
  final AsyncValue<int> unreadAsync;

  const DailySummary({
    super.key,
    required this.tasksAsync,
    required this.calendarAsync,
    required this.unreadAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pending = tasksAsync.maybeWhen(
      data: (tasks) => tasks.where((t) => !t.isCompleted).length,
      orElse: () => null,
    );

    final events = calendarAsync.maybeWhen(
      data: (events) {
        if (events.length == 1 &&
            events[0] is Map &&
            events[0].containsKey('error')) {
          return null;
        }
        return events.length;
      },
      orElse: () => null,
    );

    final unread = unreadAsync.maybeWhen(
      data: (count) => count,
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 18),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText(
                      'Daily Digest',
                      gradient: AppColors.primaryGradient,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Your productivity snapshot',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.invalidate(tasksProvider);
                  ref.invalidate(
                      calendarEventsProvider(DateUtils.dateOnly(DateTime.now())));
                  ref.invalidate(unreadProvider);
                },
                icon:
                    Icon(Icons.refresh, color: Colors.grey.shade400, size: 20),
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                  child: _digestStatCard(
                      context,
                      'Tasks',
                      pending?.toString() ?? '...',
                      'pending',
                      AppColors.strongGreen,
                      Icons.check_circle_outline_rounded)),
              const Gap(10),
              Expanded(
                  child: _digestStatCard(context, 'Events', events?.toString() ?? '...',
                      'today', AppColors.strongPink, Icons.event_rounded)),
              const Gap(10),
              Expanded(
                  child: _digestStatCard(context, 'Emails', unread?.toString() ?? '...',
                      'unread', AppColors.strongCyan, Icons.mail_outline_rounded)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _digestStatCard(BuildContext context,
      String label, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Gap(6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Gap(8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF0F172A),
              height: 1,
            ),
          ),
          const Gap(2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
