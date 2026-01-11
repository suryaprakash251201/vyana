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
  String _transcribedText = "";
  String _responseText = "";
  String? _currentRecordingPath;
  bool _isRecordingLocked = false;
  bool _continuousMode = true; // Auto-listen after speaking

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
          _transcribedText = "";
          _responseText = "";
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
      
      setState(() => _transcribedText = text);
      
      // Step 2: Send to AI and get response
      final response = await _getAIResponse(text);
      if (response == null || response.isEmpty) {
        _setState(VoiceAssistantState.idle);
        return;
      }
      
      setState(() => _responseText = response);
      
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
      
      // Send message and wait for response
      await chatNotifier.sendMessage(text);
      
      // Get the last assistant message
      final messages = ref.read(chatProvider).messages;
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        if (lastMessage.role != 'user') {
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

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _audioRecorder.dispose();
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
                    
                    const Gap(32),
                    
                    // Status text
                    Text(
                      _statusText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _getOrbColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const Gap(24),
                    
                    // Transcribed text
                    if (_transcribedText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.mic, size: 16, color: Colors.grey.shade600),
                                  const Gap(8),
                                  Text('You said:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                              const Gap(8),
                              Text(_transcribedText, style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    
                    if (_responseText.isNotEmpty && _transcribedText.isNotEmpty) const Gap(16),
                    
                    // Response text
                    if (_responseText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withOpacity(0.1),
                                AppColors.accentPink.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryPurple),
                                  const Gap(8),
                                  Text('Vyana:', style: TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const Gap(8),
                              Text(
                                _responseText.length > 200 ? '${_responseText.substring(0, 200)}...' : _responseText,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Bottom hint
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _state == VoiceAssistantState.idle 
                      ? 'Tap the orb to start speaking'
                      : _state == VoiceAssistantState.listening
                          ? 'Tap again to stop'
                          : '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
