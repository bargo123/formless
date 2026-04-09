import 'package:formless/enums/question_field_type.dart';

class QuestionsModel {
  /// The question to ask the user.
  final String question;
  /// The key to store the answer in the data map.
  final String key;
  /// Custom instructions for the AI on how to judge this answer (injected into the system prompt).
  ///
  /// Use this to spell out rules the model should follow when accepting or rejecting,
  /// e.g. "only accept if the name is exactly 3 characters" or "must be a valid email format".
  /// When set, the model uses this as a strict validation rule; it is not shown verbatim to
  /// the user unless the model paraphrases it in a rejection reason.
  final String? validationMessage;

  /// Optional hint for how to interpret answers (text vs numeric, etc.).
  final QuestionFieldType? type;

  /// Optional async callback for custom validation **after** the AI accepts the answer.
  ///
  /// The LLM still validates format and rules first ([validationMessage], [type], etc.).
  /// This runs only when that passes. Use it for anything the model cannot do reliably:
  /// calling your API to see if a nickname is taken, uniqueness in your database,
  /// or other business rules.
  ///
  /// Return `null` to accept the answer, or a non-empty [String] to reject it.
  /// The returned string is shown to the user as the rejection reason.
  ///
  /// ```dart
  /// onValidate: (answer) async {
  ///   final taken = await Api.isNicknameTaken(answer);
  ///   return taken ? 'That nickname is already taken, please choose another.' : null;
  /// }
  /// ```
  final Future<String?> Function(String answer)? onValidate;

  const QuestionsModel({
    required this.question,
    required this.key,
    this.validationMessage,
    this.type,
    this.onValidate,
  });
}
