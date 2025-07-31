# 🧪 SEWS Connect Workstation System - Test Guide

## 🚀 Setup Steps

### 1. Install Dependencies
Run these commands in your project directory:

```bash
flutter pub get
flutter packages pub run build_runner build
```

### 2. Add to Your App
You can test the workstation system in two ways:

#### Option A: Replace your main.dart temporarily
Replace your current `main.dart` with the contents of `lib/workstation_test_main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/workstation/services/workstation_storage_service.dart';
import 'features/workstation/screens/workstation_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Workstation Storage
  await WorkstationStorageService.initialize();
  
  runApp(const MyApp());
}
// ... rest of the code from workstation_test_main.dart
```

#### Option B: Add to Your Existing App
Add this to your existing navigation:

```dart
import 'features/workstation/screens/workstation_test_screen.dart';

// In your main app, add a button to navigate to:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const WorkstationTestScreen(),
  ),
);
```

## 🧪 Test Features

### 1. **Load Test Data**
- Tap "Load Test Data" to import your Excel structure sample
- This creates 5 workstations based on your provided data:
  - M12, M08, CH18, CH08 workstations
  - With quantities, priorities, dates, etc.

### 2. **QR Code Testing**
- Each workstation gets a unique QR code
- Test QR lookup functionality
- Try the QR scanner screen

### 3. **Navigation Tests**
- **Import Screen**: Test file import and sample data
- **QR Scanner**: Test camera scanning (requires device)
- **List Screen**: View all workstations with filters

### 4. **Workstation Details**
- Tap any workstation to see detailed view
- Test status updates
- Try "Assign Task to Me" (first-scan-wins)
- Test emergency reporting

## 📱 Test Workflow

1. **Start**: Run the app and go to Test Screen
2. **Initialize**: Should show "Storage initialized successfully"  
3. **Load Data**: Tap "Load Test Data" - should import 5 workstations
4. **QR Test**: Tap "Test QR Code Lookup" - should find first workstation
5. **Navigate**: Try each navigation button
6. **Scanner**: Test QR scanner (use generated QR codes)
7. **Details**: Tap workstations to see full details
8. **Actions**: Try status updates and task assignment

## 🔍 Your Excel Data Structure

The system imports these columns from your data:
- **Work Station**: M12, M08, CH18, etc.
- **Project**: Project numbers (40, 275, etc.)
- **Quantity**: Production quantities (1000, 275, etc.)
- **Workstep Progress**: finished, Not Requested, etc.
- **Priority**: express, normal
- **Dates**: Creation, Target, Planned Start/End, Actual Start/End
- **Good Parts**: Quality tracking
- **Setup Duration**: Planning data

## 🎯 Expected Results

✅ **Storage initialized successfully**
✅ **Loaded 5 test workstations successfully!**
✅ **QR Lookup Test: Found M12** (or similar)
✅ **Scanner finds workstations by QR code**
✅ **List shows workstations with status badges**
✅ **Details screen shows complete information**
✅ **Status updates work**
✅ **Task assignment works**

## 🚨 Troubleshooting

### If you get build errors:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter packages pub run build_runner build`

### If Hive errors:
- Make sure the generated file `workstation_model.g.dart` exists
- Check that Hive is properly initialized in main()

### If scanner doesn't work:
- Make sure you have camera permissions
- Test on a real device (emulator camera may not work)

### If import fails:
- Try the "Load Test Data" first to verify the system works
- Check file format (CSV works better than Excel)

## 📄 File Structure Created

```
lib/features/workstation/
├── models/
│   ├── workstation_model.dart
│   └── workstation_model.g.dart
├── services/
│   ├── excel_import_service.dart
│   └── workstation_storage_service.dart
└── screens/
    ├── workstation_test_screen.dart
    ├── workstation_import_screen.dart
    ├── qr_scanner_screen.dart
    ├── workstation_details_screen.dart
    └── workstation_list_screen.dart
```

## 🎉 Success Indicators

When everything works, you should see:
- Green status card in test screen
- 5 workstations loaded from your Excel data
- QR codes generated and searchable
- Scanner recognizes QR codes
- Full workstation management workflow

Ready to test! 🚀
