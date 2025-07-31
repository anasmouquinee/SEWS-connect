import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/workstation_model.dart';

class WorkstationStorageService {
  static const String _boxName = 'workstations';
  static Box<WorkstationModel>? _box;

  /// Initialize Hive storage for workstations
  static Future<void> initialize() async {
    try {
      debugPrint('🗄️ Initializing Workstation Storage...');
      
      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(WorkstationModelAdapter());
      }
      
      // Open box
      _box = await Hive.openBox<WorkstationModel>(_boxName);
      debugPrint('✅ Workstation Storage initialized successfully');
    } catch (e) {
      debugPrint('💥 Error initializing Workstation Storage: $e');
      rethrow;
    }
  }

  /// Get the storage box
  static Box<WorkstationModel> get _storage {
    if (_box == null || !_box!.isOpen) {
      throw StateError('WorkstationStorageService not initialized. Call initialize() first.');
    }
    return _box!;
  }

  /// Save a single workstation
  static Future<void> saveWorkstation(WorkstationModel workstation) async {
    try {
      final key = '${workstation.workStation}_${workstation.project}';
      await _storage.put(key, workstation);
      debugPrint('💾 Saved workstation: $key');
    } catch (e) {
      debugPrint('💥 Error saving workstation: $e');
      rethrow;
    }
  }

  /// Save multiple workstations
  static Future<void> saveWorkstations(List<WorkstationModel> workstations) async {
    try {
      debugPrint('💾 Saving ${workstations.length} workstations...');
      
      Map<String, WorkstationModel> workstationMap = {};
      for (WorkstationModel workstation in workstations) {
        final key = '${workstation.workStation}_${workstation.project}';
        workstationMap[key] = workstation;
      }
      
      await _storage.putAll(workstationMap);
      debugPrint('✅ Successfully saved ${workstations.length} workstations');
    } catch (e) {
      debugPrint('💥 Error saving workstations: $e');
      rethrow;
    }
  }

  /// Get all workstations
  static List<WorkstationModel> getAllWorkstations() {
    try {
      return _storage.values.toList();
    } catch (e) {
      debugPrint('💥 Error getting all workstations: $e');
      return [];
    }
  }

  /// Get workstation by QR code
  static WorkstationModel? getWorkstationByQR(String qrCode) {
    try {
      return _storage.values.firstWhere(
        (workstation) => workstation.qrCode == qrCode,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      debugPrint('⚠️ Workstation not found for QR: $qrCode');
      return null;
    }
  }

  /// Get workstation by work station name and project
  static WorkstationModel? getWorkstation(String workStationName, String project) {
    try {
      final key = '${workStationName}_$project';
      return _storage.get(key);
    } catch (e) {
      debugPrint('💥 Error getting workstation: $e');
      return null;
    }
  }

  /// Search workstations by work station name
  static List<WorkstationModel> searchByWorkStation(String query) {
    try {
      if (query.isEmpty) return getAllWorkstations();
      
      return _storage.values
          .where((workstation) => 
              workstation.workStation.toLowerCase().contains(query.toLowerCase()) ||
              workstation.project.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      debugPrint('💥 Error searching workstations: $e');
      return [];
    }
  }

  /// Get workstations by priority
  static List<WorkstationModel> getWorkstationsByPriority(String priority) {
    try {
      return _storage.values
          .where((workstation) => 
              workstation.priority.toLowerCase() == priority.toLowerCase())
          .toList();
    } catch (e) {
      debugPrint('💥 Error getting workstations by priority: $e');
      return [];
    }
  }

  /// Get workstations by status
  static List<WorkstationModel> getWorkstationsByStatus(String status) {
    try {
      return _storage.values
          .where((workstation) => 
              workstation.workstepProgress.toLowerCase() == status.toLowerCase())
          .toList();
    } catch (e) {
      debugPrint('💥 Error getting workstations by status: $e');
      return [];
    }
  }

  /// Get available workstations (not finished)
  static List<WorkstationModel> getAvailableWorkstations() {
    try {
      return _storage.values
          .where((workstation) => workstation.isAvailable)
          .toList()
        ..sort((a, b) => a.priorityLevel.compareTo(b.priorityLevel));
    } catch (e) {
      debugPrint('💥 Error getting available workstations: $e');
      return [];
    }
  }

  /// Update workstation status
  static Future<void> updateWorkstationStatus(String workStationName, String project, String newStatus) async {
    try {
      final key = '${workStationName}_$project';
      final workstation = _storage.get(key);
      
      if (workstation != null) {
        // Create updated workstation
        final updatedWorkstation = WorkstationModel(
          workStation: workstation.workStation,
          project: workstation.project,
          quantity: workstation.quantity,
          workstepProgress: newStatus,
          micrographProgress: workstation.micrographProgress,
          priority: workstation.priority,
          prototyping: workstation.prototyping,
          lockedLookReason: workstation.lockedLookReason,
          goodParts: workstation.goodParts,
          creationDate: workstation.creationDate,
          targetDate: workstation.targetDate,
          plannedStartDate: workstation.plannedStartDate,
          plannedEndDate: workstation.plannedEndDate,
          actualStartDate: workstation.actualStartDate,
          actualEndDate: workstation.actualEndDate,
          plannedSetupDuration: workstation.plannedSetupDuration,
          plannedProduction: workstation.plannedProduction,
          qrCode: workstation.qrCode,
          department: workstation.department,
          status: newStatus.toLowerCase() == 'finished' ? 'completed' : 'active',
          lastUpdated: DateTime.now(),
        );
        
        await _storage.put(key, updatedWorkstation);
        debugPrint('✅ Updated workstation status: $key -> $newStatus');
      } else {
        debugPrint('⚠️ Workstation not found for update: $key');
      }
    } catch (e) {
      debugPrint('💥 Error updating workstation status: $e');
      rethrow;
    }
  }

  /// Delete workstation
  static Future<void> deleteWorkstation(String workStationName, String project) async {
    try {
      final key = '${workStationName}_$project';
      await _storage.delete(key);
      debugPrint('🗑️ Deleted workstation: $key');
    } catch (e) {
      debugPrint('💥 Error deleting workstation: $e');
      rethrow;
    }
  }

  /// Clear all workstations
  static Future<void> clearAllWorkstations() async {
    try {
      await _storage.clear();
      debugPrint('🗑️ Cleared all workstations');
    } catch (e) {
      debugPrint('💥 Error clearing workstations: $e');
      rethrow;
    }
  }

  /// Get total count of workstations
  static int getTotalCount() {
    return _storage.length;
  }

  /// Get statistics
  static Map<String, int> getStatistics() {
    try {
      final workstations = getAllWorkstations();
      Map<String, int> stats = {
        'total': workstations.length,
        'finished': 0,
        'in_progress': 0,
        'not_requested': 0,
        'express_priority': 0,
        'normal_priority': 0,
      };

      for (WorkstationModel workstation in workstations) {
        // Count by status
        switch (workstation.workstepProgress.toLowerCase()) {
          case 'finished':
            stats['finished'] = (stats['finished'] ?? 0) + 1;
            break;
          case 'in progress':
            stats['in_progress'] = (stats['in_progress'] ?? 0) + 1;
            break;
          case 'not requested':
            stats['not_requested'] = (stats['not_requested'] ?? 0) + 1;
            break;
        }

        // Count by priority
        switch (workstation.priority.toLowerCase()) {
          case 'express':
            stats['express_priority'] = (stats['express_priority'] ?? 0) + 1;
            break;
          case 'normal':
            stats['normal_priority'] = (stats['normal_priority'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('💥 Error getting statistics: $e');
      return {'total': 0};
    }
  }

  /// Close storage
  static Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
        debugPrint('📦 Workstation Storage closed');
      }
    } catch (e) {
      debugPrint('💥 Error closing Workstation Storage: $e');
    }
  }
}
