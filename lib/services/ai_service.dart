import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  /// Provider: 'deepseek' or 'openai'
  Future<String> generateReply({
    required String apiKey,
    required String provider,
    required List<Map<String, String>> history, // [{role, content}]
    String? systemPrompt,
  }) async {
    final baseUrl = provider == 'openai'
        ? 'https://api.openai.com/v1/chat/completions'
        : 'https://api.deepseek.com/v1/chat/completions';
    final model = provider == 'openai' ? 'gpt-4o-mini' : 'deepseek-chat';

    final messages = <Map<String, String>>[
      if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
      ...history,
    ];

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );

      if (response.statusCode != 200) {
        return 'Error ${response.statusCode}: ${_extractError(response.body)}';
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) return 'No response.';
      return (choices.first['message']['content'] as String).trim();
    } catch (e) {
      return 'Network error: $e';
    }
  }

  String _extractError(String body) {
    try {
      final json = jsonDecode(body);
      return json['error']?['message']?.toString() ?? body;
    } catch (_) {
      return body.length > 200 ? body.substring(0, 200) : body;
    }
  }
}
