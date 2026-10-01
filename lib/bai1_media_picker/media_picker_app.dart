import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MediaPickerApp());
}

class MediaPickerApp extends StatelessWidget {
  const MediaPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Picker App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MediaPickerHome(),
    );
  }
}

class MediaPickerHome extends StatefulWidget {
  const MediaPickerHome({super.key});

  @override
  State<MediaPickerHome> createState() => _MediaPickerHomeState();
}

class _MediaPickerHomeState extends State<MediaPickerHome> {
  File? _mediaFile; // Lưu trữ file media (image hoặc video)
  VideoPlayerController? _videoController; // Điều khiển phát video
  final ImagePicker _picker = ImagePicker(); // Khởi tạo ImagePicker

  // Kiểm tra và yêu cầu quyền truy cập
  Future<void> _requestPermission(Permission permission) async {
    try {
      if (await permission.isDenied) {
        await permission.request();
      }
    } catch (_) {}
  }

  // Chọn ảnh hoặc video từ gallery
  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    try {
      if (isVideo) {
        await _requestPermission(Permission.videos);
        await _requestPermission(Permission.storage);
      } else {
        await _requestPermission(Permission.photos);
        await _requestPermission(Permission.storage);
      }

      final XFile? pickedFile = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(
              source: source,
              imageQuality: 100,
              maxWidth: 1920,
              maxHeight: 1080,
            );

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile.path);
          if (isVideo || _mediaFile!.path.toLowerCase().endsWith('.mp4')) {
            _videoController?.dispose();
            _videoController = VideoPlayerController.file(_mediaFile!)
              ..initialize().then((_) {
                setState(() {});
                _videoController!.play();
              });
          } else {
            _videoController?.dispose();
            _videoController = null;
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No media selected')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi chọn media: $e')));
      }
    }
  }

  // Chụp ảnh hoặc quay video từ camera
  Future<void> _captureMedia(bool isVideo) async {
    try {
      await _requestPermission(Permission.camera);
      if (isVideo) {
        await _requestPermission(Permission.microphone);
      }

      final XFile? capturedFile = isVideo
          ? await _picker.pickVideo(source: ImageSource.camera)
          : await _picker.pickImage(source: ImageSource.camera);

      if (capturedFile != null) {
        setState(() {
          _mediaFile = File(capturedFile.path);
          if (isVideo) {
            _videoController?.dispose();
            _videoController = VideoPlayerController.file(_mediaFile!)
              ..initialize().then((_) {
                setState(() {});
                _videoController!.play();
              });
          } else {
            _videoController?.dispose();
            _videoController = null;
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No media captured')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi chụp/quay media: $e')));
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Picker App')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30, width: 30),
              _mediaFile == null
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Chưa chọn ảnh hoặc video.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : _videoController != null &&
                        _videoController!.value.isInitialized
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _mediaFile!,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () => _pickMedia(ImageSource.gallery, false),
                  child: const Text('Chọn ảnh từ Gallery'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () => _captureMedia(false),
                  child: const Text('Chụp ảnh từ Camera'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () => _pickMedia(ImageSource.gallery, true),
                  child: const Text('Chọn video từ Gallery'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () => _captureMedia(true),
                  child: const Text('Quay video từ Camera'),
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
