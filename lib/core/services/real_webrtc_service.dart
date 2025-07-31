import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:io' show Platform;
import '../services/android_permission_service.dart';

/// Real WebRTC service for actual audio/video communication
/// Uses flutter_webrtc package - works on both mobile and web
class RealWebRTCService {
  static RTCPeerConnection? _peerConnection;
  static MediaStream? _localStream;
  static MediaStream? _remoteStream;
  static bool _isMuted = false;
  static bool _isVideoEnabled = true;
  static String? _currentCallId;
  static bool _isOfferer = false; // Track if this instance is the offer creator
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controllers for call events
  static final StreamController<MediaStream> _remoteStreamController = 
      StreamController<MediaStream>.broadcast();
  static final StreamController<String> _callStateController = 
      StreamController<String>.broadcast();
  
  // ICE candidate listener
  static StreamSubscription<QuerySnapshot>? _iceCandidateListener;
  
  // Getters for streams
  static Stream<MediaStream> get remoteStreamStream => _remoteStreamController.stream;
  static Stream<String> get callStateStream => _callStateController.stream;
  
  /// Configuration for WebRTC peer connection
  static const Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
    ],
    'iceCandidatePoolSize': 10,
  };

  /// Initialize WebRTC service
  static Future<bool> initialize() async {
    try {
      debugPrint('🔧 Initializing Real WebRTC service...');
      
      // Request Android 11+ permissions first
      if (!kIsWeb && Platform.isAndroid) {
        debugPrint('📱 Requesting Android permissions for WebRTC...');
        bool permissionsGranted = await AndroidPermissionService.initializePermissionsForWebRTC();
        
        if (!permissionsGranted) {
          debugPrint('⚠️ Some permissions not granted - WebRTC may not work properly');
          final status = await AndroidPermissionService.getPermissionStatus();
          debugPrint('Permission status: $status');
        }
      }
      
      debugPrint('✅ Real WebRTC service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize Real WebRTC service: $e');
      return false;
    }
  }

  /// Get user media (camera and microphone)
  static Future<MediaStream?> getUserMedia({
    bool audio = true, 
    bool video = false // Default to audio-only for voice calls
  }) async {
    try {
      debugPrint('🎥 Getting user media - Audio: $audio, Video: $video');
      
      // Start with the simplest possible constraints for mobile compatibility
      Map<String, dynamic> mediaConstraints;
      
      if (kIsWeb) {
        // Full constraints for web
        mediaConstraints = {
          'audio': audio ? {
            'echoCancellation': true,
            'noiseSuppression': true,
            'autoGainControl': true,
            'sampleRate': 44100,
          } : false,
          'video': video ? {
            'width': {'min': 640, 'ideal': 1280, 'max': 1920},
            'height': {'min': 480, 'ideal': 720, 'max': 1080},
            'frameRate': {'min': 15, 'ideal': 30, 'max': 60},
          } : false,
        };
      } else {
        // Simple constraints for mobile
        mediaConstraints = {
          'audio': audio,
          'video': video,
        };
      }

      try {
        debugPrint('🎤 Requesting media with constraints: $mediaConstraints');
        _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
        debugPrint('✅ Got media stream successfully');
      } catch (e) {
        debugPrint('⚠️ Failed to get media with initial constraints: $e');
        
        // Fallback to absolute simplest audio-only request
        if (audio) {
          try {
            debugPrint('🎤 Trying fallback: simple audio only...');
            _localStream = await navigator.mediaDevices.getUserMedia({
              'audio': true,
              'video': false,
            });
            debugPrint('✅ Got fallback audio-only media');
          } catch (fallbackError) {
            debugPrint('❌ Even simple audio request failed: $fallbackError');
            // Don't throw - return null to indicate failure
            return null;
          }
        } else {
          debugPrint('❌ No audio requested and video failed');
          return null;
        }
      }
      
      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        final videoTracks = _localStream!.getVideoTracks();
        debugPrint('✅ Got user media - Audio tracks: ${audioTracks.length}, Video tracks: ${videoTracks.length}');
        
        // Log track details
        for (var track in audioTracks) {
          debugPrint('🎤 Audio track: ${track.label}, enabled: ${track.enabled}');
        }
        for (var track in videoTracks) {
          debugPrint('🎥 Video track: ${track.label}, enabled: ${track.enabled}');
        }
      }
      
      return _localStream;
    } catch (e) {
      debugPrint('❌ Failed to get user media: $e');
      return null;
    }
  }

  /// Create peer connection
  static Future<RTCPeerConnection?> _createPeerConnection() async {
    try {
      debugPrint('🔗 Creating peer connection...');
      
      final peerConnection = await createPeerConnection(_rtcConfiguration);
      
      // Set up event handlers
      peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        debugPrint('🧊 Got ICE candidate: ${candidate.candidate?.substring(0, 50)}...');
        _sendIceCandidate(candidate);
      };

      peerConnection.onTrack = (RTCTrackEvent event) {
        debugPrint('📺 Remote track added: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _remoteStreamController.add(_remoteStream!);
        }
      };

      peerConnection.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('🔗 Connection state changed: $state');
        _callStateController.add(state.toString());
        
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          debugPrint('🎉 WebRTC connection established successfully!');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          debugPrint('❌ WebRTC connection failed!');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          debugPrint('⚠️ WebRTC connection disconnected');
        }
      };

      peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint('🧊 ICE connection state changed: $state');
        
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          debugPrint('🎉 ICE connection established successfully!');
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          debugPrint('❌ ICE connection failed!');
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          debugPrint('⚠️ ICE connection disconnected');
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateChecking) {
          debugPrint('🔍 ICE connection checking...');
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateNew) {
          debugPrint('🆕 ICE connection new');
        }
      };

      peerConnection.onIceGatheringState = (RTCIceGatheringState state) {
        debugPrint('🧊 ICE gathering state: $state');
      };

      debugPrint('✅ Peer connection created successfully');
      return peerConnection;
    } catch (e) {
      debugPrint('❌ Failed to create peer connection: $e');
      return null;
    }
  }

  /// Start a call (caller side)
  static Future<RTCSessionDescription?> createOffer(String callId, {bool video = false}) async {
    try {
      _currentCallId = callId;
      _isOfferer = true; // Mark this as the offerer
      debugPrint('📞 Creating offer for call: $callId (video: $video) - I am the OFFERER');
      
      // Get user media first - don't fail the entire call if this fails
      debugPrint('🎤 Requesting microphone access...');
      _localStream = await getUserMedia(audio: true, video: video);
      if (_localStream == null) {
        debugPrint('⚠️ Could not get user media - continuing without WebRTC audio');
        // Don't throw exception - let the call continue with Firebase signaling only
        return null;
      }
      debugPrint('✅ Got user media successfully');

      // Create peer connection
      debugPrint('🔗 Creating peer connection...');
      _peerConnection = await _createPeerConnection();
      if (_peerConnection == null) {
        debugPrint('⚠️ Could not create peer connection - continuing without WebRTC');
        return null;
      }

      // Add local stream tracks to peer connection
      debugPrint('📤 Adding local tracks to peer connection...');
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
        debugPrint('📤 Added local track: ${track.kind}');
      }

      // Create offer
      debugPrint('📝 Creating WebRTC offer...');
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Store offer in Firestore
      debugPrint('💾 Storing offer in Firestore...');
      await _firestore.collection('calls').doc(callId).update({
        'webrtc_offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
        'webrtc_state': 'offer_created',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Start listening for ICE candidates
      _startIceCandidateListener(callId);

      debugPrint('✅ Offer created and stored');
      return offer;
    } catch (e) {
      debugPrint('❌ Failed to create offer: $e');
      debugPrint('⚠️ WebRTC failed but call can continue with Firebase signaling');
      // Don't throw - return null to indicate WebRTC failed but call should continue
      return null;
    }
  }

  /// Accept a call (receiver side)
  static Future<RTCSessionDescription?> createAnswer(String callId, {bool video = false}) async {
    try {
      _currentCallId = callId;
      _isOfferer = false; // Mark this as the answerer
      debugPrint('📞 Creating answer for call: $callId (video: $video) - I am the ANSWERER');
      
      // Get call document to retrieve offer
      final callDoc = await _firestore.collection('calls').doc(callId).get();
      if (!callDoc.exists || callDoc.data() == null) {
        debugPrint('❌ Call document not found: $callId');
        return null;
      }

      final callData = callDoc.data()!;
      final offerData = callData['webrtc_offer'] as Map<String, dynamic>?;
      if (offerData == null) {
        debugPrint('❌ No WebRTC offer found in call document - continuing without WebRTC');
        return null;
      }

      // Get user media - don't fail if this fails
      debugPrint('🎤 Requesting microphone access for answer...');
      _localStream = await getUserMedia(audio: true, video: video);
      if (_localStream == null) {
        debugPrint('⚠️ Could not get user media - continuing without WebRTC audio');
        return null;
      }
      debugPrint('✅ Got user media successfully');

      // Create peer connection
      debugPrint('🔗 Creating peer connection for answer...');
      _peerConnection = await _createPeerConnection();
      if (_peerConnection == null) {
        debugPrint('⚠️ Could not create peer connection - continuing without WebRTC');
        return null;
      }

      // Add local stream tracks
      debugPrint('📤 Adding local tracks to peer connection...');
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
        debugPrint('📤 Added local track: ${track.kind}');
      }

      // Set remote description (offer)
      debugPrint('📥 Setting remote description (offer)...');
      final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
      await _peerConnection!.setRemoteDescription(offer);

      // Create answer
      debugPrint('📝 Creating WebRTC answer...');
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Store answer in Firestore
      debugPrint('💾 Storing answer in Firestore...');
      await _firestore.collection('calls').doc(callId).update({
        'webrtc_answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
        'webrtc_state': 'answer_created',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Start listening for ICE candidates
      _startIceCandidateListener(callId);

      debugPrint('✅ Answer created and stored');
      return answer;
    } catch (e) {
      debugPrint('❌ Failed to create answer: $e');
      debugPrint('⚠️ WebRTC failed but call can continue with Firebase signaling');
      // Don't throw - return null to indicate WebRTC failed but call should continue
      return null;
    }
  }

  /// Handle incoming answer (caller side)
  static Future<void> handleAnswer(String callId) async {
    try {
      debugPrint('📞 Handling answer for call: $callId');
      
      // Only the offerer should handle answers
      if (!_isOfferer) {
        debugPrint('⚠️ Not the offerer, skipping answer handling');
        return;
      }
      
      // Check if peer connection exists and is in correct state
      if (_peerConnection == null) {
        debugPrint('⚠️ No peer connection available - skipping answer handling');
        return;
      }

      final connectionState = await _peerConnection!.getConnectionState();
      final signalingState = await _peerConnection!.getSignalingState();
      
      debugPrint('🔗 Connection state: $connectionState, Signaling state: $signalingState');
      
      // Only handle answer if we're in the right signaling state
      if (signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        debugPrint('⚠️ Wrong signaling state for handling answer: $signalingState - skipping');
        return;
      }
      
      // Get call document to retrieve answer
      final callDoc = await _firestore.collection('calls').doc(callId).get();
      if (!callDoc.exists || callDoc.data() == null) {
        debugPrint('❌ Call document not found: $callId - skipping answer handling');
        return;
      }

      final callData = callDoc.data()!;
      final answerData = callData['webrtc_answer'] as Map<String, dynamic>?;
      if (answerData == null) {
        debugPrint('❌ No WebRTC answer found in call document - skipping answer handling');
        return;
      }

      // Set remote description (answer)
      debugPrint('📥 Setting remote description (answer)...');
      final answer = RTCSessionDescription(answerData['sdp'], answerData['type']);
      await _peerConnection!.setRemoteDescription(answer);

      await _firestore.collection('calls').doc(callId).update({
        'webrtc_state': 'connected',
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Answer handled successfully');
    } catch (e) {
      debugPrint('❌ Failed to handle answer: $e');
      debugPrint('⚠️ Answer handling failed but call can continue with Firebase signaling');
      // Don't throw - just log the error and continue
    }
  }

  /// Send ICE candidate
  static Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    try {
      if (_currentCallId == null) return;

      await _firestore.collection('calls').doc(_currentCallId!).collection('ice_candidates').add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': _auth.currentUser?.uid,
      });

      debugPrint('🧊 ICE candidate sent');
    } catch (e) {
      debugPrint('❌ Failed to send ICE candidate: $e');
    }
  }

  /// Start listening for ICE candidates
  static void _startIceCandidateListener(String callId) {
    _iceCandidateListener?.cancel();
    
    debugPrint('👂 Starting ICE candidate listener for call: $callId');
    
    _iceCandidateListener = _firestore
        .collection('calls')
        .doc(callId)
        .collection('ice_candidates')
        .snapshots()
        .listen((snapshot) {
      debugPrint('🧊 ICE candidates snapshot received - ${snapshot.docs.length} total candidates');
      
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          
          // Don't process our own candidates
          if (data['sender'] == _auth.currentUser?.uid) {
            debugPrint('🧊 Skipping own ICE candidate');
            continue;
          }
          
          debugPrint('🧊 New remote ICE candidate received');
          
          if (_peerConnection != null) {
            try {
              final candidate = RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              );
              
              _peerConnection?.addCandidate(candidate);
              debugPrint('🧊 ✅ Added remote ICE candidate successfully');
            } catch (e) {
              debugPrint('🧊 ❌ Failed to add ICE candidate: $e');
            }
          } else {
            debugPrint('⚠️ No peer connection available to add ICE candidate');
          }
        }
      }
    }, onError: (error) {
      debugPrint('❌ ICE candidate listener error: $error');
    });
  }

  /// Toggle microphone mute
  static Future<void> toggleMute() async {
    if (_localStream != null) {
      _isMuted = !_isMuted;
      final audioTracks = _localStream!.getAudioTracks();
      for (var track in audioTracks) {
        track.enabled = !_isMuted;
      }
      debugPrint('🎤 Microphone ${_isMuted ? 'muted' : 'unmuted'}');
    }
  }

  /// Toggle video
  static Future<void> toggleVideo() async {
    if (_localStream != null) {
      _isVideoEnabled = !_isVideoEnabled;
      final videoTracks = _localStream!.getVideoTracks();
      for (var track in videoTracks) {
        track.enabled = _isVideoEnabled;
      }
      debugPrint('🎥 Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
    }
  }

  /// End call and cleanup
  static Future<void> endCall() async {
    try {
      debugPrint('📞 Ending WebRTC call...');
      
      // Stop ICE candidate listener
      _iceCandidateListener?.cancel();
      _iceCandidateListener = null;
      
      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;
      
      // Stop local stream tracks
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          await track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }
      
      // Clear remote stream
      if (_remoteStream != null) {
        await _remoteStream!.dispose();
        _remoteStream = null;
      }
      
      // Reset states
      _isMuted = false;
      _isVideoEnabled = true;
      _currentCallId = null;
      _isOfferer = false;
      
      debugPrint('✅ WebRTC call ended and resources cleaned up');
    } catch (e) {
      debugPrint('❌ Error ending WebRTC call: $e');
    }
  }

  /// Get local stream
  static MediaStream? get localStream => _localStream;
  
  /// Get remote stream
  static MediaStream? get remoteStream => _remoteStream;
  
  /// Check if muted
  static bool get isMuted => _isMuted;
  
  /// Check if video enabled
  static bool get isVideoEnabled => _isVideoEnabled;
  
  /// Dispose of the service
  static void dispose() {
    endCall();
    _remoteStreamController.close();
    _callStateController.close();
  }
}
