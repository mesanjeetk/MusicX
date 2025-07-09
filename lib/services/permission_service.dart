import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static const List<Permission> _requiredPermissions = [
    Permission.storage,
    Permission.audio,
    Permission.notification,
  ];

  static const List<Permission> _android13Permissions = [
    Permission.audio,
    Permission.notification,
  ];

  /// Check all required permissions status
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    final Map<Permission, PermissionStatus> permissionStatuses = {};
    
    for (final permission in _requiredPermissions) {
      permissionStatuses[permission] = await permission.status;
    }
    
    return permissionStatuses;
  }

  /// Request specific permissions that are not granted
  static Future<Map<Permission, PermissionStatus>> requestMissingPermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  /// Check if all essential permissions are granted
  static Future<bool> hasAllEssentialPermissions() async {
    final statuses = await checkAllPermissions();
    
    // Check storage permission (essential for music scanning)
    final storageGranted = statuses[Permission.storage]?.isGranted ?? false;
    
    // Check audio permission (essential for playback)
    final audioGranted = statuses[Permission.audio]?.isGranted ?? false;
    
    return storageGranted && audioGranted;
  }

  /// Get list of denied permissions
  static Future<List<Permission>> getDeniedPermissions() async {
    final statuses = await checkAllPermissions();
    final deniedPermissions = <Permission>[];
    
    statuses.forEach((permission, status) {
      if (status.isDenied || status.isPermanentlyDenied) {
        deniedPermissions.add(permission);
      }
    });
    
    return deniedPermissions;
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Get user-friendly permission name
  static String getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return 'Storage Access';
      case Permission.audio:
        return 'Audio Access';
      case Permission.notification:
        return 'Notifications';
      default:
        return permission.toString().split('.').last;
    }
  }

  /// Get permission description for user
  static String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return 'Required to scan and access music files on your device';
      case Permission.audio:
        return 'Required to play music and control audio playback';
      case Permission.notification:
        return 'Required to show playback controls in notifications';
      default:
        return 'Required for app functionality';
    }
  }

  /// Show permission rationale dialog
  static Future<bool> showPermissionRationale(
    BuildContext context,
    Permission permission,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('${getPermissionName(permission)} Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(getPermissionDescription(permission)),
            const SizedBox(height: 16),
            const Text(
              'This permission is essential for the app to function properly.',
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

  /// Show settings dialog for permanently denied permissions
  static Future<bool> showSettingsDialog(
    BuildContext context,
    List<Permission> permanentlyDeniedPermissions,
  ) async {
    final permissionNames = permanentlyDeniedPermissions
        .map((p) => getPermissionName(p))
        .join(', ');
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The following permissions were permanently denied: $permissionNames',
            ),
            const SizedBox(height: 16),
            const Text(
              'Please enable these permissions in Settings to use the app.',
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
}