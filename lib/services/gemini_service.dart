import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

/// Message in a Gemini chat session.
class GeminiMessage {
  const GeminiMessage({required this.role, required this.text});
  final String role; // 'user' or 'model'
  final String text;
}

/// Service that calls the Gemini 2.0 Flash free-tier API.
///
/// Usage:
/// ```dart
/// final svc = GeminiService();
/// final reply = await svc.ask('Explain Newton's second law simply.');
/// ```
///
/// To use, set your API key via:
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
/// Or replace the placeholder in api_config.dart with your real key from:
///   https://aistudio.google.com/app/apikey
class GeminiService {
  GeminiService._internal();
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  /// Sends a prompt (with optional conversation history) to Gemini and returns
  /// the model's reply text, or an error message if the call fails.
  Future<String> ask(
    String userPrompt, {
    String? systemContext,
    List<GeminiMessage> history = const [],
  }) async {
    final apiKey = ApiConfig.geminiApiKey;
    if (apiKey == 'YOUR_GEMINI_API_KEY_HERE' || apiKey.isEmpty) {
      return '⚠️ No Gemini API key configured. Please add your free key from '
          'https://aistudio.google.com/app/apikey by running:\n'
          'flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY';
    }

    // Build the contents array: system context as first user turn if provided
    final contents = <Map<String, dynamic>>[];

    if (systemContext != null && systemContext.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [{'text': systemContext}],
      });
      contents.add({
        'role': 'model',
        'parts': [{'text': 'Understood. I will help the student with this homework assignment.'}],
      });
    }

    // Add conversation history
    for (final msg in history) {
      contents.add({
        'role': msg.role,
        'parts': [{'text': msg.text}],
      });
    }

    // Add current user question
    contents.add({
      'role': 'user',
      'parts': [{'text': userPrompt}],
    });

    final requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    };

    final modelEndpoints = [
      ApiConfig.geminiBaseUrl,
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent',
    ];

    for (int i = 0; i < modelEndpoints.length; i++) {
      final endpoint = modelEndpoints[i];
      try {
        final uri = Uri.parse('$endpoint?key=$apiKey');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] as String? ?? 'No response from AI.';
            }
          }
          return 'The AI returned an unexpected response format.';
        } else if (response.statusCode == 404 && i < modelEndpoints.length - 1) {
          // Try next fallback model
          continue;
        } else if (response.statusCode == 400) {
          return '❌ Invalid request. Please check your API key or try again.';
        } else if (response.statusCode == 429) {
          return '⏳ Rate limit reached. Please wait a moment before asking again.';
        } else if (response.statusCode == 403) {
          return '🔑 API key error. Please verify your Gemini API key is correct.';
        } else {
          return '❌ AI service error (${response.statusCode}). Please try again.';
        }
      } catch (e) {
        if (i < modelEndpoints.length - 1) continue;
        return '🌐 Network error. Please check your internet connection and try again.';
      }
    }
    return '❌ AI service unavailable. Please try again.';
  }
}
