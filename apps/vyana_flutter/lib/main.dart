import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/settings/settings_provider.dart';
import 'package:vyana_flutter/features/home/home_screen.dart';
import 'package:vyana_flutter/features/chat/chat_screen.dart';
import 'package:vyana_flutter/features/tasks/tasks_screen.dart';
import 'package:vyana_flutter/features/settings/settings_screen.dart';
import 'package:vyana_flutter/features/calendar/calendar_screen.dart';
import 'package:vyana_flutter/features/mail/mail_screen.dart';
import 'package:vyana_flutter/features/home/dashboard_screen.dart';
import 'package:vyana_flutter/features/auth/login_screen.dart';
import 'package:vyana_flutter/features/tools/tools_screen.dart';
import 'package:vyana_flutter/features/tools/reminders_screen.dart';
import 'package:vyana_flutter/features/voice_assistant/voice_assistant_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vyana_flutter/core/sound_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://bqqdjkfgkwugqssvowxi.supabase.co',
      anonKey: 'sb_publishable_yonEFuXyx5D4oJLkoS_ing_BSgQIDtO',
    );
  } catch (e) {
    debugPrint("Supabase init error: $e");
  }
  
  // Init Sounds
  try {
    await SoundService.init();
  } catch (e) {
    debugPrint("Sound init error: $e");
  }
  
  // Init Notifications
  try {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    
    // Windows-specific initialization
    const WindowsInitializationSettings initializationSettingsWindows = WindowsInitializationSettings(
      appName: 'Vyana',
      appUserModelId: 'com.vyana.app',
      guid: 'a3f02e3b-1234-5678-9abc-def012345678',
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        windows: initializationSettingsWindows,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  } catch (e) {
    debugPrint("Notification init error: $e");
  }
  
  // Init Timezones
  try {
    tz.initializeTimeZones();
  } catch (e) {
    debugPrint("Tz init error: $e");
  }

  runApp(const ProviderScope(child: VyanaApp()));
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: '/tools',
          builder: (context, state) => const ToolsScreen(),
        ),
        GoRoute(
          path: '/reminders',
          builder: (context, state) => const RemindersScreen(),
        ),
        GoRoute(
          path: '/tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/mail',
          builder: (context, state) => const MailScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/voice-assistant',
      builder: (context, state) => const VoiceAssistantScreen(),
    ),
  ],
);

class VyanaApp extends ConsumerWidget {
  const VyanaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) => MaterialApp.router(
        title: 'Vyana',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
      loading: () => const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => MaterialApp(home: Scaffold(body: Center(child: Text('Error: $err')))),
    );
  }
}
