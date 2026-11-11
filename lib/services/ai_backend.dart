/// Something that can answer one structured request: a system prompt, user
/// content blocks (text and base64 images in Messages API shape) and a JSON
/// schema the answer must match.
///
/// Two implementations exist: [ClaudeClient] talks to the Claude API over
/// HTTPS (mobile apps), and the web build can use the claude.ai artifact
/// runtime instead (see `web_ai_web.dart`), which needs no API key.
abstract class AiBackend {
  Future<Map<String, dynamic>> createJson({
    required String system,
    required List<Map<String, dynamic>> content,
    required Map<String, dynamic> schema,
    String effort = 'medium',
    int maxTokens = 16000,
  });
}
