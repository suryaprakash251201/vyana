import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/tasks/tasks_provider.dart';
import 'package:vyana_flutter/features/calendar/calendar_screen.dart';
import 'package:vyana_flutter/features/auth/supabase_auth_service.dart';
import 'package:vyana_flutter/features/notifications/notifications_screen.dart';
import 'package:vyana_flutter/features/voice_assistant/voice_assistant_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/features/mail/mail_screen.dart';

final backendStatusProvider = FutureProvider<bool>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final res = await apiClient.get('/health');
    if (res is Map && res['status'] == 'ok') return true;
    return true;
  } catch (_) {
    return false;
  }
});

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
    final unreadAsync = ref.watch(unreadProvider);
    final backendStatusAsync = ref.watch(backendStatusProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VoiceAssistantScreen()),
          );
        },
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.mic, color: Colors.white)
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(delay: 2000.ms, duration: 1000.ms)
            .shake(hz: 4, curve: Curves.easeInOutCubic, duration: 1000.ms, delay: 2000.ms),
      ).animate().scale(delay: 500.ms, duration: 300.ms, curve: Curves.easeOutBack),
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
                    ).animate().fade().scale(duration: 400.ms),
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
                        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
                        Text(
                          'Ready to help you',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                        const Gap(6),
                        backendStatusAsync.when(
                          data: (ok) => _statusChip(ok ? 'Backend: OK' : 'Backend: Offline', ok),
                          loading: () => _statusChip('Backend: Checking', false),
                          error: (_, __) => _statusChip('Backend: Error', false),
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
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.notifications_outlined, size: 22),
                          ),
                        ),
                      ),
                    ).animate().scale(delay: 300.ms, duration: 300.ms),
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
                          SizedBox(
                            height: 30, // Fixed height for typing text
                            child: DefaultTextStyle(
                              style: theme.textTheme.titleLarge!.copyWith(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold
                              ),
                              child: AnimatedTextKit(
                                animatedTexts: [
                                  TypewriterAnimatedText(
                                    'How can I help you today?',
                                    speed: const Duration(milliseconds: 70),
                                  ),
                                ],
                                totalRepeatCount: 1,
                                displayFullTextOnTap: true,
                              ),
                            ),
                          ),
                          const Gap(8),
                          Text(
                            "I can manage your tasks, check your calendar, and draft emails.",
                            style: TextStyle(color: Colors.white.withOpacity(0.9)),
                          ).animate().fadeIn(delay: 1500.ms, duration: 500.ms),
                        ],
                      ),
                    ).animate()
                     .fadeIn(duration: 600.ms)
                     .slideY(begin: 0.2, end: 0)
                     .shimmer(delay: 1500.ms, duration: 1500.ms, color: Colors.white38),
                     
                    const Gap(24),

                    // Daily Digest
                    _buildDigestCard(theme, tasksAsync, calendarAsync, unreadAsync),
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
                              index: 1,
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
                              index: 2,
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
                    ).animate().fadeIn(delay: 400.ms).slideX(),
                    const Gap(8),
                    tasksAsync.when(
                      data: (tasks) {
                        final pending = tasks.where((t) => !t.isCompleted).take(3).toList();
                        if (pending.isEmpty) {
                          return Text("No pending tasks.", style: TextStyle(color: Colors.grey))
                              .animate().fadeIn(delay: 500.ms);
                        }
                        return Column(
                          children: pending.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final t = entry.value;
                            return Container(
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
                            ).animate(delay: (400 + (idx * 100)).ms)
                             .fadeIn()
                             .slideX(begin: 0.1);
                          }).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator().animate().fadeIn(),
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

  Widget _buildDigestCard(
    ThemeData theme,
    AsyncValue<List<TaskItem>> tasksAsync,
    AsyncValue<List<dynamic>> calendarAsync,
    AsyncValue<int> unreadAsync,
  ) {
    final pending = tasksAsync.maybeWhen(
      data: (tasks) => tasks.where((t) => !t.isCompleted).length,
      orElse: () => null,
    );

    final events = calendarAsync.maybeWhen(
      data: (events) {
        if (events.length == 1 && events[0] is Map && events[0].containsKey('error')) {
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
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
              const Gap(8),
              Text('Daily Digest', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const Gap(10),
          Text(
            'Snapshot of today’s workload and inbox.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const Gap(12),
          Row(
            children: [
              _digestPill('Tasks', pending == null ? '...' : '$pending pending', AppColors.successGreen),
              const Gap(8),
              _digestPill('Events', events == null ? '...' : '$events today', AppColors.accentPink),
              const Gap(8),
              _digestPill('Mail', unread == null ? '...' : '$unread unread', AppColors.accentCyan),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _digestPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const Gap(2),
          Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _statusChip(String text, bool active) {
    final color = active ? AppColors.successGreen : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 10),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme, {int index = 0}) {
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
            child: Icon(icon, color: color, size: 20)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.2, duration: 1000.ms, curve: Curves.easeInOut),
          ),
          const Gap(12),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    ).animate(delay: (200 * index).ms).fadeIn().slideY(begin: 0.2, end: 0);
  }


}
