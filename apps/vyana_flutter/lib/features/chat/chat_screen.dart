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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                  ]
                : [
                    AppColors.primaryPurple.withOpacity(0.06),
                    AppColors.accentPink.withOpacity(0.03),
                    theme.scaffoldBackgroundColor,
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

              // Loading indicator
              if (chatState.isLoading && chatState.messages.isNotEmpty)
                _buildLoadingIndicator(),

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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo with gradient border
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              height: 38,
              width: 38,
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
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ).animate().fade().scale(duration: 400.ms),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vyana',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  chatState.isLoading ? 'Thinking...' : 'AI Assistant',
                  style: TextStyle(
                    fontSize: 11,
                    color: chatState.isLoading
                        ? AppColors.primaryPurple
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
          // Retry button if pending
          if (chatState.pendingCount > 0) ...[
            _buildRetryButton(chatState),
            const Gap(8),
          ],
          // New chat button
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _createNewChat,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18, color: Colors.white),
                Gap(4),
                Text(
                  'New',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale();
  }

  Widget _buildMessageList(ChatState chatState) {
    // Filter out empty streaming messages to avoid double loading indicator
    final messagesToShow = chatState.messages.where((m) => 
      !(m.isStreaming && m.content.isEmpty)
    ).toList();
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messagesToShow.length,
      itemBuilder: (context, index) {
        final isLast = index == messagesToShow.length - 1;
        return ChatBubble(message: messagesToShow[index])
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: isLast ? 0.15 : 0.05, end: 0);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const Gap(10),
                Text(
                  'Vyana is typing',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(4),
                _buildTypingDots(),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Voice Button
          _buildVoiceButton(theme),
          const Gap(10),
          // Text Input
          Expanded(
            child: _buildTextField(theme),
          ),
          const Gap(10),
          // Send Button
          _buildSendButton(theme, chatState),
        ],
      ),
    ).animate().slideY(begin: 0.5, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isListening
                  ? AppColors.errorRed
                  : theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isListening
                    ? Colors.transparent
                    : AppColors.primaryPurple.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: AppColors.errorRed
                            .withOpacity(0.3 + (_pulseController.value * 0.2)),
                        blurRadius: 12 + (_pulseController.value * 8),
                        spreadRadius: _pulseController.value * 4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: _isProcessingAudio
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple,
                    ),
                  )
                : Icon(
                    _isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: _isListening ? Colors.white : AppColors.primaryPurple,
                    size: 24,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _focusNode.hasFocus
              ? AppColors.primaryPurple.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: _focusNode.hasFocus
                ? AppColors.primaryPurple.withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: 4,
        minLines: 1,
        decoration: InputDecoration(
          hintText: _isListening
              ? "Listening..."
              : (_isProcessingAudio ? "Processing..." : "Message Vyana..."),
          hintStyle: TextStyle(
            color: _isListening
                ? AppColors.primaryPurple
                : Colors.grey.shade400,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        style: const TextStyle(fontSize: 15),
        onSubmitted: (_) => _sendMessage(),
        enabled: !_isListening && !_isProcessingAudio,
        onTap: () => setState(() {}),
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
          decoration: BoxDecoration(
            gradient: canSend ? AppColors.primaryGradient : null,
            color: canSend ? null : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            boxShadow: canSend
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: canSend ? _sendMessage : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: chatState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: canSend ? Colors.white : Colors.grey.shade400,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Gap(40),
          // Animated Logo
          _buildAnimatedLogo(),
          const Gap(32),
          // Title
          SizedBox(
            height: 40,
            child: DefaultTextStyle(
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: -0.5,
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Chat with Vyana',
                    speed: const Duration(milliseconds: 80),
                  ),
                ],
                totalRepeatCount: 1,
              ),
            ),
          ),
          const Gap(8),
          Text(
            'Your AI assistant for tasks, emails, and more',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 1500.ms, duration: 600.ms),
          const Gap(40),
          // Quick Prompts
          _buildQuickPrompts(theme),
          const Gap(32),
          // Tips
          _buildTips(theme),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
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
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 2000.ms,
          curve: Curves.easeInOut,
        )
        .shimmer(
          delay: 1500.ms,
          duration: 1500.ms,
          color: Colors.white.withOpacity(0.3),
        );
  }

  Widget _buildQuickPrompts(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt, size: 18, color: AppColors.warmOrange),
            const Gap(6),
            Text(
              'Quick Start',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 1700.ms),
        const Gap(12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
      ],
    );
  }

  Widget _buildPromptChip(
      String text, IconData icon, ThemeData theme, int index) {
    return InkWell(
      onTap: () => _sendQuickPrompt(text),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.15)),
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.primaryPurple),
            ),
            const Gap(10),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (1800 + (index * 100)).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1);
  }

  Widget _buildTips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentCyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.tips_and_updates_outlined,
                size: 20, color: AppColors.accentCyan),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentCyan,
                  ),
                ),
                const Gap(2),
                Text(
                  'Hold the mic button to record, or tap once to toggle.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 2200.ms, duration: 500.ms);
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
