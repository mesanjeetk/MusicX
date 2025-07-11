import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  /// Only real permissions — no fake mediaAudio
  static const List<Permission> _requiredPermissions = [
    Permission.storage,
    Permission.audio, // mic / playback
    Permission.notification, // for playback notifications
  ];

  /// Check all required permissions
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    final statuses = <Permission, PermissionStatus>{};
    for (final permission in _requiredPermissions) {
      statuses[permission] = await permission.status;
    }
    return statuses;
  }

  /// Check if all essential permissions are granted
  static Future<bool> hasAllEssentialPermissions() async {
    final statuses = await checkAllPermissions();
    final storageGranted = statuses[Permission.storage]?.isGranted ?? false;
    final audioGranted = statuses[Permission.audio]?.isGranted ?? false;
    return storageGranted && audioGranted;
  }

  /// Get list of denied permissions
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

  /// Request specific
  static Future<Map<Permission, PermissionStatus>> requestMissingPermissions(
      List<Permission> permissions) async {
    return permissions.request();
  }

  /// Check if permanently denied
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Show rationale
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

  /// Show settings dialog for permanently denied
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

  /// User-friendly names
  static String getPermissionName(Permission p) {
    switch (p) {
      case Permission.storage:
        return 'Storage Access';
      case Permission.audio:
        return 'Audio Access';
      case Permission.notification:
        return 'Notifications';
      default:
        return p.toString().split('.').last;
    }
  }

  /// User-friendly description
  static String getPermissionDescription(Permission p) {
    switch (p) {
      case Permission.storage:
        return 'Needed to scan and access your music files.';
      case Permission.audio:
        return 'Needed to play music and handle audio playback.';
      case Permission.notification:
        return 'Needed to show playback controls in the notification bar.';
      default:
        return 'Required for app functionality.';
    }
  }
}
