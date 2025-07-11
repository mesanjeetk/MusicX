import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Music Scanner with Cache',
      home: MusicScannerPage(),
    );
  }
}

class MusicScannerPage extends StatefulWidget {
  const MusicScannerPage({super.key});
  @override
  State<MusicScannerPage> createState() => _MusicScannerPageState();
}

class _MusicScannerPageState extends State<MusicScannerPage> {
  List<String> musicPaths = [];
  final List<String> validExtensions = ['mp3', 'wav', 'm4a', 'ogg'];
  late File cacheFile;

  @override
  void initState() {
    super.initState();
    initCacheAndLoad();
  }

  Future<void> initCacheAndLoad() async {
    final dir = await getApplicationDocumentsDirectory();
    cacheFile = File('${dir.path}/music_cache.json');

    if (await cacheFile.exists()) {
      final content = await cacheFile.readAsString();
      final List<dynamic> data = jsonDecode(content);
      setState(() {
        musicPaths = List<String>.from(data);
      });
    } else {
      requestPermissionAndScan();
    }
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
      scanAndCacheMusic();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
    }
  }

  Future<void> scanAndCacheMusic() async {
    List<String> foundPaths = [];

    final root = Directory('/storage/emulated/0');

    try {
      await for (FileSystemEntity entity
          in root.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (validExtensions.any((ext) => path.endsWith('.$ext'))) {
            foundPaths.add(entity.path);
          }
        }
      }
    } catch (e) {
      debugPrint("Error scanning: $e");
    }

    // Save to state and cache
    setState(() {
      musicPaths = foundPaths;
    });

    await cacheFile.writeAsString(jsonEncode(musicPaths));
  }

  Future<void> refreshManually() async {
    await scanAndCacheMusic();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Music list refreshed")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Music Files"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshManually,
          )
        ],
      ),
      body: musicPaths.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: musicPaths.length,
              itemBuilder: (context, index) {
                final path = musicPaths[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(path.split('/').last),
                  subtitle: Text(path),
                );
              },
            ),
    );
  }
}
