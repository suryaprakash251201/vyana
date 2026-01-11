import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:vyana_flutter/core/api_client.dart';

/// Voice service for TTS (Text-to-Speech) functionality
class VoiceService {
  AudioPlayer? _audioPlayer;
  final Ref _ref;
  bool _isPlaying = false;
  
  VoiceService(this._ref);
  
  /// Initialize audio player
  AudioPlayer _getPlayer() {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }
  
  /// Synthesize text to speech and play it
  Future<void> speak(String text, {String voice = 'Arista-PlayAI', VoidCallback? onComplete}) async {
    if (text.isEmpty) {
      onComplete?.call();
      return;
    }
    
    debugPrint('TTS: Starting to speak: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
    
    try {
      final apiClient = _ref.read(apiClientProvider);
      final baseUrl = apiClient.baseUrl.isEmpty ? 'http://127.0.0.1:8000' : apiClient.baseUrl;
      final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      
      debugPrint('TTS: Calling $normalizedBase/tts/synthesize');
      
      final response = await http.post(
        Uri.parse('$normalizedBase/tts/synthesize'),
        headers: {'Content-Type': 'application/json'},
        body: '{"text": "${_escapeJson(text)}", "voice": "$voice"}',
      ).timeout(const Duration(seconds: 60));
      
      debugPrint('TTS: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final bytes = response.bodyBytes;
        debugPrint('TTS: Received ${bytes.length} bytes of audio');
        
        // Play audio and wait for completion
        await _playAudio(bytes);
        debugPrint('TTS: Audio playback completed');
      } else {
        debugPrint('TTS failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      _isPlaying = false;
      onComplete?.call();
    }
  }
  
  String _escapeJson(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
  
  Future<void> _playAudio(Uint8List bytes) async {
    try {
      final player = _getPlayer();
      _isPlaying = true;
      
      // Use Completer to wait for playback to finish
      final completer = Completer<void>();
      
      // Listen for completion
      late StreamSubscription<void> subscription;
      subscription = player.onPlayerComplete.listen((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        subscription.cancel();
      });
      
      // Also set a timeout in case completion event doesn't fire
      Future.delayed(const Duration(seconds: 120), () {
        if (!completer.isCompleted) {
          debugPrint('TTS: Timeout waiting for audio completion');
          completer.complete();
        }
      });
      
      // Start playback
      await player.play(BytesSource(bytes));
      debugPrint('TTS: Audio player started');
      
      // Wait for completion
      await completer.future;
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }
  
  /// Stop any ongoing speech
  Future<void> stop() async {
    _isPlaying = false;
    await _audioPlayer?.stop();
  }
  
  /// Check if currently playing
  bool get isPlaying => _isPlaying;
  
  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}

/// Provider for VoiceService
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Voice assistant state
enum VoiceAssistantState {
  idle,
  listening,
  processing,
  speaking,
}
