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

    // Activity Chip / Tool Call - Make it subtle
    if (message.role == 'tool') {
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
                     "Processed ${message.content.length > 20 ? 'data...' : message.content}", 
                     style: TextStyle(fontSize: 10, color: theme.colorScheme.secondary, fontWeight: FontWeight.w500)
                   ),
                 ],
               ),
             ),
           ),
         ),
       );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.primaryGradient : null,
          color: isUser ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: isUser ? const Radius.circular(24) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser 
                  ? AppColors.primaryPurple.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: isUser ? null : Border.all(color: Colors.black.withOpacity(0.03)),
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
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset('assets/images/vyana_logo.png', width: 14, height: 14, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Vyana",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            MarkdownBody(
              data: message.content.isEmpty && message.isStreaming ? "..." : message.content,
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
                 ),
                 blockquote: TextStyle(color: isUser ? Colors.white70 : theme.colorScheme.secondary),
                 blockquoteDecoration: BoxDecoration(
                   border: Border(left: BorderSide(color: isUser ? Colors.white30 : theme.colorScheme.secondary.withOpacity(0.3), width: 3)),
                 ),
              ),
            ),
            if (!message.isStreaming && !isUser) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied'), duration: Duration(milliseconds: 600), behavior: SnackBarBehavior.floating),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(Icons.copy_rounded, size: 14, color: isUser ? Colors.white54 : Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ],
            if (message.isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 12),
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
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: (message.role == 'user' ? Colors.white : AppColors.primaryPurple).withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
