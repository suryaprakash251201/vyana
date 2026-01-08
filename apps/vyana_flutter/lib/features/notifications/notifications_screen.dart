import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vyana_flutter/core/theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Mock notifications for now
    final notifications = [
      {'title': 'Welcome to Vyana', 'body': 'Your AI assistant is ready to help.', 'time': 'Just now', 'isRead': false},
      {'title': 'Calendar Connected', 'body': 'Successfully connected to Google Calendar.', 'time': '2m ago', 'isRead': true},
      {'title': 'New Feature', 'body': 'Try out long press to record voice notes!', 'time': '1h ago', 'isRead': true},
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Notifications", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle_outline_rounded, size: 20, color: theme.colorScheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All marked as read')));
            },
            tooltip: 'Mark all as read',
          ),
          const Gap(8),
        ],
      ),
      body: notifications.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.notifications_off_outlined, size: 64, color: theme.colorScheme.outline.withOpacity(0.5)),
                   const Gap(16),
                   Text("No notifications", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['isRead'] as bool;
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? theme.colorScheme.surface : theme.colorScheme.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead ? theme.colorScheme.outline.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRead ? theme.colorScheme.surfaceContainerHighest : AppColors.primaryPurple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRead ? Icons.notifications_outlined : Icons.notifications_active_rounded,
                          size: 20,
                          color: isRead ? theme.colorScheme.secondary : AppColors.primaryPurple,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notif['title'] as String,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  notif['time'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontSize: 10
                                  ),
                                ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              notif['body'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
