import 'package:flutter/material.dart';
import 'package:formless/formless.dart';

/// Pass your API key at run time, e.g.:
/// `flutter run --dart-define=FORMLESS_API_KEY=your_key_here`
const String _apiKey = String.fromEnvironment('FORMLESS_API_KEY',defaultValue: "");

void main() {
  runApp(const FormlessExampleApp());
}

class FormlessExampleApp extends StatelessWidget {
  const FormlessExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formless example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const FormlessDemoPage(),
    );
  }
}

class FormlessDemoPage extends StatelessWidget {
  const FormlessDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formless')),
      body: _apiKey.isEmpty
          ? const Center(
              child: Text(
                'Provide your API key at run time:\n\n'
                'flutter run --dart-define=FORMLESS_API_KEY=your_key_here',
                textAlign: TextAlign.center,
              ),
            )
          : Formless(
              provider: AiProvider.groq,
              apiKey: _apiKey,
              questions: [
                QuestionsModel(
                  question: 'What is your full name?',
                  key: 'name',
                  type: QuestionFieldType.text,
                ),
                QuestionsModel(
                  question: 'What is your email address?',
                  key: 'email',
                  type: QuestionFieldType.email,
                ),
                QuestionsModel(
                  question: 'What is your phone number?',
                  key: 'phone',
                  type: QuestionFieldType.phone,
                  validationMessage: 'Must include country code',
                ),
              ],
      
              onComplete: (data) {
                debugPrint('Formless complete: $data');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Done: $data')),
                );
              },
              onError: (error) {
                debugPrint('Formless error: $error');
              },
            ),
    );
  }
}
