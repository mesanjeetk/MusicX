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
      debugShowCheckedModeBanner: false,
      title: 'Music Scanner',
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initCacheAndLoad();
  }

  Future<void> initCacheAndLoad() async {
    final dir = await getApplicationDocumentsDirectory();
    cacheFile = File('${dir.path}/music_cache.json');

    if (await cacheFile.exists()) {
      try {
        final content = await cacheFile.readAsString();
        final List<dynamic> data = jsonDecode(content);
        setState(() {
          musicPaths = List<String>.from(data);
          isLoading = false;
        });
        debugPrint("Loaded ${musicPaths.length} songs from cache.");
      } catch (e) {
        debugPrint("Error reading cache: $e");
        await requestPermissionAndScan(); // fallback
      }
    } else {
      debugPrint("No cache file found. Scanning storage...");
      await requestPermissionAndScan();
    }
  }

  Future<void> requestPermissionAndScan() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    PermissionStatus status;
    if (sdkInt >= 33) {
      status = await Permission.audio.request();
    } else {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      await scanAndCacheMusic();
    } else {
      debugPrint("Permission denied.");
      if (!status.isPermanentlyDenied) {
        openAppSettings();
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> scanAndCacheMusic() async {
    debugPrint("Scanning entire storage for music...");
    List<String> foundPaths = [];
    final root = Directory('/storage/emulated/0');

    try {
      await for (FileSystemEntity entity in root.list(recursive: true)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (validExtensions.any((ext) => path.endsWith('.$ext'))) {
            foundPaths.add(entity.path);
          }
        }
      }
    } catch (e) {
      debugPrint("Error scanning storage: $e");
    }

    debugPrint("Scan complete. Found ${foundPaths.length} songs.");
    setState(() {
      musicPaths = foundPaths;
      isLoading = false;
    });

    try {
      await cacheFile.writeAsString(jsonEncode(foundPaths));
      debugPrint("Cache saved to: ${cacheFile.path}");
    } catch (e) {
      debugPrint("Failed to save cache: $e");
    }
  }

  Future<void> refreshManually() async {
    setState(() => isLoading = true);
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
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : musicPaths.isEmpty
              ? const Center(child: Text("No music files found."))
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
