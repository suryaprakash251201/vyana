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
import 'package:vyana_flutter/features/chat/widgets/multi_color_loader.dart';
import 'package:vyana_flutter/core/widgets/animated_gradient_border.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

const List<Map<String, dynamic>> _quickPrompts = [
  {'text': 'Plan my day', 'icon': Icons.wb_sunny_outlined},
  {'text': 'Summarize tasks', 'icon': Icons.checklist},
  {'text': 'Draft an email', 'icon': Icons.mail_outline},
  {'text': 'Quick workout', 'icon': Icons.fitness_center},
];

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  AudioRecorder? _audioRecorder;
  bool _isListening = false;
  bool _isProcessingAudio = false;
  String? _currentRecordingPath;
  bool _isRecordingLocked = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _checkMicPermission();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  Future<void> _checkMicPermission() async {
    final recorder = AudioRecorder();
    final hasPermission = await recorder.hasPermission();
    recorder.dispose();

    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Microphone permission is required for voice input')),
      );
    }
  }

  Future<void> _startRecording() async {
    if (_isRecordingLocked || _isListening || _isProcessingAudio) {
      debugPrint('Voice: Recording locked or already in progress');
      return;
    }
    _isRecordingLocked = true;

    try {
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();

      final isRecording = await _audioRecorder!.isRecording();
      if (isRecording) {
        debugPrint('Voice: Already recording, stopping first');
        await _audioRecorder!.stop();
      }

      if (await _audioRecorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _currentRecordingPath =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        debugPrint('Voice: Starting recording to $_currentRecordingPath');
        await _audioRecorder!
            .start(const RecordConfig(), path: _currentRecordingPath!);
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
      request.files.add(await http.MultipartFile.fromPath('file', path,
          contentType: MediaType('audio', 'm4a')));

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['text'];
        if (text != null && text.toString().isNotEmpty && mounted) {
          setState(() {
            _controller.text = text.toString().trim();
            _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length));
          });
        }
      } else {
        debugPrint(
            "Transcription failed: ${response.statusCode} ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Transcription failed: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      debugPrint("Transcribe error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Voice error: ${e.toString().split(':').last.trim()}")),
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
    _focusNode.dispose();
    _audioRecorder?.dispose();
    _pulseController.dispose();
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
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (next.messages.length > (prev?.messages.length ?? 0) ||
          (next.messages.isNotEmpty &&
              prev?.messages.isNotEmpty == true &&
              next.messages.last.content.length >
                  prev!.messages.last.content.length)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    const Color(0xFF1E1E2E), // Slightly lighter dark
                  ]
                : [
                    AppColors.primaryPurple.withOpacity(0.05),
                    AppColors.accentPink.withOpacity(0.05),
                    Colors.white,
                  ],
            stops: isDark ? [0.0, 1.0] : [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(theme, chatState),

              // Messages or Welcome
              Expanded(
                child: chatState.messages.isEmpty
                    ? _buildWelcomeView(theme)
                    : _buildMessageList(chatState),
              ),

              // Loading indicator (removed bottom floating pill)


              // Input Area
              _buildInputArea(theme, chatState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ChatState chatState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.transparent, // cleaner look
      child: Row(
        children: [
          // Logo
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/vyana_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fade().scale(duration: 400.ms),
          
          const Gap(16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vyana',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    chatState.isLoading ? 'Thinking...' : 'AI Assistant',
                    key: ValueKey(chatState.isLoading),
                    style: TextStyle(
                      fontSize: 12,
                      color: chatState.isLoading
                          ? AppColors.primaryPurple
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),

          // Actions
          if (chatState.pendingCount > 0)
            _buildRetryButton(chatState),
            
          const Gap(12),
          _buildNewChatButton(theme),
        ],
      ),
    );
  }

  Widget _buildRetryButton(ChatState chatState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warmOrange.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: chatState.isRetrying
              ? null
              : () => ref.read(chatProvider.notifier).retryOutbox(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                chatState.isRetrying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.warmOrange,
                        ),
                      )
                    : const Icon(Icons.refresh,
                        size: 14, color: AppColors.warmOrange),
                const Gap(4),
                Text(
                  '${chatState.pendingCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warmOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildNewChatButton(ThemeData theme) {
    return IconButton(
      onPressed: _createNewChat,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        hoverColor: AppColors.primaryPurple.withOpacity(0.1),
      ),
      icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
      tooltip: 'New Chat',
    ).animate().fadeIn(delay: 200.ms).scale();
  }

  Widget _buildMessageList(ChatState chatState) {
    // Filter out empty streaming messages to avoid double loading indicator
    final messagesToShow = chatState.messages.where((m) => 
      !(m.isStreaming && m.content.isEmpty)
    ).toList();
    
    final showThinkingBubble = chatState.isLoading && 
        (messagesToShow.isEmpty || messagesToShow.last.role != 'assistant' || messagesToShow.last.content.isEmpty);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messagesToShow.length + (showThinkingBubble ? 1 : 0),
      itemBuilder: (context, index) {
        if (showThinkingBubble && index == messagesToShow.length) {
          return _buildThinkingBubble().animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
        }

        final isLast = index == messagesToShow.length - 1;
        return ChatBubble(message: messagesToShow[index])
            .animate() 
            .fadeIn(duration: 300.ms)
            .slideY(
              begin: 0.3, 
              end: 0, 
              curve: Curves.easeOutBack, 
              duration: 400.ms
            );
      },
    );
  }

  Widget _buildThinkingBubble() {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Image.asset('assets/images/vyana_logo.png'), 
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1.seconds, color: Colors.white.withOpacity(0.8))
            .then(delay: 1.seconds),
            
            const Gap(10),
            
            Text(
              "Thinking",
              style: TextStyle(
                color: AppColors.primaryPurple.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(4),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildTypingDots(),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTypingDots() {
    return Row(
      children: List.generate(3, (i) {
        return Container(
          margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(),
            )
            .fadeIn(delay: (i * 200).ms, duration: 400.ms)
            .then()
            .fadeOut(duration: 400.ms);
      }),
    );
  }

  Widget _buildInputArea(ThemeData theme, ChatState chatState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: AnimatedGradientBorder(
          isActive: chatState.isLoading,
          borderWidth: 4,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: _isListening
                    ? AppColors.errorRed.withOpacity(0.5)
                    : theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Voice Button (Left)
                _buildVoiceButton(theme),

                // Text Area
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? "Listening..."
                            : (_isProcessingAudio ? "Processing..." : "Ask anything..."),
                        hintStyle: TextStyle(
                          color: _isListening
                              ? AppColors.errorRed
                              : Colors.grey.shade400,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isListening && !_isProcessingAudio,
                      onTap: () => setState(() {}),
                    ),
                  ),
                ),

                // Send Button (Right)
                _buildSendButton(theme, chatState),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOutQuint);
  }
  
    Widget _buildVoiceButton(ThemeData theme) {
    return GestureDetector(
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
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.all(4),
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: _isListening
                  ? AppColors.errorRed.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: _isProcessingAudio
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFF4285F4), // Google Blue
                          Color(0xFFEA4335), // Google Red
                          Color(0xFFFBBC05), // Google Yellow
                          Color(0xFF34A853), // Google Green
                        ],
                        stops: [0.0, 0.45, 0.65, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: Colors.white, // Required for ShaderMask
                      size: 24,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme, ChatState chatState) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;
        final canSend = hasText && !chatState.isLoading;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            gradient: canSend ? AppColors.primaryGradient : null,
            color: canSend ? null : Colors.transparent, // Transparant when disabled for cleaner look
            shape: BoxShape.circle,
            boxShadow: canSend
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: canSend ? _sendMessage : null,
              child: Center(
                child: chatState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: MultiColorLoader(size: 24, strokeWidth: 3),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: canSend ? Colors.white : Colors.grey.shade300,
                        size: 24,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Gap(60),
          _buildAnimatedLogo(),
          const Gap(40),
          Text(
            'How can I help you today?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms).moveY(begin: 10, end: 0),
          const Gap(40),
          _buildQuickPrompts(theme),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.1),
            AppColors.accentPink.withOpacity(0.05),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: Image.asset(
            'assets/images/vyana_logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 3.seconds)
    .then()
    .shimmer(duration: 2.seconds, delay: 2.seconds);
  }

  Widget _buildQuickPrompts(ThemeData theme) {
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _quickPrompts.asMap().entries.map((entry) {
          final idx = entry.key;
          final prompt = entry.value;
          return _buildPromptChip(
            prompt['text'] as String,
            prompt['icon'] as IconData,
            theme,
            idx,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromptChip(
      String text, IconData icon, ThemeData theme, int index) {
    return InkWell(
      onTap: () => _sendQuickPrompt(text),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryPurple),
            const Gap(8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (100 + (index * 100)).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
    setState(() {});
  }

  void _sendQuickPrompt(String text) {
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
    setState(() {});
  }
}
