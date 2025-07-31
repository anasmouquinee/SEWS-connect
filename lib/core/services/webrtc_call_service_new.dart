import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'webrtc_call_service_web.dart';

/// Platform-aware WebRTC call service
/// Uses web-native APIs on Flutter web and flutter_webrtc on mobile
class WebRTCCallService {
  /// Initialize WebRTC service
  static Future<void> initialize() async {
    if (kIsWeb) {
      await WebRTCCallServiceWeb.initialize();
    } else {
      // Mobile implementation would go here
      debugPrint('🚀 Mobile WebRTC not implemented yet');
    }
  }
  
  /// Start a new call
  static Future<String> startCall({
    required String calleeId,
    required String calleeName,
    required String callType,
    required String callerId,
  }) async {
    final channelId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    final audioOnly = callType != 'video';
    
    if (kIsWeb) {
      // Send call invitation first
      debugPrint('🔔 Sending call invitation: callerId=$callerId, calleeId=$calleeId, calleeName=$calleeName');
      await FirebaseService.sendCallInvitation(
        callerId: callerId,
        callerName: FirebaseService.currentUser?.displayName ?? 'Unknown Caller',
        calleeId: calleeId,
        calleeName: calleeName,
        channelId: channelId,
        callType: callType,
      );
      debugPrint('✅ Call invitation sent successfully');
      
      return await WebRTCCallServiceWeb.startCall(
        channelId: channelId,
        userId: callerId,
        audioOnly: audioOnly,
      );
    } else {
      throw UnimplementedError('Mobile WebRTC not implemented');
    }
  }
  
  /// Join an existing call
  static Future<void> joinCall(String channelId, String userId) async {
    if (kIsWeb) {
      await WebRTCCallServiceWeb.joinCall(
        channelId: channelId,
        userId: userId,
        audioOnly: true, // Default to audio only for now
      );
    } else {
      throw UnimplementedError('Mobile WebRTC not implemented');
    }
  }
  
  /// Toggle microphone mute
  static bool toggleMute() {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.toggleMute();
    } else {
      return false;
    }
  }
  
  /// Toggle video on/off
  static bool toggleVideo() {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.toggleVideo();
    } else {
      return false;
    }
  }
  
  /// Toggle speaker on/off
  static bool toggleSpeaker() {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.toggleSpeaker();
    } else {
      return false;
    }
  }
  
  /// End the current call
  static Future<void> endCall() async {
    if (kIsWeb) {
      await WebRTCCallServiceWeb.endCall();
    }
  }
  
  /// Get current call status
  static Map<String, dynamic> getCallStatus() {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.getCallStatus();
    } else {
      return {
        'isInCall': false,
        'isMuted': false,
        'isVideoOn': false,
        'isSpeakerOn': false,
        'channelId': null,
        'userId': null,
        'connectionState': 'new',
      };
    }
  }
  
  /// Check if currently in a call
  static bool get isInCall {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.isInCall;
    } else {
      return false;
    }
  }
  
  /// Check if microphone is muted
  static bool get isMuted {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.isMuted;
    } else {
      return false;
    }
  }
  
  /// Check if video is on
  static bool get isVideoOn {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.isVideoOn;
    } else {
      return false;
    }
  }
  
  /// Check if speaker is on
  static bool get isSpeakerOn {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.isSpeakerOn;
    } else {
      return false;
    }
  }
  
  /// Get current channel ID
  static String? get currentChannelId {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.currentChannelId;
    } else {
      return null;
    }
  }
  
  /// Get current user ID
  static String? get currentUserId {
    if (kIsWeb) {
      return WebRTCCallServiceWeb.currentUserId;
    } else {
      return null;
    }
  }
  
  /// Set callbacks
  static void setCallbacks({
    Function()? onCallEnded,
    Function(String error)? onError,
    Function()? onCallConnected,
  }) {
    if (kIsWeb) {
      WebRTCCallServiceWeb.onCallEnded = onCallEnded;
      WebRTCCallServiceWeb.onError = onError;
      WebRTCCallServiceWeb.onCallConnected = onCallConnected;
    }
  }
  
  /// Clean up resources
  static void dispose() {
    if (kIsWeb) {
      WebRTCCallServiceWeb.dispose();
    }
  }
}
