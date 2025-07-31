import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import '../models/machine_data.dart';

/// Service for importing machine data from Excel files
class ExcelImportService {
  static const String _boxName = 'machines';
  
  /// Import first 5 rows from Excel file
  static Future<List<MachineData>> importExcelFile() async {
    try {
      // Pick Excel file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null) {
        debugPrint('❌ No file selected');
        return [];
      }

      List<MachineData> machines = [];
      
      if (kIsWeb) {
        // Web implementation
        machines = await _parseExcelFromBytes(result.files.single.bytes!);
      } else {
        // Mobile implementation
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        machines = await _parseExcelFromBytes(bytes);
      }

      // Save to local storage
      await _saveMachinesToStorage(machines);
      
      debugPrint('✅ Successfully imported ${machines.length} machines');
      return machines;
      
    } catch (e) {
      debugPrint('❌ Error importing Excel file: $e');
      rethrow;
    }
  }

  /// Parse Excel file from bytes
  static Future<List<MachineData>> _parseExcelFromBytes(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final List<MachineData> machines = [];

    // Get first sheet
    final sheet = excel.tables.values.first;
    if (sheet == null) {
      throw Exception('No sheets found in Excel file');
    }

    debugPrint('📊 Excel sheet has ${sheet.maxRows} rows and ${sheet.maxColumns} columns');

    // Skip header row and get first 5 data rows
    int rowCount = 0;
    for (int i = 1; i < sheet.maxRows && rowCount < 5; i++) {
      final row = sheet.rows[i];
      
      // Skip empty rows
      if (_isRowEmpty(row)) continue;
      
      try {
        final machine = _parseRowToMachine(row, i + 1);
        if (machine != null) {
          machines.add(machine);
          rowCount++;
          debugPrint('✅ Parsed machine ${rowCount}: ${machine.machineName}');
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing row ${i + 1}: $e');
        continue;
      }
    }

    return machines;
  }

  /// Parse a single row to MachineData
  static MachineData? _parseRowToMachine(List<Data?> row, int rowNumber) {
    try {
      // Flexible parsing - adjust column indices based on your Excel structure
      final machineId = _getCellValue(row, 0)?.toString().trim() ?? '';
      final machineName = _getCellValue(row, 1)?.toString().trim() ?? '';
      final department = _getCellValue(row, 2)?.toString().trim() ?? '';
      final location = _getCellValue(row, 3)?.toString().trim() ?? '';
      final machineType = _getCellValue(row, 4)?.toString().trim() ?? '';
      final manufacturer = _getCellValue(row, 5)?.toString().trim() ?? '';
      final model = _getCellValue(row, 6)?.toString().trim() ?? '';
      final serialNumber = _getCellValue(row, 7)?.toString().trim() ?? '';
      final installationDate = _getCellValue(row, 8)?.toString().trim() ?? '';
      final status = _getCellValue(row, 9)?.toString().trim() ?? 'Active';

      // Validate required fields
      if (machineId.isEmpty || machineName.isEmpty) {
        debugPrint('⚠️ Skipping row $rowNumber: Missing required fields (ID or Name)');
        return null;
      }

      return MachineData(
        id: machineId,
        machineName: machineName,
        department: department,
        location: location,
        machineType: machineType,
        manufacturer: manufacturer,
        model: model,
        serialNumber: serialNumber,
        installationDate: installationDate,
        status: status,
        qrCode: _generateQRCode(machineId),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error parsing row $rowNumber: $e');
      return null;
    }
  }

  /// Get cell value safely
  static dynamic _getCellValue(List<Data?> row, int columnIndex) {
    if (columnIndex >= row.length) return null;
    return row[columnIndex]?.value;
  }

  /// Check if row is empty
  static bool _isRowEmpty(List<Data?> row) {
    return row.every((cell) => 
      cell == null || 
      cell.value == null || 
      cell.value.toString().trim().isEmpty
    );
  }

  /// Generate QR code string for machine
  static String _generateQRCode(String machineId) {
    return 'SEWS_MACHINE_$machineId';
  }

  /// Save machines to local storage
  static Future<void> _saveMachinesToStorage(List<MachineData> machines) async {
    try {
      final box = await Hive.openBox<MachineData>(_boxName);
      
      for (final machine in machines) {
        await box.put(machine.id, machine);
      }
      
      debugPrint('💾 Saved ${machines.length} machines to local storage');
    } catch (e) {
      debugPrint('❌ Error saving to storage: $e');
      rethrow;
    }
  }

  /// Get all machines from storage
  static Future<List<MachineData>> getAllMachines() async {
    try {
      final box = await Hive.openBox<MachineData>(_boxName);
      return box.values.toList();
    } catch (e) {
      debugPrint('❌ Error getting machines from storage: $e');
      return [];
    }
  }

  /// Get machine by ID
  static Future<MachineData?> getMachineById(String machineId) async {
    try {
      final box = await Hive.openBox<MachineData>(_boxName);
      return box.get(machineId);
    } catch (e) {
      debugPrint('❌ Error getting machine by ID: $e');
      return null;
    }
  }

  /// Get machine by QR code
  static Future<MachineData?> getMachineByQRCode(String qrCode) async {
    try {
      final box = await Hive.openBox<MachineData>(_boxName);
      return box.values.firstWhere(
        (machine) => machine.qrCode == qrCode,
        orElse: () => throw StateError('Machine not found'),
      );
    } catch (e) {
      debugPrint('❌ Error getting machine by QR code: $e');
      return null;
    }
  }

  /// Clear all machines from storage
  static Future<void> clearAllMachines() async {
    try {
      final box = await Hive.openBox<MachineData>(_boxName);
      await box.clear();
      debugPrint('🗑️ Cleared all machines from storage');
    } catch (e) {
      debugPrint('❌ Error clearing machines: $e');
      rethrow;
    }
  }

  /// Import sample data for testing
  static Future<List<MachineData>> importSampleData() async {
    final sampleMachines = [
      MachineData(
        id: 'M001',
        machineName: 'CNC Lathe #1',
        department: 'Production',
        location: 'Floor A - Section 1',
        machineType: 'CNC Lathe',
        manufacturer: 'HAAS',
        model: 'ST-20',
        serialNumber: 'SN123456',
        installationDate: '2023-01-15',
        status: 'Active',
        qrCode: 'SEWS_MACHINE_M001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MachineData(
        id: 'M002',
        machineName: 'Milling Machine #3',
        department: 'Production',
        location: 'Floor A - Section 2',
        machineType: 'Milling Machine',
        manufacturer: 'DMG MORI',
        model: 'DMU 50',
        serialNumber: 'SN789012',
        installationDate: '2023-02-20',
        status: 'Active',
        qrCode: 'SEWS_MACHINE_M002',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MachineData(
        id: 'M003',
        machineName: 'Welding Station #1',
        department: 'Assembly',
        location: 'Floor B - Section 1',
        machineType: 'TIG Welder',
        manufacturer: 'Lincoln Electric',
        model: 'PowerTIG 325',
        serialNumber: 'SN345678',
        installationDate: '2023-03-10',
        status: 'Maintenance',
        qrCode: 'SEWS_MACHINE_M003',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MachineData(
        id: 'M004',
        machineName: 'Press Brake #2',
        department: 'Fabrication',
        location: 'Floor C - Section 1',
        machineType: 'Hydraulic Press',
        manufacturer: 'Cincinnati',
        model: 'CB 250-12',
        serialNumber: 'SN901234',
        installationDate: '2023-04-05',
        status: 'Active',
        qrCode: 'SEWS_MACHINE_M004',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MachineData(
        id: 'M005',
        machineName: 'Grinder #1',
        department: 'Finishing',
        location: 'Floor A - Section 3',
        machineType: 'Surface Grinder',
        manufacturer: 'Okamoto',
        model: 'ACC-1224DX',
        serialNumber: 'SN567890',
        installationDate: '2023-05-12',
        status: 'Active',
        qrCode: 'SEWS_MACHINE_M005',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await _saveMachinesToStorage(sampleMachines);
    debugPrint('✅ Sample data imported successfully');
    return sampleMachines;
  }
}
