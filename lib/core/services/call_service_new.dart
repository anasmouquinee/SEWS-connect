import 'dart:async';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'real_webrtc_service.dart';

class CallService {
  static bool _isInCall = false;
  static bool _isMuted = false;
  static bool _isVideoOn = false;
  static String? _currentCallId;
  
  // Callbacks
  static Function(String uid)? onUserJoined;
  static Function(String uid)? onUserLeft;
  static Function()? onCallEnded;
  static Function(String error)? onError;
  
  static Future<void> initialize() async {
    await RealWebRTCService.initialize();
    debugPrint('✅ CallService initialized with WebRTC');
  }
  
  static Future<String> startCall({
    required String calleeId,
    required String calleeName,
    required String callType,
  }) async {
    try {
      // Generate unique call ID
      final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
      _currentCallId = callId;
      _isInCall = true;
      _isVideoOn = callType == 'video';
      
      debugPrint('✅ CallService: Starting WebRTC call with ID $callId');
      
      // Send call invitation via Firebase first
      await _sendCallInvitation(
        calleeId: calleeId,
        calleeName: calleeName,
        callId: callId,
        callType: callType,
      );
      
      // Start WebRTC call as the caller (offerer)
      await RealWebRTCService.startCall(
        callId: callId,
        isVideoCall: callType == 'video',
      );
      
      return callId;
    } catch (e) {
      debugPrint('❌ Error starting call: $e');
      _isInCall = false;
      _currentCallId = null;
      rethrow;
    }
  }
  
  static Future<void> _sendCallInvitation({
    required String calleeId,
    required String calleeName,
    required String callId,
    required String callType,
  }) async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await FirebaseService.sendCallInvitation(
        callerId: user.uid,
        callerName: user.displayName ?? 'SEWS User',
        calleeId: calleeId,
        calleeName: calleeName,
        channelId: callId, // Use callId as channelId for WebRTC
        callType: callType,
      );
      
      debugPrint('✅ Call invitation sent to $calleeId');
    } catch (e) {
      debugPrint('❌ Error sending call invitation: $e');
      throw e;
    }
  }
  
  static Future<void> acceptCall({
    required String callId,
    required String channelId,
    required String callType,
    String? callerName,
  }) async {
    try {
      _currentCallId = callId;
      _isInCall = true;
      _isVideoOn = callType == 'video';
      
      // Answer the WebRTC call
      await RealWebRTCService.answerCall(
        callId: channelId, // Use channelId as the WebRTC call ID
        isVideoCall: callType == 'video',
      );
      
      // Update call status in Firebase
      await FirebaseService.markCallAsRead(callId);
      
      debugPrint('✅ Accepted call and answered WebRTC: $channelId');
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      rethrow;
    }
  }
  
  static Future<void> declineCall(String callId) async {
    try {
      // Update call status in Firebase
      await FirebaseService.markCallAsRead(callId);
      debugPrint('✅ Call declined');
    } catch (e) {
      debugPrint('❌ Error declining call: $e');
    }
  }
  
  static Future<void> endCall() async {
    try {
      if (_currentCallId != null) {
        await RealWebRTCService.endCall();
      }
      
      _isInCall = false;
      _currentCallId = null;
      _isMuted = false;
      _isVideoOn = false;
      
      onCallEnded?.call();
      debugPrint('✅ Call ended');
    } catch (e) {
      debugPrint('❌ Error ending call: $e');
    }
  }
  
  static Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await RealWebRTCService.toggleMute();
      debugPrint('✅ Audio muted: $_isMuted');
    } catch (e) {
      debugPrint('❌ Error toggling mute: $e');
    }
  }
  
  static Future<void> toggleVideo() async {
    try {
      _isVideoOn = !_isVideoOn;
      await RealWebRTCService.toggleVideo();
      debugPrint('✅ Video on: $_isVideoOn');
    } catch (e) {
      debugPrint('❌ Error toggling video: $e');
    }
  }
  
  static Future<void> toggleCamera() async {
    try {
      await RealWebRTCService.switchCamera();
      debugPrint('✅ Camera toggled');
    } catch (e) {
      debugPrint('❌ Error toggling camera: $e');
    }
  }
  
  static Future<void> sendChatMessage(String message) async {
    try {
      // WebRTC doesn't have built-in chat, could implement via Firebase
      debugPrint('💬 Chat message: $message');
      // TODO: Implement chat via Firebase if needed
    } catch (e) {
      debugPrint('❌ Error sending chat message: $e');
    }
  }
  
  // Getters
  static bool get isInCall => _isInCall;
  static bool get isMuted => _isMuted;
  static bool get isVideoOn => _isVideoOn;
  static String? get currentCallId => _currentCallId;
  
  // For backward compatibility with old call invitations
  static String getRoomIdFromChannelId(String channelId) {
    // Convert old channel IDs to call IDs if needed
    if (channelId.startsWith('call_')) {
      return channelId;
    }
    return 'call_legacy_$channelId';
  }
}
