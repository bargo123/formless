import 'package:flutter/material.dart';
import 'package:formless/models/formless_theme.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.theme,
    this.onEdit,
  });

  final String text;
  final bool isUser;
  final FormlessTheme? theme;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser
        ? (theme?.userBubbleColor ?? const Color(0xff612A74))
        : (theme?.botBubbleColor ?? Colors.grey.shade200);
    final textColor = isUser ? (theme?.userTextColor ?? Colors.white) : theme?.botTextColor;

    final bubble = GestureDetector(
      onLongPress: isUser ? onEdit : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor),
        ),
      ),
    );

    if (!isUser || onEdit == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: bubble,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            bubble,
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
