# SEWS Connect - iOS Build Guide

## Overview
Your SEWS Connect app is now ready for iOS deployment! This guide will help you build and deploy your workstation management app with QR scanning and WebRTC video calling on iOS devices.

## Prerequisites for iOS Development

### 1. Mac Computer Required
- iOS apps can only be built on macOS
- You'll need access to a Mac with Xcode installed
- Minimum macOS 12.0 (Monterey) recommended

### 2. Xcode Installation
```bash
# Install Xcode from Mac App Store or download from Apple Developer Portal
# After installation, accept the license:
sudo xcode-select --install
sudo xcodebuild -license accept
```

### 3. iOS Development Setup
```bash
# Verify iOS setup
flutter doctor
# Should show checkmarks for:
# ✅ Xcode - develop for iOS and macOS
# ✅ iOS toolchain
```

## Project Configuration

### Current iOS Setup ✅
Your SEWS Connect app now includes:

- **iOS folder structure**: Complete iOS project configuration
- **Info.plist**: Configured with all required permissions:
  - Camera access for QR scanning
  - Microphone access for WebRTC calls
  - File access for Excel imports
  - Photo library access
- **Bundle Identifier**: `com.sews.connect`
- **App Name**: "SEWS Connect"
- **iOS Deployment Target**: iOS 11.0+

### Key Features Configured:
1. **QR Code Scanning**: Camera permissions configured
2. **WebRTC Video Calls**: Microphone permissions set
3. **Excel Import**: File picker permissions ready
4. **Industrial Design**: SEWS branding and colors

## Building for iOS

### 1. Open on Mac
Transfer your project to a Mac computer and run:

```bash
cd "path/to/SEWS connect(pfa)"
flutter doctor
```

### 2. Install iOS Dependencies
```bash
# Navigate to iOS folder
cd ios

# Install CocoaPods dependencies
pod install

# Return to root
cd ..
```

### 3. Build iOS App
```bash
# Debug build (for testing)
flutter build ios --debug

# Release build (for App Store)
flutter build ios --release
```

### 4. Open in Xcode
```bash
# Open the workspace in Xcode
open ios/Runner.xcworkspace
```

## Code Signing & Deployment

### 1. Apple Developer Account
- Sign up at https://developer.apple.com
- Cost: $99/year for individual developer

### 2. Configure Signing in Xcode
1. Select "Runner" target
2. Go to "Signing & Capabilities"
3. Select your Team
4. Xcode will automatically manage provisioning profiles

### 3. Build for Device
```bash
# Connect iOS device via USB
flutter run --release
```

## App Store Deployment

### 1. Archive Build
In Xcode:
1. Product → Archive
2. Wait for build completion
3. Click "Distribute App"
4. Choose "App Store Connect"

### 2. App Store Connect
1. Visit https://appstoreconnect.apple.com
2. Create new app entry
3. Upload your build
4. Fill app metadata:
   - App Name: "SEWS Connect"
   - Description: "Manufacturing workstation management with QR scanning and team communication"
   - Keywords: "manufacturing", "QR", "workstation", "communication"
   - Category: Business

## Testing Your iOS App

### Core Features to Test:
1. **Excel Import**: Test with your workstation data
2. **QR Code Generation**: Verify QR codes are generated correctly
3. **QR Scanning**: Test camera scanning functionality
4. **WebRTC Calls**: Test video calling between devices
5. **Local Storage**: Verify Hive database works on iOS
6. **UI/UX**: Test on different iPhone/iPad sizes

### Sample Test Data
Your app includes sample workstation data:
- M12 - Cable Assembly (High Priority)
- M08 - Connector Testing (Medium Priority)
- CH18 - Cable Harness (Low Priority)
- CH08 - Final Assembly (High Priority)

## iOS-Specific Considerations

### 1. Performance
- iOS devices have excellent performance for Flutter apps
- WebRTC works smoothly on iOS Safari engine
- Camera scanning is very responsive

### 2. Permissions
All required permissions are configured:
```xml
<!-- Already in your Info.plist -->
<key>NSCameraUsageDescription</key>
<string>SEWS Connect needs camera access to scan QR codes</string>

<key>NSMicrophoneUsageDescription</key>
<string>SEWS Connect needs microphone access for video calls</string>
```

### 3. File Management
- Excel import works with iOS Files app
- Local Hive storage is sandboxed per iOS requirements
- QR codes can be saved to Photos

## Troubleshooting

### Common Issues:
1. **Build Errors**: Check Xcode build settings match Flutter requirements
2. **Permission Denied**: Ensure Info.plist permissions are correct
3. **Signing Issues**: Verify Apple Developer account is active
4. **WebRTC Issues**: Check network connectivity and STUN servers

### Debug Commands:
```bash
# Check iOS devices
flutter devices

# Debug on iOS
flutter run --debug

# View logs
flutter logs
```

## Production Checklist

Before App Store submission:
- [ ] Test on multiple iOS devices (iPhone, iPad)
- [ ] Verify all permissions work correctly
- [ ] Test Excel import with real data
- [ ] Test QR scanning in various lighting
- [ ] Test WebRTC calls across networks
- [ ] Optimize app icons for all sizes
- [ ] Review app metadata and screenshots

## Current Status ✅

Your SEWS Connect app is fully configured for iOS:
- ✅ iOS project structure created
- ✅ Permissions configured for camera, microphone, files
- ✅ Bundle identifier set to `com.sews.connect`
- ✅ App icons and launch screens configured
- ✅ WebRTC video calling ready
- ✅ QR scanning functionality prepared
- ✅ Excel import system configured
- ✅ Industrial SEWS branding applied

**Next Step**: Transfer project to Mac and run `flutter build ios` to generate your iOS app!

## Support
- Flutter iOS Documentation: https://docs.flutter.dev/deployment/ios
- Apple Developer Documentation: https://developer.apple.com/documentation/
- WebRTC iOS Guidelines: https://webrtc.org/native-code/ios/
