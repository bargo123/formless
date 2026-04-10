import 'package:flutter/material.dart';

/// Controls the visual appearance of the root `Formless` chat widget.
///
/// All properties are optional — any value left null falls back to the
/// built-in default. Only override what you need.
///
/// ```dart
/// Formless(
///   theme: FormlessTheme(
///     userBubbleColor: Colors.blue,
///     botBubbleColor: Colors.grey.shade100,
///     sendButtonColor: Colors.blue,
///   ),
///   ...
/// )
/// ```
class FormlessTheme {
  const FormlessTheme({
    this.userBubbleColor,
    this.botBubbleColor,
    this.userTextColor,
    this.botTextColor,
    this.sendButtonColor,
    this.typingIndicatorColor,
    this.inputBorderColor,
    this.inputHintText,
    this.inputDecoration,
    this.inputTextStyle,
  });

  /// Background color of the user's chat bubbles.
  /// Defaults to `Color(0xff612A74)`.
  final Color? userBubbleColor;

  /// Background color of the bot's chat bubbles.
  /// Defaults to `Colors.grey.shade200`.
  final Color? botBubbleColor;

  /// Text color inside the user's chat bubbles.
  /// Defaults to `Colors.white`.
  final Color? userTextColor;

  /// Text color inside the bot's chat bubbles.
  /// Defaults to the surrounding theme's default text color.
  final Color? botTextColor;

  /// Background color of the send button circle.
  /// Defaults to `Color(0xff612A74)`.
  final Color? sendButtonColor;

  /// Color of the animated typing indicator dots shown while the bot is thinking.
  /// Defaults to `Colors.grey`.
  final Color? typingIndicatorColor;

  /// Border color of the text input field.
  /// Ignored when [inputDecoration] is provided.
  /// Defaults to the surrounding theme's outline color.
  final Color? inputBorderColor;

  /// Hint text shown inside the input field when it is empty.
  /// Ignored when [inputDecoration] is provided.
  /// Defaults to `'Answer the question'`.
  final String? inputHintText;

  /// Fully custom decoration for the text input field.
  ///
  /// When set, this replaces the default decoration entirely — pass the same
  /// [InputDecoration] you already use elsewhere in your app to make the field
  /// feel native. [inputBorderColor] and [inputHintText] are ignored when this
  /// is provided.
  ///
  /// ```dart
  /// inputDecoration: InputDecoration(
  ///   hintText: 'Your answer…',
  ///   filled: true,
  ///   fillColor: Colors.grey.shade100,
  ///   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  /// )
  /// ```
  final InputDecoration? inputDecoration;

  /// Style applied to the text the user types inside the input field.
  /// Useful for matching your app's font family, size, or weight.
  final TextStyle? inputTextStyle;
}
