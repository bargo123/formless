import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:formless/enums/ai_provider.dart';
import 'package:formless/models/questions_model.dart';
import 'package:formless/validator/propmt.dart';

const String _jsonRetrySystemSuffix =
    '\n\nCRITICAL: Your entire reply must be one JSON object only. No markdown, no text before or after the JSON.';

String _stripBom(String s) {
  if (s.isEmpty) return s;
  if (s.codeUnitAt(0) == 0xFEFF) return s.substring(1);
  return s;
}

/// Waits when the server returns 429, then retries the same POST a few times.
Future<http.Response> _postWith429Retries({
  required Uri uri,
  required Map<String, String> headers,
  required String body,
  int maxAttempts = 4,
}) async {
  var res = await http.post(uri, headers: headers, body: body);
  for (var attempt = 1; attempt < maxAttempts && res.statusCode == 429; attempt++) {
    final wait = _retryDelayAfter429(res, attempt);
    await Future<void>.delayed(wait);
    res = await http.post(uri, headers: headers, body: body);
  }
  return res;
}

Duration _retryDelayAfter429(http.Response res, int attemptIndex) {
  final ra = res.headers['retry-after'];
  if (ra != null) {
    final sec = int.tryParse(ra.trim());
    if (sec != null && sec > 0) {
      return Duration(seconds: sec.clamp(1, 120));
    }
  }
  final seconds = 1 << attemptIndex.clamp(0, 5);
  return Duration(seconds: seconds.clamp(1, 32));
}

String _userFacingApiError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('empty content') || s.contains('empty completion')) {
    return 'The assistant returned an empty reply. Please try again.';
  }
  if (s.contains('429') || s.contains('rate limit')) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  if (s.contains('401') || s.contains('unauthorized') || s.contains('invalid api key')) {
    return 'API key was rejected. Check your provider settings.';
  }
  if (s.contains('socket') || s.contains('connection') || s.contains('network')) {
    return 'Network error. Check your connection and try again.';
  }
  return 'Could not reach the assistant. Please try again.';
}

