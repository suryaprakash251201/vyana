import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/chat/chat_provider.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  String _displayedText = '';
  int _currentIndex = 0;
  bool _animationComplete = false;
  String? _lastContent;

  void _copyMessage(BuildContext context) {
    final text = widget.message.content.trim();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void didUpdateWidget(ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If content changed (streaming update), continue animation
    if (widget.message.content != _lastContent) {
      _lastContent = widget.message.content;
      if (!_animationComplete) {
        _continueAnimation();
      } else if (widget.message.isStreaming) {
        _animationComplete = false;
        _continueAnimation();
      }
    }
  }

  void _initAnimation() {
    final isUser = widget.message.role == 'user';
    _lastContent = widget.message.content;
    
    // User messages and tool messages don't animate
    if (isUser || widget.message.role == 'tool') {
      _displayedText = widget.message.content;
      _animationComplete = true;
      return;
    }
    
    // If message is not streaming and has content, show immediately (old messages)
    if (!widget.message.isStreaming && widget.message.content.isNotEmpty) {
      _displayedText = widget.message.content;
      _animationComplete = true;
      return;
    }
    
    // Start typing animation for new AI messages
    _displayedText = '';
    _currentIndex = 0;
    _continueAnimation();
  }

  void _continueAnimation() {
    if (!mounted) return;
    
    final content = widget.message.content;
    if (_currentIndex >= content.length) {
      if (!widget.message.isStreaming) {
        setState(() => _animationComplete = true);
      }
      return;
    }
    
    // Animate characters with variable speed
    Future.delayed(const Duration(milliseconds: 8), () {
      if (!mounted) return;
      
      final content = widget.message.content;
      if (_currentIndex < content.length) {
        setState(() {
          // Add multiple characters at once for faster feel
          final charsToAdd = _getCharsToAdd(content);
          _currentIndex += charsToAdd;
          if (_currentIndex > content.length) _currentIndex = content.length;
          _displayedText = content.substring(0, _currentIndex);
        });
        _continueAnimation();
      } else if (!widget.message.isStreaming) {
        setState(() => _animationComplete = true);
      }
    });
  }

  int _getCharsToAdd(String content) {
    // Speed up for longer content
    if (content.length > 500) return 4;
    if (content.length > 200) return 3;
    if (content.length > 100) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';
    final theme = Theme.of(context);

    // Activity Chip / Tool Call - Make it subtle
    if (widget.message.role == 'tool') {
       return Padding(
         padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 24),
         child: Center(
           child: Opacity(
             opacity: 0.7,
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
               decoration: BoxDecoration(
                 color: theme.colorScheme.surfaceContainerHighest,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Icon(Icons.hub_outlined, size: 12, color: theme.colorScheme.secondary),
                   const SizedBox(width: 6),
                   Text(
                     "Processed ${widget.message.content.length > 20 ? 'data...' : widget.message.content}", 
                     style: TextStyle(fontSize: 10, color: theme.colorScheme.secondary, fontWeight: FontWeight.w500)
                   ),
                 ],
               ),
             ),
           ),
         ),
       );
    }

    // Determine what text to show
    final textToShow = isUser ? widget.message.content : _displayedText;
    final showCursor = !isUser && !_animationComplete && widget.message.isStreaming;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isUser ? null : () => _copyMessage(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          decoration: BoxDecoration(
            gradient: isUser ? AppColors.primaryGradient : null,
            color: isUser ? null : theme.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: isUser 
                    ? AppColors.primaryPurple.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: isUser ? null : Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated text content with typing cursor
              if (textToShow.isEmpty && !_animationComplete)
                _buildTypingIndicator()
              else
                MarkdownBody(
                  data: showCursor ? '$textToShow▌' : textToShow,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                     p: theme.textTheme.bodyMedium?.copyWith(
                         color: isUser ? Colors.white : theme.colorScheme.onSurface,
                         height: 1.5,
                         fontSize: 15,
                     ),
                     strong: TextStyle(fontWeight: FontWeight.w600, color: isUser ? Colors.white : theme.colorScheme.primary),
                     code: TextStyle(
                       backgroundColor: isUser ? Colors.white24 : theme.colorScheme.surfaceContainerHighest,
                       color: isUser ? Colors.white : theme.colorScheme.primary,
                       fontSize: 13,
                       fontFamily: 'monospace',
                     ),
                     codeblockDecoration: BoxDecoration(
                       color: isUser ? Colors.white10 : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: Colors.white.withOpacity(0.1)),
                     ),
                     blockquote: TextStyle(color: isUser ? Colors.white70 : theme.colorScheme.secondary),
                     blockquoteDecoration: BoxDecoration(
                       border: Border(left: BorderSide(color: isUser ? Colors.white30 : theme.colorScheme.secondary.withOpacity(0.3), width: 3)),
                     ),
                  ),
                ),
              if (_animationComplete && !isUser) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _copyMessage(context),
                      icon: const Icon(Icons.copy, size: 16),
                      tooltip: 'Copy reply',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => _buildTypingDot(i)),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
