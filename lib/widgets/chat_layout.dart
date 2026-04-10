import 'package:flutter/material.dart';
import 'package:formless/enums/ai_provider.dart';
import 'package:formless/enums/question_field_type.dart';
import 'package:formless/models/answers_model.dart';
import 'package:formless/models/formless_theme.dart';
import 'package:formless/models/questions_model.dart';
import 'package:formless/validator/ai_agent_validator.dart';
import 'package:formless/widgets/chat_input_bar.dart';
import 'package:formless/widgets/chat_message_list.dart';

/// Default field list when the host app does not pass [ChatLayout.questions].
const List<QuestionsModel> kDefaultFormlessQuestions = [
  QuestionsModel(
    question: 'What is your full name?',
    key: 'name',
    type: QuestionFieldType.text,
  ),
  QuestionsModel(
    question: 'What is your age?',
    key: 'age',
    type: QuestionFieldType.numeric,
    validationMessage: 'age should be between 18 and 100',
  ),
  QuestionsModel(
    question: 'What is your email?',
    key: 'email',
    type: QuestionFieldType.email,
  ),
  QuestionsModel(
    question: 'What is your phone number?',
    key: 'phone',
    validationMessage: 'Must include country code',
  ),
];

class ChatLayout extends StatefulWidget {
  const ChatLayout({
    super.key,
    this.sendIcon,
    this.theme,
    this.onComplete,
    this.onError,
    required this.provider,
    required this.apiKey,
    this.model,
    this.questions = kDefaultFormlessQuestions,
    this.unexpectedErrorMessage = 'Something went wrong, please try again.',
  });

  final Widget? sendIcon;
  final FormlessTheme? theme;
  final List<QuestionsModel> questions;
  final void Function(Map<String, dynamic> data)? onComplete;
  final void Function(String error)? onError;
  final AiProvider provider;
  final String apiKey;
  final String? model;
  final String? unexpectedErrorMessage;

  @override
  State<ChatLayout> createState() => _ChatLayoutState();
}

class _ChatLayoutState extends State<ChatLayout> {
  final List<dynamic> _messages = [];
  final List<Map<String, String>> _history = [];
  final List<int> _historyCheckpoints = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isWaiting = false;
  bool _isComplete = false;
  String? _errorMessage;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    assert(widget.questions.isNotEmpty, 'Formless: questions list must not be empty.');
    if (widget.questions.isEmpty) return;
    final firstQuestion = widget.questions[0].question;
    _messages.add(
      QuestionsModel(
        question: firstQuestion,
        key: widget.questions[0].key,
        type: widget.questions[0].type,
      ),
    );
    _history.add({'role': 'assistant', 'content': firstQuestion});
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _onSend() async {
    if (_isComplete) return;
    final userText = _controller.text.trim();
    if (userText.isEmpty || _isWaiting) return;

    // snapshot history length before this round so we can roll back on edit
    _historyCheckpoints.add(_history.length);

    // add user message to UI + history
    setState(() {
      _messages.add(AnswersModel(answer: userText));
      _isWaiting = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await sendMessage(
        provider: widget.provider,
        apiKey: widget.apiKey,
        model: widget.model,
        questions: widget.questions,
        history: _history,
        userMessage: userText,
      );

      if (!mounted) return;

      if (reply['result'] == false) {
        final reason = reply['reason'] ?? 'Please try again.';

        if (reply['isApiError'] == true) {
          // infrastructure error — roll back the user bubble, restore input, show banner
          widget.onError?.call(reason.toString());
          setState(() {
            _messages.removeLast();
            _historyCheckpoints.removeLast();
            _controller.text = userText;
            _isWaiting = false;
          });
          _showError(reason.toString());
        } else {
          // LLM rejected the answer — show the reason in chat
          _history.add({'role': 'user', 'content': userText});
          _history.add({'role': 'assistant', 'content': reason});
          setState(() {
            _messages.add(QuestionsModel(question: reason, key: ''));
            _isWaiting = false;
          });
        }

      } else if (reply['done'] == true || reply['result'] == true) {
        // run optional post-AI validation before accepting the answer
        final currentQuestion = widget.questions[_currentQuestionIndex];
        final customError = await currentQuestion.onValidate?.call(userText);

        if (!mounted) return;

        if (customError != null) {
          // custom validator rejected — tell the AI validation failed and re-ask
          // the same question so it stays on this field next round
          _history.add({'role': 'user', 'content': userText});
          _history.add({
            'role': 'assistant',
            'content': '$customError ${currentQuestion.question}',
          });
          // show only the friendly error to the user, not the re-asked question
          setState(() {
            _messages.add(QuestionsModel(question: customError, key: ''));
            _isWaiting = false;
          });
        } else if (reply['done'] == true) {
          // all fields collected — fire onComplete
          _currentQuestionIndex = 0;
          _history.add({'role': 'user', 'content': userText});
          setState(() {
            _isWaiting = false;
            _isComplete = true;
          });
          _controller.clear();
          final data = reply['data'];
          final raw = data is Map<String, dynamic>
              ? data
              : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
          final expectedKeys = widget.questions.map((q) => q.key).toSet();
          final payload = {
            for (final entry in raw.entries)
              if (expectedKeys.contains(entry.key)) entry.key: entry.value,
          };
          widget.onComplete?.call(payload);
        } else {
          // valid — show next question
          _currentQuestionIndex++;
          final nextQuestion = reply['nextQuestion'] ?? '';
          _history.add({'role': 'user', 'content': userText});
          _history.add({'role': 'assistant', 'content': nextQuestion});
          setState(() {
            _messages.add(QuestionsModel(question: nextQuestion, key: ''));
            _isWaiting = false;
          });
        }
      }

      _scrollToBottom();

    } catch (e) {
      if (!mounted) return;
      widget.onError?.call(e.toString());
      setState(() {
        _messages.removeLast();
        _historyCheckpoints.removeLast();
        _controller.text = userText;
        _isWaiting = false;
      });
      _showError('Something went wrong, please try again.');
      _scrollToBottom();
    }
  }

  void _onEditMessage(int messageIndex) {
    if (_isComplete) return;
    final item = _messages[messageIndex];
    if (item is! AnswersModel || _isWaiting) return;

    // count how many AnswersModel entries precede this one → checkpoint index
    var answerIndex = 0;
    for (var i = 0; i < messageIndex; i++) {
      if (_messages[i] is AnswersModel) answerIndex++;
    }

    setState(() {
      _controller.text = item.answer;
      _messages.removeRange(messageIndex, _messages.length);
      _history.removeRange(_historyCheckpoints[answerIndex], _history.length);
      _historyCheckpoints.removeRange(answerIndex, _historyCheckpoints.length);
      _currentQuestionIndex = answerIndex;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ChatMessageList(
            messages: _messages,
            scrollController: _scrollController,
            isWaiting: _isWaiting,
            theme: widget.theme,
            onEditMessage: _isComplete ? null : _onEditMessage,
          ),
        ),
        if (_errorMessage != null)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.unexpectedErrorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _errorMessage = null),
                    child: Icon(Icons.close, color: Colors.red.shade400, size: 16),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        ChatInputBar(
          controller: _controller,
          onSend: _onSend,
          isWaiting: _isWaiting,
          enabled: !_isComplete,
          theme: widget.theme,
          sendIcon: widget.sendIcon,
        ),
      ],
    );
  }
}