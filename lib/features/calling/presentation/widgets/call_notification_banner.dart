import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';

class CallNotificationBanner extends StatefulWidget {
  const CallNotificationBanner({super.key});

  @override
  State<CallNotificationBanner> createState() => _CallNotificationBannerState();
}

class _CallNotificationBannerState extends State<CallNotificationBanner> {
  bool _isVisible = false;
  String _message = '';
  Color _backgroundColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _listenForCallInvitations();
  }

  void _listenForCallInvitations() {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) return;

    FirebaseService.getCallInvitations(currentUser.uid).listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final invitation = snapshot.docs.first.data();
        final callerName = invitation['callerName'] ?? 'Unknown Caller';
        final callType = invitation['callType'] ?? 'audio';
        
        setState(() {
          _message = '📞 Incoming ${callType} call from $callerName';
          _backgroundColor = Colors.green;
          _isVisible = true;
        });
        
        // Auto hide after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _isVisible = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isVisible ? 60 : 0,
      child: Container(
        width: double.infinity,
        color: _backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.phone, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isVisible = false;
                });
              },
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
