import 'package:cloud_functions/cloud_functions.dart';

class CallAccessException implements Exception {
  final String message;
  CallAccessException(this.message);
  @override
  String toString() => message;
}

/// Result of minting a real-time voice/video join token. `appId` is the
/// provider's *public* app identifier (safe client-side); the app
/// certificate used to sign the token never leaves the backend.
class ConsultationCallToken {
  final String appId;
  final String channelName;
  final String token;
  final int uid;

  const ConsultationCallToken({
    required this.appId,
    required this.channelName,
    required this.token,
    required this.uid,
  });

  factory ConsultationCallToken.fromMap(Map<dynamic, dynamic> map) {
    return ConsultationCallToken(
      appId: map['appId'] as String,
      channelName: map['channelName'] as String,
      token: map['token'] as String,
      uid: (map['uid'] as num).toInt(),
    );
  }
}

/// Requests a short-lived, server-minted join token for a paid call/video
/// consultation. There is no real-time media SDK wired into the Flutter
/// app yet (see functions/README.md) — this is the trusted access-control
/// half of that integration: it proves the caller is a paid participant on
/// this exact consultation before any token is issued, which is the part
/// that must never be client-side regardless of which provider is used.
class CallAccessService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<ConsultationCallToken> mintCallToken(String consultationId) async {
    try {
      final callable = _functions.httpsCallable('mintConsultationCallToken');
      final result = await callable.call<Map<String, dynamic>>({
        'consultationId': consultationId,
      });
      return ConsultationCallToken.fromMap(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw CallAccessException(e.message ?? 'Could not start the call.');
    }
  }
}

/// Agora join token for a direct guide call (`call_sessions`), minted by
/// the `mintCallSessionToken` Cloud Function only for a participant of an
/// ACTIVE call. For a free-trial call the token expires with the free time,
/// so Agora itself ends the audio even if an app never hangs up.
class CallSessionTokenService {
  CallSessionTokenService({FirebaseFunctions? functions})
      : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  Future<ConsultationCallToken> mint(String sessionId) async {
    try {
      final result = await _functions
          .httpsCallable('mintCallSessionToken')
          .call<Map<String, dynamic>>({'sessionId': sessionId});
      return ConsultationCallToken.fromMap(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw CallAccessException(e.message ?? 'Could not connect call audio.');
    }
  }
}
