import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/call_service.dart';
import '../pages/active_call_page.dart';

class CallAcceptanceWidget extends StatefulWidget {
  const CallAcceptanceWidget({super.key});

  @override
  State<CallAcceptanceWidget> createState() => _CallAcceptanceWidgetState();
}

class _CallAcceptanceWidgetState extends State<CallAcceptanceWidget> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseService.currentUser;
    
    if (currentUser == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Please sign in to receive calls'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.call_received, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Incoming Call Monitor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Listening for incoming calls...',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Stream builder to show incoming calls
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.getCallInvitations(currentUser.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.phone_disabled, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('No incoming calls'),
                      ],
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final invitation = doc.data();
                    final invitationId = doc.id;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[700],
                            child: Text(
                              (invitation['callerName'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invitation['callerName'] ?? 'Unknown Caller',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Incoming ${invitation['callType']} call',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Decline button
                              IconButton(
                                onPressed: () => _declineCall(invitationId),
                                icon: const Icon(Icons.call_end),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Accept button
                              IconButton(
                                onPressed: () => _acceptCall(invitation, invitationId),
                                icon: Icon(
                                  invitation['callType'] == 'video' 
                                      ? Icons.videocam 
                                      : Icons.phone,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptCall(Map<String, dynamic> invitation, String invitationId) async {
    try {
      // Get call ID from invitation
      final callId = invitation['callId'] ?? invitationId;
      
      // Accept the call through CallService
      await CallService.acceptCall(
        callId: callId,
        roomId: callId, // Use callId as roomId
        callType: invitation['callType'] ?? 'video',
        callerName: invitation['callerName'],
      );
      
      // Update invitation status
      await FirebaseService.respondToCallInvitation(
        invitationId: invitationId,
        response: 'accepted',
      );
      
      // Navigate to call page
      if (mounted) {
        await CallService.navigateToCallPage(
          context,
          callId: callId,
          callType: invitation['callType'] ?? 'video',
          callerName: invitation['callerName'] ?? 'Unknown',
          isIncoming: true,
        );
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call accepted! Joining call...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineCall(String invitationId) async {
    try {
      // Decline the call through CallService
      await CallService.declineCall(invitationId);
      
      // Update invitation status
      await FirebaseService.respondToCallInvitation(
        invitationId: invitationId,
        response: 'declined',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call declined'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error declining call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
