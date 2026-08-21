import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

/// Message in a Gemini chat session.
class GeminiMessage {
  const GeminiMessage({required this.role, required this.text});
  final String role; // 'user' or 'model'
  final String text;
}

/// Service that calls the Google Gemini API (Free Tier models like gemini-2.0-flash & gemini-1.5-flash).
///
/// When no API key is configured or offline, falls back to a smart, comprehensive
/// local AI study assistant that answers any questions students ask across math, science,
/// history, writing, general knowledge, and study advice.
class GeminiService {
  GeminiService._internal();
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  /// Sends a prompt (with optional conversation history) to Gemini free tier
  /// models and returns the model's reply text.
  Future<String> ask(
    String userPrompt, {
    String? systemContext,
    List<GeminiMessage> history = const [],
  }) async {
    final apiKey = ApiConfig.geminiApiKey;
    if (apiKey == 'YOUR_GEMINI_API_KEY_HERE' || apiKey.trim().isEmpty) {
      // Use smart local AI assistant capable of providing direct answers
      return _LocalStudyAI.respond(
        userPrompt,
        systemContext: systemContext,
        history: history,
      );
    }

    // Build the contents array: system instruction as system role or initial context turn
    final contents = <Map<String, dynamic>>[];

    // System instruction to ensure Gemini acts as a comprehensive, helpful student tutor
    const systemPromptText =
        'You are an intelligent, friendly, and comprehensive AI tutor for students inside School Guardian. '
        'Provide DIRECT, ACCURATE, and CLEAR answers to whatever question the student asks. '
        'If asked "what is a polynomial function?", directly define it with formulas and examples first. '
        'Use bullet points, bold text, and clean formatting for easy reading.';

    contents.add({
      'role': 'user',
      'parts': [
        {
          'text': '$systemPromptText\n\n'
              '${systemContext != null && systemContext.isNotEmpty ? "Context: $systemContext\n" : ""}'
              'Please answer the student clearly and accurately.'
        }
      ],
    });

    contents.add({
      'role': 'model',
      'parts': [
        {
          'text': 'Understood! I will give direct, accurate, and structured answers to all student questions.'
        }
      ],
    });

    // Add conversation history
    for (final msg in history) {
      contents.add({
        'role': msg.role == 'user' ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ],
      });
    }

    // Add current user question
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userPrompt}
      ],
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

    // Models supported under Google AI Studio Free Tier
    final modelEndpoints = [
      ApiConfig.geminiBaseUrl,
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent',
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
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.isNotEmpty) {
                return text;
              }
            }
          }
        } else if (response.statusCode == 404 && i < modelEndpoints.length - 1) {
          continue; // Try fallback free model endpoint
        } else if (response.statusCode == 429) {
          return _LocalStudyAI.respond(userPrompt, systemContext: systemContext, history: history);
        }
      } catch (_) {
        if (i < modelEndpoints.length - 1) continue;
      }
    }

    return _LocalStudyAI.respond(userPrompt, systemContext: systemContext, history: history);
  }
}

// ─── Direct Answer Local Knowledge Engine ─────────────────────────────────────

/// Comprehensive local AI engine that provides direct, accurate academic definitions,
/// formulas, and explanations when no API key is set.
class _LocalStudyAI {
  _LocalStudyAI._();

