import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/chat/chat_provider.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);

    // Activity Chip / Tool Call
    if (message.role == 'tool') {
       return Padding(
         padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
         child: Center(
           child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             decoration: BoxDecoration(
               gradient: AppColors.secondaryGradient,
               borderRadius: BorderRadius.circular(20),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.build_circle_outlined, size: 16, color: Colors.white),
                 const SizedBox(width: 8),
                 Text(message.content, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
               ],
             ),
           ),
         ),
       );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
                  ? AppColors.primaryPurple.withOpacity(0.25)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset('assets/images/vyana_logo.png', width: 16, height: 16, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Vyana",
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            MarkdownBody(
              data: message.content.isEmpty && message.isStreaming ? "..." : message.content,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                 p: theme.textTheme.bodyMedium?.copyWith(
                     color: isUser ? Colors.white : theme.colorScheme.onSurface,
                     height: 1.4,
                 ),
                 code: TextStyle(
                   backgroundColor: isUser ? Colors.white24 : theme.colorScheme.surfaceContainerHighest,
                   color: isUser ? Colors.white : theme.colorScheme.primary,
                 ),
              ),
            ),
            if (!message.isStreaming) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(milliseconds: 1000)),
                    );
                  },
                  child: Icon(Icons.copy_rounded, size: 14, color: isUser ? Colors.white70 : Colors.grey.shade400),
                ),
              ),
            ],
            if (message.isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) => _buildTypingDot(i)),
                ),
              ),
          ],
        ),
      ),
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
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
