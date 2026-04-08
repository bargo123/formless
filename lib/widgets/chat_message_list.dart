import 'package:flutter/material.dart';
import 'package:formless/models/answers_model.dart';
import 'package:formless/models/formless_theme.dart';
import 'package:formless/models/questions_model.dart';
import 'package:formless/widgets/message_bubble.dart';
import 'package:formless/widgets/typing_indicator.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isWaiting,
    this.theme,
    this.onEditMessage,
  });

  final List<dynamic> messages;
  final ScrollController scrollController;
  final bool isWaiting;
  final FormlessTheme? theme;
  final void Function(int index)? onEditMessage;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: messages.length + (isWaiting ? 1 : 0),
      itemBuilder: (context, index) {
        if (isWaiting && index == messages.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme?.botBubbleColor ?? Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TypingIndicator(
                dotColor: theme?.typingIndicatorColor,
              ),
            ),
          );
        }

        final item = messages[index];
        if (item is QuestionsModel) {
          return MessageBubble(
            text: item.question,
            isUser: false,
            theme: theme,
          );
        } else if (item is AnswersModel) {
          return MessageBubble(
            text: item.answer,
            isUser: true,
            theme: theme,
            onEdit: onEditMessage != null ? () => onEditMessage!(index) : null,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
