import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/features/settings/settings_provider.dart';

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
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@Riverpod(keepAlive: true)
class Chat extends _$Chat {
  @override
  ChatState build() {
    return ChatState();
  }

  Future<void> sendMessage(String content) async {
    final userMsg = ChatMessage(id: DateTime.now().toString(), role: 'user', content: content);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    // Add placeholder for assistant response
    final assistantMsgId = DateTime.now().add(const Duration(milliseconds: 1)).toString();
    final assistantMsg = ChatMessage(id: assistantMsgId, role: 'model', content: '', isStreaming: true);
    state = state.copyWith(messages: [...state.messages, assistantMsg]);

    final apiClient = ref.read(apiClientProvider);
    final settingsAsync = ref.read(settingsProvider); // Read latest settings
    final settings = settingsAsync.value; 

    if (settings == null) {
       _finishStreaming(assistantMsgId);
       // Handle error
       return;
    }

    try {
      final request = http.Request('POST', Uri.parse('${apiClient.baseUrl}/chat/stream'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'messages': state.messages
            .where((m) => !m.isStreaming && m.role != 'tool') 
            .map((m) => {'role': m.role, 'content': m.content}).toList(),
        'settings': {
          'tools_enabled': settings.toolsEnabled,
          'tamil_mode': settings.tamilMode,
          'model': settings.geminiModel,
          'memory_enabled': settings.memoryEnabled,
          'custom_instructions': settings.customInstructions,
        }
      });

      final response = await http.Client().send(request);

      response.stream.transform(utf8.decoder).listen((value) {
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
              print('Error parsing SSE: $e');
            }
          }
        }
      }, onDone: () {
        _finishStreaming(assistantMsgId);
      }, onError: (e) {
        _finishStreaming(assistantMsgId);
      });

    } catch (e) {
      print("Chat Error: $e");
      _appendContent(assistantMsgId, "Error: $e"); // Show error in UI
      _finishStreaming(assistantMsgId);
      state = state.copyWith(isLoading: false);
    }
  }

  void _appendContent(String id, String newContent) {
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
  }

  void clearChat() {
    state = ChatState();
  }
}
