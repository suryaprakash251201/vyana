import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:vyana_flutter/core/api_client.dart';

/// Voice service for TTS (Text-to-Speech) functionality
class VoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Ref _ref;
  
  VoiceService(this._ref);
  
  /// Synthesize text to speech and play it
  Future<void> speak(String text, {String voice = 'orpheus', VoidCallback? onComplete}) async {
    if (text.isEmpty) return;
    
    try {
      final apiClient = _ref.read(apiClientProvider);
      final baseUrl = apiClient.baseUrl.isEmpty ? 'http://127.0.0.1:8000' : apiClient.baseUrl;
      final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      
      final response = await http.post(
        Uri.parse('$normalizedBase/tts/synthesize'),
        headers: {'Content-Type': 'application/json'},
        body: '{"text": "${_escapeJson(text)}", "voice": "$voice"}',
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await _playAudio(bytes, onComplete);
      } else {
        debugPrint('TTS failed: ${response.statusCode}');
        onComplete?.call();
      }
    } catch (e) {
      debugPrint('TTS error: $e');
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
  
  Future<void> _playAudio(Uint8List bytes, VoidCallback? onComplete) async {
    try {
      // Set completion listener
      _audioPlayer.onPlayerComplete.first.then((_) {
        onComplete?.call();
      });
      
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('Audio playback error: $e');
      onComplete?.call();
    }
  }
  
  /// Stop any ongoing speech
  Future<void> stop() async {
    await _audioPlayer.stop();
  }
  
  /// Check if currently playing
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  
  void dispose() {
    _audioPlayer.dispose();
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
