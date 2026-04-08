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

  const QuestionsModel({
    required this.question,
    required this.key,
    this.validationMessage,
    this.type,
  });
}
