import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/call_service.dart';
import '../../../calling/presentation/pages/active_call_page.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> with TickerProviderStateMixin {
  bool _isInMeeting = false;
  TabController? _tabController;
  
  final TextEditingController _meetingIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _selectedParticipants = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  List<Map<String, dynamic>> _scheduledMeetings = [];
  List<Map<String, dynamic>> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _meetingIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadData() async {
    try {
      // Load available users from Firebase for inviting to meetings
      final usersStream = FirebaseService.getUsers();
      final usersSnapshot = await usersStream.first;
      
      setState(() {
        _availableUsers = usersSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'uid': doc.id,
            'name': data['username'] ?? 'Unknown User',
            'department': data['department'] ?? 'Unknown',
            'role': data['role'] ?? 'Unknown',
            'email': data['email'] ?? '',
            'avatar': (data['username'] ?? 'U').substring(0, 1).toUpperCase(),
            'isOnline': data['isOnline'] ?? false,
          };
        }).toList();
      });

      // Load scheduled meetings from Firebase
      final meetingsSnapshot = await FirebaseFirestore.instance
          .collection('meetings')
          .where('participants', arrayContains: FirebaseService.currentUser?.uid)
          .get();
      
      setState(() {
        _scheduledMeetings = meetingsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled Meeting',
            'description': data['description'] ?? '',
            'date': (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'duration': data['duration'] ?? 30,
            'participants': List<String>.from(data['participants'] ?? []),
            'organizer': data['organizerName'] ?? 'Unknown',
            'status': data['status'] ?? 'scheduled',
            'meetingId': data['meetingId'] ?? doc.id,
            'type': data['type'] ?? 'video',
          };
        }).toList()
          ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      });
    } catch (e) {
      print('❌ Error loading meeting data: $e');
      // Fallback to empty lists if Firebase fails
      setState(() {
        _availableUsers = [];
        _scheduledMeetings = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: _isInMeeting
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.videocam), text: 'Join'),
                  Tab(icon: Icon(Icons.schedule), text: 'Scheduled'),
                  Tab(icon: Icon(Icons.add), text: 'Create'),
                ],
              ),
      ),
      body: _isInMeeting
          ? _buildInMeetingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJoinMeetingTab(),
                _buildScheduledMeetingsTab(),
                _buildCreateMeetingTab(),
              ],
            ),
    );
  }

  Widget _buildInMeetingView() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Video area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 120, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'Meeting in Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Connected',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Meeting controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMeetingControl(Icons.mic_off, 'Mute', Colors.red),
                _buildMeetingControl(Icons.videocam_off, 'Camera', Colors.grey),
                _buildMeetingControl(Icons.screen_share, 'Share', Colors.blue),
                _buildMeetingControl(Icons.call_end, 'End', Colors.red, () => _endMeeting()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingControl(IconData icon, String label, Color color, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildJoinMeetingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick join section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Join Meeting',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _meetingIdController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting ID',
                      hintText: 'Enter meeting ID or link',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _joinMeeting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Join Meeting'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Upcoming meetings
          const Text(
            'Upcoming Meetings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._scheduledMeetings.where((meeting) {
            final meetingDate = meeting['date'] as DateTime;
            return meetingDate.isAfter(DateTime.now()) && 
                   meetingDate.difference(DateTime.now()).inHours < 2;
          }).map((meeting) => _buildUpcomingMeetingCard(meeting)).toList(),
          
          if (_scheduledMeetings.where((meeting) {
            final meetingDate = meeting['date'] as DateTime;
            return meetingDate.isAfter(DateTime.now()) && 
                   meetingDate.difference(DateTime.now()).inHours < 2;
          }).isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming meetings',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMeetingCard(Map<String, dynamic> meeting) {
    final meetingDate = meeting['date'] as DateTime;
    final isToday = meetingDate.day == DateTime.now().day;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.videocam, color: Colors.white),
        ),
        title: Text(meeting['title'] ?? 'Unknown Meeting'),
        subtitle: Text(
          isToday
              ? 'Today at ${TimeOfDay.fromDateTime(meetingDate).format(context)}'
              : '${meetingDate.day}/${meetingDate.month} at ${TimeOfDay.fromDateTime(meetingDate).format(context)}',
        ),
        trailing: ElevatedButton(
          onPressed: () => _joinSpecificMeeting(meeting),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Join'),
        ),
      ),
    );
  }

  Widget _buildScheduledMeetingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scheduled Meetings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_scheduledMeetings.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No scheduled meetings',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a new meeting to get started',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ..._scheduledMeetings.map((meeting) => _buildScheduledMeetingCard(meeting)).toList(),
        ],
      ),
    );
  }

  Widget _buildScheduledMeetingCard(Map<String, dynamic> meeting) {
    final meetingDate = meeting['date'] as DateTime;
    final isToday = meetingDate.day == DateTime.now().day;
    final isPast = meetingDate.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meeting['title'] ?? 'Unknown Meeting',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPast ? Colors.grey : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPast ? 'Past' : 'Scheduled',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (meeting['description']?.isNotEmpty == true)
              Text(
                meeting['description'],
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  isToday
                      ? 'Today at ${TimeOfDay.fromDateTime(meetingDate).format(context)}'
                      : '${meetingDate.day}/${meetingDate.month} at ${TimeOfDay.fromDateTime(meetingDate).format(context)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${meeting['participants']?.length ?? 0} participants',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showMeetingDetails(meeting),
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isPast)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _joinSpecificMeeting(meeting),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Join'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateMeetingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Meeting',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Meeting title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Meeting Title *',
              hintText: 'Enter meeting title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Meeting description
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter meeting description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Date and time selection
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Participants selection
          const Text(
            'Select Participants',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _availableUsers.length,
              itemBuilder: (context, index) {
                final user = _availableUsers[index];
                final isSelected = _selectedParticipants.contains(user['uid']);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedParticipants.add(user['uid']);
                      } else {
                        _selectedParticipants.remove(user['uid']);
                      }
                    });
                  },
                  title: Text(user['name'] ?? 'Unknown User'),
                  subtitle: Text('${user['department']} • ${user['role']}'),
                  secondary: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      user['avatar'] ?? 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Create meeting button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createMeeting,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create Meeting', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _joinMeeting() async {
    final meetingId = _meetingIdController.text.trim();
    if (meetingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting ID')),
      );
      return;
    }
    
    try {
      // Navigate to active call page with meeting channel
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ActiveCallPage(
            channelId: meetingId,
            callType: 'video', // Meetings are video by default
            calleeName: 'Meeting',
            isIncoming: false,
          ),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joining meeting: $meetingId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join meeting: $e')),
      );
    }
  }

  void _joinSpecificMeeting(Map<String, dynamic> meeting) async {
    try {
      final meetingId = meeting['meetingId'] ?? meeting['id'];
      final meetingTitle = meeting['title'] ?? 'Meeting';
      
      // Navigate to active call page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ActiveCallPage(
            channelId: meetingId,
            callType: 'video', // Meetings are video by default
            calleeName: meetingTitle,
            isIncoming: false,
          ),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joining meeting: $meetingTitle')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join meeting: $e')),
      );
    }
  }

  void _endMeeting() {
    setState(() {
      _isInMeeting = false;
    });
  }

  void _showMeetingDetails(Map<String, dynamic> meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meeting['title'] ?? 'Meeting Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meeting['description']?.isNotEmpty == true) ...[
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(meeting['description']),
              const SizedBox(height: 12),
            ],
            const Text('Meeting ID:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(meeting['meetingId'] ?? 'Unknown'),
            const SizedBox(height: 12),
            const Text('Organizer:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(meeting['organizer'] ?? 'Unknown'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _quickJoin() {
    final meetingId = _meetingIdController.text.trim();
    if (meetingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting ID')),
      );
      return;
    }
    
    setState(() {
      _isInMeeting = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining meeting: $meetingId')),
    );
  }

  void _startInstantMeeting() {
    setState(() {
      _isInMeeting = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting instant meeting...')),
    );
    
    // Switch to Create tab for future meetings
    if (_tabController != null) {
      _tabController!.animateTo(2); // Switch to Create tab
    }
  }

  void _scheduleForLater() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening meeting scheduler...')),
    );
    
    // Switch to create meeting tab
    if (_tabController != null) {
      _tabController!.animateTo(2);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _createMeeting() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting title')),
      );
      return;
    }

    final meetingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Creating meeting...'),
          ],
        ),
      ),
    );

    try {
      // Create meeting in Firebase
      final meetingId = await FirebaseService.createMeeting(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: meetingDateTime,
        duration: 60, // Default duration
        participants: List.from(_selectedParticipants),
        type: 'video', // Default type
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (meetingId != null) {
        // Refresh the meetings list
        _loadData();
        
        // Clear form
        setState(() {
          _titleController.clear();
          _descriptionController.clear();
          _selectedParticipants.clear();
          _selectedDate = DateTime.now();
          _selectedTime = TimeOfDay.now();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Meeting "${_titleController.text}" created successfully!')),
          );

          // Switch to scheduled meetings tab
          if (_tabController != null) {
            _tabController!.animateTo(1);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create meeting. Please try again.')),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating meeting: $e')),
        );
      }
      print('❌ Error in _createMeeting: $e');
    }
  }
}
