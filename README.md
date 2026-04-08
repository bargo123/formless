# Formless

A Flutter package that turns any list of fields into an AI-powered conversational form.

<img src="https://raw.githubusercontent.com/bargo123/formless/main/assets/images/formless_example.gif" width="320"/>

Instead of a traditional form, Formless walks the user through each question one at a time in a chat UI. The LLM validates answers in natural language, asks for corrections when needed, and returns a clean `key → value` map when all fields are collected.

## Features

- Chat-style UI — no traditional form widgets needed
- Supports **Groq**, **OpenAI**, **Gemini**, and **DeepSeek**
- Per-field validation with optional custom rules
- Users can edit any previous answer by long-pressing their bubble
- Fully themeable — bubble colors, input field, send button, and more
- Automatic JSON retry and rate-limit backoff

## Free to use

Formless works with providers that offer a **free tier** — you don't need a paid plan to get started:

| Provider | Free tier |
|---|---|
| **Groq** | Yes — generous free tier, very fast |
| **Gemini** | Yes — free tier available |
| **OpenAI** | No — pay per use |
| **DeepSeek** | No — pay per use |

## Privacy & security

User data is sent **directly from the device to the AI provider** — it never passes through any third-party server, including Formless itself. The package makes HTTP calls straight to the provider's API using the key you supply, so your users' answers stay between them and the provider you choose.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  formless: ^0.1.0
```

Then run:

```sh
flutter pub get
```

## Getting started

You need an API key from one of the supported providers:

| Provider | Where to get a key |
|---|---|
| Groq | https://console.groq.com |
| OpenAI | https://platform.openai.com |
| Gemini | https://aistudio.google.com |
| DeepSeek | https://platform.deepseek.com |

Pass the key at runtime using `--dart-define` — never hardcode it:

```sh
flutter run --dart-define=MY_API_KEY=your_key_here
```

## Usage

### Minimal

```dart
import 'package:formless/formless.dart';

Formless(
  provider: AiProvider.openAi,
  apiKey: const String.fromEnvironment('MY_API_KEY'),
  onComplete: (data) {
    // data = {'name': 'Alice', 'email': 'alice@example.com', ...}
    print(data);
  },
)
```

This uses the built-in default questions: name, age, email, and phone.

### Custom questions

```dart
Formless(
  provider: AiProvider.groq,
  apiKey: const String.fromEnvironment('MY_API_KEY'),
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
      question: 'What is your monthly income?',
      key: 'income',
      type: QuestionFieldType.numeric,
      validationMessage: 'Only accept values between 1000 and 100000',
    ),
  ],
  onComplete: (data) => print(data),
)
```

### Custom theme

```dart
Formless(
  provider: AiProvider.openAi,
  apiKey: const String.fromEnvironment('MY_API_KEY'),
  theme: FormlessTheme(
    userBubbleColor: Colors.blue.shade700,
    botBubbleColor: Colors.grey.shade100,
    sendButtonColor: Colors.blue.shade700,
    inputDecoration: InputDecoration(
      hintText: 'Type your answer...',
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  onComplete: (data) => print(data),
)
```

### Override the model

```dart
Formless(
  provider: AiProvider.openAi,
  apiKey: const String.fromEnvironment('MY_API_KEY'),
  model: 'gpt-4o',
  onComplete: (data) => print(data),
)
```

## API reference

### `Formless`

| Parameter | Type | Required | Description |
|---|---|---|---|
| `provider` | `AiProvider` | Yes | Which LLM API to use |
| `apiKey` | `String` | Yes | API key for the chosen provider |
| `questions` | `List<QuestionsModel>?` | No | Fields to collect; defaults to name/age/email/phone |
| `model` | `String?` | No | Override the provider's default model |
| `theme` | `FormlessTheme?` | No | Colors and input field styling |
| `sendIcon` | `Widget?` | No | Custom icon inside the send button |
| `onComplete` | `Function(Map<String, dynamic>)?` | No | Called with collected data when done |
| `onError` | `Function(String)?` | No | Called on network or API errors |

### `QuestionsModel`

| Parameter | Type | Required | Description |
|---|---|---|---|
| `question` | `String` | Yes | The question shown to the user |
| `key` | `String` | Yes | Key used in the `onComplete` data map |
| `type` | `QuestionFieldType?` | No | Drives validation rules (email, phone, numeric, etc.) |
| `validationMessage` | `String?` | No | Custom rule the LLM must strictly follow |

### `FormlessTheme`

| Parameter | Description |
|---|---|
| `userBubbleColor` | User message bubble background |
| `botBubbleColor` | Bot message bubble background |
| `userTextColor` | Text color in user bubbles |
| `botTextColor` | Text color in bot bubbles |
| `sendButtonColor` | Send button background |
| `typingIndicatorColor` | Animated typing dots color |
| `inputDecoration` | Full `InputDecoration` override for the text field |
| `inputTextStyle` | Text style for what the user types |
| `inputBorderColor` | Border color (ignored when `inputDecoration` is set) |
| `inputHintText` | Hint text (ignored when `inputDecoration` is set) |

## License

MIT
# formless
# formless
