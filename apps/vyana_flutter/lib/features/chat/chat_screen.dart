import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/features/chat/chat_provider.dart';
import 'package:vyana_flutter/features/chat/widgets/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isListening = false;
  bool _isProcessingAudio = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isListening = true);
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isListening = false;
        _isProcessingAudio = true;
      });

      if (path != null) {
        await _transcribeAudio(path);
      }
    } catch (e) {
      print("Error stopping record: $e");
    } finally {
      if (mounted) setState(() => _isProcessingAudio = false);
    }
  }

  Future<void> _transcribeAudio(String path) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final baseUrl = apiClient.baseUrl.isEmpty ? 'http://127.0.0.1:8000' : apiClient.baseUrl;
      final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final uri = Uri.parse('$normalizedBase/voice/transcribe');
      
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        path,
        contentType: MediaType('audio', 'm4a')
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['text'];
        if (text != null && text.isNotEmpty) {
          setState(() {
             _controller.text = text;
             _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
          });
        }
      } else {
        print("Transcription failed: ${response.statusCode} ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transcription failed: ${response.statusCode}")));
      }
    } catch (e) {
      print("Transcribe error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _createNewChat() {
    ref.read(chatProvider.notifier).clearChat();
    _controller.clear();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final theme = Theme.of(context);

    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (next.messages.length > (prev?.messages.length ?? 0) || 
          (next.messages.isNotEmpty && prev?.messages.isNotEmpty == true && next.messages.last.content.length > prev!.messages.last.content.length)) {
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryPurple.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      height: 40, width: 40,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primaryPurple.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: ClipOval(child: Image.asset('assets/images/vyana_logo.png', fit: BoxFit.cover)),
                    ),
                    const Gap(12),
                    Text('Vyana', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _createNewChat,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text("New Chat"),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface, foregroundColor: theme.colorScheme.primary,
                        elevation: 0, side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Messages
              Expanded(
                child: chatState.messages.isEmpty
                    ? _buildWelcomeView(theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          return ChatBubble(message: chatState.messages[index]);
                        },
                      ),
              ),
              
              if (chatState.isLoading && chatState.messages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(borderRadius: BorderRadius.circular(4), color: AppColors.primaryPurple, backgroundColor: AppColors.primaryPurple.withOpacity(0.1)),
                ),
              
              // Input Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    // Voice Button (Hold to record)
                    GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      // Also support Tap to toggle for non-touch?
                      // Let's keep Hold for now or Tap-Tap. 
                      // User asked for "voice function".
                      onTapDown: (_) => _startRecording(),
                      onTapUp: (_) => _stopRecording(),
                      onTapCancel: _stopRecording,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isListening ? AppColors.errorRed : theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: _isListening ? Colors.transparent : Colors.grey.shade300),
                          boxShadow: _isListening ? [BoxShadow(color: AppColors.errorRed.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)] : [],
                        ),
                        child: _isProcessingAudio 
                            ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.white : Colors.grey.shade600),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(28),
                           boxShadow: [BoxShadow(color: AppColors.primaryPurple.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: _isListening ? "Listening..." : (_isProcessingAudio ? "Processing..." : "Ask Vyana anything..."),
                            hintStyle: TextStyle(color: _isListening ? AppColors.primaryPurple : Colors.grey.shade400),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            filled: true, fillColor: theme.colorScheme.surface,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          enabled: !_isListening && !_isProcessingAudio,
                        ),
                      ),
                    ),
                    const Gap(12),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final hasText = _controller.text.isNotEmpty || chatState.isLoading;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: hasText ? null : AppColors.primaryGradient,
                            color: hasText ? theme.colorScheme.primary : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3 + (_pulseController.value * 0.2)), blurRadius: 12 + (_pulseController.value * 4), offset: const Offset(0, 4))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: chatState.isLoading ? null : _sendMessage,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Icon(chatState.isLoading ? Icons.hourglass_top : Icons.send_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 120, height: 120,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3 + (_pulseController.value * 0.2)), blurRadius: 30 + (_pulseController.value * 10), spreadRadius: 5)],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(child: Image.asset('assets/images/vyana_logo.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.auto_awesome, color: AppColors.primaryPurple, size: 48))),
                  ),
                );
              },
            ),
            const Gap(32),
            Text('Chat with Vyana', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
            const Gap(8),
            Text('Ask anything or give commands', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
  }
}
