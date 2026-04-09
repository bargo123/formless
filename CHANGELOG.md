# Changelog

## 0.1.3

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
