import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/tasks/tasks_provider.dart';
import 'package:vyana_flutter/features/calendar/calendar_screen.dart';
import 'package:vyana_flutter/features/auth/supabase_auth_service.dart';
import 'package:vyana_flutter/features/voice_assistant/voice_assistant_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/features/mail/mail_screen.dart';

// Widgets
import 'widgets/home_header.dart';
import 'widgets/assistant_hero.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/daily_summary.dart';
import 'widgets/stats_grid.dart';
import 'widgets/upcoming_list.dart';

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
                    Colors.black,
                    const Color(0xFF050505),
                    const Color(0xFF0A0A0A),
                  ]
                : [
                    const Color(0xFFF8FAFC), // Slate 50
                    const Color(0xFFEFF6FF), // Blue 50
                    const Color(0xFFF0FDF4), // Green 50 (Hint)
                    const Color(0xFFFFF7ED), // Orange 50 (Hint)
                  ],
            stops: isDark
                ? [0.0, 0.5, 1.0]
                : [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: HomeHeader(backendStatusAsync: backendStatusAsync),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Gap(8),

                    // Hero Card
                    const AssistantHero(),
                    const Gap(20),

                    // Quick Actions
                    const QuickActionsGrid(),
                    const Gap(20),

                    // Daily Digest
                    DailySummary(
                      tasksAsync: tasksAsync,
                      calendarAsync: calendarAsync,
                      unreadAsync: unreadAsync,
                    ),
                    const Gap(20),

                    // Stats Grid
                    StatsGrid(
                      tasksAsync: tasksAsync,
                      calendarAsync: calendarAsync,
                    ),
                    const Gap(20),

                    // Upcoming Section
                    UpcomingList(tasksAsync: tasksAsync),
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
}
