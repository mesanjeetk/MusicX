import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DownloadMusicScanner(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DownloadMusicScanner extends StatefulWidget {
  const DownloadMusicScanner({super.key});

  @override
  State<DownloadMusicScanner> createState() => _DownloadMusicScannerState();
}

class _DownloadMusicScannerState extends State<DownloadMusicScanner> {
  List<FileSystemEntity> musicFiles = [];
  final List<String> validExtensions = ['mp3', 'wav', 'm4a', 'ogg'];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    scanDownloadFolder();
  }

  Future<void> scanDownloadFolder() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    PermissionStatus status;

    if (sdkInt >= 33) {
      status = await Permission.audio.request();
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      debugPrint("❌ Permission denied");
      setState(() => isLoading = false);
      return;
    }

    final dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      debugPrint("⚠️ Download directory does not exist");
      setState(() => isLoading = false);
      return;
    }

    final files = dir.listSync(recursive: true);
    final found = files.where((f) {
      final path = f.path.toLowerCase();
      return validExtensions.any((ext) => path.endsWith('.$ext'));
    }).toList();

    setState(() {
      musicFiles = found;
      isLoading = false;
    });

    debugPrint("✅ Found ${found.length} music files in /Download");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Download Music Files")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : musicFiles.isEmpty
              ? const Center(child: Text("No music files found in Download folder."))
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
