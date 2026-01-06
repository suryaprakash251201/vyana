import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vyana_flutter/main.dart'; // Import VyanaApp
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: VyanaApp()));

    // Verify chat screen is default
    expect(find.byIcon(Icons.chat_bubble), findsOneWidget); // Bottom Nav Icon selected
    
    // Check initial state (might be loading or empty)
    await tester.pumpAndSettle();
    expect(find.text("Vyana"), findsOneWidget); // AppBar title
  });
}
