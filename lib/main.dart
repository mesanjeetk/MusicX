import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Optimized Music Scanner',
      home: const MusicScannerPage(),
    );
  }
}

class MusicScannerPage extends StatefulWidget {
  const MusicScannerPage({super.key});

  @override
  State<MusicScannerPage> createState() => _MusicScannerPageState();
}

class _MusicScannerPageState extends State<MusicScannerPage> {
  List<FileSystemEntity> musicFiles = [];
  final List<String> validExtensions = ['mp3', 'wav', 'm4a', 'ogg'];

  final List<String> targetDirs = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Downloads',
    '/storage/emulated/0/Documents',
  ];

  @override
  void initState() {
    super.initState();
    requestPermissionAndScan();
  }

  Future<void> requestPermissionAndScan() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
  
    bool granted = false;
  
    if (sdkInt >= 33) {
      granted = await Permission.audio.request().isGranted;
    } else {
      granted = await Permission.storage.request().isGranted;
    }
  
    if (granted) {
      scanMultipleFolders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
    }
  }


  Future<void> scanMultipleFolders() async {
    List<FileSystemEntity> foundFiles = [];

    for (String path in targetDirs) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          final files = dir.listSync(recursive: true);
          for (var file in files) {
            if (file is File) {
              final ext = file.path.split('.').last.toLowerCase();
              if (validExtensions.contains(ext)) {
                foundFiles.add(file);
              }
            }
          }
        } catch (e) {
          debugPrint('Error scanning $path: $e');
        }
      }
    }

    setState(() {
      musicFiles = foundFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Found Audio Files")),
      body: musicFiles.isEmpty
          ? const Center(child: Text("No music files found"))
          : ListView.builder(
              itemCount: musicFiles.length,
              itemBuilder: (context, index) {
                final file = musicFiles[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(file.path.split('/').last),
                  subtitle: Text(file.path),
                );
              },
            ),
    );
  }
}
