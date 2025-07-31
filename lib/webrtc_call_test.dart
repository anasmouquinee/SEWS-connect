import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/services/call_service_new.dart';
import '../core/services/real_webrtc_service.dart';
import '../core/services/firebase_service.dart';

class WebRTCCallTestScreen extends StatefulWidget {
  const WebRTCCallTestScreen({super.key});

  @override
  State<WebRTCCallTestScreen> createState() => _WebRTCCallTestScreenState();
}

class _WebRTCCallTestScreenState extends State<WebRTCCallTestScreen> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isInitialized = false;
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isVideoOn = false;
  String _status = 'Not initialized';
  String? _currentCallId;
  
  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      
      // Initialize WebRTC service
      await CallService.initialize();
      
      // Listen to WebRTC streams
      RealWebRTCService.remoteStreamStream.listen((stream) {
        debugPrint('📺 Remote stream received');
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      });
      
      RealWebRTCService.callStateStream.listen((state) {
        debugPrint('📞 Call state: $state');
        setState(() {
          _status = state;
          _isInCall = state.contains('connected') || state.contains('stable');
        });
      });
      
      setState(() {
        _isInitialized = true;
        _status = 'WebRTC initialized - Ready for calls';
      });
      
      debugPrint('✅ WebRTC Call Test initialized');
    } catch (e) {
      debugPrint('❌ Error initializing WebRTC: $e');
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC Call Test'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isInitialized ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isInitialized ? Colors.green : Colors.orange,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _isInitialized ? Icons.check_circle : Icons.warning,
                  color: _isInitialized ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'WebRTC Status',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                if (_currentCallId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Call ID: $_currentCallId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Video Views
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Remote Video (Other person)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: RTCVideoView(
                          _remoteRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          placeholderBuilder: (context) => Container(
                            color: Colors.black,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.videocam_off,
                                    color: Colors.white,
                                    size: 64,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Remote Video',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Local Video (You)
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: RTCVideoView(
                          _localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          placeholderBuilder: (context) => Container(
                            color: Colors.black,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.videocam_off,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Your Video',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Control Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Test Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isInitialized && !_isInCall ? _startTestCall : null,
                        icon: const Icon(Icons.call),
                        label: const Text('Start Test Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isInitialized && !_isInCall ? _startVideoCall : null,
                        icon: const Icon(Icons.videocam),
                        label: const Text('Start Video Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Call Control Buttons
                if (_isInCall) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute Button
                      FloatingActionButton(
                        onPressed: _toggleMute,
                        backgroundColor: _isMuted ? Colors.red : Colors.grey,
                        child: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                      
                      // Video Button
                      FloatingActionButton(
                        onPressed: _toggleVideo,
                        backgroundColor: _isVideoOn ? Colors.blue : Colors.grey,
                        child: Icon(
                          _isVideoOn ? Icons.videocam : Icons.videocam_off,
                          color: Colors.white,
                        ),
                      ),
                      
                      // End Call Button
                      FloatingActionButton(
                        onPressed: _endCall,
                        backgroundColor: Colors.red,
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                        ),
                      ),
                      
                      // Switch Camera Button
                      FloatingActionButton(
                        onPressed: _switchCamera,
                        backgroundColor: Colors.orange,
                        child: const Icon(
                          Icons.switch_camera,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // System Test Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isInitialized ? _testMediaAccess : null,
                      icon: const Icon(Icons.science),
                      label: const Text('Test Camera & Microphone'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTestCall() async {
    try {
      setState(() {
        _status = 'Starting audio call...';
      });
      
      // Simulate calling another user
      final callId = await CallService.startCall(
        calleeId: 'test_user_123',
        calleeName: 'Test User',
        callType: 'audio',
      );
      
      setState(() {
        _currentCallId = callId;
        _isInCall = true;
        _status = 'Audio call started';
      });
      
    } catch (e) {
      setState(() {
        _status = 'Error starting call: $e';
      });
    }
  }

  Future<void> _startVideoCall() async {
    try {
      setState(() {
        _status = 'Starting video call...';
      });
      
      // Simulate calling another user
      final callId = await CallService.startCall(
        calleeId: 'test_user_123',
        calleeName: 'Test User',
        callType: 'video',
      );
      
      setState(() {
        _currentCallId = callId;
        _isInCall = true;
        _isVideoOn = true;
        _status = 'Video call started';
      });
      
    } catch (e) {
      setState(() {
        _status = 'Error starting video call: $e';
      });
    }
  }

  Future<void> _testMediaAccess() async {
    try {
      setState(() {
        _status = 'Testing camera and microphone...';
      });
      
      // Test getting user media
      final stream = await RealWebRTCService.getUserMedia(audio: true, video: true);
      
      if (stream != null) {
        setState(() {
          _localRenderer.srcObject = stream;
          _status = '✅ Camera and microphone working!';
        });
        
        // Stop the test stream after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          stream.dispose();
          setState(() {
            _localRenderer.srcObject = null;
            _status = 'Media test completed - Ready for calls';
          });
        });
      } else {
        setState(() {
          _status = '❌ Failed to access camera/microphone';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Media test error: $e';
      });
    }
  }

  Future<void> _toggleMute() async {
    await CallService.toggleMute();
    setState(() {
      _isMuted = CallService.isMuted;
    });
  }

  Future<void> _toggleVideo() async {
    await CallService.toggleVideo();
    setState(() {
      _isVideoOn = CallService.isVideoOn;
    });
  }

  Future<void> _switchCamera() async {
    await CallService.toggleCamera();
  }

  Future<void> _endCall() async {
    await CallService.endCall();
    setState(() {
      _isInCall = false;
      _isMuted = false;
      _isVideoOn = false;
      _currentCallId = null;
      _status = 'Call ended - Ready for new calls';
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    });
  }
}