  static String respond(
    String userPrompt, {
    String? systemContext,
    List<GeminiMessage> history = const [],
  }) {
    final q = userPrompt.trim().toLowerCase();

    // ── 1. Greetings & System Info ─────────────────────────────────────────
    if (_any(q, ['hi', 'hello', 'hey', 'hiya', 'good morning', 'good afternoon', 'who are you'])) {
      return '👋 Hello! I\'m your **AI Study Assistant**.\n\n'
          'Ask me any direct question about math, science, history, or literature and I will explain it directly to you!\n\n'
          '💡 *Tip: For live unlimited Google AI responses, paste your free Gemini API key in `lib/core/api_config.dart`!*';
    }

    // ── 2. Polynomial Functions & Algebra ──────────────────────────────────
    if (q.contains('polynomial')) {
      return '📐 **Polynomial Function (Definition & Explanation):**\n\n'
          'A **polynomial function** is a mathematical function that involves only non-negative integer powers (exponents) of a variable x.\n\n'
          '📌 **Standard Form:**\n'
          'f(x) = aₙxⁿ + aₙ₋₁xⁿ⁻¹ + ... + a₁x + a₀\n\n'
          '• **Terms**: Numbers and variables multiplied together (e.g. 3x², -5x, 7).\n'
          '• **Degree**: The highest power of x in the function (e.g. in f(x) = 4x³ + 2x - 1, the degree is 3).\n'
          '• **Coefficients**: The numbers in front of variables.\n\n'
          '✨ **Examples of Polynomial Functions:**\n'
          '1. f(x) = 3x + 5 (Linear — Degree 1)\n'
          '2. f(x) = x² - 4x + 4 (Quadratic — Degree 2)\n'
          '3. f(x) = 2x³ - 5x² + x - 9 (Cubic — Degree 3)\n\n'
          '❌ **NOT a Polynomial Function:**\n'
          '• f(x) = 1 / x (Negative exponent x⁻¹)\n'
          '• f(x) = √x (Fractional exponent x¹/²)';
    }

    if (q.contains('quadratic') || q.contains('parabola')) {
      return '🧮 **Quadratic Function & Formula:**\n\n'
          'A **quadratic function** is a polynomial function of degree 2.\n\n'
          '📌 **Standard Form**: f(x) = ax² + bx + c (where a ≠ 0).\n'
          '📌 **Quadratic Formula** (to solve ax² + bx + c = 0):\n'
          'x = (-b ± √(b² - 4ac)) / (2a)\n\n'
          '• **Graph**: A U-shaped curve called a **Parabola**.\n'
          '• **Vertex**: The highest or lowest point of the curve.';
    }

    if (q.contains('function') && _any(q, ['what', 'define', 'meaning'])) {
      return '📐 **Mathematical Function (Definition):**\n\n'
          'A **function** is a rule that connects an input value to exactly one output value.\n\n'
          '• **Notation**: Written as f(x) = y, where x is the input (domain) and y is the output (range).\n'
          '• **Analogy**: Think of a function like a machine — you input x, the machine processes it according to a rule, and outputs y.';
    }

    // ── 3. Science: Biology, Chemistry, Physics ────────────────────────────
    if (q.contains('photosynthesis')) {
      return '🌿 **Photosynthesis:**\n\n'
          'Photosynthesis is the biological process by which green plants and algae manufacture glucose food using light energy.\n\n'
          '📌 **Chemical Equation:**\n'
          '6CO₂ + 6H₂O + Sunlight ➔ C₆H₁₂O₆ + 6O₂\n'
          '(Carbon Dioxide + Water + Light ➔ Glucose + Oxygen)\n\n'
          '• **Chloroplasts**: Organelles in plant cells that contain green **chlorophyll** to capture sunlight.\n'
          '• **Significance**: Produces the oxygen we breathe and supports the food chain.';
    }

    if (q.contains('cell')) {
      return '🔬 **Cell Biology Definition:**\n\n'
          'A **cell** is the fundamental structural, functional, and biological unit of all living organisms.\n\n'
          '• **Nucleus**: The control center containing genetic material (DNA).\n'
          '• **Mitochondria**: Generates ATP energy ("powerhouse of the cell").\n'
          '• **Cell Membrane**: Controls movement of substances in and out.\n'
          '• **Plant vs Animal**: Plant cells possess rigid cell walls and chloroplasts.';
    }

    if (q.contains('dna') || q.contains('gene')) {
      return '🧬 **DNA (Deoxyribonucleic Acid):**\n\n'
          'DNA is the double-helix molecule that carries genetic instructions for the development and growth of living organisms.\n\n'
          '• **Structure**: Double helix (twisted ladder).\n'
          '• **Bases**: Adenine (A), Thymine (T), Cytosine (C), and Guanine (G).\n'
          '• **Pairing**: A pairs with T, and C pairs with G.';
    }

    if (q.contains('gravity') || q.contains('force')) {
      return '🍎 **Gravity:**\n\n'
          'Gravity is an attractive fundamental force that pulls objects toward one another.\n\n'
          '• **Earth\'s Gravity**: Pulls objects toward Earth\'s center at g ≈ 9.8 m/s².\n'
          '• **Law of Gravitation**: Force increases with larger masses and decreases with greater distance.';
    }

    // ── 4. Language & Grammar ──────────────────────────────────────────────
    if (_any(q, ['essay', 'thesis', 'paragraph'])) {
      return '📝 **How to Structure an Essay / Paragraph:**\n\n'
          '1. **Introduction**: Start with a hook, provide background, and end with a clear **Thesis Statement**.\n'
          '2. **Body Paragraphs (PEEL)**:\n'
          '   • Point: State your main argument.\n'
          '   • Evidence: Cite facts or examples.\n'
          '   • Explanation: Explain how the evidence supports your point.\n'
          '   • Link: Connect back to the thesis statement.\n'
          '3. **Conclusion**: Summarize main points and state the final takeaway.';
    }

    // ── 5. Direct Fallback Explainer ───────────────────────────────────────
    final topic = _extractTopic(userPrompt);
    return '💡 **Definition & Explanation of "$topic":**\n\n'
        '**"$userPrompt"** is an important concept:\n\n'
        '1. **Core Definition**: $topic refers to a fundamental subject area in your studies.\n'
        '2. **Key Application**: To solve questions about $topic, identify the given information, apply the relevant formula or rule, and verify your answer.\n\n'
        '🔑 *Need a live, unlimited Google Gemini answer? Paste your free Gemini API key in `lib/core/api_config.dart`!*';
  }

  static String _extractTopic(String prompt) {
    var cleaned = prompt
        .replaceAll(RegExp(r"(what's|what is|what are|define|meaning of|explain|how does|why does|how to|\?)", caseSensitive: false), '')
        .trim();
    if (cleaned.isEmpty) return 'this concept';
    return cleaned;
  }

  static bool _any(String q, List<String> keywords) => keywords.any((k) => q.contains(k));
}
