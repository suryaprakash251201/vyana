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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    if (hour < 20) return '🌆';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(supabaseUserProvider, (prev, next) {
      next.whenData((user) {
        if (user == null) {
          context.go('/login');
        }
      });
    });

    final tasksAsync = ref.watch(tasksProvider);
    final calendarAsync =
        ref.watch(calendarEventsProvider(DateUtils.dateOnly(DateTime.now())));
    final unreadAsync = ref.watch(unreadProvider);
    final backendStatusAsync = ref.watch(backendStatusProvider);

    return Scaffold(
      floatingActionButton: _buildFAB(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkSurface.withOpacity(0.8),
                  ]
                : [
                    AppColors.primaryPurple.withOpacity(0.08),
                    AppColors.accentPink.withOpacity(0.04),
                    theme.scaffoldBackgroundColor,
                  ],
            stops: isDark ? [0.0, 1.0] : [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(theme, backendStatusAsync),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Gap(8),

                    // Hero Card
                    _buildHeroCard(theme),
                    const Gap(20),

                    // Quick Actions
                    _buildQuickActions(theme),
                    const Gap(20),

                    // Daily Digest
                    _buildDigestCard(
                        theme, tasksAsync, calendarAsync, unreadAsync),
                    const Gap(20),

                    // Stats Grid
                    _buildStatsGrid(theme, tasksAsync, calendarAsync),
                    const Gap(20),

                    // Upcoming Section
                    _buildUpcomingSection(theme, tasksAsync, calendarAsync),
                    const Gap(100), // Space for FAB
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple
                    .withOpacity(0.4 + (_pulseController.value * 0.2)),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: _pulseController.value * 4,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const VoiceAssistantScreen()),
              );
            },
            backgroundColor: AppColors.primaryPurple,
            elevation: 0,
            child: const Icon(Icons.mic, color: Colors.white, size: 28),
          ),
        );
      },
    ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.elasticOut);
  }

  Widget _buildHeader(ThemeData theme, AsyncValue<bool> backendStatusAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Avatar with glow
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/vyana_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ).animate().fade().scale(duration: 400.ms),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_getGreeting()} ${_getGreetingEmoji()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                const Gap(2),
                Text(
                  'Suryaprakash',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),
                const Gap(6),
                backendStatusAsync.when(
                  data: (ok) => _statusBadge(ok ? 'Connected' : 'Offline', ok),
                  loading: () => _statusBadge('Connecting...', false),
                  error: (_, __) => _statusBadge('Error', false),
                ),
              ],
            ),
          ),
          // Notification button with badge
          _buildNotificationButton(theme),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.9),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationsScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.notifications_outlined, size: 24),
          ),
        ),
      ),
    ).animate().scale(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildHeroCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF9333EA),
            Color(0xFFDB2777),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 14),
                        const Gap(4),
                        const Text(
                          'AI Assistant',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(12),
              SizedBox(
                height: 28, // Reduced height
                child: DefaultTextStyle(
                  style: theme.textTheme.titleLarge!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22, // Slightly smaller font
                    letterSpacing: -0.5,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'How can I help you?',
                        speed: const Duration(milliseconds: 60),
                      ),
                    ],
                    totalRepeatCount: 1,
                    displayFullTextOnTap: true,
                  ),
                ),
              ),
              const Gap(8),
              Text(
                "Manage tasks, check calendar, draft emails, and more.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const Gap(16),
              // Quick prompt buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPromptChip("What's my schedule?", Icons.calendar_today),
                  _buildPromptChip("Check emails", Icons.mail_outline),
                  _buildPromptChip("Add a task", Icons.add_task),
                ],
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.15, end: 0)
        .shimmer(delay: 2000.ms, duration: 1500.ms, color: Colors.white24);
  }

  Widget _buildPromptChip(String label, IconData icon) {
    return InkWell(
      onTap: () => context.go('/chat'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const Gap(6),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ).animate().fadeIn(delay: 200.ms),
        const Gap(12),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildQuickActionCard(
                  'New Task',
                  Icons.add_task,
                  AppColors.successGreen,
                  () => context.go('/tasks'),
                )),
                const Gap(16),
                Expanded(
                    child: _buildQuickActionCard(
                  'Schedule',
                  Icons.event,
                  AppColors.accentPink,
                  () => context.go('/calendar'),
                )),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                    child: _buildQuickActionCard(
                  'Compose',
                  Icons.edit_note,
                  AppColors.accentCyan,
                  () => context.go('/mail'),
                )),
                const Gap(16),
                Expanded(
                    child: _buildQuickActionCard(
                  'Contacts',
                  Icons.contacts,
                  AppColors.warmOrange,
                  () => context.go('/tools'),
                )),
              ],
            ),
          ],
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildQuickActionCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                    Text(
                      'Daily Digest',
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
                      'Tasks',
                      pending?.toString() ?? '...',
                      'pending',
                      AppColors.successGreen,
                      Icons.check_circle_outline)),
              const Gap(10),
              Expanded(
                  child: _digestStatCard('Events', events?.toString() ?? '...',
                      'today', AppColors.accentPink, Icons.event)),
              const Gap(10),
              Expanded(
                  child: _digestStatCard('Emails', unread?.toString() ?? '...',
                      'unread', AppColors.accentCyan, Icons.mail_outline)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _digestStatCard(
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
              color: color,
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

  Widget _buildStatsGrid(
    ThemeData theme,
    AsyncValue<List<TaskItem>> tasksAsync,
    AsyncValue<List<dynamic>> calendarAsync,
  ) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => context.go('/tasks'),
            borderRadius: BorderRadius.circular(20),
            child: _buildStatCard(
              "Pending Tasks",
              tasksAsync.when(
                data: (tasks) =>
                    tasks.where((t) => !t.isCompleted).length.toString(),
                loading: () => "...",
                error: (_, __) => "0",
              ),
              Icons.task_alt,
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
            borderRadius: BorderRadius.circular(20),
            child: _buildStatCard(
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
              Icons.calendar_month,
              AppColors.accentPink,
              theme,
              index: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      ThemeData theme,
      {int index = 0}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
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
              color: color,
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

  Widget _buildUpcomingSection(
    ThemeData theme,
    AsyncValue<List<TaskItem>> tasksAsync,
    AsyncValue<List<dynamic>> calendarAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upcoming",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: () => context.go('/tasks'),
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

  Widget _statusBadge(String text, bool active) {
    final color = active ? AppColors.successGreen : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(6),
          Text(
            text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 10),
          ),
        ],
      ),
    );
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
