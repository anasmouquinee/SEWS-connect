import 'package:flutter/material.dart';
import '../models/workstation_model.dart';
import '../services/workstation_storage_service.dart';
import 'workstation_details_screen.dart';

class WorkstationListScreen extends StatefulWidget {
  const WorkstationListScreen({super.key});

  @override
  State<WorkstationListScreen> createState() => _WorkstationListScreenState();
}

class _WorkstationListScreenState extends State<WorkstationListScreen> {
  List<WorkstationModel> _workstations = [];
  List<WorkstationModel> _filteredWorkstations = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = true;

  final List<String> _filterOptions = [
    'All',
    'Not Requested',
    'In Progress',
    'Finished',
    'Express Priority',
    'Normal Priority',
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkstations();
  }

  Future<void> _loadWorkstations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final workstations = WorkstationStorageService.getAllWorkstations();
      setState(() {
        _workstations = workstations;
        _filteredWorkstations = workstations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading workstations: $e');
    }
  }

  void _filterWorkstations() {
    List<WorkstationModel> filtered = _workstations;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((workstation) {
        return workstation.workStation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               workstation.project.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status/priority filter
    switch (_selectedFilter) {
      case 'Not Requested':
        filtered = filtered.where((w) => w.workstepProgress.toLowerCase() == 'not requested').toList();
        break;
      case 'In Progress':
        filtered = filtered.where((w) => w.workstepProgress.toLowerCase() == 'in progress').toList();
        break;
      case 'Finished':
        filtered = filtered.where((w) => w.workstepProgress.toLowerCase() == 'finished').toList();
        break;
      case 'Express Priority':
        filtered = filtered.where((w) => w.priority.toLowerCase() == 'express').toList();
        break;
      case 'Normal Priority':
        filtered = filtered.where((w) => w.priority.toLowerCase() == 'normal').toList();
        break;
    }

    // Sort by priority and then by creation date
    filtered.sort((a, b) {
      int priorityComparison = a.priorityLevel.compareTo(b.priorityLevel);
      if (priorityComparison != 0) return priorityComparison;
      
      if (a.creationDate != null && b.creationDate != null) {
        return b.creationDate!.compareTo(a.creationDate!);
      }
      return 0;
    });

    setState(() {
      _filteredWorkstations = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workstations'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkstations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search workstations or projects...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterWorkstations();
                  },
                ),
                const SizedBox(height: 12),
                
                // Filter Dropdown
                Row(
                  children: [
                    const Text('Filter: '),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: _filterOptions.map((filter) {
                          return DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value ?? 'All';
                          });
                          _filterWorkstations();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Statistics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1565C0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', _workstations.length, Colors.white),
                _buildStatItem('In Progress', 
                  _workstations.where((w) => w.workstepProgress.toLowerCase() == 'in progress').length,
                  Colors.orange),
                _buildStatItem('Finished', 
                  _workstations.where((w) => w.workstepProgress.toLowerCase() == 'finished').length,
                  Colors.green),
                _buildStatItem('Express', 
                  _workstations.where((w) => w.priority.toLowerCase() == 'express').length,
                  Colors.red),
              ],
            ),
          ),
          
          // Workstation List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWorkstations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadWorkstations,
                        child: ListView.builder(
                          itemCount: _filteredWorkstations.length,
                          itemBuilder: (context, index) {
                            final workstation = _filteredWorkstations[index];
                            return _buildWorkstationCard(workstation);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'No workstations found'
                : 'No workstations available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'Try adjusting your search or filter'
                : 'Import workstation data to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedFilter != 'All') ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                  _filteredWorkstations = _workstations;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkstationCard(WorkstationModel workstation) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkstationDetailsScreen(workstation: workstation),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Workstation ID
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      workstation.workStation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(workstation.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workstation.priority,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(workstation.workstepProgress),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workstation.workstepProgress,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Project Name
              Text(
                'Project: ${workstation.project}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Details Row
              Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Qty: ${workstation.quantity}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  
                  if (workstation.goodParts != '0') ...[
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Good: ${workstation.goodParts}',
                      style: const TextStyle(color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  if (workstation.targetDate != null) ...[
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Target: ${workstation.targetDate!.day}/${workstation.targetDate!.month}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              
              // Progress Bar
              Row(
                children: [
                  Text(
                    'Progress: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: workstation.completionPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(workstation.workstepProgress),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${workstation.completionPercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              // QR Code Indicator
              if (workstation.qrCode != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'QR Code Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'finished':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'not requested':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'express':
        return Colors.red;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
