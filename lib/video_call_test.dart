import 'package:flutter/material.dart';
import 'core/services/call_service_new.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  // Initialize Call Service
  await CallService.initialize();
  
  runApp(const VideoCallTestApp());
}

class VideoCallTestApp extends StatelessWidget {
  const VideoCallTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEWS Connect - Video Call Test',
      theme: ThemeData(
        primaryColor: const Color(0xFF1565C0),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
      ),
      home: const CallTestScreen(),
    );
  }
}

class CallTestScreen extends StatefulWidget {
  const CallTestScreen({super.key});

  @override
  State<CallTestScreen> createState() => _CallTestScreenState();
}

class _CallTestScreenState extends State<CallTestScreen> {
  bool _isTestingCall = false;
  String _callStatus = 'Ready to test';
  String? _currentRoomId;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    CallService.onCallEnded = () {
      setState(() {
        _callStatus = 'Call ended';
        _currentRoomId = null;
      });
    };

    CallService.onError = (error) {
      setState(() {
        _callStatus = 'Error: $error';
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEWS Connect - Call Test'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      CallService.isInCall ? Icons.video_call : Icons.phone,
                      size: 48,
                      color: CallService.isInCall ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Call System Status',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_callStatus),
                    if (_currentRoomId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Room ID: $_currentRoomId',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // System Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow('Firebase', FirebaseService.currentUser != null),
                    _buildStatusRow('Jitsi Service', true), // Assuming initialized
                    _buildStatusRow('Call Service', true),
                    _buildStatusRow('In Call', CallService.isInCall),
                    _buildStatusRow('Audio Muted', CallService.isMuted),
                    _buildStatusRow('Video On', CallService.isVideoOn),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            const Text(
              'Test Functions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Start Test Call
            ElevatedButton.icon(
              onPressed: _isTestingCall || CallService.isInCall ? null : _startTestCall,
              icon: _isTestingCall 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.video_call),
              label: Text(_isTestingCall ? 'Starting Call...' : 'Start Test Video Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Start Audio Call
            ElevatedButton.icon(
              onPressed: _isTestingCall || CallService.isInCall ? null : _startTestAudioCall,
              icon: const Icon(Icons.call),
              label: const Text('Start Test Audio Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Call Controls (only show when in call)
            if (CallService.isInCall) ...[
              const Text(
                'Call Controls',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleMute,
                      icon: Icon(CallService.isMuted ? Icons.mic_off : Icons.mic),
                      label: Text(CallService.isMuted ? 'Unmute' : 'Mute'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CallService.isMuted ? Colors.red : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleVideo,
                      icon: Icon(CallService.isVideoOn ? Icons.videocam : Icons.videocam_off),
                      label: Text(CallService.isVideoOn ? 'Video Off' : 'Video On'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CallService.isVideoOn ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _endCall,
                  icon: const Icon(Icons.call_end),
                  label: const Text('End Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
            
            const Spacer(),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Instructions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Click "Start Test Video Call" to test video calling\n'
                    '2. Click "Start Test Audio Call" to test audio only\n'
                    '3. The Jitsi Meet interface will open\n'
                    '4. Use call controls to test mute/video\n'
                    '5. Use "End Call" to terminate the call\n\n'
                    'Note: This creates a test room for you to verify the system works.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            status ? 'Ready' : 'Not Ready',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: status ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTestCall(String callType) async {
    setState(() {
      _isTestingCall = true;
      _callStatus = 'Starting $callType call...';
    });

    try {
      final roomId = await CallService.startCall(
        calleeId: 'test-user', // Test user ID
        calleeName: 'Test Call',
        callType: callType,
      );

      setState(() {
        _currentRoomId = roomId;
        _callStatus = 'Call started successfully! Room: $roomId';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$callType call started! Room: $roomId'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _callStatus = 'Error starting call: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTestingCall = false;
      });
    }
  }

  Future<void> _startTestVideoCall() async {
    await _startTestCall('video');
  }

  Future<void> _startTestAudioCall() async {
    await _startTestCall('audio');
  }

  Future<void> _toggleMute() async {
    await CallService.toggleMute();
    setState(() {});
  }

  Future<void> _toggleVideo() async {
    await CallService.toggleVideo();
    setState(() {});
  }

  Future<void> _endCall() async {
    await CallService.endCall();
    setState(() {
      _callStatus = 'Call ended';
      _currentRoomId = null;
    });
  }
}
