import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Result of one `aiChatComplete` call.
class AiChatBackendResult {
  final String text;
  final bool cached;

  /// True when the LLM's reply drew on general educational/career
  /// knowledge rather than (or in addition to) College Reality's verified
  /// data -- the prompt instructs it to say so inline, this just mirrors
  /// that back as a structured flag for callers that want it.
  final bool isGeneralAdvice;

  const AiChatBackendResult({
    required this.text,
    required this.cached,
    required this.isGeneralAdvice,
  });
}

/// Thrown when the server reports the caller has hit their daily AI-chat
/// quota (`resource-exhausted`). Deliberately a distinct type from every
/// other failure: a quota hit should surface a clear "try again tomorrow"
/// message, not silently fall back to a database-only answer the way a
/// transient network/service failure should.
class AiChatQuotaExceededException implements Exception {
  final String message;
  const AiChatQuotaExceededException(this.message);
  @override
  String toString() => message;
}

/// Flutter's only connection to the LLM -- a single authenticated callable
/// to the `aiChatComplete` Cloud Function (functions/src/aiChat.js). No
/// API key, no direct provider SDK, and no Gemini-specific code exists on
/// this side at all; swapping the backend's provider never touches this
/// class. See functions/README.md for the request/response contract.
class AiChatBackendClient {
  AiChatBackendClient({FirebaseFunctions? functions}) : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  // Resolved lazily (on first actual use) rather than in the constructor
  // initializer list -- constructing an AiAssistantService/
  // AiChatBackendClient must never itself require a live Firebase app
  // (e.g. in a plain Dart unit test that never calls .complete()).
  FirebaseFunctions get _functions => _functionsOverride ?? FirebaseFunctions.instance;

  static void _log(String message) {
    if (kDebugMode) debugPrint('[AiChatBackendClient] $message');
  }

  Future<AiChatBackendResult> complete({
    required String question,
    required String mode,
    String? collegeId,
    Map<String, dynamic>? collegeContext,
    List<Map<String, dynamic>>? candidateColleges,
    List<Map<String, String>>? history,
    Map<String, String?>? filters,
  }) async {
    _log('START aiChatComplete mode=$mode collegeId=${collegeId ?? "(none)"}');
    try {
      final callable = _functions.httpsCallable(
        'aiChatComplete',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final response = await callable.call<Map<String, dynamic>>({
        'question': question,
        'mode': mode,
        'collegeId': ?collegeId,
        'collegeContext': ?collegeContext,
        'candidateColleges': ?candidateColleges,
        'history': ?history,
        'filters': ?filters,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      _log('SUCCESS aiChatComplete cached=${data['cached']}');
      return AiChatBackendResult(
        text: data['text'] as String? ?? '',
        cached: data['cached'] as bool? ?? false,
        isGeneralAdvice: data['isGeneralAdvice'] as bool? ?? false,
      );
    } on FirebaseFunctionsException catch (e) {
      _log('FAILED aiChatComplete code=${e.code} message=${e.message}');
      if (e.code == 'resource-exhausted') {
        throw AiChatQuotaExceededException(
          e.message ?? "You've reached today's AI chat limit. Please try again tomorrow.",
        );
      }
      rethrow;
    }
  }
}
