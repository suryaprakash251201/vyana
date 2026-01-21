import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:gap/gap.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/core/api_client.dart';
import 'package:vyana_flutter/features/chat/chat_provider.dart';
import 'package:vyana_flutter/features/voice_assistant/voice_service.dart';

// Create a local model for session history
class SessionMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  SessionMessage({required this.text, required this.isUser, required this.timestamp});
}

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  VoiceAssistantState _state = VoiceAssistantState.idle;
  String _statusText = "Tap to speak";
  String? _currentRecordingPath;
  bool _isRecordingLocked = false;
  bool _continuousMode = true; // Auto-listen after speaking
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<SessionMessage> _sessionMessages = [];
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _checkMicPermission();
  }

  Future<void> _checkMicPermission() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
    }
  }

  void _setState(VoiceAssistantState newState) {
    setState(() {
      _state = newState;
      switch (newState) {
        case VoiceAssistantState.idle:
          _statusText = "Tap to speak";
          break;
        case VoiceAssistantState.listening:
          _statusText = "Listening...";
          break;
        case VoiceAssistantState.processing:
          _statusText = "Thinking...";
          break;
        case VoiceAssistantState.speaking:
          _statusText = "Speaking...";
          break;
      }
    });
  }

  Future<void> _startListening() async {
    if (_isRecordingLocked || _state == VoiceAssistantState.listening) return;
    _isRecordingLocked = true;
    
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _currentRecordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: _currentRecordingPath!);
        _setState(VoiceAssistantState.listening);
        setState(() {
          // Reset transcription logic if needed, but we use history now
        });
      }
    } catch (e) {
      debugPrint("Start recording error: $e");
    } finally {
      _isRecordingLocked = false;
    }
  }

  Future<void> _stopListening() async {
    if (_state != VoiceAssistantState.listening) return;
    
    try {
      final path = await _audioRecorder.stop();
      _setState(VoiceAssistantState.processing);
      
      if (path != null && path.isNotEmpty) {
        await _processVoiceInput(path);
        _cleanupAudioFile(path);
      } else {
        _setState(VoiceAssistantState.idle);
      }
    } catch (e) {
      debugPrint("Stop recording error: $e");
      _setState(VoiceAssistantState.idle);
    }
  }

  void _cleanupAudioFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint("Cleanup error: $e");
    }
  }

  Future<void> _processVoiceInput(String audioPath) async {
    try {
      // Step 1: Transcribe audio
      final text = await _transcribeAudio(audioPath);
      if (text == null || text.isEmpty) {
        _setState(VoiceAssistantState.idle);
        return;
      }
      
      setState(() {
        _sessionMessages.add(SessionMessage(
          text: text, 
          isUser: true, 
          timestamp: DateTime.now()
        ));
      });
      _scrollToBottom();
      
      // Step 2: Send to AI and get response
      final response = await _getAIResponse(text);
      if (response == null || response.isEmpty) {
        _setState(VoiceAssistantState.idle);
        return;
      }
      
      setState(() {
        _sessionMessages.add(SessionMessage(
          text: response, 
          isUser: false, 
          timestamp: DateTime.now()
        ));
      });
      _scrollToBottom();
      
      // Step 3: Speak the response
      _setState(VoiceAssistantState.speaking);
      final voiceService = ref.read(voiceServiceProvider);
      await voiceService.speak(response, onComplete: () {
        if (mounted) {
          if (_continuousMode) {
            // Auto-listen for next command
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _continuousMode) _startListening();
            });
          } else {
            _setState(VoiceAssistantState.idle);
          }
        }
      });
      
    } catch (e) {
      debugPrint("Process voice error: $e");
      _setState(VoiceAssistantState.idle);
    }
  }

  Future<String?> _transcribeAudio(String path) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final baseUrl = apiClient.baseUrl.isEmpty ? 'http://127.0.0.1:8000' : apiClient.baseUrl;
      final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      
      var request = http.MultipartRequest('POST', Uri.parse('$normalizedBase/voice/transcribe'));
      request.files.add(await http.MultipartFile.fromPath(
        'file', path,
        contentType: MediaType('audio', 'm4a'),
      ));
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text']?.toString().trim();
      }
    } catch (e) {
      debugPrint("Transcribe error: $e");
    }
    return null;
  }

  Future<String?> _getAIResponse(String text) async {
    try {
      // Use the chat provider to get AI response
      final chatNotifier = ref.read(chatProvider.notifier);
      
      // Send message (starts async streaming)
      await chatNotifier.sendMessage(text);
      
      // Wait for streaming to complete (isLoading becomes false)
      // Poll the state until loading is finished
      int maxWaitSeconds = 60;
      int waited = 0;
      while (ref.read(chatProvider).isLoading && waited < maxWaitSeconds) {
        await Future.delayed(const Duration(milliseconds: 200));
        waited++;
      }
      
      // Add small delay to ensure state is fully updated
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get the last assistant message
      final messages = ref.read(chatProvider).messages;
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        if (lastMessage.role != 'user' && lastMessage.content.isNotEmpty) {
          return lastMessage.content;
        }
      }
    } catch (e) {
      debugPrint("AI response error: $e");
    }
    return null;
  }

  void _toggleListening() {
    if (_state == VoiceAssistantState.idle) {
      _startListening();
    } else if (_state == VoiceAssistantState.listening) {
      _stopListening();
    } else if (_state == VoiceAssistantState.speaking) {
      // Stop speaking and go idle
      ref.read(voiceServiceProvider).stop();
      _setState(VoiceAssistantState.idle);
    }
  }

  void _handleTextSubmit(String text) async {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    setState(() {
      _sessionMessages.add(SessionMessage(
        text: text, 
        isUser: true, 
        timestamp: DateTime.now()
      ));
      _state = VoiceAssistantState.processing;
    });
    _scrollToBottom();
    
    // Get AI response
    final response = await _getAIResponse(text);
    if (response == null || response.isEmpty) {
      _setState(VoiceAssistantState.idle);
      return;
    }
    
    setState(() {
      _sessionMessages.add(SessionMessage(
        text: response, 
        isUser: false, 
        timestamp: DateTime.now()
      ));
      _state = VoiceAssistantState.speaking;
    });
    _scrollToBottom();
    
    // Speak response
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.speak(response, onComplete: () {
      if (mounted) {
        _setState(VoiceAssistantState.idle);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _audioRecorder.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryPurple.withOpacity(0.15),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Gap(8),
                    Text(
                      'Voice Assistant',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    // Continuous mode toggle
                    Row(
                      children: [
                        Text('Auto', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Switch(
                          value: _continuousMode,
                          onChanged: (v) => setState(() => _continuousMode = v),
                          activeColor: AppColors.primaryPurple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Orb
                    GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _state == VoiceAssistantState.listening 
                                ? _pulseAnimation.value 
                                : 1.0,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _getOrbGradient(),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getOrbColor().withOpacity(0.4),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _buildOrbIcon(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Conversation History
                    Expanded(
                      child: _sessionMessages.isEmpty 
                        ? Center(
                            child: Text(
                              'Start talking or typing...',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            itemCount: _sessionMessages.length,
                            itemBuilder: (context, index) {
                              final msg = _sessionMessages[index];
                              final isUser = msg.isUser;
                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isUser 
                                        ? AppColors.primaryPurple.withOpacity(0.1) 
                                        : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                                      bottomRight: Radius.circular(isUser ? 4 : 20),
                                    ),
                                    border: Border.all(
                                      color: isUser 
                                          ? AppColors.primaryPurple.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.text,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: isUser ? theme.textTheme.bodyLarge?.color : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                    
                    // Orb and Status (condensed when keyboard is open)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: MediaQuery.of(context).viewInsets.bottom > 0 ? 100 : 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (MediaQuery.of(context).viewInsets.bottom == 0) ...[
                            GestureDetector(
                              onTap: _toggleListening,
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _state == VoiceAssistantState.listening 
                                        ? _pulseAnimation.value 
                                        : 1.0,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: _getOrbGradient(),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getOrbColor().withOpacity(0.4),
                                            blurRadius: 40,
                                            spreadRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _buildOrbIcon(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Gap(24),
                            Text(
                              _statusText,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _getOrbColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else ...[
                            // Mini Orb when typing
                             GestureDetector(
                               onTap: _toggleListening,
                               child: Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   shape: BoxShape.circle,
                                   gradient: _getOrbGradient(),
                                 ),
                                 child: const Icon(Icons.mic, color: Colors.white, size: 24),
                               ),
                             ),
                             const Gap(8),
                             Text(_statusText, style: TextStyle(color: _getOrbColor(), fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                    
                    // Input Area
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onSubmitted: _handleTextSubmit,
                              textInputAction: TextInputAction.send,
                            ),
                          ),
                          const Gap(8),
                          IconButton(
                            onPressed: () => _handleTextSubmit(_textController.text),
                            icon: const Icon(Icons.send_rounded),
                            color: AppColors.primaryPurple,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
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

  Gradient _getOrbGradient() {
    switch (_state) {
      case VoiceAssistantState.idle:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryPurple, AppColors.accentPink],
        );
      case VoiceAssistantState.listening:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.errorRed, Colors.orange],
        );
      case VoiceAssistantState.processing:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber, Colors.orange],
        );
      case VoiceAssistantState.speaking:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue, Colors.cyan],
        );
    }
  }

  Color _getOrbColor() {
    switch (_state) {
      case VoiceAssistantState.idle:
        return AppColors.primaryPurple;
      case VoiceAssistantState.listening:
        return AppColors.errorRed;
      case VoiceAssistantState.processing:
        return Colors.amber;
      case VoiceAssistantState.speaking:
        return Colors.blue;
    }
  }

  Widget _buildOrbIcon() {
    switch (_state) {
      case VoiceAssistantState.idle:
        return const Icon(Icons.mic, size: 64, color: Colors.white);
      case VoiceAssistantState.listening:
        return const Icon(Icons.mic, size: 64, color: Colors.white);
      case VoiceAssistantState.processing:
        return const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 4,
          ),
        );
      case VoiceAssistantState.speaking:
        return const Icon(Icons.volume_up, size: 64, color: Colors.white);
    }
  }
}
