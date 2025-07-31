import 'package:hive/hive.dart';

part 'workstation_model.g.dart';

@HiveType(typeId: 0)
class WorkstationModel extends HiveObject {
  @HiveField(0)
  final String workStation;

  @HiveField(1)
  final String project;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final String workstepProgress;

  @HiveField(4)
  final String micrographProgress;

  @HiveField(5)
  final String priority;

  @HiveField(6)
  final String prototyping;

  @HiveField(7)
  final String lockedLookReason;

  @HiveField(8)
  final String goodParts;

  @HiveField(9)
  final DateTime? creationDate;

  @HiveField(10)
  final DateTime? targetDate;

  @HiveField(11)
  final DateTime? plannedStartDate;

  @HiveField(12)
  final DateTime? plannedEndDate;

  @HiveField(13)
  final DateTime? actualStartDate;

  @HiveField(14)
  final DateTime? actualEndDate;

  @HiveField(15)
  final double? plannedSetupDuration;

  @HiveField(16)
  final double? plannedProduction;

  @HiveField(17)
  final String? qrCode;

  @HiveField(18)
  final String department;

  @HiveField(19)
  final String status;

  @HiveField(20)
  final DateTime lastUpdated;

  WorkstationModel({
    required this.workStation,
    required this.project,
    required this.quantity,
    required this.workstepProgress,
    required this.micrographProgress,
    required this.priority,
    required this.prototyping,
    required this.lockedLookReason,
    required this.goodParts,
    this.creationDate,
    this.targetDate,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.plannedSetupDuration,
    this.plannedProduction,
    this.qrCode,
    this.department = '',
    this.status = 'active',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Generate QR code for this workstation
  String generateQRCode() {
    return 'SEWS_WS_${workStation}_${project}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Check if workstation is available for task assignment
  bool get isAvailable {
    return status == 'active' && workstepProgress != 'finished';
  }

  /// Get completion percentage
  double get completionPercentage {
    switch (workstepProgress.toLowerCase()) {
      case 'finished':
        return 100.0;
      case 'in progress':
        return 50.0;
      case 'not requested':
        return 0.0;
      default:
        return 25.0;
    }
  }

  /// Get priority level for sorting
  int get priorityLevel {
    switch (priority.toLowerCase()) {
      case 'express':
        return 1;
      case 'normal':
        return 2;
      case 'low':
        return 3;
      default:
        return 2;
    }
  }

  /// Convert to Map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'workStation': workStation,
      'project': project,
      'quantity': quantity,
      'workstepProgress': workstepProgress,
      'micrographProgress': micrographProgress,
      'priority': priority,
      'prototyping': prototyping,
      'lockedLookReason': lockedLookReason,
      'goodParts': goodParts,
      'creationDate': creationDate?.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'plannedStartDate': plannedStartDate?.toIso8601String(),
      'plannedEndDate': plannedEndDate?.toIso8601String(),
      'actualStartDate': actualStartDate?.toIso8601String(),
      'actualEndDate': actualEndDate?.toIso8601String(),
      'plannedSetupDuration': plannedSetupDuration,
      'plannedProduction': plannedProduction,
      'qrCode': qrCode,
      'department': department,
      'status': status,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from Map (JSON deserialization)
  factory WorkstationModel.fromJson(Map<String, dynamic> json) {
    return WorkstationModel(
      workStation: json['workStation'] ?? '',
      project: json['project'] ?? '',
      quantity: json['quantity'] ?? 0,
      workstepProgress: json['workstepProgress'] ?? '',
      micrographProgress: json['micrographProgress'] ?? '',
      priority: json['priority'] ?? '',
      prototyping: json['prototyping'] ?? '',
      lockedLookReason: json['lockedLookReason'] ?? '',
      goodParts: json['goodParts'] ?? '',
      creationDate: json['creationDate'] != null ? DateTime.parse(json['creationDate']) : null,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      plannedStartDate: json['plannedStartDate'] != null ? DateTime.parse(json['plannedStartDate']) : null,
      plannedEndDate: json['plannedEndDate'] != null ? DateTime.parse(json['plannedEndDate']) : null,
      actualStartDate: json['actualStartDate'] != null ? DateTime.parse(json['actualStartDate']) : null,
      actualEndDate: json['actualEndDate'] != null ? DateTime.parse(json['actualEndDate']) : null,
      plannedSetupDuration: json['plannedSetupDuration']?.toDouble(),
      plannedProduction: json['plannedProduction']?.toDouble(),
      qrCode: json['qrCode'],
      department: json['department'] ?? '',
      status: json['status'] ?? 'active',
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'WorkstationModel(workStation: $workStation, project: $project, quantity: $quantity, status: $workstepProgress)';
  }
}
