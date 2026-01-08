import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  // Initialize - call this in main
  static Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  static Future<void> playSent() async {
    try {
      // User needs to add assets/sounds/sent.mp3
      // We'll use a try-catch to avoid crashing if file missing
      await _player.play(AssetSource('sounds/sent.mp3'), volume: 0.5);
    } catch (e) {
      debugPrint("Error playing sent sound: $e");
    }
  }

  static Future<void> playReceived() async {
    try {
      await _player.play(AssetSource('sounds/received.mp3'), volume: 0.5);
    } catch (e) {
      debugPrint("Error playing received sound: $e");
    }
  }
}
