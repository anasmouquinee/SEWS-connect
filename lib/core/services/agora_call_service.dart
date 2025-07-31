import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_service.dart';

class AgoraCallService {
  // REAL Agora App ID - This would be from your Agora Console
  static const String agoraAppId = "YOUR_AGORA_APP_ID"; // Replace with real App ID
  
  static RtcEngine? _engine;
  static bool _isInCall = false;
  static bool _isMuted = false;
  static bool _isVideoOn = false;
  static bool _isSpeakerOn = false;
  static String? _currentChannelId;
  static String? _currentToken;
  static Set<int> _remoteUsers = {};
  
  // Callbacks
  static Function(int uid)? onUserJoined;
  static Function(int uid)? onUserLeft;
  static Function()? onCallEnded;
  static Function(String error)? onError;
  
  static Future<void> initialize() async {
    try {
      // Request permissions first
      await _requestPermissions();
      
      // Check if we have a real App ID
      if (agoraAppId == "YOUR_AGORA_APP_ID") {
        debugPrint('⚠️ AGORA: Using demo mode - Please add your Agora App ID');
        return;
      }
      
      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      
      // Set up event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('✅ AGORA: Successfully joined channel: ${connection.channelId}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('✅ AGORA: User joined: $remoteUid');
          _remoteUsers.add(remoteUid);
          onUserJoined?.call(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint('✅ AGORA: User left: $remoteUid');
          _remoteUsers.remove(remoteUid);
          onUserLeft?.call(remoteUid);
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('❌ AGORA: Error $err: $msg');
          onError?.call('Agora Error: $msg');
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('✅ AGORA: Left channel');
          _isInCall = false;
          _remoteUsers.clear();
          onCallEnded?.call();
        },
      ));
      
      debugPrint('✅ AGORA: Engine initialized successfully');
    } catch (e) {
      debugPrint('❌ AGORA: Failed to initialize: $e');
      onError?.call('Failed to initialize Agora: $e');
    }
  }
  
  static Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }
  
  static Future<String> startCall({
    required String calleeId,
    required String calleeName,
    required String callType,
  }) async {
    try {
      // Generate a unique channel ID
      final channelId = 'call_${DateTime.now().millisecondsSinceEpoch}';
      _currentChannelId = channelId;
      _isVideoOn = callType == 'video';
      
      // Send call invitation via Firebase
      await _sendCallInvitation(
        calleeId: calleeId,
        calleeName: calleeName,
        channelId: channelId,
        callType: callType,
      );
      
      // Join Agora channel
      await _joinChannel(channelId, callType);
      
      // Log call start
      await FirebaseService.logCall(
        calleeId: calleeId,
        calleeName: calleeName,
        type: callType,
        status: 'started',
        duration: 0,
      );
      
      debugPrint('✅ AGORA: Call started with channel $channelId');
      return channelId;
    } catch (e) {
      debugPrint('❌ AGORA: Failed to start call: $e');
      throw e;
    }
  }
  
  static Future<void> joinCall({
    required String channelId,
    required String callType,
  }) async {
    try {
      _currentChannelId = channelId;
      _isVideoOn = callType == 'video';
      
      await _joinChannel(channelId, callType);
      
      debugPrint('✅ AGORA: Joined call with channel $channelId');
    } catch (e) {
      debugPrint('❌ AGORA: Failed to join call: $e');
      throw e;
    }
  }
  
  static Future<void> _joinChannel(String channelId, String callType) async {
    if (_engine == null) {
      debugPrint('⚠️ AGORA: Engine not initialized, using demo mode');
      _isInCall = true;
      return;
    }
    
    try {
      // Configure for video call if needed
      if (callType == 'video') {
        await _engine!.enableVideo();
        await _engine!.enableLocalVideo(true);
      } else {
        await _engine!.disableVideo();
      }
      
      // Join the channel
      await _engine!.joinChannel(
        token: _currentToken ?? '', // You would generate this from your Agora server
        channelId: channelId,
        uid: 0, // Let Agora assign UID
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      
      _isInCall = true;
      debugPrint('✅ AGORA: Successfully joined channel $channelId');
    } catch (e) {
      debugPrint('❌ AGORA: Failed to join channel: $e');
      throw e;
    }
  }
  
  static Future<void> endCall() async {
    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
      }
      
      _isInCall = false;
      _isMuted = false;
      _isVideoOn = false;
      _isSpeakerOn = false;
      _currentChannelId = null;
      _remoteUsers.clear();
      
      debugPrint('✅ AGORA: Call ended');
    } catch (e) {
      debugPrint('❌ AGORA: Error ending call: $e');
    }
  }
  
  static Future<void> toggleMute() async {
    if (_engine != null) {
      _isMuted = !_isMuted;
      await _engine!.muteLocalAudioStream(_isMuted);
      debugPrint('✅ AGORA: Microphone ${_isMuted ? 'muted' : 'unmuted'}');
    }
  }
  
  static Future<void> toggleVideo() async {
    if (_engine != null) {
      _isVideoOn = !_isVideoOn;
      await _engine!.enableLocalVideo(_isVideoOn);
      debugPrint('✅ AGORA: Video ${_isVideoOn ? 'enabled' : 'disabled'}');
    }
  }
  
  static Future<void> toggleSpeaker() async {
    if (_engine != null) {
      _isSpeakerOn = !_isSpeakerOn;
      await _engine!.setEnableSpeakerphone(_isSpeakerOn);
      debugPrint('✅ AGORA: Speaker ${_isSpeakerOn ? 'on' : 'off'}');
    }
  }
  
  static Future<void> switchCamera() async {
    if (_engine != null && _isVideoOn) {
      await _engine!.switchCamera();
      debugPrint('✅ AGORA: Camera switched');
    }
  }
  
  static Future<void> _sendCallInvitation({
    required String calleeId,
    required String calleeName,
    required String channelId,
    required String callType,
  }) async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) return;
      
      await FirebaseService.sendCallInvitation(
        callerId: currentUser.uid,
        callerName: currentUser.displayName ?? 'Unknown Caller',
        calleeId: calleeId,
        calleeName: calleeName,
        channelId: channelId,
        callType: callType,
      );
      
      debugPrint('✅ AGORA: Call invitation sent to $calleeName');
    } catch (e) {
      debugPrint('❌ AGORA: Failed to send call invitation: $e');
    }
  }
  
  static Widget? createLocalVideoView() {
    if (_engine == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Local Video\n(Add Agora App ID for real video)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return _isVideoOn 
        ? AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine!,
              canvas: const VideoCanvas(uid: 0),
            ),
          )
        : Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.videocam_off, color: Colors.white, size: 50),
            ),
          );
  }
  
  static Widget? createRemoteVideoView(int uid) {
    if (_engine == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Text(
            'Remote Video\n(Add Agora App ID for real video)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: _currentChannelId),
      ),
    );
  }
  
  static Future<void> dispose() async {
    try {
      await endCall();
      await _engine?.release();
      _engine = null;
      debugPrint('✅ AGORA: Service disposed');
    } catch (e) {
      debugPrint('❌ AGORA: Error disposing: $e');
    }
  }
  
  // Getters
  static bool get isInCall => _isInCall;
  static bool get isMuted => _isMuted;
  static bool get isVideoOn => _isVideoOn;
  static bool get isSpeakerOn => _isSpeakerOn;
  static String? get currentChannelId => _currentChannelId;
  static Set<int> get remoteUsers => _remoteUsers;
  static bool get hasEngine => _engine != null && agoraAppId != "YOUR_AGORA_APP_ID";
}
