import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  // Common permissions that may be needed by the app
  static final List<Permission> requiredCommonPermissions = [
    Permission.notification,
  ];

  /// Request audio/storage permission depending on Android version
  static Future<bool> requestMediaPermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    final permission = sdkInt >= 33 ? Permission.audio : Permission.storage;
    final status = await permission.request();

    return status.isGranted;
  }
  
  static Future<bool> hasMediaPermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    final permission = sdkInt >= 33 ? Permission.audio : Permission.storage;
    return permission.isGranted;
  }

  /// Request notification permission if necessary (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    // No need to request notification permission below Android 13
    return true;
  }

  /// Request multiple permissions in one go
  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  /// Utility method to check and request all required permissions
  static Future<bool> ensureAllPermissions() async {
    final mediaGranted = await requestMediaPermission();
    final notificationGranted = await requestNotificationPermission();

    return mediaGranted && notificationGranted;
  }
}
