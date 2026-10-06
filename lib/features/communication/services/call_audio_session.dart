import 'dart:async';

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
  }) => CallAudioState(
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
  CallAudioSession({required this.sessionId, CallSessionTokenService? tokens})
    : _tokens = tokens ?? CallSessionTokenService(),
      // Every call starts on the earpiece like a normal phone call (video
      // calls are audio-only for now); the Speaker button switches.
      state = ValueNotifier(const CallAudioState());

  final String sessionId;
  final CallSessionTokenService _tokens;
  final ValueNotifier<CallAudioState> state;

  RtcEngine? _engine;
  bool _started = false;
  bool _disposed = false;

  /// In the channel. Agora ignores setEnableSpeakerphone before this, so a
  /// Speaker tap while still connecting is applied on join instead.
  bool _joined = false;

  void _set(CallAudioState next) {
    if (!_disposed) state.value = next;
  }

  void _fail(String message) => _set(
    state.value.copyWith(status: CallAudioStatus.failed, error: message),
  );

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
      await engine.initialize(
        RtcEngineContext(
          appId: token.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (_, _) {
            _joined = true;
            _set(state.value.copyWith(status: CallAudioStatus.waitingForPeer));
            // Apply whatever the user picked while audio was connecting.
            unawaited(_applyRoute());
            unawaited(_engine?.muteLocalAudioStream(state.value.muted));
          },
          onUserJoined: (_, _, _) =>
              _set(state.value.copyWith(status: CallAudioStatus.connected)),
          onUserOffline: (_, _, _) => _set(
            state.value.copyWith(status: CallAudioStatus.waitingForPeer),
          ),
          onConnectionStateChanged: (_, connState, _) {
            if (connState == ConnectionStateType.connectionStateReconnecting) {
              _set(state.value.copyWith(status: CallAudioStatus.reconnecting));
            } else if (connState == ConnectionStateType.connectionStateFailed) {
              _fail('Call audio connection lost.');
            }
          },
          onError: (err, msg) => debugPrint('[CallAudio] $err $msg'),
        ),
      );
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
  /// Before the channel is joined only the preference is stored; it is
  /// applied on join. A failed switch reverts the button.
  Future<void> setSpeakerOn(bool on) async {
    final previous = state.value.speakerOn;
    _set(state.value.copyWith(speakerOn: on));
    try {
      if (_joined) {
        await _engine?.setEnableSpeakerphone(on);
      } else {
        await _engine?.setDefaultAudioRouteToSpeakerphone(on);
      }
    } catch (e) {
      debugPrint('[CallAudio] speaker switch failed: $e');
      _set(state.value.copyWith(speakerOn: previous));
    }
  }

  Future<void> _applyRoute() async {
    try {
      await _engine?.setEnableSpeakerphone(state.value.speakerOn);
    } catch (e) {
      debugPrint('[CallAudio] route: $e');
    }
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
    _joined = false;
    if (engine == null) return;
    try {
      // Silence both directions first so hanging up is instant, even while
      // leaveChannel/release finish in the background.
      await engine.muteAllRemoteAudioStreams(true);
      await engine.muteLocalAudioStream(true);
      await engine.leaveChannel();
      await engine.release();
    } catch (e) {
      debugPrint('[CallAudio] teardown: $e');
    }
  }
}
