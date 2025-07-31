import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/workstation_model.dart';

class ExcelImportService {
  static const String _dateFormat1 = 'dd.MM.yyyy HH:mm:ss';
  static const String _dateFormat2 = 'dd.MM.yyyy';
  static const String _dateFormat3 = 'yyyy-MM-dd HH:mm:ss';

  /// Import workstation data from CSV/Excel file
  static Future<List<WorkstationModel>> importFromFile() async {
    try {
      debugPrint('📂 Opening file picker for CSV/Excel import...');
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase();
        
        debugPrint('📄 Selected file: ${file.path}');
        debugPrint('📋 File extension: $extension');

        if (extension == 'csv') {
          return await _importFromCSV(file);
        } else {
          throw UnsupportedError('Excel files (.xlsx, .xls) require additional dependencies. Please convert to CSV format.');
        }
      } else {
        debugPrint('❌ No file selected');
        return [];
      }
    } catch (e) {
      debugPrint('💥 Error importing file: $e');
      rethrow;
    }
  }

  /// Import from CSV content (for testing or direct import)
  static Future<List<WorkstationModel>> importFromCSVContent(String csvContent) async {
    try {
      debugPrint('📊 Importing from CSV content...');
      
      // Parse CSV content
      List<List<dynamic>> csvData = const CsvToListConverter().convert(csvContent);
      
      if (csvData.isEmpty) {
        debugPrint('⚠️ CSV is empty');
        return [];
      }

      // Get headers from first row
      List<String> headers = csvData.first.map((e) => e.toString()).toList();
      debugPrint('📋 Headers found: $headers');

      // Process data rows (skip header)
      List<WorkstationModel> workstations = [];
      
      for (int i = 1; i < csvData.length && i <= 5; i++) { // Import first 5 rows as requested
        try {
          final row = csvData[i];
          final workstation = _parseWorkstationFromRow(headers, row, i);
          if (workstation != null) {
            workstations.add(workstation);
            debugPrint('✅ Imported workstation ${i}: ${workstation.workStation}');
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing row $i: $e');
        }
      }

      debugPrint('🎉 Successfully imported ${workstations.length} workstations');
      return workstations;
    } catch (e) {
      debugPrint('💥 Error importing CSV content: $e');
      rethrow;
    }
  }

  /// Import from CSV file
  static Future<List<WorkstationModel>> _importFromCSV(File file) async {
    try {
      final content = await file.readAsString();
      return await importFromCSVContent(content);
    } catch (e) {
      debugPrint('💥 Error reading CSV file: $e');
      rethrow;
    }
  }

  /// Parse workstation from CSV row
  static WorkstationModel? _parseWorkstationFromRow(List<String> headers, List<dynamic> row, int rowIndex) {
    try {
      // Create a map of column name to value
      Map<String, String> rowData = {};
      for (int i = 0; i < headers.length && i < row.length; i++) {
        rowData[headers[i].toLowerCase().trim()] = row[i].toString().trim();
      }

      // Extract required fields
      String workStation = _getFieldValue(rowData, ['work station', 'workstation', 'station']) ?? 'WS-$rowIndex';
      String project = _getFieldValue(rowData, ['project', 'proj']) ?? '';
      int quantity = int.tryParse(_getFieldValue(rowData, ['quantity', 'qty']) ?? '0') ?? 0;
      String workstepProgress = _getFieldValue(rowData, ['workstep progress', 'progress', 'status']) ?? 'Not Requested';
      String micrographProgress = _getFieldValue(rowData, ['micrograph progress', 'micrograph']) ?? 'Not Requested';
      String priority = _getFieldValue(rowData, ['priority', 'prio']) ?? 'normal';
      String prototyping = _getFieldValue(rowData, ['prototyping', 'prototype']) ?? 'no';
      String lockedLookReason = _getFieldValue(rowData, ['locked look reason', 'reason']) ?? 'no';
      String goodParts = _getFieldValue(rowData, ['good parts', 'parts']) ?? '0';

      // Parse dates
      DateTime? creationDate = _parseDate(_getFieldValue(rowData, ['creation date', 'created']));
      DateTime? targetDate = _parseDate(_getFieldValue(rowData, ['target date', 'target']));
      DateTime? plannedStartDate = _parseDate(_getFieldValue(rowData, ['planned start date', 'start planned']));
      DateTime? plannedEndDate = _parseDate(_getFieldValue(rowData, ['planned end date', 'end planned']));
      DateTime? actualStartDate = _parseDate(_getFieldValue(rowData, ['actual start date', 'start actual']));
      DateTime? actualEndDate = _parseDate(_getFieldValue(rowData, ['actual end date', 'end actual']));

      // Parse numeric fields
      double? plannedSetupDuration = double.tryParse(_getFieldValue(rowData, ['planned setup duration', 'setup duration']) ?? '0');
      double? plannedProduction = double.tryParse(_getFieldValue(rowData, ['planned production', 'production']) ?? '0');

      // Generate QR code
      String qrCode = 'SEWS_${workStation}_${project}_${DateTime.now().millisecondsSinceEpoch}';

      return WorkstationModel(
        workStation: workStation,
        project: project,
        quantity: quantity,
        workstepProgress: workstepProgress,
        micrographProgress: micrographProgress,
        priority: priority,
        prototyping: prototyping,
        lockedLookReason: lockedLookReason,
        goodParts: goodParts,
        creationDate: creationDate,
        targetDate: targetDate,
        plannedStartDate: plannedStartDate,
        plannedEndDate: plannedEndDate,
        actualStartDate: actualStartDate,
        actualEndDate: actualEndDate,
        plannedSetupDuration: plannedSetupDuration,
        plannedProduction: plannedProduction,
        qrCode: qrCode,
        department: 'Manufacturing', // Default department
        status: workstepProgress.toLowerCase() == 'finished' ? 'completed' : 'active',
      );
    } catch (e) {
      debugPrint('💥 Error parsing workstation from row $rowIndex: $e');
      return null;
    }
  }

  /// Get field value by trying multiple possible column names
  static String? _getFieldValue(Map<String, String> rowData, List<String> possibleNames) {
    for (String name in possibleNames) {
      String? value = rowData[name.toLowerCase()];
      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return null;
  }

  /// Parse date from string with multiple format support
  static DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'null') {
      return null;
    }

    // Try different date formats
    List<String> formats = [_dateFormat1, _dateFormat2, _dateFormat3];
    
    for (String format in formats) {
      try {
        return DateFormat(format).parse(dateString);
      } catch (e) {
        // Try next format
      }
    }

    // Try parsing ISO format
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      debugPrint('⚠️ Could not parse date: $dateString');
      return null;
    }
  }

  /// Create sample CSV content for testing
  static String createSampleCSV() {
    return '''Work Station,Project,Quantity,Workstep Progress,Micrograph Progress,Priority,Prototyping,Locked Look Reason,Good Parts,Creation Date,Target Date,Planned Start Date,Planned End Date,Actual Start Date,Actual End Date,Planned Setup Duration,Planned Production
M12,40,1000,finished,Not Requested,express,no,no,1000,28.06.2025 12:56:22,28.06.2025 22:00:00,28.06.2025 13:02:18,28.06.2025 15:56:18,28.06.2025 13:02:18,28.06.2025 15:56:18,13,179
M12,40,finished,Not Requested,express,no,no,40,28.06.2025 12:54:24,24.06.2025 22:00:00,28.06.2025 13:09:51,28.06.2025 13:48:05,1,234
M08,275,finished,Not Requested,express,no,no,275,28.06.2025 12:49:17,30.06.2025 22:00:00,28.06.2025 13:06:39,28.06.2025 13:30:45,1,14.2
CH18,175,finished,Not Requested,express,no,no,175,28.06.2025 12:41:35,28.06.2025 22:00:00,28.06.2025 13:01:02,28.06.2025 13:26:37,1,9.275
CH08,897,finished,Not Requested,express,no,no,697,28.06.2025 11:37:54,28.06.2025 22:00:00,28.06.2025 13:04:19,28.06.2025 14:20:50,1,26.446''';
  }
}
