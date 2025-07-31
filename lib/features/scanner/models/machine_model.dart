import 'package:hive/hive.dart';

part 'machine_model.g.dart';

@HiveType(typeId: 3)
class MachineModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String reference;

  @HiveField(3)
  final String department;

  @HiveField(4)
  final String location;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final String? manufacturer;

  @HiveField(7)
  final String? model;

  @HiveField(8)
  final String? serialNumber;

  @HiveField(9)
  final DateTime? installationDate;

  @HiveField(10)
  final DateTime? nextMaintenanceDate;

  @HiveField(11)
  final String status; // active, maintenance, offline

  @HiveField(12)
  final Map<String, dynamic>? additionalData;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  MachineModel({
    required this.id,
    required this.name,
    required this.reference,
    required this.department,
    required this.location,
    this.description,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.installationDate,
    this.nextMaintenanceDate,
    this.status = 'active',
    this.additionalData,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from CSV row
  factory MachineModel.fromCsvRow(Map<String, dynamic> row) {
    return MachineModel(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      reference: row['reference']?.toString() ?? row['ref']?.toString() ?? '',
      department: row['department']?.toString() ?? '',
      location: row['location']?.toString() ?? '',
      description: row['description']?.toString(),
      manufacturer: row['manufacturer']?.toString(),
      model: row['model']?.toString(),
      serialNumber: row['serial_number']?.toString() ?? row['serialNumber']?.toString(),
      installationDate: _parseDate(row['installation_date'] ?? row['installationDate']),
      nextMaintenanceDate: _parseDate(row['next_maintenance_date'] ?? row['nextMaintenanceDate']),
      status: row['status']?.toString() ?? 'active',
      additionalData: _parseAdditionalData(row),
    );
  }

  /// Parse date from various formats
  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) {
        if (dateValue.isEmpty) return null;
        return DateTime.parse(dateValue);
      }
      return null;
    } catch (e) {
      print('Error parsing date: $dateValue - $e');
      return null;
    }
  }

  /// Extract additional data from CSV row
  static Map<String, dynamic>? _parseAdditionalData(Map<String, dynamic> row) {
    final knownFields = {
      'id', 'name', 'reference', 'ref', 'department', 'location',
      'description', 'manufacturer', 'model', 'serial_number', 'serialNumber',
      'installation_date', 'installationDate', 'next_maintenance_date', 
      'nextMaintenanceDate', 'status'
    };

    final additionalData = <String, dynamic>{};
    
    for (final entry in row.entries) {
      if (!knownFields.contains(entry.key) && entry.value != null) {
        additionalData[entry.key] = entry.value;
      }
    }

    return additionalData.isEmpty ? null : additionalData;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'reference': reference,
      'department': department,
      'location': location,
      'description': description,
      'manufacturer': manufacturer,
      'model': model,
      'serialNumber': serialNumber,
      'installationDate': installationDate?.toIso8601String(),
      'nextMaintenanceDate': nextMaintenanceDate?.toIso8601String(),
      'status': status,
      'additionalData': additionalData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create copy with updated fields
  MachineModel copyWith({
    String? id,
    String? name,
    String? reference,
    String? department,
    String? location,
    String? description,
    String? manufacturer,
    String? model,
    String? serialNumber,
    DateTime? installationDate,
    DateTime? nextMaintenanceDate,
    String? status,
    Map<String, dynamic>? additionalData,
  }) {
    return MachineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      department: department ?? this.department,
      location: location ?? this.location,
      description: description ?? this.description,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      installationDate: installationDate ?? this.installationDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      status: status ?? this.status,
      additionalData: additionalData ?? this.additionalData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'MachineModel(id: $id, name: $name, ref: $reference, dept: $department)';
  }
}
