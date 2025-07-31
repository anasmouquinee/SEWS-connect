import 'dart:async';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'jitsi_service.dart';

class CallService {
  static bool _isInCall = false;
  static bool _isMuted = false;
  static bool _isVideoOn = false;
  static String? _currentRoomId;
  
  // Callbacks
  static Function(String uid)? onUserJoined;
  static Function(String uid)? onUserLeft;
  static Function()? onCallEnded;
  static Function(String error)? onError;
  
  static Future<void> initialize() async {
    await JitsiService.initialize();
    debugPrint('✅ CallService initialized with Jitsi Meet');
  }
  
  static Future<String> startCall({
    required String calleeId,
    required String calleeName,
    required String callType,
  }) async {
    try {
      // Generate unique room ID for the call
      final roomId = JitsiService.generateFriendlyMeetingId();
      _currentRoomId = roomId;
      _isInCall = true;
      _isVideoOn = callType == 'video';
      
      debugPrint('✅ CallService: Starting Jitsi call with room $roomId');
      
      // Send call invitation via Firebase
      await _sendCallInvitation(
        calleeId: calleeId,
        calleeName: calleeName,
        roomId: roomId,
        callType: callType,
      );
      
      // Join the Jitsi meeting
      await JitsiService.joinMeeting(
        roomId: roomId,
        displayName: FirebaseService.currentUser?.displayName ?? 'SEWS User',
        email: FirebaseService.currentUser?.email ?? '',
        audioMuted: false,
        videoMuted: callType != 'video',
        subject: 'SEWS Connect Call with $calleeName',
      );
      
      return roomId;
    } catch (e) {
      debugPrint('❌ Error starting call: $e');
      _isInCall = false;
      _currentRoomId = null;
      rethrow;
    }
  }
  
  static Future<void> _sendCallInvitation({
    required String calleeId,
    required String calleeName,
    required String roomId,
    required String callType,
  }) async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await FirebaseService.sendCallInvitation(
        calleeId: calleeId,
        calleeName: calleeName,
        callType: callType,
        jitsiRoomId: roomId, // Pass Jitsi room ID
      );
      
      debugPrint('✅ Call invitation sent to $calleeId');
    } catch (e) {
      debugPrint('❌ Error sending call invitation: $e');
      throw e;
    }
  }
  
  static Future<void> acceptCall({
    required String callId,
    required String roomId,
    required String callType,
    String? callerName,
  }) async {
    try {
      _currentRoomId = roomId;
      _isInCall = true;
      _isVideoOn = callType == 'video';
      
      // Join the Jitsi meeting
      await JitsiService.joinMeeting(
        roomId: roomId,
        displayName: FirebaseService.currentUser?.displayName ?? 'SEWS User',
        email: FirebaseService.currentUser?.email ?? '',
        audioMuted: false,
        videoMuted: callType != 'video',
        subject: callerName != null ? 'SEWS Connect Call with $callerName' : 'SEWS Connect Call',
      );
      
      // Update call status in Firebase
      await FirebaseService.markCallAsRead(callId);
      
      debugPrint('✅ Accepted call and joined Jitsi room: $roomId');
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
      if (_currentRoomId != null) {
        await JitsiService.hangUp();
      }
      
      _isInCall = false;
      _currentRoomId = null;
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
      await JitsiService.setAudioMuted(_isMuted);
      debugPrint('✅ Audio muted: $_isMuted');
    } catch (e) {
      debugPrint('❌ Error toggling mute: $e');
    }
  }
  
  static Future<void> toggleVideo() async {
    try {
      _isVideoOn = !_isVideoOn;
      await JitsiService.setVideoMuted(!_isVideoOn);
      debugPrint('✅ Video on: $_isVideoOn');
    } catch (e) {
      debugPrint('❌ Error toggling video: $e');
    }
  }
  
  static Future<void> toggleCamera() async {
    try {
      await JitsiService.toggleCamera();
      debugPrint('✅ Camera toggled');
    } catch (e) {
      debugPrint('❌ Error toggling camera: $e');
    }
  }
  
  static Future<void> sendChatMessage(String message) async {
    try {
      await JitsiService.sendChatMessage(message: message);
      debugPrint('✅ Chat message sent: $message');
    } catch (e) {
      debugPrint('❌ Error sending chat message: $e');
    }
  }
  
  // Getters
  static bool get isInCall => _isInCall;
  static bool get isMuted => _isMuted;
  static bool get isVideoOn => _isVideoOn;
  static String? get currentRoomId => _currentRoomId;
  
  // For backward compatibility with old call invitations
  static String getRoomIdFromChannelId(String channelId) {
    // Convert old channel IDs to room IDs if needed
    if (channelId.startsWith('sews-')) {
      return channelId;
    }
    return 'sews-legacy-$channelId';
  }
}
