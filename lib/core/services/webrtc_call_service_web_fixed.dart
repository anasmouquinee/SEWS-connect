import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Web-compatible WebRTC service using browser native APIs
/// This provides real peer-to-peer audio/video calls for Flutter web
class WebRTCCallServiceWeb {
  static bool _isInCall = false;
  static bool _isMuted = false;
  static bool _isVideoOn = false;
  static bool _isSpeakerOn = false;
  static String? _currentChannelId;
  static String? _currentUserId;
  
  // JavaScript WebRTC instance
  static js.JsObject? _webRTCInstance;
  
  // Firebase signaling
  static StreamSubscription? _signalingSubscription;
  
  // Callbacks
  static Function()? onCallEnded;
  static Function(String error)? onError;
  static Function()? onCallConnected;
  
  /// Initialize WebRTC service for web
  static Future<void> initialize() async {
    try {
      // Get the WebRTC JavaScript instance
      _webRTCInstance = js.context['webRTCMethods'];
      
      if (_webRTCInstance == null) {
        throw Exception('WebRTC JavaScript not loaded');
      }
      
      // Set up callbacks including ICE candidate callback
      js.context['flutter_callbacks'] = js.JsObject.jsify({
        'onRemoteStream': (stream) {
          debugPrint('🎵 Remote stream received');
          onCallConnected?.call();
        },
        'onLocalStream': (stream) {
          debugPrint('🎤 Local stream ready');
        },
        'onCallConnected': () {
          debugPrint('🔗 Call connected');
          onCallConnected?.call();
        },
        'onCallEnded': () {
          debugPrint('📞 Call ended from JavaScript');
          _isInCall = false;
          _currentChannelId = null;
          _currentUserId = null;
          onCallEnded?.call();
        },
        'onError': (error) {
          debugPrint('❌ WebRTC error: $error');
          onError?.call(error.toString());
        },
        'onIceCandidate': (candidate) async {
          if (_currentChannelId != null) {
            await _sendIceCandidate(_currentChannelId!, candidate);
          }
        },
      });
      
      debugPrint('✅ WebRTC Web service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize WebRTC Web: $e');
      rethrow;
    }
  }
  
  /// Start a new call (generates new channel ID)
  static Future<String> startCall({
    required String userId,
    bool audioOnly = true,
  }) async {
    try {
      debugPrint('📞 Starting new call...');
      
      _currentUserId = userId;
      _isInCall = true;
      
      // Ensure WebRTC is initialized
      if (_webRTCInstance == null) {
        await initialize();
      }
      
      // Get user media first
      await _webRTCInstance!.callMethod('getUserMedia', [audioOnly]);
      debugPrint('✅ Got user media for start');
      
      // Create peer connection
      _webRTCInstance!.callMethod('createPeerConnection');
      debugPrint('✅ Created peer connection for start');
      
      // Create offer
      final offer = await _webRTCInstance!.callMethod('createOffer');
      debugPrint('✅ Created offer');
      
      // Generate unique channel ID
      final channelId = 'call_${DateTime.now().millisecondsSinceEpoch}';
      _currentChannelId = channelId;
      
      // Save offer to Firebase
      await FirebaseFirestore.instance
          .collection('webrtc_calls')
          .doc(channelId)
          .set({
        'offer': {
          'type': offer['type'],
          'sdp': offer['sdp'],
        },
        'created_by': userId,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'calling',
        'ice_candidates': [], // Initialize empty array
      });
      
      // Listen for answer and ICE candidates
      _setupSignalingListener(channelId);
      
      debugPrint('✅ Call started: $channelId');
      return channelId;
    } catch (e) {
      debugPrint('❌ Failed to start call: $e');
      _isInCall = false;
      onError?.call('Failed to start call: $e');
      rethrow;
    }
  }
  
  /// Join an existing call
  static Future<void> joinCall({
    required String channelId,
    required String userId,
    bool audioOnly = true,
  }) async {
    try {
      debugPrint('📞 Joining call: $channelId');
      
      _currentChannelId = channelId;
      _currentUserId = userId;
      _isInCall = true;
      
      // Ensure WebRTC is initialized
      if (_webRTCInstance == null) {
        await initialize();
      }
      
      // Get user media first
      await _webRTCInstance!.callMethod('getUserMedia', [audioOnly]);
      debugPrint('✅ Got user media for join');
      
      // Create peer connection
      _webRTCInstance!.callMethod('createPeerConnection');
      debugPrint('✅ Created peer connection for join');
      
      // Get the offer from Firebase with retry logic
      DocumentSnapshot callDoc;
      int retries = 0;
      const maxRetries = 5;
      
      do {
        callDoc = await FirebaseFirestore.instance
            .collection('webrtc_calls')
            .doc(channelId)
            .get();
        
        if (!callDoc.exists) {
          if (retries < maxRetries) {
            debugPrint('⏳ Call document not found, retrying... ($retries/$maxRetries)');
            await Future.delayed(Duration(milliseconds: 500));
            retries++;
            continue;
          } else {
            throw Exception('Call document not found after $maxRetries retries');
          }
        }
        break;
      } while (retries < maxRetries);
      
      final callData = callDoc.data() as Map<String, dynamic>?;
      if (callData == null || callData['offer'] == null) {
        throw Exception('Call data or offer is null');
      }
      
      final offer = callData['offer'] as Map<String, dynamic>;
      debugPrint('✅ Got offer from Firebase: ${offer.keys}');
      
      // Create answer
      final answer = await _webRTCInstance!.callMethod('createAnswer', [
        js.JsObject.jsify(offer)
      ]);
      
      debugPrint('✅ Created answer');
      
      // Save answer to Firebase
      await FirebaseFirestore.instance
          .collection('webrtc_calls')
          .doc(channelId)
          .update({
        'answer': {
          'type': answer['type'],
          'sdp': answer['sdp'],
        },
        'joined_by': userId,
        'status': 'connected',
      });
      
      // Listen for ICE candidates
      _setupSignalingListener(channelId);
      
      debugPrint('✅ Joined call: $channelId');
    } catch (e) {
      debugPrint('❌ Failed to join call: $e');
      _isInCall = false;
      onError?.call('Failed to join call: $e');
      rethrow;
    }
  }
  
