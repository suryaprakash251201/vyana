import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// State to hold selected date and events
// State to hold selected date and events
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateUtils.dateOnly(DateTime.now());

  void set(DateTime date) => state = DateUtils.dateOnly(date);
}

final calendarEventsProvider = FutureProvider.family<List<dynamic>, DateTime>((ref, date) async {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = await SharedPreferences.getInstance();
  final calendarId = prefs.getString('calendarId');
  final calendarIdParam = (calendarId != null && calendarId.trim().isNotEmpty)
      ? '&calendar_id=${Uri.encodeComponent(calendarId.trim())}'
      : '';
  
  // Format target date: YYYY-MM-DD
  final dateStr = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
  final cacheKey = 'calendar_events_$dateStr';

  // 1. Try to fetch from API
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final res = await apiClient.get('/calendar/events?date=$dateStr&user_id=$userId$calendarIdParam');
    if (res['events'] is List) {
      final events = res['events'] as List<dynamic>;
      // Save to cache
      await prefs.setString(cacheKey, jsonEncode(events));
      return events;
    } else if (res['error'] != null) {
      throw res['error'];
    }
    return [];
  } catch (e) {
    // 2. If API fails (offline), try Cache
    if (prefs.containsKey(cacheKey)) {
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        return jsonDecode(cachedStr) as List<dynamic>;
      }
    }
    // Re-throw if no cache
    rethrow;
  }
});

// 0: Month, 1: Schedule
final calendarViewModeProvider = NotifierProvider<CalendarViewModeNotifier, int>(CalendarViewModeNotifier.new);

class CalendarViewModeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int mode) => state = mode;
}

final scheduleEventsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final now = DateTime.now();
  final startStr = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
  // Fetch next 7 days
  final end = now.add(const Duration(days: 7));
  final endStr = "${end.year}-${end.month.toString().padLeft(2,'0')}-${end.day.toString().padLeft(2,'0')}";
  final prefs = await SharedPreferences.getInstance();
  final calendarId = prefs.getString('calendarId');
  final calendarIdParam = (calendarId != null && calendarId.trim().isNotEmpty)
      ? '&calendar_id=${Uri.encodeComponent(calendarId.trim())}'
      : '';
  
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final res = await apiClient.get('/calendar/events?start=$startStr&end=$endStr&user_id=$userId$calendarIdParam');
    if (res['events'] is List) {
      return res['events'] as List<dynamic>;
    }
  } catch (e) {
    debugPrint("Error fetching schedule: $e");
  }
  return [];
});

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});



  void _showAddEventDialog(BuildContext context, DateTime selectedDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEventSheet(initialDate: selectedDate),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    
    final eventsAsync = viewMode == 0 
        ? ref.watch(calendarEventsProvider(selectedDate))
        : ref.watch(scheduleEventsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accentPink.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accentPink, AppColors.primaryPurple],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPink.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
                    ),
                    const Gap(16),
                    Text(
                      'Calendar',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                     IconButton(
                      onPressed: () => ref.refresh(calendarEventsProvider(selectedDate)),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),



              // View Toggle
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref.read(calendarViewModeProvider.notifier).set(0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: viewMode == 0 ? AppColors.primaryPurple : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Month View",
                            style: TextStyle(
                              color: viewMode == 0 ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref.read(calendarViewModeProvider.notifier).set(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: viewMode == 1 ? AppColors.primaryPurple : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Schedule",
                            style: TextStyle(
                              color: viewMode == 1 ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (viewMode == 0) ...[
                // Date Navigation (Only for Month View)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                       BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8, offset: const Offset(0,2)
                       )
                    ]
                  ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        ref.read(selectedDateProvider.notifier).set(
                            selectedDate.subtract(const Duration(days: 1)));
                      },
                    ),
                    
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const Gap(8),
                        Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                           style: theme.textTheme.titleLarge?.copyWith(
                             fontWeight: FontWeight.bold,
                             fontSize: 18,
                           ),
                        ),
                      ],
                    ),

                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        ref.read(selectedDateProvider.notifier).set(
                            selectedDate.add(const Duration(days: 1)));
                      },
                    ),
                  ],
                ),
              ),
              ], // End Date Navigation
              
              const Gap(16),
              const Gap(8),

              // Content
              Expanded(
                child: eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return Center(child: Text('No events found', style: TextStyle(color: Colors.grey.shade600)));
                    }
                    if (events.length == 1 && events[0] is Map && events[0]['error'] != null) {
                       return Center(child: Text("Error: ${events[0]['error']}", style: const TextStyle(color: Colors.red)));
                    }
                    if (events.length == 1 && events[0] is Map && events[0]['error'] != null) {
                       return Center(child: Text("Error: ${events[0]['error']}", style: const TextStyle(color: Colors.red)));
                    }
                    return viewMode == 0
                      ? _buildEventsView(events, theme, ref)
                      : _buildScheduleView(events, theme, ref);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e', textAlign: TextAlign.center)),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context, viewMode==0 ? selectedDate : DateTime.now()),
        backgroundColor: AppColors.accentPink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }



  Widget _buildEventsView(List<dynamic> events, ThemeData theme, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final summary = event['summary'] ?? 'No Title';
        final start = event['start'] ?? '';
        final location = event['location'];
        final description = event['description'] ?? '';
        final meetLink = event['meet_link'];
        final isAllDay = event['is_all_day'] == true;
        final recurrence = event['recurrence'];
        
        // Get color from event
        final colorId = event['color_id']?.toString() ?? '9';
        final eventColor = calendarColors[colorId] ?? AppColors.accentPink;
        
        // Parse time
        String timeStr = "";
        DateTime? eventDate;
        try {
          eventDate = DateTime.parse(start).toLocal();
          timeStr = isAllDay 
            ? "All day" 
            : "${eventDate.hour.toString().padLeft(2,'0')}:${eventDate.minute.toString().padLeft(2,'0')}";
        } catch (_) {}

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => _AddEventSheet(
                initialDate: eventDate ?? ref.read(selectedDateProvider),
                existingEvent: event,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
               boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4, offset:const Offset(0,2)
                  )
               ]
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                     Text(timeStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isAllDay ? eventColor : null)),
                     Container(
                      width: 4, height: 40,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: eventColor,
                        borderRadius: BorderRadius.circular(4)
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(summary, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          if (recurrence != null) ...[
                            const Gap(4),
                            Icon(Icons.repeat, size: 16, color: Colors.grey.shade600),
                          ],
                          if (meetLink != null) ...[
                            const Gap(4),
                            GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(meetLink);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam, size: 14, color: Colors.green.shade700),
                                    const Gap(2),
                                    Text("Meet", style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const Gap(4),
                        Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      if (location != null && location.isNotEmpty) ...[
                        const Gap(4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const Gap(4),
                            Expanded(child: Text(location, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleView(List<dynamic> events, ThemeData theme, WidgetRef ref) {
    // Group events by Date
    final Map<String, List<dynamic>> grouped = {};
    for (var e in events) {
      final start = e['start'];
      if (start != null) {
        try {
          final dt = DateTime.parse(start).toLocal();
          final dateKey = "${dt.year}-${dt.month}-${dt.day}";
          if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
          grouped[dateKey]!.add(e);
        } catch (_) {}
      }
    }
    
    if (grouped.isEmpty) {
       return Center(child: Text('No upcoming schedule for next 7 days', style: TextStyle(color: Colors.grey.shade600)));
    }
    
    final sortedKeys = grouped.keys.toList()..sort();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final dayEvents = grouped[key]!;
        final dateParts = key.split('-');
        final dt = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
        
        // Header
        bool isToday = DateUtils.isSameDay(dt, DateTime.now());
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
               child: Text(
                 isToday ? "Today" : "${dt.day}/${dt.month} - ${_getWeekday(dt.weekday)}",
                 style: theme.textTheme.titleMedium?.copyWith(
                   fontWeight: FontWeight.bold,
                   color: isToday ? AppColors.accentPink : theme.colorScheme.onSurface
                 ),
               ),
             ),
             ...dayEvents.map((e) => _buildEventItem(context, e, theme, ref)).toList(),
          ],
        );
      },
    );
  }
  
  String _getWeekday(int d) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[d-1];
  }

  Widget _buildEventItem(BuildContext context, dynamic event, ThemeData theme, WidgetRef ref) {
      final summary = event['summary'] ?? 'No Title';
      final start = event['start'] ?? '';
      final meetLink = event['meet_link'];
      final isAllDay = event['is_all_day'] == true;
      final recurrence = event['recurrence'];
      
      // Get color from event
      final colorId = event['color_id']?.toString() ?? '9';
      final eventColor = calendarColors[colorId] ?? AppColors.primaryPurple;
      
      String timeStr = "";
      DateTime? eventDate;
      try {
        eventDate = DateTime.parse(start).toLocal();
        timeStr = isAllDay 
          ? "All day" 
          : "${eventDate.hour.toString().padLeft(2,'0')}:${eventDate.minute.toString().padLeft(2,'0')}";
      } catch (_) {}

      return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => _AddEventSheet(
                initialDate: eventDate ?? DateTime.now(),
                existingEvent: event,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.05)),
               boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 2, offset:const Offset(0,1)
                  )
               ]
            ),
            child: Row(
              children: [
                Text(timeStr, style: TextStyle(fontWeight: FontWeight.bold, color: eventColor)),
                const Gap(12),
                Container(width: 3, height: 24, decoration: BoxDecoration(
                  color: eventColor,
                  borderRadius: BorderRadius.circular(2),
                )),
                const Gap(12),
                Expanded(child: Text(summary, style: const TextStyle(fontWeight: FontWeight.w500))),
                if (recurrence != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.repeat, size: 16, color: Colors.grey.shade500),
                  ),
                if (meetLink != null)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(meetLink);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Icon(Icons.videocam, size: 18, color: Colors.green.shade600),
                  ),
              ],
            ),
          )
      );
  }
}

