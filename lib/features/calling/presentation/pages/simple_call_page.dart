import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import '../../../../core/services/call_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/video_call_service.dart';
import '../../../../core/services/media_service.dart';

class SimpleCallPage extends StatefulWidget {
  final String callId;
  final String callType;
  final String? callerName;
  final bool isIncoming;

  const SimpleCallPage({
    super.key,
    required this.callId,
    required this.callType,
    this.callerName,
    required this.isIncoming,
  });

  @override
  State<SimpleCallPage> createState() => _SimpleCallPageState();
}

class _SimpleCallPageState extends State<SimpleCallPage> {
  bool _isMuted = false;
  bool _isVideoOn = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;
  DateTime? _callStartTime;
  Timer? _timer;
  
  // WebRTC video renderers
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  RTCVideoRenderer? _remoteAudioRenderer; // For audio-only remote stream
  
  // Stream subscriptions
  StreamSubscription? _remoteStreamSubscription;
  StreamSubscription? _callStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _initializeCall();
  }

  Future<void> _initializeRenderers() async {
    try {
      // Initialize video renderers
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
      _remoteAudioRenderer = RTCVideoRenderer(); // Also handles audio-only streams
      
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
      await _remoteAudioRenderer!.initialize();
      
      debugPrint('✅ Video renderers initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize video renderers: $e');
      // Don't throw - allow call to continue without video renderers for audio-only calls
      debugPrint('⚠️ Continuing without video renderers - audio calls should still work');
    }
  }

  Future<void> _initializeCall() async {
    try {
      _callStartTime = DateTime.now();
      
      debugPrint('🔧 Starting call initialization...');
      
      // Initialize media service
      debugPrint('🔧 Initializing media service...');
      await MediaService.initialize();
      debugPrint('✅ Media service initialized');
      
      if (widget.isIncoming) {
        debugPrint('📞 This is an incoming call - accepting...');
        // For incoming calls, the acceptance is handled by the call service
        await CallService.acceptCall(
          callId: widget.callId,
          roomId: widget.callId,
          callType: widget.callType,
          callerName: widget.callerName,
        );
        debugPrint('✅ Incoming call accepted');
      } else {
        debugPrint('📞 This is an outgoing call - already initiated');
      }
      
      setState(() {
        _isVideoOn = widget.callType == 'video';
      });

      debugPrint('🔧 Setting up WebRTC listeners...');
      // Set up WebRTC stream listeners
      _setupWebRTCListeners();
      
      debugPrint('🔧 Updating states from service...');
      // Get initial states from VideoCallService
      _updateStatesFromService();

      // Simulate connection establishment (WebRTC will update this when actually connected)
      await Future.delayed(const Duration(seconds: 2));
      
      // If still not connected after reasonable time, consider it connected for Firebase signaling
      if (!_isConnected) {
        debugPrint('⚠️ WebRTC not connected after 2s, assuming Firebase signaling mode');
        setState(() {
          _isConnected = true;
        });
      }

      // Start the call timer
      _startTimer();
      
    } catch (e) {
      debugPrint('❌ Error initializing call: $e');
      // Show the actual error instead of a generic message
      _showErrorAndExit('Call setup failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  void _setupWebRTCListeners() {
    // Listen for remote stream
    _remoteStreamSubscription = VideoCallService.remoteStreamStream.listen((stream) {
      debugPrint('📺 Received remote stream');
      
      // Set remote stream only if renderers are properly initialized
      try {
        if (_remoteRenderer != null) {
          _remoteRenderer!.srcObject = stream;
        }
        if (_remoteAudioRenderer != null) {
          _remoteAudioRenderer!.srcObject = stream;
          debugPrint('🔊 Remote audio stream set to audio renderer');
        }
      } catch (e) {
        debugPrint('❌ Error setting remote stream: $e');
      }
      
      setState(() {});
    });

    // Listen for call state changes
    _callStateSubscription = VideoCallService.callStateStream.listen((state) {
      debugPrint('🔗 WebRTC call state: $state');
      if (state.contains('Connected') || state.contains('connected') || 
          state.contains('RTCPeerConnectionStateConnected')) {
        setState(() {
          _isConnected = true;
        });
      }
    });
  }

  void _updateStatesFromService() {
    // Get local stream and set it to renderer
    final localStream = VideoCallService.localStream;
    if (localStream != null && _localRenderer != null) {
      try {
        _localRenderer!.srcObject = localStream;
        setState(() {});
      } catch (e) {
        debugPrint('❌ Error setting local stream: $e');
      }
    }
    
    // Update mute and video states
    setState(() {
      _isMuted = VideoCallService.isMuted;
      _isVideoOn = VideoCallService.isVideoEnabled;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild and update the timer display
        });
      }
    });
  }

  void _requestWebMediaPermissions() async {
    try {
      if (kIsWeb) {
        // Request camera and microphone permissions for web
        final constraints = {
          'video': widget.callType == 'video',
          'audio': true,
        };
        
        // This would typically use the browser's getUserMedia API
        debugPrint('📹 Requesting media permissions for web...');
      }
    } catch (e) {
      debugPrint('❌ Error requesting media permissions: $e');
    }
  }

  void _showErrorAndExit(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleMute() async {
    await VideoCallService.toggleMute();
    setState(() {
      _isMuted = VideoCallService.isMuted;
    });
  }

  void _toggleVideo() async {
    await VideoCallService.toggleVideo();
    setState(() {
      _isVideoOn = VideoCallService.isVideoEnabled;
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = CallService.toggleSpeaker();
    });
  }

  Future<void> _endCall() async {
    try {
      await CallService.endCall();
      
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error ending call: $e');
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  String _getCallDuration() {
    if (_callStartTime == null) return '00:00';
    
    final duration = DateTime.now().difference(_callStartTime!);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with call info
            _buildCallHeader(),
            
            // Video/Audio area
            Expanded(
              child: _isVideoOn ? _buildVideoArea() : _buildAudioArea(),
            ),
            
            // Call controls
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCallHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            widget.callerName ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected ? _getCallDuration() : 'Connecting...',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.callType == 'video' ? 'Video Call' : 'Audio Call',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.black87],
        ),
      ),
      child: Stack(
        children: [
          // Main video area - Remote participant stream
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black87,
            child: _remoteRenderer != null && _remoteRenderer!.srcObject != null
                ? RTCVideoView(_remoteRenderer!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.white38,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Waiting for connection...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Local video preview (top right)
          if (_isVideoOn && _localRenderer != null)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _localRenderer!.srcObject != null
                      ? RTCVideoView(_localRenderer!, mirror: true)
                      : const Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: Colors.white54,
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioArea() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.black87],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 32),
            Icon(
              Icons.phone,
              size: 48,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Audio connected',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            onPressed: _toggleMute,
            isActive: !_isMuted,
            color: _isMuted ? Colors.red : Colors.white,
          ),
          
          // Video button (only for video calls)
          if (widget.callType == 'video')
            _buildControlButton(
              icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
              onPressed: _toggleVideo,
              isActive: _isVideoOn,
              color: _isVideoOn ? Colors.white : Colors.red,
            ),
          
          // Speaker button
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            onPressed: _toggleSpeaker,
            isActive: _isSpeakerOn,
            color: Colors.white,
          ),
          
          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            onPressed: _endCall,
            isActive: false,
            color: Colors.white,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
    required Color color,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor ?? (isActive ? Colors.white24 : Colors.red.withOpacity(0.2)),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white38 : Colors.red.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    
    // Clean up WebRTC renderers
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    _remoteAudioRenderer?.dispose();
    
    // Cancel stream subscriptions
    _remoteStreamSubscription?.cancel();
    _callStateSubscription?.cancel();
    
    super.dispose();
  }
}
