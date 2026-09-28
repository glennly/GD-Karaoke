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
    await c.initialize();
    await c.play();
    setState(() => current = path);
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
            : const Center(child: Text('Connect USB OTG and add MP4 karaoke videos')),
        ),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: () => controller?.seekTo(Duration.zero), icon: const Icon(Icons.replay)),
          IconButton(onPressed: () => controller?.value.isPlaying == true ? controller?.pause() : controller?.play(),
            icon: const Icon(Icons.play_arrow, size: 38)),
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
        onPressed: _addMp4, icon: const Icon(Icons.add), label: const Text('ADD MP4')),
    );
  }
}