Map<String, dynamic>? _coerceDataMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// Pulls the first top-level JSON object from [raw], ignoring prose/markdown around it.
String? _extractJsonObject(String raw) {
  final start = raw.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var inString = false;
  var escape = false;
  for (var i = start; i < raw.length; i++) {
    final c = raw[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (c == '\\' && inString) {
      escape = true;
      continue;
    }
    if (c == '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) return raw.substring(start, i + 1);
    }
  }
  return null;
}

/// Some models return JSON as a string, or wrap the object in a one-element array.
Map<String, dynamic>? _coerceDecodedToMap(Object? decoded) {
  if (decoded == null) return null;
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  if (decoded is String) {
    final t = decoded.trim();
    if (t.isEmpty) return null;
    try {
      final inner = jsonDecode(t);
      return _coerceDecodedToMap(inner);
    } catch (_) {
      final extracted = _extractJsonObject(t);
      if (extracted == null) return null;
      try {
        return _coerceDecodedToMap(jsonDecode(extracted));
      } catch (_) {
        return null;
      }
    }
  }
  if (decoded is List && decoded.isNotEmpty) {
    return _coerceDecodedToMap(decoded.first);
  }
  return null;
}

String _tryRepairTrailingCommas(String json) {
  var s = json;
  for (var i = 0; i < 8; i++) {
    final next = s.replaceAllMapped(RegExp(r',\s*([}\]])'), (m) => m[1]!);
    if (next == s) break;
    s = next;
  }
  return s;
}

Object? _jsonDecodeLenient(String s) {
  try {
    return jsonDecode(s);
  } catch (_) {
    try {
      return jsonDecode(_tryRepairTrailingCommas(s));
    } catch (_) {
      return null;
    }
  }
}

Map<String, dynamic>? _tryDecodeModelJson(String raw) {
  final cleaned = _stripBom(raw).replaceAll('```json', '').replaceAll('```', '').trim();
  if (cleaned.isEmpty) return null;

  var decoded = _jsonDecodeLenient(cleaned);
  if (decoded == null) {
    final extracted = _extractJsonObject(cleaned);
    if (extracted != null) {
      decoded = _jsonDecodeLenient(extracted);
    }
  }

  return _coerceDecodedToMap(decoded);
}

String? _coerceOptionalString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

Map<String, dynamic> _normalizeAiResponse(Map<String, dynamic> parsed) {
  final result = parsed['result'] == true;
  final reason = _coerceOptionalString(parsed['reason']);
  final nextQuestion = _coerceOptionalString(parsed['nextQuestion']);
  final done = parsed['done'] == true;
  final data = _coerceDataMap(parsed['data']);

  return <String, dynamic>{
    'result': result,
    'reason': reason,
    'nextQuestion': nextQuestion,
    'done': done,
    'data': data,
  };
}

Future<Map<String, dynamic>> sendMessage({
  required AiProvider provider,
  required String apiKey,
  String? model,
  required List<QuestionsModel> questions,
  required List<Map<String, String>> history,
  required String userMessage,
}) async {
  final systemPrompt = buildSystemPrompt(questions);

  String raw;
  try {
    switch (provider) {
      case AiProvider.groq:
        raw = await _callGroq(
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          history: history,
          userMessage: userMessage,
        );
      case AiProvider.deepSeek:
        raw = await _callDeepSeek(
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          history: history,
          userMessage: userMessage,
        );
      case AiProvider.gemini:
        raw = await _callGemini(
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          history: history,
          userMessage: userMessage,
        );
      case AiProvider.openAi:
        raw = await _callOpenAi(
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          history: history,
          userMessage: userMessage,
        );
    }
  } catch (e) {
    return {
      'result': false,
      'isApiError': true,
      'reason': _userFacingApiError(e),
      'nextQuestion': null,
      'done': false,
      'data': null,
    };
  }

  try {
    var parsed = _tryDecodeModelJson(raw);
    if (parsed == null) {
      try {
        // Space out the optional second call so we are less likely to hit burst limits.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        switch (provider) {
          case AiProvider.groq:
            raw = await _callGroq(
              apiKey: apiKey,
              model: model,
              systemPrompt: systemPrompt + _jsonRetrySystemSuffix,
              history: history,
              userMessage: userMessage,
            );
          case AiProvider.deepSeek:
            raw = await _callDeepSeek(
              apiKey: apiKey,
              model: model,
              systemPrompt: systemPrompt + _jsonRetrySystemSuffix,
              history: history,
              userMessage: userMessage,
            );
          case AiProvider.gemini:
            raw = await _callGemini(
              apiKey: apiKey,
              model: model,
              systemPrompt: systemPrompt + _jsonRetrySystemSuffix,
              history: history,
              userMessage: userMessage,
            );
          case AiProvider.openAi:
            raw = await _callOpenAi(
              apiKey: apiKey,
              model: model,
              systemPrompt: systemPrompt + _jsonRetrySystemSuffix,
              history: history,
              userMessage: userMessage,
            );
        }
        parsed = _tryDecodeModelJson(raw);
      } catch (_) {
        // keep parsed == null
      }
    }

    if (parsed == null) {
      return {
        'result': false,
        'isApiError': true,
        'reason': 'The assistant reply could not be read. Please try again.',
        'nextQuestion': null,
        'done': false,
        'data': null,
      };
    }
    return _normalizeAiResponse(parsed);
  } catch (_) {
    return {
      'result': false,
      'isApiError': true,
      'reason': 'Something went wrong, please try again.',
      'nextQuestion': null,
      'done': false,
      'data': null,
    };
  }
}

// ── Groq ──────────────────────────────────────────────────────────────────────
Future<String> _callGroq({
  required String apiKey,
  String? model,
  required String systemPrompt,
  required List<Map<String, String>> history,
  required String userMessage,
}) async {
  final body = jsonEncode({
    'model': model ?? 'meta-llama/llama-4-scout-17b-16e-instruct',
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': userMessage},
    ],
    'temperature': 0,
    'max_tokens': 1024,
    'response_format': {'type': 'json_object'},
  });
  final res = await _postWith429Retries(
    uri: Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: body,
  );
  if (res.statusCode != 200) {
    final bodyText = res.body.trim();
    String? msg;
    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is Map) {
          final m = err['message'];
          if (m is String) msg = m;
        }
      }
    } catch (_) {
      // ignore non-JSON bodies
    }
    throw Exception('HTTP ${res.statusCode}: ${msg ?? bodyText}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return _openAiMessageContent(data);
}

