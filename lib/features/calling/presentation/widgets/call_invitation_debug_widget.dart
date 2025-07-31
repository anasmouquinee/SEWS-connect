import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/firebase_service.dart';

class CallInvitationDebugWidget extends StatefulWidget {
  const CallInvitationDebugWidget({super.key});

  @override
  State<CallInvitationDebugWidget> createState() => _CallInvitationDebugWidgetState();
}

class _CallInvitationDebugWidgetState extends State<CallInvitationDebugWidget> {
  final _emailController = TextEditingController();
  String _debugOutput = '';
  bool _isListening = false;
  late StreamSubscription _invitationSubscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _invitationSubscription.cancel();
    super.dispose();
  }

  void _startListening() {
    final currentUser = FirebaseService.currentUser;
    if (currentUser != null && !_isListening) {
      if (mounted) {
        setState(() {
          _isListening = true;
          _debugOutput += '\n🎧 Started listening for call invitations for ${currentUser.email}';
        });
      }
      
      _invitationSubscription = FirebaseService.getCallInvitations(currentUser.uid).listen(
        (snapshot) {
          if (mounted && snapshot.docs.isNotEmpty) {
            setState(() {
              _debugOutput += '\n📞 Received ${snapshot.docs.length} call invitation(s):';
              for (var doc in snapshot.docs) {
                final data = doc.data();
                _debugOutput += '\n  - From: ${data['callerName']} (${data['callType']})';
                _debugOutput += '\n    Status: ${data['status']}';
                _debugOutput += '\n    Channel: ${data['channelId']}';
                _debugOutput += '\n    Time: ${data['timestamp']?.toDate() ?? 'N/A'}';
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _debugOutput += '\n❌ Error listening for invitations: $error';
            });
          }
        },
      );
    }
  }

  Future<void> _sendTestCall() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _debugOutput += '\n❌ Please enter an email address';
      });
      return;
    }

    try {
      setState(() {
        _debugOutput += '\n📤 Searching for user with email: $email';
      });

      // Search for user by email
      final userQuery = await FirebaseService.getUserByEmail(email);
      if (userQuery.docs.isEmpty) {
        setState(() {
          _debugOutput += '\n❌ No user found with email: $email';
        });
        return;
      }

      final userData = userQuery.docs.first.data() as Map<String, dynamic>;
      final userId = userQuery.docs.first.id;
      final userName = userData['username'] ?? 'Unknown User';

      setState(() {
        _debugOutput += '\n✅ Found user: $userName ($userId)';
        _debugOutput += '\n📞 Sending test call invitation...';
      });

      // Send call invitation
      final currentUser = FirebaseService.currentUser;
      if (currentUser != null) {
        await FirebaseService.sendCallInvitation(
          callerId: currentUser.uid,
          callerName: currentUser.displayName ?? currentUser.email ?? 'Test Caller',
          calleeId: userId,
          calleeName: userName,
          channelId: 'test_call_${DateTime.now().millisecondsSinceEpoch}',
          callType: 'audio',
        );

        setState(() {
          _debugOutput += '\n✅ Test call invitation sent successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _debugOutput += '\n❌ Error sending test call: $e';
      });
    }
  }

  void _clearDebugOutput() {
    setState(() {
      _debugOutput = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Call Invitation Debug Tool',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isListening ? 'LISTENING' : 'NOT LISTENING',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Test call section
            const Text(
              'Send Test Call Invitation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Email',
                      hintText: 'Enter email to send test call',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendTestCall,
                  child: const Text('Send Test Call'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Debug output section
            Row(
              children: [
                const Text(
                  'Debug Output:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearDebugOutput,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugOutput.isEmpty 
                      ? 'Debug output will appear here...' 
                      : _debugOutput,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              'Current User: ${FirebaseService.currentUser?.email ?? 'Not authenticated'}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
