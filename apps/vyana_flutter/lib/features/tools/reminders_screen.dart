import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gap/gap.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/main.dart'; // Access global plugin instance
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<PendingNotificationRequest> _pendingNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    if (mounted) {
      setState(() {
        _pendingNotifications = pendingNotificationRequests;
      });
    }
  }

  Future<void> _cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    await _loadNotifications();
  }

  Future<void> _scheduleNotification(String title, TimeOfDay time) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Initialize Timezone (ensure this is called in main or here once)
    tz_data.initializeTimeZones();
    
    // Convert to TZDateTime
    // Assuming local, requires timezone package setup properly.
    // For simplicity, we use the basic schedule method or zoned if needed.
    // flutter_local_notifications usually requires TZDateTime for precise scheduling.
    
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            'reminders_channel', 
            'Reminders',
            channelDescription: 'User scheduled reminders',
            importance: Importance.max,
            priority: Priority.high,
        );
        
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails, iOS: DarwinNotificationDetails());

    // Generate unique ID
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Using simple schedule (might be deprecated or limited depending on version, usually zonedSchedule is preferred)
    // We'll use zonedSchedule
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Reminder: $title',
        title,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for ${time.format(context)}')));
       await _loadNotifications();
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set Reminder"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Label (e.g., Take Meds)"),
                autofocus: true,
              ),
              const Gap(16),
              ListTile(
                title: Text("Time: ${selectedTime.format(context)}"),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: selectedTime);
                  if (t != null) {
                    setState(() => selectedTime = t);
                  }
                },
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _scheduleNotification(titleController.text, selectedTime);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Set"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reminders")),
      body: _pendingNotifications.isEmpty
          ? const Center(child: Text("No active reminders"))
          : ListView.builder(
              itemCount: _pendingNotifications.length,
              itemBuilder: (context, index) {
                final item = _pendingNotifications[index];
                return ListTile(
                  leading: const Icon(Icons.alarm, color: AppColors.primaryPurple),
                  title: Text(item.title ?? "Reminder"),
                  subtitle: Text(item.body ?? ""),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _cancelNotification(item.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_alarm),
      ),
    );
  }
}
