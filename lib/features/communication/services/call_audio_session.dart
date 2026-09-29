import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../consultations/services/call_access_service.dart';

enum CallAudioStatus {
  idle,
  connecting,
  /// In the channel, waiting for the other person's audio to arrive.
  waitingForPeer,
  connected,
  reconnecting,
  failed,
}

@immutable
class CallAudioState {
  final CallAudioStatus status;
  final bool muted;
  final bool speakerOn;
  final String? error;

  const CallAudioState({
    this.status = CallAudioStatus.idle,
    this.muted = false,
    this.speakerOn = false,
    this.error,
  });

  CallAudioState copyWith({
    CallAudioStatus? status,
    bool? muted,
    bool? speakerOn,
    String? error,
  }) =>
      CallAudioState(
        status: status ?? this.status,
        muted: muted ?? this.muted,
        speakerOn: speakerOn ?? this.speakerOn,
        error: error ?? this.error,
      );
}

/// The real-time audio for ONE direct guide call (Agora). Before this the
/// app had no media at all -- a "connected" call was only a Firestore doc.
///
/// Lifecycle (owned by ActiveCallScreen): [join] once the call is ACTIVE,
/// [dispose] when it ends or the screen goes away. Safe against dispose
/// racing an in-flight join. The Firestore call_sessions doc stays the
/// source of truth for whether the call is on; Agora only carries audio.
class CallAudioSession {
  CallAudioSession({
    required this.sessionId,
    required bool isVideo,
    CallSessionTokenService? tokens,
  })  : _tokens = tokens ?? CallSessionTokenService(),
        // Voice calls start on the earpiece like a normal phone call;
        // video calls start on the loudspeaker.
        state = ValueNotifier(CallAudioState(speakerOn: isVideo));

  final String sessionId;
  final CallSessionTokenService _tokens;
  final ValueNotifier<CallAudioState> state;

  RtcEngine? _engine;
  bool _started = false;
  bool _disposed = false;

  void _set(CallAudioState next) {
    if (!_disposed) state.value = next;
  }

  void _fail(String message) =>
      _set(state.value.copyWith(status: CallAudioStatus.failed, error: message));

  Future<void> join() async {
    if (_started || _disposed) return;
    _started = true;
    _set(state.value.copyWith(status: CallAudioStatus.connecting));

    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        _fail('Allow microphone access to talk on this call.');
        return;
      }

      final token = await _tokens.mint(sessionId);
      if (_disposed) return;

      final engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(RtcEngineContext(
        appId: token.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (_, _) =>
            _set(state.value.copyWith(status: CallAudioStatus.waitingForPeer)),
        onUserJoined: (_, _, _) =>
            _set(state.value.copyWith(status: CallAudioStatus.connected)),
        onUserOffline: (_, _, _) =>
            _set(state.value.copyWith(status: CallAudioStatus.waitingForPeer)),
        onConnectionStateChanged: (_, connState, _) {
          if (connState == ConnectionStateType.connectionStateReconnecting) {
            _set(state.value.copyWith(status: CallAudioStatus.reconnecting));
          } else if (connState == ConnectionStateType.connectionStateFailed) {
            _fail('Call audio connection lost.');
          }
        },
        onError: (err, msg) => debugPrint('[CallAudio] $err $msg'),
      ));
      await engine.enableAudio();
      await engine.setDefaultAudioRouteToSpeakerphone(state.value.speakerOn);
      await engine.joinChannel(
        token: token.token,
        channelId: token.channelName,
        uid: token.uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );
      if (_disposed) await _teardown();
    } on CallAccessException catch (e) {
      _fail(e.message);
    } catch (e) {
      debugPrint('[CallAudio] join failed: $e');
      _fail('Could not connect call audio.');
    }
  }

  Future<void> setMuted(bool muted) async {
    _set(state.value.copyWith(muted: muted));
    await _engine?.muteLocalAudioStream(muted);
  }

  /// Loudspeaker on/off (Agora audio route: speaker vs earpiece/headset).
  Future<void> setSpeakerOn(bool on) async {
    _set(state.value.copyWith(speakerOn: on));
    await _engine?.setEnableSpeakerphone(on);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _teardown();
    state.dispose();
  }

  Future<void> _teardown() async {
    final engine = _engine;
    _engine = null;
    if (engine == null) return;
    try {
      await engine.leaveChannel();
      await engine.release();
    } catch (e) {
      debugPrint('[CallAudio] teardown: $e');
    }
  }
}
