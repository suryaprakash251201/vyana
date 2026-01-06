import 'dart:io';

class AppConstants {
  static String get defaultBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android Emulator loopback
    }
    return 'http://localhost:8000'; // Windows/Web/iOS Simulator
  }
  static const String appName = 'Vyana';
}
