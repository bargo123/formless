# Changelog

## 0.1.5

* Chat UX after completion: input stays disabled and user bubbles remain right-aligned (no layout shift).

## 0.1.4

* Resolved static analysis issues (`comment_references`, `prefer_single_quotes`) so pub.dev can complete package analysis successfully.

## 0.1.3

* After all questions are answered, the chat input and send button are disabled so users cannot send more messages (editing previous answers is also disabled).
* Keep user message bubbles right-aligned when the form is complete (they no longer jump to the left).
* Added optional `onError` callback on `Formless` / `ChatLayout` so host apps can log or surface validation and API failures.
* Documented `QuestionsModel.onValidate` (post-AI checks such as nickname availability) in README, API table, and dartdocs.
* Exclude local `build/` from the published tarball via `.pubignore`.
* Version bump for pub.dev publication.

## 0.1.2

* Updated demo GIF.

## 0.1.1

* Added `backgroundColor` parameter to `Formless` for background color control.
* Added `unexpectedErrorMessage` parameter to customize the error banner text.
* API and network errors now show a dismissible banner instead of a chat bubble.
* User's message is automatically restored in the input field after an API error.
* Added demo GIF to README.

## 0.1.0

* Initial release.
* Conversational chat UI that collects form fields one at a time.
* Supports Groq, OpenAI, Gemini, and DeepSeek as AI providers.
* Per-field validation via LLM with custom `validationMessage` override.
* `FormlessTheme` for full color and input field customization.
* Optional `model` parameter to override the provider's default model.
* Long-press any sent answer to edit it and roll back the conversation.
* Automatic JSON retry and 429 rate-limit backoff.
