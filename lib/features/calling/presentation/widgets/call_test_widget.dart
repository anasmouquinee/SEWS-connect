import 'package:flutter/material.dart';
import '../../../../core/services/firebase_service.dart';

class CallTestWidget extends StatefulWidget {
  const CallTestWidget({super.key});

  @override
  State<CallTestWidget> createState() => _CallTestWidgetState();
}

class _CallTestWidgetState extends State<CallTestWidget> {
  final TextEditingController _testUserController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Call Test Mode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Test call invitations between users:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _testUserController,
            decoration: const InputDecoration(
              labelText: 'Test User Email',
              hintText: 'Enter email to test call invitation',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _sendTestCall('audio'),
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('Test Audio Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _sendTestCall('video'),
                icon: const Icon(Icons.videocam, size: 16),
                label: const Text('Test Video Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendTestCall(String callType) async {
    final testEmail = _testUserController.text.trim();
    if (testEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a test user email')),
      );
      return;
    }

    try {
      // Find user by email (simplified for testing)
      final usersSnapshot = await FirebaseService.getUsers().first;
      final testUser = usersSnapshot.docs.firstWhere(
        (doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['email'] == testEmail;
        },
        orElse: () => throw Exception('User not found'),
      );

      final userData = testUser.data() as Map<String, dynamic>;
      
      // Send test call invitation
      await FirebaseService.sendCallInvitation(
        callerId: FirebaseService.currentUser!.uid,
        callerName: FirebaseService.currentUser!.displayName ?? 'Test Caller',
        calleeId: testUser.id,
        calleeName: userData['username'] ?? 'Test User',
        channelId: 'test_call_${DateTime.now().millisecondsSinceEpoch}',
        callType: callType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Test $callType call sent to $testEmail'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to send test call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _testUserController.dispose();
    super.dispose();
  }
}
