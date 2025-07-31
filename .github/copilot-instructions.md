<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# SEWS Connect - Flutter App Development Guidelines

## Project Overview
SEWS Connect is a comprehensive company communication and task management app built with Flutter for SEWS manufacturing company. The app focuses on department-based communication, QR/barcode scanning for equipment management, and smart task assignment workflows.

## Key Features
- Real-time messaging with department-based channels
- Voice/video calling and meetings
- QR/barcode scanner for equipment identification
- First-scan-wins task assignment system
- Department-specific notifications
- Maintenance workflow management
- Smart dashboard with role-based views

## Architecture Guidelines
- Use **Feature-First Architecture** with clear separation of concerns
- Implement **Riverpod** for state management
- Use **Go Router** for navigation
- Follow **Material Design 3** principles
- Implement **Hive** for local storage

## Code Style Preferences
- Prefer `const` constructors wherever possible
- Use meaningful widget names and file organization
- Implement proper error handling and loading states
- Add comprehensive comments for business logic
- Follow Flutter naming conventions

## Technology Stack Focus
- **Flutter 3.19+** with latest stable features
- **Riverpod** for state management
- **Socket.io** for real-time communication
- **Agora RTC** for video/audio calling
- **Mobile Scanner** for QR/barcode scanning
- **Firebase** for push notifications
- **Hive** for local data persistence

## Specific Requirements
- **Department Integration**: Always consider department-specific features and permissions
- **Real-time Updates**: Implement live data updates for tasks, messages, and notifications
- **Scanner Integration**: QR/barcode scanning should be seamlessly integrated into task workflows
- **Emergency Features**: Prioritize emergency communication channels and alerts
- **Mobile-First**: Design for mobile devices with responsive layouts

## Folder Structure
```
lib/
├── core/                 # App-wide configurations
├── features/            # Feature-based modules
│   ├── auth/           # Authentication
│   ├── dashboard/      # Main dashboard
│   ├── messaging/      # Chat system
│   ├── scanner/        # QR/Barcode scanning
│   ├── tasks/          # Task management
│   └── ...
└── main.dart
```

## Business Logic Focus
- **Task Assignment**: First person to scan QR code gets the task
- **Department Notifications**: Role-based alert system
- **Equipment Management**: Machine-centric workflow design
- **Emergency Protocols**: Priority communication channels
- **Real-time Collaboration**: Live updates across all features

## UI/UX Principles
- **Company Branding**: Use SEWS color scheme (Blue primary, Green secondary)
- **Industrial Design**: Professional interface suitable for manufacturing environment
- **Accessibility**: Large touch targets, clear typography, high contrast
- **Offline Support**: Graceful degradation when network is unavailable
- **Quick Actions**: One-tap access to common tasks

## Testing Preferences
- Focus on integration tests for user workflows
- Unit tests for business logic and state management
- Widget tests for UI components
- Mock real-time services for testing

## Performance Considerations
- Optimize for older Android devices common in industrial settings
- Implement efficient image caching for user profiles and machine photos
- Use lazy loading for large lists (tasks, messages, etc.)
- Minimize battery usage for always-on features

When helping with this project, prioritize these guidelines and focus on creating robust, enterprise-grade features that enhance workplace communication and task management in a manufacturing environment.
