import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isInitialized = false;

  // Initialize - call this in main
  static Future<void> init() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      // Set audio context for better cross-platform support
      await _player.setPlayerMode(PlayerMode.lowLatency);
      _isInitialized = true;
      debugPrint("SoundService initialized successfully");
    } catch (e) {
      debugPrint("SoundService init error: $e");
      _isInitialized = false;
    }
  }

  static Future<void> playSent() async {
    if (!_isInitialized) {
      debugPrint("SoundService not initialized, attempting init...");
      await init();
    }
    try {
      await _player.play(AssetSource('sounds/sent.mp3'), volume: 0.5);
    } catch (e) {
      debugPrint("Error playing sent sound: $e");
    }
  }

  static Future<void> playReceived() async {
    if (!_isInitialized) {
      debugPrint("SoundService not initialized, attempting init...");
      await init();
    }
    try {
      await _player.play(AssetSource('sounds/received.mp3'), volume: 0.5);
    } catch (e) {
      debugPrint("Error playing received sound: $e");
    }
  }

  static Future<void> play(String filename) async {
    if (!_isInitialized) {
      debugPrint("SoundService not initialized, attempting init...");
      await init();
    }
    try {
      await _player.play(AssetSource('sounds/$filename'), volume: 0.5);
      debugPrint("Playing sound: $filename");
    } catch (e) {
      debugPrint("Error playing sound $filename: $e");
    }
  }
}
