import 'package:hive/hive.dart';

part 'machine_data.g.dart';

@HiveType(typeId: 0)
class MachineData extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String machineName;

  @HiveField(2)
  final String department;

  @HiveField(3)
  final String location;

  @HiveField(4)
  final String machineType;

  @HiveField(5)
  final String manufacturer;

  @HiveField(6)
  final String model;

  @HiveField(7)
  final String serialNumber;

  @HiveField(8)
  final String installationDate;

  @HiveField(9)
  final String status;

  @HiveField(10)
  final String qrCode;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final String? description;

  @HiveField(14)
  final String? maintenanceSchedule;

  @HiveField(15)
  final String? lastMaintenanceDate;

  @HiveField(16)
  final String? nextMaintenanceDate;

  @HiveField(17)
  final List<String>? operatingInstructions;

  @HiveField(18)
  final List<String>? safetyNotes;

  @HiveField(19)
  final String? imageUrl;

  @HiveField(20)
  final Map<String, dynamic>? specifications;

  MachineData({
    required this.id,
    required this.machineName,
    required this.department,
    required this.location,
    required this.machineType,
    required this.manufacturer,
    required this.model,
    required this.serialNumber,
    required this.installationDate,
    required this.status,
    required this.qrCode,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.maintenanceSchedule,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.operatingInstructions,
    this.safetyNotes,
    this.imageUrl,
    this.specifications,
  });

  /// Create a copy with updated fields
  MachineData copyWith({
    String? id,
    String? machineName,
    String? department,
    String? location,
    String? machineType,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? installationDate,
    String? status,
    String? qrCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? maintenanceSchedule,
    String? lastMaintenanceDate,
    String? nextMaintenanceDate,
    List<String>? operatingInstructions,
    List<String>? safetyNotes,
    String? imageUrl,
    Map<String, dynamic>? specifications,
  }) {
    return MachineData(
      id: id ?? this.id,
      machineName: machineName ?? this.machineName,
      department: department ?? this.department,
      location: location ?? this.location,
      machineType: machineType ?? this.machineType,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      installationDate: installationDate ?? this.installationDate,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      maintenanceSchedule: maintenanceSchedule ?? this.maintenanceSchedule,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      operatingInstructions: operatingInstructions ?? this.operatingInstructions,
      safetyNotes: safetyNotes ?? this.safetyNotes,
      imageUrl: imageUrl ?? this.imageUrl,
      specifications: specifications ?? this.specifications,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'machineName': machineName,
      'department': department,
      'location': location,
      'machineType': machineType,
      'manufacturer': manufacturer,
      'model': model,
      'serialNumber': serialNumber,
      'installationDate': installationDate,
      'status': status,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
      'maintenanceSchedule': maintenanceSchedule,
      'lastMaintenanceDate': lastMaintenanceDate,
      'nextMaintenanceDate': nextMaintenanceDate,
      'operatingInstructions': operatingInstructions,
      'safetyNotes': safetyNotes,
      'imageUrl': imageUrl,
      'specifications': specifications,
    };
  }

  /// Create from JSON
  factory MachineData.fromJson(Map<String, dynamic> json) {
    return MachineData(
      id: json['id'] ?? '',
      machineName: json['machineName'] ?? '',
      department: json['department'] ?? '',
      location: json['location'] ?? '',
      machineType: json['machineType'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      installationDate: json['installationDate'] ?? '',
      status: json['status'] ?? 'Active',
      qrCode: json['qrCode'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      description: json['description'],
      maintenanceSchedule: json['maintenanceSchedule'],
      lastMaintenanceDate: json['lastMaintenanceDate'],
      nextMaintenanceDate: json['nextMaintenanceDate'],
      operatingInstructions: json['operatingInstructions']?.cast<String>(),
      safetyNotes: json['safetyNotes']?.cast<String>(),
      imageUrl: json['imageUrl'],
      specifications: json['specifications']?.cast<String, dynamic>(),
    );
  }

  /// Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return '#4CAF50'; // Green
      case 'maintenance':
        return '#FF9800'; // Orange
      case 'inactive':
        return '#F44336'; // Red
      case 'scheduled':
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get status icon
  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'active':
        return '✅';
      case 'maintenance':
        return '🔧';
      case 'inactive':
        return '❌';
      case 'scheduled':
        return '📅';
      default:
        return '❓';
    }
  }

  /// Check if maintenance is due
  bool get isMaintenanceDue {
    if (nextMaintenanceDate == null) return false;
    try {
      final nextDate = DateTime.parse(nextMaintenanceDate!);
      return DateTime.now().isAfter(nextDate);
    } catch (e) {
      return false;
    }
  }

  /// Get days until next maintenance
  int? get daysUntilMaintenance {
    if (nextMaintenanceDate == null) return null;
    try {
      final nextDate = DateTime.parse(nextMaintenanceDate!);
      return nextDate.difference(DateTime.now()).inDays;
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'MachineData(id: $id, name: $machineName, department: $department, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MachineData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
