import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/core/widgets/gradient_widgets.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientText(
          'Quick Actions',
          gradient: AppColors.primaryGradient,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ).animate().fadeIn(delay: 200.ms),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'New Task',
                Icons.add_circle_outline_rounded,
                AppColors.successGreen,
                () => context.go('/tools/tasks'),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Schedule',
                Icons.calendar_month_rounded,
                AppColors.accentPink,
                () => context.go('/tools/calendar'),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Compose',
                Icons.mark_email_unread_rounded,
                AppColors.accentCyan,
                () => context.go('/tools/mail'),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Contacts',
                Icons.people_alt_rounded,
                AppColors.warmOrange,
                () => context.go('/tools/contacts'),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
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
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


}
