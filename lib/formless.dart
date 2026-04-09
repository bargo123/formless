import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

export 'package:formless/enums/ai_provider.dart';
export 'package:formless/enums/question_field_type.dart';
export 'package:formless/models/formless_theme.dart';
export 'package:formless/models/questions_model.dart';
export 'package:formless/widgets/chat_layout.dart' show kDefaultFormlessQuestions;

import 'package:formless/enums/ai_provider.dart';
import 'package:formless/models/formless_theme.dart';
import 'package:formless/models/questions_model.dart';
import 'package:formless/widgets/chat_layout.dart';

/// A conversational form widget powered by an LLM.
///
/// Drop [Formless] anywhere in your widget tree. It renders a chat-style UI
/// that walks the user through each question one at a time, validates answers
/// using the chosen AI provider, and calls [onComplete] with a clean
/// `key -> value` map once every field has been collected.
/// For server-side or app-specific checks (e.g. nickname already taken), set
/// [QuestionsModel.onValidate] on individual questions.
///
/// ```dart
/// Formless(
///   provider: AiProvider.openAi,
///   apiKey: 'sk-...',
///   questions: [
///     QuestionsModel(question: 'What is your name?', key: 'name', type: QuestionFieldType.text),
///     QuestionsModel(question: 'What is your email?', key: 'email', type: QuestionFieldType.email),
///   ],
///   onComplete: (data) => print(data), // {'name': 'Alice', 'email': 'alice@example.com'}
/// )
/// ```
class Formless extends StatefulWidget {
  /// A conversational form widget powered by an LLM.
  ///
  /// Renders a chat-style UI that walks the user through each [questions] one
  /// at a time, validates answers via the chosen AI [provider], and calls
  /// [onComplete] with a clean `key -> value` map once every field is collected.
  /// Use [QuestionsModel.onValidate] for app-specific checks after the AI accepts.
  ///
  /// ```dart
  /// Formless(
  ///   provider: AiProvider.openAi,
  ///   apiKey: 'sk-...',
  ///   questions: [
  ///     QuestionsModel(question: 'What is your name?', key: 'name', type: QuestionFieldType.text),
  ///     QuestionsModel(question: 'What is your email?', key: 'email', type: QuestionFieldType.email),
  ///   ],
  ///   onComplete: (data) => print(data), // {'name': 'Alice', 'email': 'alice@example.com'}
  /// )
  /// ```
  const Formless({
    super.key,
    required this.provider,
    required this.apiKey,
    this.model,
    this.questions,
    this.onComplete,
    this.onError,
    this.sendIcon,
    this.theme, this.backgroundColor,
  });

  /// The AI provider to use for answer validation.
  /// See [AiProvider] for available options and their default models.
  final AiProvider provider;

  /// Your API key for the chosen [provider].
  /// Obtain this from your provider's dashboard and pass it at runtime —
  /// never hardcode it in source control.
  final String apiKey;

  /// Override the model name sent to the provider's API.
  /// When null, each provider falls back to a sensible default
  /// (e.g. `gpt-4o-mini` for OpenAI, `gemini-3.1-flash-lite-preview` for Gemini).
  final String? model;

  /// The list of questions to collect from the user.
  /// Each [QuestionsModel] defines the question text, the key used in the
  /// result map, an optional field type, and optional custom validation rules.
  /// Defaults to [kDefaultFormlessQuestions] (name, age, email, phone) when null.
  final List<QuestionsModel>? questions;

  /// Called when the user has successfully answered all questions.
  /// Receives a `Map<String, dynamic>` where each key matches a
  /// [QuestionsModel.key] and the value is the collected answer.
  final void Function(Map<String, dynamic> data)? onComplete;

  /// Called when a network or API error occurs.
  /// Receives a human-readable error message you can display or log.
  final void Function(String error)? onError;

  /// Custom widget to show inside the send button (defaults to a send arrow icon).
  final Widget? sendIcon;

  /// Visual theme for colors used throughout the chat UI.
  /// See [FormlessTheme] for all available options.
  /// When null, built-in defaults are used.
  final FormlessTheme? theme;

  /// The background color of the formless widget.
  /// When null, the background color is the surrounding theme's background color.
  final Color? backgroundColor;

  @override
  State<Formless> createState() => _FormlessState();
}

class _FormlessState extends State<Formless> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ChatLayout(
          provider: widget.provider,
          apiKey: widget.apiKey,
          model: widget.model,
          questions: widget.questions ?? kDefaultFormlessQuestions,
          onComplete: widget.onComplete,
          onError: widget.onError,
          sendIcon: widget.sendIcon,
          theme: widget.theme,
        ),
      ),
    );
  }
}
