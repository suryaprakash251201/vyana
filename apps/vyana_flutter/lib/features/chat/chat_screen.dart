import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/features/chat/chat_provider.dart';
import 'package:vyana_flutter/features/chat/widgets/chat_bubble.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

const List<String> _quickPrompts = [
  'Plan my day with priorities',
  'Summarize my recent tasks',
  'Draft a polite follow-up email',
  'Create a 15-min workout plan',
];

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  AudioRecorder? _audioRecorder;
  bool _isListening = false;
  bool _isProcessingAudio = false;
  String? _currentRecordingPath;
  bool _isRecordingLocked = false; // Prevent race conditions

  @override
  void initState() {
    super.initState();
    // Check microphone permission on init
    _checkMicPermission();
  }
  
  Future<void> _checkMicPermission() async {
    final recorder = AudioRecorder();
    final hasPermission = await recorder.hasPermission();
    recorder.dispose();
    
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required for voice input')),
      );
    }
  }

  Future<void> _startRecording() async {
    // Prevent race conditions from multiple triggers
    if (_isRecordingLocked || _isListening || _isProcessingAudio) {
      debugPrint('Voice: Recording locked or already in progress');
      return;
    }
    _isRecordingLocked = true;
    
    try {
      // Initialize a fresh recorder
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();
      
      // Check if recorder is in a valid state
      final isRecording = await _audioRecorder!.isRecording();
      if (isRecording) {
        debugPrint('Voice: Already recording, stopping first');
        await _audioRecorder!.stop();
      }
      
      if (await _audioRecorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _currentRecordingPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        debugPrint('Voice: Starting recording to $_currentRecordingPath');
        await _audioRecorder!.start(const RecordConfig(), path: _currentRecordingPath!);
        if (mounted) setState(() => _isListening = true);
        debugPrint('Voice: Recording started');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please grant microphone permission')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording error: $e')),
        );
      }
      // Reset state on error
      if (mounted) setState(() => _isListening = false);
      _audioRecorder?.dispose();
      _audioRecorder = null;
    } finally {
      _isRecordingLocked = false;
    }
  }

  Future<void> _stopRecording() async {
    if (!_isListening) {
      debugPrint('Voice: Not listening, nothing to stop');
      return;
    }
    
    debugPrint('Voice: Stopping recording');
    
    try {
      final path = await _audioRecorder?.stop();
      debugPrint('Voice: Recording stopped, path: $path');
      
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessingAudio = true;
        });
      }

      if (path != null && path.isNotEmpty) {
        await _transcribeAudio(path);
        // Clean up audio file after transcription
        _cleanupAudioFile(path);
      }
    } catch (e) {
      debugPrint("Error stopping record: $e");
    } finally {
      _audioRecorder?.dispose();
      _audioRecorder = null;
      
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessingAudio = false;
        });
      }
    }
  }
  
  void _cleanupAudioFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint("Error cleaning up audio file: $e");
    }
  }

  Future<void> _transcribeAudio(String path) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final uri = apiClient.resolve(
        '/voice/transcribe',
        fallbackBaseUrl: 'http://127.0.0.1:8000',
      );
      
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        path,
        contentType: MediaType('audio', 'm4a')
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['text'];
        if (text != null && text.toString().isNotEmpty && mounted) {
          setState(() {
             _controller.text = text.toString().trim();
             _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
          });
        }
      } else {
        debugPrint("Transcription failed: ${response.statusCode} ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Transcription failed: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      debugPrint("Transcribe error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Voice error: ${e.toString().split(':').last.trim()}")),
        );
      }
    }
  }

  void _createNewChat() {
    ref.read(chatProvider.notifier).clearChat();
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder?.dispose();
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
                    ).animate().fade().scale(duration: 400.ms),
                    const Gap(12),
                    Text('Vyana', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary))
                        .animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
                    const Spacer(),
                    if (chatState.pendingCount > 0) ...[
                      OutlinedButton.icon(
                        onPressed: chatState.isRetrying ? null : () => ref.read(chatProvider.notifier).retryOutbox(),
                        icon: chatState.isRetrying
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh, size: 16),
                        label: Text('Retry (${chatState.pendingCount})', style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const Gap(8),
                    ],
                    FilledButton.icon(
                      onPressed: _createNewChat,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text("New Chat"),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface, foregroundColor: theme.colorScheme.primary,
                        elevation: 0, side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ).animate().fadeIn(delay: 200.ms).scale(),
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
                          return ChatBubble(message: chatState.messages[index])
                             .animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
                        },
                      ),
              ),
              
              if (chatState.isLoading && chatState.messages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(borderRadius: BorderRadius.circular(4), color: AppColors.primaryPurple, backgroundColor: AppColors.primaryPurple.withOpacity(0.1))
                     .animate().fadeIn(),
                ),
              
              // Input Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickActionButton(
                            icon: Icons.check_circle_outline,
                            label: 'Tasks',
                            onTap: () => context.go('/tasks'),
                          ),
                          _QuickActionButton(
                            icon: Icons.calendar_today,
                            label: 'Calendar',
                            onTap: () => context.go('/calendar'),
                          ),
                          _QuickActionButton(
                            icon: Icons.mail_outline,
                            label: 'Mail',
                            onTap: () => context.go('/mail'),
                          ),
                          _QuickActionButton(
                            icon: Icons.grid_view,
                            label: 'Tools',
                            onTap: () => context.go('/tools'),
                          ),
                        ],
                      ),
                    ),
                    const Gap(10),
                    Row(
                      children: [
                        // Voice Button (Hold OR Tap to record)
                        GestureDetector(
                          onLongPressStart: (_) => _startRecording(),
                          onLongPressEnd: (_) => _stopRecording(),
                          onLongPressCancel: _stopRecording,
                          onTap: () {
                            if (_isListening) {
                              _stopRecording();
                            } else {
                              _startRecording();
                            }
                          },
                          child: Tooltip(
                            message: 'Hold or Tap to record voice',
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isListening ? AppColors.errorRed : theme.colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _isListening 
                                        ? Colors.transparent 
                                        : AppColors.primaryPurple.withOpacity(0.3),
                                    width: 1.5
                                ),
                                boxShadow: _isListening ? [BoxShadow(color: AppColors.errorRed.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)] : [],
                              ),
                              child: _isProcessingAudio 
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(
                                      _isListening ? Icons.mic : Icons.mic_none, 
                                      color: _isListening ? Colors.white : AppColors.primaryPurple,
                                    ),
                            ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 500.ms, curve: Curves.easeInOut).then().scale(begin: const Offset(1.2,1.2), end: const Offset(1,1)),
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
                        
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _controller,
                          builder: (context, value, child) {
                            final hasText = value.text.trim().isNotEmpty;
                            
                            return Container(
                              decoration: BoxDecoration(
                                gradient: hasText || chatState.isLoading ? AppColors.primaryGradient : null,
                                color: !hasText && !chatState.isLoading ? Colors.grey.shade300 : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                    if (hasText || chatState.isLoading)
                                        BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: chatState.isLoading || !hasText ? null : _sendMessage,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: chatState.isLoading 
                                        ? const SizedBox(
                                            width: 24, 
                                            height: 24, 
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                          )
                                        : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                                  ),
                                ),
                              ),
                            ).animate(target: hasText ? 1 : 0).scale(begin: const Offset(0.9,0.9), end: const Offset(1.1,1.1), duration: 200.ms);
                          }
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
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
            Container(
              width: 140, height: 140,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient, shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primaryPurple.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset('assets/images/vyana_logo.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.auto_awesome, color: AppColors.primaryPurple, size: 48))
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms, curve: Curves.easeInOut)
             .then()
             .shimmer(duration: 2000.ms, delay: 1000.ms, color: Colors.white.withOpacity(0.4))
             .boxShadow(
                begin: BoxShadow(color: AppColors.primaryPurple.withOpacity(0.2), blurRadius: 20, spreadRadius: 0),
                end: BoxShadow(color: AppColors.primaryPurple.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
                duration: 2000.ms,
                curve: Curves.easeInOut
             ),
            const Gap(32),
            SizedBox(
              height: 40,
              child: DefaultTextStyle(
                style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText('Chat with Vyana', speed: const Duration(milliseconds: 100)),
                  ],
                  totalRepeatCount: 1,
                ),
              ),
            ),
            const Gap(8),
            Text('Ask anything or give commands', style: TextStyle(color: Colors.grey.shade600, fontSize: 16))
               .animate().fadeIn(delay: 1500.ms, duration: 800.ms),
            const Gap(20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPrompts
                  .map((prompt) => ActionChip(
                        label: Text(prompt, style: const TextStyle(fontSize: 12)),
                        onPressed: () => _sendQuickPrompt(prompt),
                        backgroundColor: theme.colorScheme.surface,
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ))
                  .toList(),
            ).animate().fadeIn(delay: 1700.ms, duration: 800.ms),
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
    // Force rebuild for send button animation
    setState(() {});
  }

  void _sendQuickPrompt(String text) {
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
    setState(() {});
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: theme.colorScheme.primary),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
