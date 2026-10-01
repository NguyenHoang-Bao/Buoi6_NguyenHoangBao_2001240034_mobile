import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const PhotoCaptureApp());
}

class PhotoCaptureApp extends StatelessWidget {
  const PhotoCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Capture & Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      home: const PhotoCaptureHome(),
    );
  }
}

class PhotoCaptureHome extends StatefulWidget {
  const PhotoCaptureHome({super.key});

  @override
  State<PhotoCaptureHome> createState() => _PhotoCaptureHomeState();
}

class _PhotoCaptureHomeState extends State<PhotoCaptureHome> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Yêu cầu quyền
  Future<void> _requestPermission(Permission permission) async {
    try {
      if (await permission.isDenied) {
        await permission.request();
      }
    } catch (_) {}
  }

  // Chọn ảnh từ gallery
  Future<void> _pickImageFromGallery() async {
    try {
      await _requestPermission(Permission.photos);
      await _requestPermission(Permission.storage);
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
      }
    }
  }

  // Chụp ảnh từ camera
  Future<void> _captureImageFromCamera() async {
    try {
      await _requestPermission(Permission.camera);
      final XFile? capturedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (capturedFile != null) {
        setState(() {
          _imageFile = File(capturedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi chụp ảnh: $e')));
      }
    }
  }

  // Xem trước ảnh toàn màn hình
  void _showFullScreenPreview(BuildContext context) {
    if (_imageFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImage(imageFile: _imageFile!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Capture & Preview')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _imageFile == null
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Chưa có ảnh nào được chọn.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _showFullScreenPreview(context),
                      child: Tooltip(
                        message: 'Nhấn để xem toàn màn hình',
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              _imageFile!,
                              height: 300,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  child: const Text('Chọn ảnh từ Gallery'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _captureImageFromCamera,
                  child: const Text('Chụp ảnh từ Camera'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget xem trước toàn màn hình
class FullScreenImage extends StatelessWidget {
  final File imageFile;

  const FullScreenImage({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Xem trước')),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(imageFile),
        ),
      ),
    );
  }
}
