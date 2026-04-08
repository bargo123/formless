/// Which LLM HTTP API the package should use to validate answers.
///
/// Pass one of these values to [Formless.provider].
/// Each provider uses its own default model which can be overridden via [Formless.model].
enum AiProvider {
  /// Groq inference API. Default model: `meta-llama/llama-4-scout-17b-16e-instruct`.
  /// Fast and free-tier friendly. Get a key at https://console.groq.com.
  groq,

  /// DeepSeek API. Default model: `deepseek-chat`.
  /// Cost-effective with strong instruction-following. Get a key at https://platform.deepseek.com.
  deepSeek,

  /// Google Gemini API. Default model: `gemini-3.1-flash-lite-preview`.
  /// Get a key at https://aistudio.google.com.
  gemini,

  /// OpenAI API. Default model: `gpt-4o-mini`.
  /// Get a key at https://platform.openai.com.
  openAi,
}
