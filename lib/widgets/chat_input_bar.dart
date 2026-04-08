import 'package:flutter/material.dart';
import 'package:formless/models/formless_theme.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isWaiting,
    this.theme,
    this.sendIcon,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isWaiting;
  final FormlessTheme? theme;
  final Widget? sendIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onSend(),
            style: theme?.inputTextStyle,
            decoration: theme?.inputDecoration ??
                InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    borderSide: theme?.inputBorderColor != null
                        ? BorderSide(color: theme!.inputBorderColor!)
                        : const BorderSide(color:  Color(0xff612A74)),
                  ) ,
                  border: OutlineInputBorder(
                    
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    borderSide: theme?.inputBorderColor != null
                        ? BorderSide(color: theme!.inputBorderColor!)
                        : const BorderSide(color: Color(0xff612A74)),
                  ),
                  hintText: theme?.inputHintText ?? 'Answer the question',
                ),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: isWaiting ? null : onSend,
          child: CircleAvatar(
            backgroundColor: theme?.sendButtonColor ?? const Color(0xff612A74),
            radius: 30,
            child: sendIcon ??
                Image.asset(
                  'assets/images/send_icon.png',
                  scale: 3,
                  package: 'formless',
                ),
          ),
        ),
      ],
    );
  }
}
