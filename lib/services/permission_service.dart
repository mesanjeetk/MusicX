import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  /// Final correct list:
  /// ✅ READ_EXTERNAL_STORAGE → Permission.storage (for Android < 10)
  /// ✅ READ_MEDIA_AUDIO → Permission.audio (maps to microphone — not correct!)
  /// 👉 So use only Permission.storage + Permission.notification + microphone if recording!
  static const List<Permission> _requiredPermissions = [
    Permission.storage, // For older Androids (READ_EXTERNAL_STORAGE)
    Permission.notification, // POST_NOTIFICATIONS
    Permission.microphone, // RECORD_AUDIO — only if you use mic!
  ];

  /// Checks all required
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    final statuses = <Permission, PermissionStatus>{};
    for (final permission in _requiredPermissions) {
      statuses[permission] = await permission.status;
    }
    return statuses;
  }

  /// Check if all essentials granted
  static Future<bool> hasAllEssentialPermissions() async {
    final statuses = await checkAllPermissions();
    final storageGranted = statuses[Permission.storage]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    // If you don’t record, ignore micGranted
    return storageGranted; // Only storage is essential for music scanning
  }

  /// Get denied list
  static Future<List<Permission>> getDeniedPermissions() async {
    final statuses = await checkAllPermissions();
    final denied = <Permission>[];
    statuses.forEach((permission, status) {
      if (status.isDenied || status.isPermanentlyDenied) {
        denied.add(permission);
      }
    });
    return denied;
  }

  /// Request missing
  static Future<Map<Permission, PermissionStatus>> requestMissingPermissions(
      List<Permission> permissions) async {
    return permissions.request();
  }

  /// Check permanently denied
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Rationale
  static Future<bool> showPermissionRationale(
      BuildContext context, Permission permission) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('${getPermissionName(permission)} Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(getPermissionDescription(permission)),
            const SizedBox(height: 16),
            const Text(
              'This permission is needed for the app to work properly.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show settings dialog
  static Future<bool> showSettingsDialog(
      BuildContext context, List<Permission> perms) async {
    final names = perms.map(getPermissionName).join(', ');
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The following permissions were permanently denied: $names'),
            const SizedBox(height: 16),
            const Text(
              'Please open settings to grant them.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Friendly name
  static String getPermissionName(Permission p) {
    switch (p) {
      case Permission.storage:
        return 'Storage Access';
      case Permission.microphone:
        return 'Microphone Access';
      case Permission.notification:
        return 'Notifications';
      default:
        return p.toString().split('.').last;
    }
  }

  /// Friendly description
  static String getPermissionDescription(Permission p) {
    switch (p) {
      case Permission.storage:
        return 'Needed to scan and access your music files.';
      case Permission.microphone:
        return 'Needed to record audio or capture mic input.';
      case Permission.notification:
        return 'Needed to show playback controls in the notification bar.';
      default:
        return 'Required for app functionality.';
    }
  }
}
