import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/tasks/tasks_provider.dart';
import 'package:vyana_flutter/features/calendar/calendar_screen.dart';
import 'package:vyana_flutter/features/auth/supabase_auth_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Redirect if logged out
    ref.listen(supabaseUserProvider, (prev, next) {
       next.whenData((user) {
         if (user == null) {
           context.go('/login');
         }
       });
    });

    final tasksAsync = ref.watch(tasksProvider);
    final calendarAsync = ref.watch(calendarEventsProvider(DateUtils.dateOnly(DateTime.now())));

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
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/vyana_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.auto_awesome, color: AppColors.primaryPurple),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi Suryaprakash',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Ready to help you',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No new notifications")),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.notifications_outlined, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    // Welcome Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "How can I help you today?",
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const Gap(8),
                          Text(
                            "I can manage your tasks, check your calendar, and draft emails.",
                            style: TextStyle(color: Colors.white.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),

                    const Gap(24),
                    

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.go('/tasks'),
                            child: _buildStatCard(
                              "Tasks", 
                              tasksAsync.when(
                                data: (tasks) => "${tasks.where((t) => !t.isCompleted).length} Pending",
                                loading: () => "...",
                                error: (_, __) => "Error",
                              ),
                              Icons.check_circle_outline,
                              AppColors.successGreen,
                              theme,
                            ),
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: InkWell(
                            onTap: () => context.go('/calendar'),
                            child: _buildStatCard(
                              "Events", 
                              calendarAsync.when(
                                data: (events) {
                                   if (events.isEmpty) return "0 Today";
                                   if (events.length == 1 && events[0] is Map && events[0].containsKey('error')) {
                                     return "Error";
                                   }
                                   return "${events.length} Today";
                                },
                                loading: () => "...",
                                error: (_, __) => "Error",
                              ),
                              Icons.calendar_today,
                              AppColors.accentPink,
                              theme,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(24),
                    
                    // Recent Tasks Preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pending Tasks",
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () => context.go('/tasks'),
                          child: const Text("View All"),
                        )
                      ],
                    ),
                    const Gap(8),
                    tasksAsync.when(
                      data: (tasks) {
                        final pending = tasks.where((t) => !t.isCompleted).take(3).toList();
                        if (pending.isEmpty) {
                          return Text("No pending tasks.", style: TextStyle(color: Colors.grey));
                        }
                        return Column(
                          children: pending.map((t) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle_outlined, size: 16, color: Colors.grey),
                                const Gap(12),
                                Expanded(child: Text(t.title)),
                              ],
                            ),
                          )).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text("Could not load tasks"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(12),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }


}
