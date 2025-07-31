import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/call_service.dart';
import '../pages/active_call_page.dart';

class CallInvitationDialog extends StatelessWidget {
  final Map<String, dynamic> invitation;
  final String invitationId;

  const CallInvitationDialog({
    super.key,
    required this.invitation,
    required this.invitationId,
  });

  @override
  Widget build(BuildContext context) {
    final callerName = invitation['callerName'] ?? 'Unknown Caller';
    final callType = invitation['callType'] ?? 'audio';
    final isVideo = callType == 'video';

    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Caller avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue[700],
            child: Text(
              callerName.isNotEmpty ? callerName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Caller name
          Text(
            callerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Call type
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isVideo ? Icons.videocam : Icons.phone,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Decline button
              GestureDetector(
                onTap: () => _declineCall(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              
              // Accept button
              GestureDetector(
                onTap: () => _acceptCall(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVideo ? Icons.videocam : Icons.phone,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _acceptCall(BuildContext context) async {
    try {
      // Get call ID from invitation
      final callId = invitation['callId'] ?? invitationId;
      final callType = invitation['callType'] ?? 'audio';
      final callerName = invitation['callerName'] ?? 'Unknown Caller';
      
      // Accept call using call service
      await CallService.acceptCall(
        callId: callId,
        roomId: callId, // Use callId as roomId
        callType: callType,
        callerName: callerName,
      );
      
      // Update invitation status to accepted
      await FirebaseService.respondToCallInvitation(
        invitationId: invitationId,
        response: 'accepted',
      );

      // Navigate to call page
      if (context.mounted) {
        await CallService.navigateToCallPage(
          context,
          callId: callId,
          callType: callType,
          callerName: callerName,
          isIncoming: true,
        );
      }
      
      // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept call: $e')),
        );
      }
    }
  }

  void _declineCall(BuildContext context) async {
    try {
      // Get call ID from invitation
      final callId = invitation['callId'] ?? invitationId;
      
      // Decline call using call service
      await CallService.declineCall(callId);
      
      // Update invitation status to declined
      await FirebaseService.respondToCallInvitation(
        invitationId: invitationId,
        response: 'declined',
      );
      
      // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error declining call: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class CallInvitationListener extends StatefulWidget {
  final Widget child;

  const CallInvitationListener({
    super.key,
    required this.child,
  });

  @override
  State<CallInvitationListener> createState() => _CallInvitationListenerState();
}

class _CallInvitationListenerState extends State<CallInvitationListener> {
  Set<String> _shownInvitations = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseService.currentUser;
    
    if (currentUser == null) {
      return widget.child;
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.getCallInvitations(currentUser.uid),
      builder: (context, snapshot) {
        debugPrint('📱 Call invitation listener: uid=${currentUser.uid}, hasData=${snapshot.hasData}, docs=${snapshot.data?.docs.length ?? 0}');
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          debugPrint('📞 Found ${snapshot.data!.docs.length} call invitations');
          // Find new invitations that haven't been shown
          for (final invitation in snapshot.data!.docs) {
            final invitationId = invitation.id;
            final invitationData = invitation.data();
            
            debugPrint('📞 Processing invitation: $invitationId, data: $invitationData');
            
            // Only show if we haven't shown this invitation yet
            if (!_shownInvitations.contains(invitationId)) {
              _shownInvitations.add(invitationId);
              
              debugPrint('📞 Showing new call invitation dialog');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Check if context is valid and has Navigator
                if (mounted && context.mounted && Navigator.canPop(context) || ModalRoute.of(context) != null) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => CallInvitationDialog(
                      invitation: invitationData,
                      invitationId: invitationId,
                    ),
                  ).then((_) {
                    // Remove from shown list when dialog is closed
                    _shownInvitations.remove(invitationId);
                  });
                } else {
                  debugPrint('⚠️ Cannot show dialog - invalid Navigator context');
                  _shownInvitations.remove(invitationId); // Remove so it can be tried again
                }
              });
              break; // Only show one at a time
            }
          }
        }
        
        return widget.child;
      },
    );
  }
}
