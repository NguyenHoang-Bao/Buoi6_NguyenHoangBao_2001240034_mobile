import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const VideoRecorderApp());
}

class VideoRecorderApp extends StatelessWidget {
  const VideoRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Recorder & Playback',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const VideoRecorderHome(),
    );
  }
}

class VideoRecorderHome extends StatefulWidget {
  const VideoRecorderHome({super.key});

  @override
  State<VideoRecorderHome> createState() => _VideoRecorderHomeState();
}

class _VideoRecorderHomeState extends State<VideoRecorderHome> {
  File? _videoFile;
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();

  // Yêu cầu quyền
  Future<void> _requestPermission(Permission permission) async {
    try {
      if (await permission.isDenied) {
        await permission.request();
      }
    } catch (_) {}
  }

  // Chọn video từ gallery
  Future<void> _pickVideoFromGallery() async {
    try {
      await _requestPermission(Permission.videos);
      await _requestPermission(Permission.photos);
      await _requestPermission(Permission.storage);
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        _loadVideo(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi chọn video: $e')));
      }
    }
  }

  // Quay video từ camera
  Future<void> _recordVideoFromCamera() async {
    try {
      await _requestPermission(Permission.camera);
      await _requestPermission(Permission.microphone);
      final XFile? recordedFile = await _picker.pickVideo(
        source: ImageSource.camera,
      );
      if (recordedFile != null) {
        _loadVideo(File(recordedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi quay video: $e')));
      }
    }
  }

  // Tải và khởi tạo video
  void _loadVideo(File videoFile) {
    setState(() {
      _videoFile = videoFile;
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Recorder & Playback')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _videoController != null && _videoController!.value.isInitialized
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    )
                  : Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Center(
                        child: Text(
                          'Chưa có video nào được chọn.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              if (_videoController != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                      child: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: 240,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.video_library),
                  onPressed: _pickVideoFromGallery,
                  label: const Text('Chọn video từ Gallery'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 240,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videocam),
                  onPressed: _recordVideoFromCamera,
                  label: const Text('Quay video từ Camera'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
