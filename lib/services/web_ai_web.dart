import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'ai_backend.dart';
import 'claude_client.dart';

/// Web build hosted as a claude.ai artifact: Claude is reached through the
/// artifact runtime's `sample` capability, on the viewer's own Claude
/// account, so no API key is needed. Resolves null anywhere else.
Future<AiBackend?> loadBuiltInAi() async {
  try {
    final claude = globalContext['claude'];
    if (claude == null || !claude.isA<JSObject>()) return null;
    final sample = await (claude as JSObject)
        .callMethod<JSPromise<JSAny?>>('use'.toJS, 'sample'.toJS)
        .toDart;
    if (sample == null || !sample.isA<JSObject>()) return null;
    return SampleBackend(sample as JSObject);
  } catch (_) {
    return null;
  }
}

class SampleBackend implements AiBackend {
  SampleBackend(this._sample);

  final JSObject _sample;

  @override
  Future<Map<String, dynamic>> createJson({
    required String system,
    required List<Map<String, dynamic>> content,
    required Map<String, dynamic> schema,
    String effort = 'medium',
    int maxTokens = 16000,
  }) async {
    final text = StringBuffer(system)..writeln();
    final images = <web.Blob>[];
    for (final block in content) {
      if (block['type'] == 'text') {
        text.writeln(block['text']);
      } else if (block['type'] == 'image') {
        final source = block['source'] as Map<String, dynamic>;
        final bytes = base64Decode(source['data'] as String);
        images.add(web.Blob(
          [bytes.toJS].toJS,
          web.BlobPropertyBag(type: source['media_type'] as String),
        ));
        text.writeln('[Image ${images.length} is attached.]');
      }
    }
    text
      ..writeln()
      ..writeln('Reply with ONLY one JSON object, no other text. It must match '
          'this JSON Schema exactly (all properties required):')
      ..writeln(jsonEncode(schema));

    final options = JSObject()..['modelTier'] = 'default'.toJS;
    if (images.isNotEmpty) options['images'] = images.toJS;

    final JSAny? result;
    try {
      result = await _sample
          .callMethod<JSPromise<JSAny?>>('json'.toJS, text.toString().toJS, options)
          .toDart;
    } catch (e) {
      throw ClaudeException(_kindFor(_codeOf(e)), _codeOf(e) ?? e.toString());
    }
    final encoded = (globalContext['JSON'] as JSObject)
        .callMethod<JSString>('stringify'.toJS, result);
    final decoded = jsonDecode(encoded.toDart);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ClaudeException(ClaudeErrorKind.badResponse, 'not an object');
  }

  static String? _codeOf(Object e) {
    try {
      final code = (e as JSObject)['code'];
      return code != null && code.isA<JSString>() ? (code as JSString).toDart : null;
    } catch (_) {
      return null;
    }
  }

  static ClaudeErrorKind _kindFor(String? code) => switch (code) {
        'not_granted' ||
        'sampling_disabled' ||
        'not_declared' ||
        'capability_disabled' ||
        'capability_removed' ||
        'session_expired' =>
          ClaudeErrorKind.notAllowed,
        'rate_limited' => ClaudeErrorKind.rateLimited,
        'refused' => ClaudeErrorKind.refused,
        'image_rejected' ||
        'images_unavailable' ||
        'prompt_too_large' =>
          ClaudeErrorKind.badRequest,
        'upstream_error' => ClaudeErrorKind.overloaded,
        _ => ClaudeErrorKind.badResponse,
      };
}
