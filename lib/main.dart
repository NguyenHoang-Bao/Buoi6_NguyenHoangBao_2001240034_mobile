import 'package:flutter/material.dart';

import 'bai1_media_picker/media_picker_app.dart';
import 'bai2_photo_capture/photo_capture_app.dart';
import 'bai3_sms_contacts/sms_contacts_app.dart';
import 'bai4_video_recorder/video_recorder_app.dart';
import 'bai5_contact_management/contact_management_app.dart';
import 'bai6_music_player/music_player_app.dart';
import 'bai7_sms_analyzer/sms_analyzer_app.dart';

void main() {
  runApp(const MultimediaHubApp());
}

class MultimediaHubApp extends StatelessWidget {
  const MultimediaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buổi 06 - Multimedia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const ExerciseDirectoryScreen(),
    );
  }
}

class ExerciseDirectoryScreen extends StatelessWidget {
  const ExerciseDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = [
      _ExerciseItem(
        title: 'Bài tập 1: Media Picker App',
        subtitle: 'Chọn ảnh/video từ gallery, chụp/quay từ camera & hiển thị',
        badge: 'Hướng dẫn (Trang 6-14)',
        icon: Icons.perm_media,
        color: Colors.blue,
        screen: const MediaPickerHome(),
      ),
      _ExerciseItem(
        title: 'Bài tập 2: Photo Capture & Preview',
        subtitle:
            'Chụp ảnh hoặc chọn từ gallery, xem trước toàn màn hình khi chạm',
        badge: 'Hướng dẫn (Trang 15-18)',
        icon: Icons.fullscreen,
        color: Colors.teal,
        screen: const PhotoCaptureHome(),
      ),
      _ExerciseItem(
        title: 'Bài tập 3: SMS & Contacts Reader',
        subtitle: 'Đọc và hiển thị danh sách tin nhắn SMS & danh bạ thiết bị',
        badge: 'Hướng dẫn (Trang 19-25)',
        icon: Icons.contact_phone,
        color: Colors.blueAccent,
        screen: const MainHomePage(),
      ),
      _ExerciseItem(
        title: 'Bài tập 4: Video Recorder & Playback',
        subtitle: 'Quay video từ camera hoặc chọn từ gallery, phát video với Play/Pause',
        badge: 'Tại lớp (Trang 25-28)',
        icon: Icons.video_collection,
        color: Colors.purple,
        screen: const VideoRecorderHome(),
      ),
      _ExerciseItem(
        title: 'Bài tập 5: Quản lý và thêm danh bạ',
        subtitle: 'Danh sách danh bạ có ảnh đại diện, nút + thêm danh bạ mới',
        badge: 'Tại lớp (Trang 28-33)',
        icon: Icons.contacts,
        color: Colors.cyan,
        screen: const ContactsListScreen(),
      ),
      _ExerciseItem(
        title: 'Bài tập 6: Ứng dụng nghe nhạc',
        subtitle: 'Giao diện nghe nhạc đĩa than quay, Timeline, Playlist (theo ảnh trang 37)',
        badge: 'Về nhà (Trang 33-37)',
        icon: Icons.music_note,
        color: const Color(0xFFE91E63),
        screen: const MusicPlayerMainScreen(),
      ),
      _ExerciseItem(
        title: 'Bài tập 7: SMS Analyzer',
        subtitle: 'Thống kê tin nhắn, lọc SĐT, ngày/tháng, lọc [QC], lọc [OTP] & trích xuất mã 6 số',
        badge: 'Về nhà (Trang 37)',
        icon: Icons.analytics,
        color: Colors.indigo,
        screen: const SmsAnalyzerScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BÀI 06: MULTIMEDIA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          // Banner giới thiệu sinh viên
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.amber, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Lập trình di động - Buổi 06',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Chủ đề: Multimedia & Tài nguyên thiết bị (Camera, Gallery, Video, Audio, Contacts, SMS)',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Đầy đủ các bài tập từ Bài 1 đến Bài 7 theo yêu cầu tài liệu PDF.',
                    style: TextStyle(
                      color: Colors.lightGreenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Danh sách bài tập
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final ex = exercises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ex.screen),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: ex.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(ex.icon, color: ex.color, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ex.color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ex.badge,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: ex.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ex.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  ex.subtitle,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: exercises.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _ExerciseItem {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final Widget screen;

  _ExerciseItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
