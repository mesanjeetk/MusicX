import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';

class PermissionHandlerWidget extends StatefulWidget {
  final Widget child;
  
  const PermissionHandlerWidget({super.key, required this.child});

  @override
  State<PermissionHandlerWidget> createState() => _PermissionHandlerWidgetState();
}

class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  bool _hasEssentialPermissions = false;
  bool _isCheckingPermissions = true;
  List<Permission> _deniedPermissions = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isCheckingPermissions = true);
    
    final hasPermissions = await PermissionService.hasAllEssentialPermissions();
    final deniedPermissions = await PermissionService.getDeniedPermissions();
    
    setState(() {
      _hasEssentialPermissions = hasPermissions;
      _deniedPermissions = deniedPermissions;
      _isCheckingPermissions = false;
    });
  }

  Future<void> _requestSpecificPermission(Permission permission) async {
    // Check if permanently denied
    final isPermanentlyDenied = await PermissionService.isPermanentlyDenied(permission);
    
    if (isPermanentlyDenied) {
      final shouldOpenSettings = await PermissionService.showSettingsDialog(
        context,
        [permission],
      );
      
      if (shouldOpenSettings) {
        await openAppSettings();
        // Recheck permissions when user returns from settings
        _checkPermissions();
      }
      return;
    }

    // Show rationale if needed
    final shouldRequest = await PermissionService.showPermissionRationale(
      context,
      permission,
    );
    
    if (!shouldRequest) return;

    // Request the specific permission
    final result = await PermissionService.requestMissingPermissions([permission]);
    
    if (result[permission]?.isGranted ?? false) {
      // Remove from denied list and recheck
      _checkPermissions();
    } else if (result[permission]?.isPermanentlyDenied ?? false) {
      // Show settings dialog
      final shouldOpenSettings = await PermissionService.showSettingsDialog(
        context,
        [permission],
      );
      
      if (shouldOpenSettings) {
        await openAppSettings();
        _checkPermissions();
      }
    }
  }

  Future<void> _requestAllMissingPermissions() async {
    final permanentlyDenied = <Permission>[];
    final canRequest = <Permission>[];
    
    // Categorize denied permissions
    for (final permission in _deniedPermissions) {
      if (await PermissionService.isPermanentlyDenied(permission)) {
        permanentlyDenied.add(permission);
      } else {
        canRequest.add(permission);
      }
    }
    
    // Handle permanently denied permissions
    if (permanentlyDenied.isNotEmpty) {
      final shouldOpenSettings = await PermissionService.showSettingsDialog(
        context,
        permanentlyDenied,
      );
      
      if (shouldOpenSettings) {
        await openAppSettings();
        _checkPermissions();
        return;
      }
    }
    
    // Request permissions that can be requested
    if (canRequest.isNotEmpty) {
      final results = await PermissionService.requestMissingPermissions(canRequest);
      
      // Check if any became permanently denied
      final newlyPermanentlyDenied = <Permission>[];
      results.forEach((permission, status) {
        if (status.isPermanentlyDenied) {
          newlyPermanentlyDenied.add(permission);
        }
      });
      
      if (newlyPermanentlyDenied.isNotEmpty) {
        final shouldOpenSettings = await PermissionService.showSettingsDialog(
          context,
          newlyPermanentlyDenied,
        );
        
        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
      
      _checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade400, Colors.blue.shade800],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'Checking Permissions...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_hasEssentialPermissions) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade400, Colors.blue.shade800],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Permissions Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This app needs certain permissions to function properly. Please grant the required permissions.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Individual permission cards
                  ..._deniedPermissions.map((permission) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        leading: Icon(
                          _getPermissionIcon(permission),
                          color: Colors.orange,
                        ),
                        title: Text(
                          PermissionService.getPermissionName(permission),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          PermissionService.getPermissionDescription(permission),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _requestSpecificPermission(permission),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Grant'),
                        ),
                      ),
                    ),
                  )),
                  
                  const SizedBox(height: 24),
                  
                  // Grant all button
                  if (_deniedPermissions.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestAllMissingPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Grant All Permissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Refresh button
                  TextButton(
                    onPressed: _checkPermissions,
                    child: const Text(
                      'Refresh Permission Status',
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return Icons.folder;
      case Permission.audio:
        return Icons.volume_up;
      case Permission.notification:
        return Icons.notifications;
      default:
        return Icons.security;
    }
  }
}