import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/features/settings/settings_provider.dart';
import 'package:vyana_flutter/core/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyana_flutter/features/settings/low_cost_provider.dart';

part 'chat_provider.g.dart';

class ChatMessage {
  final String id;
  final String role; // user, model, tool
  final String content;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? content, bool? isStreaming}) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().toString(),
      role: json['role']?.toString() ?? 'model',
      content: json['content']?.toString() ?? '',
    );
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final int pendingCount;
  final bool isRetrying;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.pendingCount = 0,
    this.isRetrying = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    int? pendingCount,
    bool? isRetrying,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      pendingCount: pendingCount ?? this.pendingCount,
      isRetrying: isRetrying ?? this.isRetrying,
    );
  }
}

@Riverpod(keepAlive: true)
class Chat extends _$Chat {
  StreamSubscription? _currentStreamSubscription;
  http.Client? _activeStreamClient;
  bool _restored = false;
  static const _outboxKey = 'chat_outbox';
  
  @override
  ChatState build() {
    // Cancel any active stream when provider is disposed
    ref.onDispose(() {
      _currentStreamSubscription?.cancel();
      _activeStreamClient?.close();
    });
    _restoreMessages();
    _restoreOutboxCount();
    return ChatState();
  }

  Future<void> _restoreMessages() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('chat_history');
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final messages = decoded
            .where((item) => item is Map)
            .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (messages.isNotEmpty) {
          state = state.copyWith(messages: messages);
        }
      }
    } catch (_) {
      // Ignore restore errors
    }
  }

  Future<void> _persistMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final safeMessages = state.messages.where((m) => !m.isStreaming).toList();
      final payload = jsonEncode(safeMessages.map((m) => m.toJson()).toList());
      await prefs.setString('chat_history', payload);
    } catch (_) {
      // Ignore persist errors
    }
  }

  Future<void> _restoreOutboxCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_outboxKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        state = state.copyWith(pendingCount: decoded.length);
      }
    } catch (_) {
      // Ignore restore errors
    }
  }

  Future<List<Map<String, dynamic>>> _loadOutbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_outboxKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .where((item) => item is Map)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveOutbox(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outboxKey, jsonEncode(items));
    state = state.copyWith(pendingCount: items.length);
  }

  Future<void> _enqueueOutbox(String content) async {
    final items = await _loadOutbox();
    items.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _saveOutbox(items);
  }

  Future<void> sendMessage(String content) async {
    await _sendMessageInternal(content, addUserMessage: true);
  }

  Future<bool> _sendMessageInternal(String content, {required bool addUserMessage}) async {
    var adjustedContent = content;
    final lowCost = ref.read(lowCostSettingsProvider).value;
    if (lowCost != null && lowCost.enabled && content.length > lowCost.maxInputChars) {
      adjustedContent = content.substring(0, lowCost.maxInputChars);
    }

    if (addUserMessage) {
      final userMsg = ChatMessage(id: DateTime.now().toString(), role: 'user', content: adjustedContent);
      state = state.copyWith(
        messages: [...state.messages, userMsg],
        isLoading: true,
      );
      if (adjustedContent.length < content.length) {
        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage(
              id: DateTime.now().add(const Duration(milliseconds: 1)).toString(),
              role: 'tool',
              content: 'Low-cost mode: input trimmed to ${adjustedContent.length} chars.',
            )
          ],
        );
      }
      _persistMessages();
    } else {
      state = state.copyWith(isLoading: true);
    }

    // Add placeholder for assistant response
    final assistantMsgId = DateTime.now().add(const Duration(milliseconds: 2)).toString();
    final assistantMsg = ChatMessage(id: assistantMsgId, role: 'model', content: '', isStreaming: true);
    state = state.copyWith(messages: [...state.messages, assistantMsg]);

    final apiClient = ref.read(apiClientProvider);
    final settingsAsync = ref.read(settingsProvider);
    final settings = settingsAsync.value;

    if (settings == null) {
      _finishStreaming(assistantMsgId);
      return false;
    }

    if (apiClient.baseUrl.trim().isEmpty) {
      _appendContent(assistantMsgId, 'Backend URL is not set. Update it in Settings.');
      _finishStreaming(assistantMsgId);
      return false;
    }

    try {
      await SoundService.playSent();

      final styleHint = settings.responseStyle.isNotEmpty ? "Response style: ${settings.responseStyle}." : "";
      final toneHint = settings.responseTone.isNotEmpty ? "Tone: ${settings.responseTone}." : "";
      final combinedInstructions = [
        settings.customInstructions,
        styleHint,
        toneHint,
      ].where((value) => value.trim().isNotEmpty).join("\n");

      Future<bool> runStreamWithModel(String modelId) async {
        final request = http.Request('POST', apiClient.resolve('/chat/stream'));
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode({
          'messages': state.messages
              .where((m) => !m.isStreaming && m.role != 'tool')
              .map((m) => {'role': m.role, 'content': m.content}).toList(),
          'settings': {
            'tools_enabled': settings.toolsEnabled,
            'tamil_mode': settings.tamilMode,
            'model': modelId,
            'memory_enabled': settings.memoryEnabled,
            'custom_instructions': combinedInstructions,
            'mcp_enabled': settings.mcpEnabled,
            'max_output_tokens': settings.maxOutputTokens,
          }
        });

        _activeStreamClient?.close();
        _activeStreamClient = http.Client();
        final response = await _activeStreamClient!.send(request).timeout(const Duration(seconds: 60));

        if (response.statusCode != 200) {
          _activeStreamClient?.close();
          return false;
        }

        await _currentStreamSubscription?.cancel();

        SoundService.playReceived();

        final completer = Completer<bool>();
        _currentStreamSubscription = response.stream.transform(utf8.decoder).listen((value) {
          final lines = value.split('\n\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final dataStr = line.substring(6);
              if (dataStr.trim().isEmpty) continue;
              try {
                final data = jsonDecode(dataStr);
                if (data['type'] == 'text') {
                  _appendContent(assistantMsgId, data['content']);
                } else if (data['type'] == 'error') {
                  _appendContent(assistantMsgId, "Error: ${data['content']}");
                }
              } catch (e) {
                debugPrint('Error parsing SSE: $e');
              }
            }
          }
        }, onDone: () {
          _finishStreaming(assistantMsgId);
          _activeStreamClient?.close();
          if (!completer.isCompleted) completer.complete(true);
        }, onError: (e) {
          debugPrint('Stream error: $e');
          _appendContent(assistantMsgId, "Connection error. Please try again.");
          _finishStreaming(assistantMsgId);
          _activeStreamClient?.close();
          if (!completer.isCompleted) completer.complete(false);
        });

        return completer.future;
      }

      var success = await runStreamWithModel(settings.geminiModel);
      if (!success) {
        final lowCostSettings = ref.read(lowCostSettingsProvider).value;
        if (lowCostSettings != null && lowCostSettings.enabled && lowCostSettings.fallbackModel != settings.geminiModel) {
          _appendContent(assistantMsgId, '\nRetrying with fallback model...\n');
          success = await runStreamWithModel(lowCostSettings.fallbackModel);
        }
      }

      if (!success) {
        await _enqueueOutbox(adjustedContent);
        _appendContent(assistantMsgId, '\nSaved to Outbox. Tap Retry when online.');
      }

      return success;
    } catch (e) {
      debugPrint("Chat Error: $e");
      _appendContent(assistantMsgId, "Error: ${e.toString().split(':').last.trim()}");
      _finishStreaming(assistantMsgId);
      state = state.copyWith(isLoading: false);
      await _enqueueOutbox(adjustedContent);
      return false;
    }
  }

  void _appendContent(String id, String newContent) {
    // Skip blank/empty content to prevent blank messages
    if (newContent.trim().isEmpty) return;
    
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == id) {
          return m.copyWith(content: m.content + newContent);
        }
        return m;
      }).toList(),
    );
  }

  void _finishStreaming(String id) {
    state = state.copyWith(
      isLoading: false,
      messages: state.messages.map((m) {
        if (m.id == id) {
          return m.copyWith(isStreaming: false);
        }
        return m;
      }).toList(),
    );
    _persistMessages();
  }

  void clearChat() {
    state = ChatState();
    _persistMessages();
  }

  Future<void> retryOutbox() async {
    if (state.isRetrying) return;
    state = state.copyWith(isRetrying: true);
    final items = await _loadOutbox();
    final remaining = <Map<String, dynamic>>[];

    for (final item in items) {
      final content = item['content']?.toString() ?? '';
      if (content.trim().isEmpty) continue;
      final success = await _sendMessageInternal(content, addUserMessage: false);
      if (!success) {
        remaining.add(item);
      }
    }

    await _saveOutbox(remaining);
    state = state.copyWith(isRetrying: false);
  }
}