  /// Set up Firebase signaling listener
  static void _setupSignalingListener(String channelId) {
    _signalingSubscription?.cancel();
    
    _signalingSubscription = FirebaseFirestore.instance
        .collection('webrtc_calls')
        .doc(channelId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      
      try {
        // Handle answer (for caller)
        if (data['answer'] != null && _currentUserId == data['created_by']) {
          final answer = data['answer'];
          await _webRTCInstance!.callMethod('setRemoteDescription', [
            js.JsObject.jsify(answer)
          ]);
          debugPrint('✅ Set remote description (answer)');
        }
        
        // Handle ICE candidates
        if (data['ice_candidates'] != null) {
          final candidates = List<Map<String, dynamic>>.from(data['ice_candidates']);
          for (final candidate in candidates) {
            if (candidate['from'] != _currentUserId) {
              await _webRTCInstance!.callMethod('addIceCandidate', [
                js.JsObject.jsify(candidate['candidate'])
              ]);
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Signaling error: $e');
      }
    });
  }
  
  /// Send ICE candidate through signaling
  static Future<void> _sendIceCandidate(String channelId, Map<String, dynamic> candidate) async {
    if (_currentUserId == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('webrtc_calls')
          .doc(channelId)
          .update({
        'ice_candidates': FieldValue.arrayUnion([{
          'candidate': candidate,
          'from': _currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        }])
      });
    } catch (e) {
      debugPrint('❌ Failed to send ICE candidate: $e');
    }
  }
  
  /// Toggle microphone mute
  static bool toggleMute() {
    if (_webRTCInstance != null) {
      _isMuted = _webRTCInstance!.callMethod('toggleMute');
      debugPrint(_isMuted ? '🔇 Microphone muted' : '🔊 Microphone unmuted');
    }
    return _isMuted;
  }
  
  /// Toggle video on/off
  static bool toggleVideo() {
    if (_webRTCInstance != null) {
      _isVideoOn = _webRTCInstance!.callMethod('toggleVideo');
      debugPrint(_isVideoOn ? '📹 Video enabled' : '📹 Video disabled');
    }
    return _isVideoOn;
  }
  
  /// Toggle speaker on/off
  static bool toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    debugPrint(_isSpeakerOn ? '🔊 Speaker enabled' : '🔇 Speaker disabled');
    return _isSpeakerOn;
  }
  
  /// End the current call
  static Future<void> endCall() async {
    try {
      debugPrint('📞 Ending call...');
      
      // End call in JavaScript
      if (_webRTCInstance != null) {
        _webRTCInstance!.callMethod('endCall');
      }
      
      // Cancel signaling subscription
      _signalingSubscription?.cancel();
      _signalingSubscription = null;
      
      // Update call status in Firebase
      if (_currentChannelId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('webrtc_calls')
              .doc(_currentChannelId!)
              .update({
            'status': 'ended',
            'ended_at': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('⚠️ Could not update call status in Firebase: $e');
        }
      }
      
      // Reset state
      _isInCall = false;
      _isMuted = false;
      _isVideoOn = false;
      _currentChannelId = null;
      _currentUserId = null;
      
      debugPrint('✅ Call ended and resources cleaned up');
      onCallEnded?.call();
    } catch (e) {
      debugPrint('❌ Error ending call: $e');
    }
  }
  
  /// Get current call status
  static Map<String, dynamic> getCallStatus() {
    Map<String, dynamic> jsStatus = {};
    
    if (_webRTCInstance != null) {
      try {
        final status = _webRTCInstance!.callMethod('getCallStatus');
        jsStatus = Map<String, dynamic>.from(status);
      } catch (e) {
        debugPrint('❌ Failed to get JS call status: $e');
      }
    }
    
    return {
      'isInCall': _isInCall,
      'isMuted': _isMuted,
      'isVideoOn': _isVideoOn,
      'isSpeakerOn': _isSpeakerOn,
      'channelId': _currentChannelId,
      'userId': _currentUserId,
      'connectionState': jsStatus['connectionState'] ?? 'new',
    };
  }
  
  /// Set callbacks for handling WebRTC events
  static void setCallbacks({
    Function()? onCallEnded,
    Function(String error)? onError,
    Function()? onCallConnected,
  }) {
    WebRTCCallServiceWeb.onCallEnded = onCallEnded;
    WebRTCCallServiceWeb.onError = onError;
    WebRTCCallServiceWeb.onCallConnected = onCallConnected;
  }
  
  /// Check if currently in a call
  static bool get isInCall => _isInCall;
  
  /// Check if microphone is muted
  static bool get isMuted => _isMuted;
  
  /// Check if video is on
  static bool get isVideoOn => _isVideoOn;
  
  /// Check if speaker is on
  static bool get isSpeakerOn => _isSpeakerOn;
  
  /// Get current channel ID
  static String? get currentChannelId => _currentChannelId;
  
  /// Get current user ID
  static String? get currentUserId => _currentUserId;
  
  /// Clean up resources
  static void dispose() {
    _signalingSubscription?.cancel();
    if (_webRTCInstance != null) {
      _webRTCInstance!.callMethod('endCall');
    }
    _isInCall = false;
    _currentChannelId = null;
    _currentUserId = null;
  }
}
