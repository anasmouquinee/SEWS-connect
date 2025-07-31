import 'package:flutter/material.dart';
import '../../../../core/services/call_service.dart';
import '../../../../core/services/firebase_service.dart';

class ActiveCallPage extends StatefulWidget {
  final String channelId;
  final String callType;
  final String calleeName;
  final bool isIncoming;

  const ActiveCallPage({
    super.key,
    required this.channelId,
    required this.callType,
    required this.calleeName,
    this.isIncoming = false,
  });

  @override
  State<ActiveCallPage> createState() => _ActiveCallPageState();
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isVideoOn = false;
  bool _isSpeakerOn = false;
  Duration _callDuration = Duration.zero;
  late DateTime _callStartTime;

  @override
  void initState() {
    super.initState();
    _initializeCall();
    _startCallTimer();
  }

  void _initializeCall() async {
    try {
      _callStartTime = DateTime.now();
      
      // For Jitsi calls, the room joining will be handled by the CallService
      // when the call is accepted in the acceptance widget
      
      if (mounted) {
        setState(() {
          _isVideoOn = widget.callType == 'video';
          _isMuted = false;
          _isSpeakerOn = false;
          _isConnected = true; // Jitsi handles connection automatically
        });
      }
      
    } catch (e) {
      print('❌ Error initializing call: $e');
      // Delay showing error until widget is fully mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _endCall();
        }
      });
    }
  }

  void _startCallTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _callDuration = DateTime.now().difference(_callStartTime);
        });
        _startCallTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  void dispose() {
    // Jitsi handles cleanup automatically
    super.dispose();
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
            widget.calleeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected ? _formatDuration(_callDuration) : 'Connecting...',
            style: TextStyle(
              color: _isConnected ? Colors.green : Colors.orange,
              fontSize: 16,
            ),
          ),
          if (!_isConnected && !widget.isIncoming)
            const Text(
              'Calling...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    return Stack(
      children: [
        // Remote video (full screen) - For web, we'll show avatar placeholder
        _buildAvatarPlaceholder(),
        
        // Local video (small overlay)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildLocalAvatarPlaceholder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.blue[700],
            child: Text(
              widget.calleeName.isNotEmpty 
                ? widget.calleeName[0].toUpperCase()
                : 'U',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.calleeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected ? 'Audio Call' : 'Connecting...',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.blue[700],
              child: Text(
                widget.calleeName.isNotEmpty 
                  ? widget.calleeName[0].toUpperCase()
                  : 'U',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera is off',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalAvatarPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.white54,
          size: 40,
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
            isActive: !_isMuted,
            color: _isMuted ? Colors.red : Colors.grey[700]!,
            onTap: _toggleMute,
          ),
          
          // Speaker button (audio calls only)
          if (widget.callType == 'audio')
            _buildControlButton(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              isActive: _isSpeakerOn,
              color: _isSpeakerOn ? Colors.blue : Colors.grey[700]!,
              onTap: _toggleSpeaker,
            ),
          
          // Video button (video calls only)
          if (widget.callType == 'video')
            _buildControlButton(
              icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
              isActive: _isVideoOn,
              color: _isVideoOn ? Colors.blue : Colors.red,
              onTap: _toggleVideo,
            ),
          
          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            isActive: false,
            color: Colors.red,
            onTap: _endCall,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      // Jitsi handles mute/unmute through its UI
    });
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOn = !_isVideoOn;
      // Jitsi handles video toggle through its UI
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      // Jitsi handles speaker toggle through its UI
    });
  }

  void _endCall() async {
    try {
      // Log call completion
      final duration = _callDuration.inSeconds;
      final currentUser = FirebaseService.currentUser;
      
      if (currentUser != null) {
        await FirebaseService.logCall(
          calleeId: 'unknown', // You should track this properly
          calleeName: widget.calleeName,
          type: widget.callType,
          status: duration > 0 ? 'completed' : 'missed',
          duration: duration,
        );
      }
      
      await CallService.declineCall(widget.channelId);
      
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error ending call: $e');
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}
