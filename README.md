# 🏭 SEWS Connect - Manufacturing Communication Hub

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.19%2B-blue.svg" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-orange.svg" alt="License">
</div>

SEWS Connect is a comprehensive communication and task management application designed specifically for SEWS manufacturing company. Built with Flutter, it provides real-time messaging, video calling, QR-based equipment management, and intelligent task assignment workflows.

## ✨ Key Features

### 🔄 Real-Time Communication
- **Department-based messaging** with instant notifications
- **WebRTC video/audio calling** with Android 11+ compatibility
- **Emergency communication channels** for critical alerts
- **Firebase Firestore integration** for seamless real-time updates

### � Workstation Management
- **Excel import functionality** for bulk workstation data
- **QR code generation** for equipment identification
- **First-scan-wins task assignment** system
- **Mobile scanner integration** for barcode/QR scanning

### 🎯 Smart Task Management
- **Priority-based task assignment** with department filtering
- **Real-time task status updates** across all devices
- **Equipment-centric workflow design** for manufacturing environment
- **Offline support** with local Hive storage

### 🎨 Manufacturing-Focused UI
- **Material Design 3** with SEWS branding
- **Industrial-grade interface** suitable for factory environments
- **Large touch targets** and high contrast for accessibility
- **Role-based dashboard views** for different user types

## Technology Stack

- **Framework**: Flutter 3.19+
- **State Management**: Riverpod
- **Routing**: Go Router
- **Real-time Communication**: Socket.io, WebSocket
- **Video/Audio**: Agora RTC Engine
- **Local Storage**: Hive
- **Camera & Scanner**: Mobile Scanner, Camera plugin
- **Push Notifications**: Firebase Cloud Messaging
- **UI Components**: Material Design 3

## Project Structure
 - ui mproject component 
 llocal sotrage 
 hive " video audio state  managemnt 
river pod " routing go router  ' push notification { llocal so}
```
lib/
├── core/
│   ├── app.dart                 # Main app configuration
│   ├── theme/                   # App theme and styling
│   └── services/               # Core services (Hive, etc.)
├── features/
│   ├── auth/                   # Authentication
│   ├── dashboard/              # Main dashboard
│   ├── messaging/              # Chat and messaging
│   ├── calling/                # Voice and video calls
│   ├── meetings/               # Video conferences
│   ├── scanner/                # QR/Barcode scanning
│   ├── tasks/                  # Task management
│   ├── notifications/          # Notification system
│   └── maintenance/            # Maintenance workflows
└── main.dart                   # App entry point
```

## Getting Started

### Prerequisites
- Flutter SDK 3.19.0 or higher
- Dart SDK 3.1.3 or higher
- Android Studio or VS Code
- Android device/emulator or iOS device/simulator

### Installation

1. **Clone the repository** (or use this existing project)
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

### Configuration

1. **Firebase Setup** (for notifications):
   - Create a Firebase project
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

2. **Agora Setup** (for video/audio calls):
   - Get Agora App ID from [Agora Console](https://console.agora.io/)
   - Add your App ID to the configuration

## Key Features Breakdown

### Department-Based Communication
- **Maintenance Team**: Real-time alerts for equipment issues
- **IT Support**: System notifications and technical updates  
- **HR Department**: Company announcements and employee communications
- **Production Floor**: Shift updates and production targets
- **Emergency Response**: Critical alerts with highest priority

### Smart Task Assignment
1. **Equipment Issue Detection**: System automatically creates tasks
2. **QR Code Generation**: Each machine has unique QR/barcode
3. **First-Scan-Wins**: First employee to scan gets the task
4. **Real-time Updates**: Instant notification to all relevant departments
5. **Progress Tracking**: Track task completion in real-time

### Equipment Management
- **Machine Database**: Comprehensive equipment information
- **Status Monitoring**: Real-time operational status
- **Maintenance Schedules**: Automated preventive maintenance
- **Issue Reporting**: Quick incident reporting with photos
- **Work History**: Complete maintenance history per machine

## Usage Examples

### Claiming a Maintenance Task
1. Receive notification about equipment issue
2. Navigate to Scanner page
3. Scan QR code on the machine
4. Task automatically assigned to you
5. Update progress as you work
6. Mark as complete when finished

### Emergency Communication
1. Use Emergency channel for urgent issues
2. All messages prioritized and highlighted
3. Department heads automatically notified
4. Real-time status updates
5. Resolution tracking and reporting

### Department Coordination
1. Join department-specific chat rooms
2. Receive targeted notifications
3. Coordinate with team members
4. Share files and updates
5. Track departmental tasks and goals

## Contributing

1. Follow Flutter best practices
2. Use proper state management with Riverpod
3. Maintain consistent code style
4. Add tests for new features
5. Update documentation as needed

## Support

For technical support or feature requests, contact the SEWS IT department.

## License

This project is proprietary software developed for SEWS company internal use.

---

**SEWS Connect** - Connecting teams, streamlining workflows, enhancing productivity.
