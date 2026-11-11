import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'ai_backend.dart';

enum ClaudeErrorKind {
  missingApiKey,
  invalidApiKey,
  rateLimited,
  overloaded,
  network,
  timeout,
  refused,
  truncated,
  badResponse,
  badRequest,

  /// The viewer did not allow the page to use Claude (web build on claude.ai).
  notAllowed,
}

class ClaudeException implements Exception {
  const ClaudeException(this.kind, [this.detail = '']);

  final ClaudeErrorKind kind;
  final String detail;

  @override
  String toString() => 'ClaudeException($kind${detail.isEmpty ? '' : ': $detail'})';
}

/// Minimal Claude Messages API client.
///
/// Dart has no official Anthropic SDK, so this talks to `POST /v1/messages`
/// directly over HTTPS. Only the features FridgeChef needs are covered:
/// image + text input, JSON structured outputs and effort control.
class ClaudeClient implements AiBackend {
  ClaudeClient({
    required this.apiKey,
    http.Client? httpClient,
    String? baseUrl,
    String? model,
    this.timeout = const Duration(seconds: 180),
    this.maxRetries = 2,
  })  : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.baseUrl,
        model = model ?? AppConfig.model;

  final String apiKey;
  final String baseUrl;
  final String model;
  final Duration timeout;
  final int maxRetries;
  final http.Client _http;

  static const apiVersion = '2026-10-21';

  /// Opt-in server-side fallback: if a safety classifier declines the request
  /// on the primary model, the API re-runs it on a fallback model.
  static const fallbackBeta = 'server-side-fallback-2026-07-01';

  static Map<String, dynamic> imageBlock(String mediaType, String base64Data) =>
      {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': mediaType,
          'data': base64Data,
        },
      };

  static Map<String, dynamic> textBlock(String text) =>
      {'type': 'text', 'text': text};

  @override
  /// Sends one user turn and returns the response parsed as JSON that
  /// conforms to [schema].
  Future<Map<String, dynamic>> createJson({
    required String system,
    required List<Map<String, dynamic>> content,
    required Map<String, dynamic> schema,
    String effort = 'medium',
    int maxTokens = 16000,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const ClaudeException(ClaudeErrorKind.missingApiKey);
    }
    final body = jsonEncode({
      'model': model,
      'max_tokens': maxTokens,
      'system': system,
      'messages': [
        {'role': 'user', 'content': content},
      ],
      'output_config': {
        'effort': effort,
        'format': {'type': 'json_schema', 'schema': schema},
      },
      'fallbacks': 'default',
    });

    final response = await _postWithRetry(body);
    return parseJsonResponse(response);
  }

  Future<Map<String, dynamic>> _postWithRetry(String body) async {
    final uri = Uri.parse('$baseUrl/v1/messages');
    final headers = {
      'content-type': 'application/json',
      'x-api-key': apiKey.trim(),
      'anthropic-version': apiVersion,
      'anthropic-beta': fallbackBeta,
    };

    var attempt = 0;
    while (true) {
      try {
        final res =
            await _http.post(uri, headers: headers, body: body).timeout(timeout);
        if (res.statusCode == 200) {
          return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        }
        final error = _errorFor(res);
        final retryable = error.kind == ClaudeErrorKind.rateLimited ||
            error.kind == ClaudeErrorKind.overloaded;
        if (!retryable || attempt >= maxRetries) throw error;
        await Future<void>.delayed(_retryDelay(res, attempt));
      } on TimeoutException {
        // Not retried: the user already waited the full timeout once.
        throw const ClaudeException(ClaudeErrorKind.timeout);
      } on SocketException catch (e) {
        if (attempt >= maxRetries) {
          throw ClaudeException(ClaudeErrorKind.network, e.message);
        }
        await Future<void>.delayed(_retryDelay(null, attempt));
      } on http.ClientException catch (e) {
        if (attempt >= maxRetries) {
          throw ClaudeException(ClaudeErrorKind.network, e.message);
        }
        await Future<void>.delayed(_retryDelay(null, attempt));
      } on FormatException catch (e) {
        throw ClaudeException(ClaudeErrorKind.badResponse, e.message);
      }
      attempt++;
    }
  }

  Duration _retryDelay(http.Response? res, int attempt) {
    final header = res?.headers['retry-after'];
    final seconds = header == null ? null : int.tryParse(header);
    if (seconds != null) return Duration(seconds: min(seconds, 30));
    return Duration(milliseconds: 1000 * pow(2, attempt).toInt());
  }

  ClaudeException _errorFor(http.Response res) {
    var message = '';
    try {
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      message = (json['error']?['message'] as String?) ?? '';
    } catch (_) {
      message = res.body;
    }
    switch (res.statusCode) {
      case 401:
      case 403:
        return ClaudeException(ClaudeErrorKind.invalidApiKey, message);
      case 429:
        return ClaudeException(ClaudeErrorKind.rateLimited, message);
      case 400:
      case 404:
      case 413:
        return ClaudeException(ClaudeErrorKind.badRequest, message);
      default:
        if (res.statusCode >= 500) {
          return ClaudeException(ClaudeErrorKind.overloaded, message);
        }
        return ClaudeException(
          ClaudeErrorKind.badResponse,
          'HTTP ${res.statusCode}: $message',
        );
    }
  }

  /// Extracts the JSON document from a Messages API response.
  ///
  /// Checks the stop reason first: a refusal or a truncated response may not
  /// match the schema. Thinking and fallback blocks are skipped; only `text`
  /// blocks carry the structured output.
  static Map<String, dynamic> parseJsonResponse(Map<String, dynamic> response) {
    final stopReason = response['stop_reason'] as String?;
    if (stopReason == 'refusal') {
      final details = response['stop_details'] as Map<String, dynamic>?;
      throw ClaudeException(
        ClaudeErrorKind.refused,
        (details?['explanation'] as String?) ?? '',
      );
    }
    if (stopReason == 'max_tokens') {
      throw const ClaudeException(ClaudeErrorKind.truncated);
    }
    final text = ((response['content'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String? ?? '')
        .join();
    if (text.trim().isEmpty) {
      throw const ClaudeException(ClaudeErrorKind.badResponse, 'empty response');
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException catch (e) {
      throw ClaudeException(ClaudeErrorKind.badResponse, e.message);
    }
    throw const ClaudeException(ClaudeErrorKind.badResponse, 'not an object');
  }

  void close() => _http.close();
}