// Calendar color mapping
const Map<String, Color> calendarColors = {
  '1': Color(0xFF7986CB), // Lavender
  '2': Color(0xFF33B679), // Sage
  '3': Color(0xFF8E24AA), // Grape
  '4': Color(0xFFE67C73), // Flamingo
  '5': Color(0xFFF6BF26), // Banana
  '6': Color(0xFFFF8A65), // Tangerine
  '7': Color(0xFF039BE5), // Peacock
  '8': Color(0xFF616161), // Graphite
  '9': Color(0xFF3F51B5), // Blueberry
  '10': Color(0xFF0B8043), // Basil
  '11': Color(0xFFD50000), // Tomato
};

class _AddEventSheet extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final Map<String, dynamic>? existingEvent; // null for new, filled for edit
  
  const _AddEventSheet({required this.initialDate, this.existingEvent});

  @override
  ConsumerState<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<_AddEventSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _attendeesController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  bool _saving = false;
  
  // New feature flags
  bool _isAllDay = false;
  bool _addMeetLink = false;
  String _recurrence = 'none'; // none, daily, weekly, monthly, yearly
  int _recurrenceCount = 1;
  String _colorId = '9'; // Default blueberry
  int _reminderMinutes = 30;

  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _endTime = TimeOfDay(hour: _selectedTime.hour + 1, minute: _selectedTime.minute);
    
    if (widget.existingEvent != null) {
      _titleController.text = widget.existingEvent!['summary'] ?? '';
      _descriptionController.text = widget.existingEvent!['description'] ?? '';
      _locationController.text = widget.existingEvent!['location'] ?? '';
      
      // Parse existing event data
      final startStr = widget.existingEvent!['start'];
      if (startStr != null) {
        try {
          final dt = DateTime.parse(startStr).toLocal();
          _selectedDate = DateUtils.dateOnly(dt);
          _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}
      }
      
      final endStr = widget.existingEvent!['end'];
      if (endStr != null) {
        try {
          final dt = DateTime.parse(endStr).toLocal();
          _endTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}
      }
      
      // Check if all-day event
      _isAllDay = widget.existingEvent!['is_all_day'] == true;
      
      // Color
      if (widget.existingEvent!['color_id'] != null) {
        _colorId = widget.existingEvent!['color_id'].toString();
      }
      
      // Check for Meet link
      _addMeetLink = widget.existingEvent!['meet_link'] != null;
      
      // Recurrence
      if (widget.existingEvent!['recurrence'] != null) {
        final recStr = widget.existingEvent!['recurrence'].toString().toLowerCase();
        if (recStr.contains('daily')) _recurrence = 'daily';
        else if (recStr.contains('weekly')) _recurrence = 'weekly';
        else if (recStr.contains('monthly')) _recurrence = 'monthly';
        else if (recStr.contains('yearly')) _recurrence = 'yearly';
      }
    }
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) return;
    setState(() => _saving = true);
    
    final dt = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute
    );
    final startStr = dt.toIso8601String();
    
    // Calculate duration
    final startMinutes = _selectedTime.hour * 60 + _selectedTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    int durationMinutes = endMinutes - startMinutes;
    if (durationMinutes <= 0) durationMinutes = 60; // Default 1 hour

    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarId = prefs.getString('calendarId');
      Map<String, dynamic> result;
      
      // Build request body with all features
      final body = <String, dynamic>{
        'summary': _titleController.text,
        'start_time': startStr,
        'duration_minutes': _isAllDay ? 1440 : durationMinutes,
        'description': _descriptionController.text,
        'is_all_day': _isAllDay,
        'add_meet_link': _addMeetLink,
        'color_id': _colorId,
        'reminders': [_reminderMinutes],
        if (_locationController.text.isNotEmpty) 'location': _locationController.text,
        if (_attendeesController.text.isNotEmpty) 
          'attendees': _attendeesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        if (_recurrence != 'none') 'recurrence': _recurrence.toUpperCase(),
        if (_recurrence != 'none') 'recurrence_count': _recurrenceCount,
        if (calendarId != null && calendarId.trim().isNotEmpty) 'calendar_id': calendarId.trim(),
      };
      
      if (isEditing) {
        // Update existing event
        body['id'] = widget.existingEvent!['id'];
        result = await ref.read(apiClientProvider).put('/calendar/update', body: body);
      } else {
        // Create new event
        body['user_id'] = Supabase.instance.client.auth.currentUser?.id;
        result = await ref.read(apiClientProvider).post('/calendar/create', body: body);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['result'] ?? (isEditing ? "Event Updated" : "Event Created")))
        );
        ref.invalidate(calendarEventsProvider);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!isEditing) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text("Are you sure you want to delete this event?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarId = prefs.getString('calendarId');
      await ref.read(apiClientProvider).delete('/calendar/delete', body: {
        'id': widget.existingEvent!['id'],
        if (calendarId != null && calendarId.trim().isNotEmpty) 'calendar_id': calendarId.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event deleted")));
        ref.invalidate(calendarEventsProvider);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      decoration: BoxDecoration(
         color: theme.scaffoldBackgroundColor,
         borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEditing ? "Edit Event" : "Add Event", style: theme.textTheme.titleLarge),
                if (isEditing)
                  IconButton(
                    onPressed: _saving ? null : _delete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ],
            ),
            const Gap(16),
            
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Event Title",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              autofocus: !isEditing,
            ),
            const Gap(12),
            
            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description (optional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                hintText: "Add notes about this event...",
              ),
              maxLines: 2,
            ),
            const Gap(12),
            
            // Location
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Location (optional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: "Add location...",
              ),
            ),
            const Gap(16),
            
            // All-day toggle
            SwitchListTile(
              title: const Text("All-day event"),
              subtitle: const Text("Event spans entire day"),
              value: _isAllDay,
              onChanged: (v) => setState(() => _isAllDay = v),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.wb_sunny_outlined),
            ),
            
            // Date and Time pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                       final d = await showDatePicker(
                         context: context, 
                         initialDate: _selectedDate, 
                         firstDate: DateTime.now().subtract(const Duration(days: 365)), 
                         lastDate: DateTime(2030)
                       );
                       if (d != null) setState(() => _selectedDate = d);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                  ),
                ),
                if (!_isAllDay) ...[
                  const Gap(8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                         final t = await showTimePicker(context: context, initialTime: _selectedTime);
                         if (t != null) setState(() => _selectedTime = t);
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                         final t = await showTimePicker(context: context, initialTime: _endTime);
                         if (t != null) setState(() => _endTime = t);
                      },
                      icon: const Icon(Icons.access_time_filled),
                      label: Text(_endTime.format(context)),
                    ),
                  ),
                ],
              ],
            ),
            const Gap(16),
            
            // Color picker
            Row(
              children: [
                const Icon(Icons.palette, color: Colors.grey),
                const Gap(12),
                const Text("Color: "),
                const Gap(8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: calendarColors.entries.map((entry) {
                        final isSelected = _colorId == entry.key;
                        return GestureDetector(
                          onTap: () => setState(() => _colorId = entry.key),
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                              border: isSelected 
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                              boxShadow: isSelected 
                                ? [BoxShadow(color: entry.value.withOpacity(0.5), blurRadius: 8)]
                                : null,
                            ),
                            child: isSelected 
                              ? const Icon(Icons.check, color: Colors.white, size: 16) 
                              : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            
            // Google Meet toggle
            SwitchListTile(
              title: const Text("Add Google Meet"),
              subtitle: const Text("Generate video call link"),
              value: _addMeetLink,
              onChanged: (v) => setState(() => _addMeetLink = v),
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.videocam, color: _addMeetLink ? Colors.green : Colors.grey),
            ),
            
            // Recurrence
            Row(
              children: [
                const Icon(Icons.repeat, color: Colors.grey),
                const Gap(12),
                const Text("Repeat: "),
                const Gap(8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _recurrence,
                    isExpanded: true,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    ],
                    onChanged: (v) => setState(() => _recurrence = v ?? 'none'),
                  ),
                ),
              ],
            ),
            if (_recurrence != 'none') ...[
              const Gap(8),
              Row(
                children: [
                  const Gap(36),
                  const Text("For "),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _recurrenceCount.toString()),
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n > 0) _recurrenceCount = n;
                      },
                    ),
                  ),
                  const Gap(8),
                  Text("${_recurrence == 'daily' ? 'days' : _recurrence == 'weekly' ? 'weeks' : _recurrence == 'monthly' ? 'months' : 'years'}"),
                ],
              ),
            ],
            const Gap(16),
            
            // Reminder
            Row(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.grey),
                const Gap(12),
                const Text("Reminder: "),
                const Gap(8),
                Expanded(
                  child: DropdownButton<int>(
                    value: _reminderMinutes,
                    isExpanded: true,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('At time of event')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                      DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                      DropdownMenuItem(value: 60, child: Text('1 hour before')),
                      DropdownMenuItem(value: 1440, child: Text('1 day before')),
                    ],
                    onChanged: (v) => setState(() => _reminderMinutes = v ?? 30),
                  ),
                ),
              ],
            ),
            const Gap(16),
            
            // Attendees
            TextField(
              controller: _attendeesController,
              decoration: const InputDecoration(
                labelText: "Attendees (optional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people_outline),
                hintText: "email1@example.com, email2@example.com",
              ),
            ),
            const Gap(24),
            
            // Show existing Meet link if editing
            if (isEditing && widget.existingEvent!['meet_link'] != null) ...[
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.green),
                  title: const Text("Google Meet"),
                  subtitle: Text(widget.existingEvent!['meet_link'], style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () async {
                      final uri = Uri.parse(widget.existingEvent!['meet_link']);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
              ),
              const Gap(16),
            ],
            
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.accentPink),
              child: _saving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : Text(isEditing ? "Update Event" : "Create Event"),
            )
          ],
        ),
      ),
    );
  }
}
