import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    
    int _getIndex() {
      if (location.startsWith('/home')) return 0;
      if (location.startsWith('/chat')) return 1;
      if (location.startsWith('/tools')) return 2;
      // Tasks/Calendar/Mail should highlight Tools tab
      if (location.startsWith('/tools/tasks')) return 2;
      if (location.startsWith('/tools/calendar')) return 2;
      if (location.startsWith('/tools/mail')) return 2;
      if (location.startsWith('/settings')) return 3;
      return 0;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getIndex(),
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/home'); break;
            case 1: context.go('/chat'); break;
            case 2: context.go('/tools'); break;
            case 3: context.go('/settings'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Tools'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
