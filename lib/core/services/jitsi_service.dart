import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'firebase_service.dart';

class JitsiService {
  static final JitsiMeet _jitsiMeetPlugin = JitsiMeet();
  static bool _isInitialized = false;
  
  // Your Jitsi API key
  static const String _jitsiApiKey = "vpaas-magic-cookie-6289be79c41e4a4d87ca772f42c0da4b";

  // Initialize Jitsi Meet
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure Jitsi Meet settings with your API
      var options = JitsiMeetConferenceOptions(
        serverURL: "https://8x8.vc", // Use 8x8 server for your API key
        room: "",
        token: _jitsiApiKey, // Use your API key as token
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": "SEWS Connect Meeting",
          "requireDisplayName": true,
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: FirebaseService.currentUser?.displayName ?? "SEWS User",
          email: FirebaseService.currentUser?.email ?? "",
        ),
      );

      _isInitialized = true;
      debugPrint('✅ Jitsi Meet initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Jitsi Meet: $e');
    }
  }

  // Join a meeting with a specific room ID
  static Future<void> joinMeeting({
    required String roomId,
    String? displayName,
    String? email,
    bool audioMuted = false,
    bool videoMuted = false,
    String? subject,
  }) async {
    try {
      await initialize();

      var options = JitsiMeetConferenceOptions(
        serverURL: "https://8x8.vc", // Use 8x8 server for your API key
        room: roomId,
        token: _jitsiApiKey, // Use your API key as token
        configOverrides: {
          "startWithAudioMuted": audioMuted,
          "startWithVideoMuted": videoMuted,
          "subject": subject ?? "SEWS Connect Meeting",
          "requireDisplayName": true,
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "toolbox.alwaysVisible": true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: displayName ?? FirebaseService.currentUser?.displayName ?? "SEWS User",
          email: email ?? FirebaseService.currentUser?.email ?? "",
        ),
      );

      // Add event listeners
      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint("✅ Conference joined: $url");
        },
        conferenceTerminated: (url, error) {
          debugPrint("❌ Conference terminated: $url, error: $error");
        },
        conferenceWillJoin: (url) {
          debugPrint("🔄 Conference will join: $url");
        },
        participantJoined: (email, name, role, participantId) {
          debugPrint("👥 Participant joined: $name ($email)");
        },
        participantLeft: (participantId) {
          debugPrint("👋 Participant left: $participantId");
        },
        audioMutedChanged: (muted) {
          debugPrint("🔊 Audio muted changed: $muted");
        },
        videoMutedChanged: (muted) {
          debugPrint("📹 Video muted changed: $muted");
        },
        endpointTextMessageReceived: (senderId, message) {
          debugPrint("💬 Message received from $senderId: $message");
        },
        screenShareToggled: (participantId, sharing) {
          debugPrint("📺 Screen share toggled by $participantId: $sharing");
        },
        chatMessageReceived: (senderId, message, isPrivate, timestamp) {
          debugPrint("💬 Chat message from $senderId: $message");
        },
        chatToggled: (isOpen) {
          debugPrint("💬 Chat toggled: $isOpen");
        },
      );

      await _jitsiMeetPlugin.join(options, listener);
      debugPrint('✅ Successfully joined Jitsi meeting: $roomId');
    } catch (e) {
      debugPrint('❌ Error joining Jitsi meeting: $e');
      rethrow;
    }
  }

  // Create a new meeting room
  static Future<String> createMeeting({
    required String meetingTitle,
    String? organizerName,
    String? organizerEmail,
  }) async {
    try {
      // Generate a unique room ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final roomId = 'sews-${timestamp}';
      
      debugPrint('✅ Created Jitsi meeting room: $roomId');
      return roomId;
    } catch (e) {
      debugPrint('❌ Error creating Jitsi meeting: $e');
      rethrow;
    }
  }

  // Start an instant meeting
  static Future<String> startInstantMeeting({
    required String organizerName,
    String? organizerEmail,
  }) async {
    final roomId = await createMeeting(
      meetingTitle: 'Instant Meeting',
      organizerName: organizerName,
      organizerEmail: organizerEmail,
    );
    
    await joinMeeting(
      roomId: roomId,
      displayName: organizerName,
      email: organizerEmail,
      subject: 'SEWS Connect - Instant Meeting',
    );
    
    return roomId;
  }

  // Hang up/leave current meeting
  static Future<void> hangUp() async {
    try {
      await _jitsiMeetPlugin.hangUp();
      debugPrint('✅ Successfully left Jitsi meeting');
    } catch (e) {
      debugPrint('❌ Error leaving Jitsi meeting: $e');
    }
  }

  // Set audio muted state
  static Future<void> setAudioMuted(bool muted) async {
    try {
      await _jitsiMeetPlugin.setAudioMuted(muted);
      debugPrint('✅ Audio muted set to: $muted');
    } catch (e) {
      debugPrint('❌ Error setting audio muted: $e');
    }
  }

  // Set video muted state
  static Future<void> setVideoMuted(bool muted) async {
    try {
      await _jitsiMeetPlugin.setVideoMuted(muted);
      debugPrint('✅ Video muted set to: $muted');
    } catch (e) {
      debugPrint('❌ Error setting video muted: $e');
    }
  }

  // Send chat message
  static Future<void> sendChatMessage({
    required String message,
    String? to,
  }) async {
    try {
      await _jitsiMeetPlugin.sendChatMessage(message: message, to: to);
      debugPrint('✅ Chat message sent: $message');
    } catch (e) {
      debugPrint('❌ Error sending chat message: $e');
    }
  }

  // Toggle camera (not available in current version)
  static Future<void> toggleCamera() async {
    try {
      // Note: toggleCamera method is not available in the current version
      // Users can use the Jitsi UI controls to switch cameras
      debugPrint('✅ Camera toggle should be handled by Jitsi UI');
    } catch (e) {
      debugPrint('❌ Error toggling camera: $e');
    }
  }

  // Toggle screen share
  static Future<void> toggleScreenShare() async {
    try {
      // Note: Screen share toggle API may vary by version
      // Users can use the Jitsi UI controls for screen sharing
      debugPrint('✅ Screen share should be handled by Jitsi UI');
    } catch (e) {
      debugPrint('❌ Error toggling screen share: $e');
    }
  }

  // Get meeting URL for sharing
  static String getMeetingUrl(String roomId) {
    return 'https://meet.jit.si/$roomId';
  }

  // Generate a user-friendly meeting ID
  static String generateFriendlyMeetingId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'SEWS-$random';
  }
}
