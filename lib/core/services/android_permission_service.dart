import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Android 11+ permission handler for WebRTC
class AndroidPermissionService {
  static bool _permissionsInitialized = false;
  
  /// Initialize and request all necessary permissions for Android 11+
  static Future<bool> initializePermissionsForWebRTC() async {
    if (_permissionsInitialized) return true;
    
    try {
      debugPrint('🔐 Initializing Android 11+ permissions for WebRTC...');
      
      // Get Android version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final androidVersion = androidInfo.version.sdkInt;
      
      debugPrint('📱 Android SDK: $androidVersion');
      
      // List of permissions needed for WebRTC on Android 11+
      List<Permission> permissionsToRequest = [
        Permission.camera,
        Permission.microphone,
      ];
      
      // Add Android 11+ specific permissions
      if (androidVersion >= 31) { // Android 12+
        permissionsToRequest.addAll([
          Permission.bluetoothConnect,
        ]);
      }
      
      // Request all permissions at once
      debugPrint('🔐 Requesting ${permissionsToRequest.length} permissions...');
      Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();
      
      // Check results
      bool allGranted = true;
      for (var entry in statuses.entries) {
        final permission = entry.key;
        final status = entry.value;
        
        debugPrint('  ${permission.toString()}: ${status.toString()}');
        
        if (status != PermissionStatus.granted) {
          if (status == PermissionStatus.permanentlyDenied) {
            debugPrint('⚠️ ${permission.toString()} permanently denied - user must enable in settings');
          } else {
            debugPrint('❌ ${permission.toString()} not granted: $status');
            allGranted = false;
          }
        }
      }
      
      _permissionsInitialized = allGranted;
      
      if (allGranted) {
        debugPrint('✅ All WebRTC permissions granted for Android $androidVersion');
      } else {
        debugPrint('⚠️ Some WebRTC permissions not granted - functionality may be limited');
      }
      
      return allGranted;
      
    } catch (e) {
      debugPrint('❌ Error requesting Android permissions: $e');
      return false;
    }
  }
  
  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }
  
  /// Check if microphone permission is granted
  static Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }
  
  /// Request camera permission specifically
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }
  
  /// Request microphone permission specifically
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }
  
  /// Open app settings if permissions are permanently denied
  static Future<void> openSettings() async {
    await openAppSettings();
  }
  
  /// Get detailed permission status for debugging
  static Future<Map<String, String>> getPermissionStatus() async {
    final Map<String, String> status = {};
    
    status['camera'] = (await Permission.camera.status).toString();
    status['microphone'] = (await Permission.microphone.status).toString();
    
    // Check Android version for Bluetooth permissions
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      if (androidInfo.version.sdkInt >= 31) {
        status['bluetoothConnect'] = (await Permission.bluetoothConnect.status).toString();
      } else {
        status['bluetooth_note'] = 'Android version < 12, Bluetooth permissions not required';
      }
    } catch (e) {
      status['bluetooth_error'] = e.toString();
    }
    
    return status;
  }
}
