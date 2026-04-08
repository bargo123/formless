import 'package:flutter_test/flutter_test.dart';
import 'package:formless/enums/question_field_type.dart';
import 'package:formless/models/formless_theme.dart';
import 'package:formless/models/questions_model.dart';
import 'package:formless/validator/propmt.dart';

void main() {
  // ── QuestionsModel ──────────────────────────────────────────────────────────

  group('QuestionsModel', () {
    test('stores required fields', () {
      const q = QuestionsModel(question: 'What is your name?', key: 'name');
      expect(q.question, 'What is your name?');
      expect(q.key, 'name');
      expect(q.type, isNull);
      expect(q.validationMessage, isNull);
    });

    test('stores optional type and validationMessage', () {
      const q = QuestionsModel(
        question: 'Age?',
        key: 'age',
        type: QuestionFieldType.numeric,
        validationMessage: 'must be between 18 and 100',
      );
      expect(q.type, QuestionFieldType.numeric);
      expect(q.validationMessage, 'must be between 18 and 100');
    });
  });

  // ── FormlessTheme ───────────────────────────────────────────────────────────

  group('FormlessTheme', () {
    test('all fields are null by default', () {
      const theme = FormlessTheme();
      expect(theme.userBubbleColor, isNull);
      expect(theme.botBubbleColor, isNull);
      expect(theme.sendButtonColor, isNull);
      expect(theme.typingIndicatorColor, isNull);
      expect(theme.inputDecoration, isNull);
      expect(theme.inputTextStyle, isNull);
      expect(theme.inputBorderColor, isNull);
      expect(theme.inputHintText, isNull);
    });
  });

  // ── buildSystemPrompt ───────────────────────────────────────────────────────

  group('buildSystemPrompt', () {
    test('includes each question key in the prompt', () {
      final questions = [
        const QuestionsModel(question: 'Name?', key: 'name', type: QuestionFieldType.text),
        const QuestionsModel(question: 'Email?', key: 'email', type: QuestionFieldType.email),
      ];
      final prompt = buildSystemPrompt(questions);
      expect(prompt, contains('"name"'));
      expect(prompt, contains('"email"'));
    });

    test('includes custom validationMessage in the prompt', () {
      final questions = [
        const QuestionsModel(
          question: 'Income?',
          key: 'income',
          type: QuestionFieldType.numeric,
          validationMessage: 'only accept between 1000 and 100000',
        ),
      ];
      final prompt = buildSystemPrompt(questions);
      expect(prompt, contains('only accept between 1000 and 100000'));
      expect(prompt, contains('CUSTOM validation rule'));
    });

    test('lists all keys in the required data keys line', () {
      final questions = [
        const QuestionsModel(question: 'Name?', key: 'name'),
        const QuestionsModel(question: 'Age?', key: 'age'),
        const QuestionsModel(question: 'Email?', key: 'email'),
      ];
      final prompt = buildSystemPrompt(questions);
      expect(prompt, contains('"name"'));
      expect(prompt, contains('"age"'));
      expect(prompt, contains('"email"'));
    });

    test('uses default validation rule for email type', () {
      final questions = [
        const QuestionsModel(question: 'Email?', key: 'email', type: QuestionFieldType.email),
      ];
      final prompt = buildSystemPrompt(questions);
      expect(prompt, contains('accept only complete emails'));
    });

    test('uses default validation rule for phone type', () {
      final questions = [
        const QuestionsModel(question: 'Phone?', key: 'phone', type: QuestionFieldType.phone),
      ];
      final prompt = buildSystemPrompt(questions);
      expect(prompt, contains('accept only phone numbers'));
    });

    test('custom rule overrides default type rule', () {
      final questions = [
        const QuestionsModel(
          question: 'Email?',
          key: 'email',
          type: QuestionFieldType.email,
          validationMessage: 'only accept @company.com addresses',
        ),
      ];
      final prompt = buildSystemPrompt(questions);
      expect(prompt, contains('only accept @company.com addresses'));
      expect(prompt, contains('CUSTOM validation rule'));
    });

    test('prompt always instructs JSON-only reply', () {
      final questions = [
        const QuestionsModel(question: 'Name?', key: 'name'),
      ];
      final prompt = buildSystemPrompt(questions);
      expect(prompt, contains('valid JSON'));
    });
  });
}