// ── DeepSeek ──────────────────────────────────────────────────────────────────
Future<String> _callDeepSeek({
  required String apiKey,
  String? model,
  required String systemPrompt,
  required List<Map<String, String>> history,
  required String userMessage,
}) async {
  final body = jsonEncode({
    'model': model ?? 'deepseek-chat',
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': userMessage},
    ],
    'temperature': 0,
    'max_tokens': 1024,
    'response_format': {'type': 'json_object'},
  });
  final res = await _postWith429Retries(
    uri: Uri.parse('https://api.deepseek.com/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: body,
  );
  if (res.statusCode != 200) {
    final bodyText = res.body.trim();
    String? msg;
    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is Map) {
          final m = err['message'];
          if (m is String) msg = m;
        }
      }
    } catch (_) {
      // ignore non-JSON bodies
    }
    throw Exception('HTTP ${res.statusCode}: ${msg ?? bodyText}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return _openAiMessageContent(data);
}

// ── Gemini ────────────────────────────────────────────────────────────────────
Future<String> _callGemini({
  required String apiKey,
  String? model,
  required String systemPrompt,
  required List<Map<String, String>> history,
  required String userMessage,
}) async {
  final resolvedModel = model ?? 'gemini-3.1-flash-lite-preview';
  final url =
      'https://generativelanguage.googleapis.com/v1beta/models/$resolvedModel:generateContent?key=$apiKey';

  final contents = [
    ...history.map((m) => {
      'role': m['role'] == 'assistant' ? 'model' : 'user',
      'parts': [{'text': m['content']}],
    }),
    {'role': 'user', 'parts': [{'text': userMessage}]},
  ];

  final geminiBody = jsonEncode({
    'system_instruction': {'parts': [{'text': systemPrompt}]},
    'contents': contents,
    'generationConfig': {
      'temperature': 0,
      'maxOutputTokens': 1024,
      'responseMimeType': 'application/json',
    },
  });
  final res = await _postWith429Retries(
    uri: Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: geminiBody,
  );
  if (res.statusCode != 200) {
    final bodyText = res.body.trim();
    throw Exception('HTTP ${res.statusCode}: ${bodyText.isEmpty ? 'Gemini request failed' : bodyText}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final candidates = data['candidates'];
  if (candidates is! List || candidates.isEmpty) {
    throw Exception('Gemini returned no candidates');
  }
  final content = candidates[0]['content'];
  if (content is! Map) throw Exception('Gemini response missing content');
  final parts = content['parts'];
  if (parts is! List || parts.isEmpty) throw Exception('Gemini response missing parts');
  final text = parts[0]['text'];
  if (text is! String || text.isEmpty) throw Exception('Gemini response empty text');
  return text;
}

// ── OpenAI ────────────────────────────────────────────────────────────────────
Future<String> _callOpenAi({
  required String apiKey,
  String? model,
  required String systemPrompt,
  required List<Map<String, String>> history,
  required String userMessage,
}) async {
  final body = jsonEncode({
    'model': model ?? 'gpt-4o-mini',
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': userMessage},
    ],
    'temperature': 0,
    'max_tokens': 1024,
    'response_format': {'type': 'json_object'},
  });
  final res = await _postWith429Retries(
    uri: Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: body,
  );
  if (res.statusCode != 200) {
    final bodyText = res.body.trim();
    String? msg;
    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is Map) {
          final m = err['message'];
          if (m is String) msg = m;
        }
      }
    } catch (_) {
      // ignore non-JSON bodies
    }
    throw Exception('HTTP ${res.statusCode}: ${msg ?? bodyText}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return _openAiMessageContent(data);
}

String _openAiMessageContent(Map<String, dynamic> data) {
  final choices = data['choices'];
  if (choices is! List || choices.isEmpty) {
    throw Exception('API returned no choices');
  }
  final message = choices[0]['message'];
  if (message is! Map) throw Exception('API response missing message');
  final content = message['content'];
  if (content == null) throw Exception('API response missing content');
  if (content is String) {
    if (content.isEmpty) throw Exception('API response empty content');
    return content;
  }
  return content.toString();
}