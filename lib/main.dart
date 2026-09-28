import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const GDKaraokeApp());

class GDKaraokeApp extends StatelessWidget {
  const GDKaraokeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'GD Karaoke',
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(primary: Colors.white),
    ),
    home: const KaraokeHome(),
  );
}

class KaraokeHome extends StatefulWidget {
  const KaraokeHome({super.key});
  @override State<KaraokeHome> createState() => _KaraokeHomeState();
}

class _KaraokeHomeState extends State<KaraokeHome> {
  List<String> songs = [];
  String? current;
  VideoPlayerController? controller;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => songs = p.getStringList('songs') ?? []);
  }

  Future<void> _addMp4() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['mp4'],
      allowMultiple: true, withData: false,
    );
    if (result == null) return;
    final p = await SharedPreferences.getInstance();
    final paths = [...songs, ...result.files.map((f) => f.path).whereType<String>()];
    songs = paths.toSet().toList();
    await p.setStringList('songs', songs);
    setState(() {});
    if (result.files.isNotEmpty) _play(result.files.first.path);
  }

  Future<void> _play(String? path) async {
    if (path == null) return;
    await controller?.dispose();
    final c = VideoPlayerController.file(File(path));
    controller = c;
    try {
      await c.initialize();
      await c.play();
      if (mounted) setState(() => current = path);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to play this MP4 file.')));
    }
  }

  @override void dispose() { controller?.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final name = current?.split('/').last ?? 'GD KARAOKE';
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 GD KARAOKE'),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [IconButton(onPressed: _addMp4, icon: const Icon(Icons.usb))],
      ),
      body: Column(children: [
        Expanded(
          flex: 3,
          child: controller != null && controller!.value.isInitialized
            ? Center(child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!)))
            : const Center(child: Text('Connect USB OTG and select MP4 karaoke videos')),
        ),
        Padding(padding: const EdgeInsets.all(8), child: Text(name,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: () => controller?.seekTo(Duration.zero), icon: const Icon(Icons.replay)),
          IconButton(onPressed: () {
            if (controller == null) return;
            controller!.value.isPlaying ? controller!.pause() : controller!.play();
            setState(() {});
          }, icon: Icon(controller?.value.isPlaying == true ? Icons.pause : Icons.play_arrow, size: 38)),
        ]),
        const Divider(),
        Expanded(flex: 2, child: ListView.builder(
          itemCount: songs.length,
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.music_video),
            title: Text(songs[i].split('/').last),
            onTap: () => _play(songs[i]),
          ),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMp4, icon: const Icon(Icons.usb), label: const Text('ADD MP4')),
    );
  }
}
