import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MusicPlayerApp());
}

class SongItem {
  final String title;
  final String artist;
  final String duration;
  final String path;

  const SongItem({
    required this.title,
    required this.artist,
    required this.duration,
    required this.path,
  });
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF13071F),
        primaryColor: const Color(0xFFE91E63),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE91E63),
          secondary: Color(0xFFAB47BC),
        ),
      ),
      home: const MusicPlayerMainScreen(),
    );
  }
}

class MusicPlayerMainScreen extends StatefulWidget {
  const MusicPlayerMainScreen({super.key});

  @override
  State<MusicPlayerMainScreen> createState() => _MusicPlayerMainScreenState();
}

class _MusicPlayerMainScreenState extends State<MusicPlayerMainScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _rotationController;

  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _showPlaylist = false;

  final List<SongItem> _playlist = const [
    SongItem(
      title: 'Em Của Ngày Hôm Qua',
      artist: 'Sơn Tùng M-TP',
      duration: '3:45',
      path: 'audios/sample1.mp3',
    ),
    SongItem(
      title: 'Nơi Này Có Anh',
      artist: 'Sơn Tùng M-TP',
      duration: '4:20',
      path: 'audios/sample2.mp3',
    ),
    SongItem(
      title: 'Chúng Ta Của Hiện Tại',
      artist: 'Sơn Tùng M-TP',
      duration: '5:01',
      path: 'audios/sample3.mp3',
    ),
    SongItem(
      title: 'Lạc Trôi',
      artist: 'Sơn Tùng M-TP',
      duration: '3:50',
      path: 'audios/sample1.mp3',
    ),
    SongItem(
      title: 'Có Chắc Yêu Là Đây',
      artist: 'Sơn Tùng M-TP',
      duration: '3:22',
      path: 'audios/sample2.mp3',
    ),
    SongItem(
      title: 'Hãy Trao Cho Anh',
      artist: 'Sơn Tùng M-TP ft. Snoop Dogg',
      duration: '4:05',
      path: 'audios/sample3.mp3',
    ),
    SongItem(
      title: 'Muộn Rồi Mà Sao Còn',
      artist: 'Sơn Tùng M-TP',
      duration: '4:18',
      path: 'audios/sample1.mp3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (_isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      });
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() {
        _totalDuration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() {
        _currentPosition = p;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_isRepeat) {
        _playCurrentSong();
      } else {
        _nextSong();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _playCurrentSong() async {
    try {
      final song = _playlist[_currentIndex];
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(song.path));
      setState(() {
        _isPlaying = true;
      });
      _rotationController.repeat();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi phát âm thanh: $e')));
      }
    }
  }

  Future<void> _pauseSong() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
    _rotationController.stop();
  }

  Future<void> _stopSong() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });
    _rotationController.reset();
  }

  void _nextSong() {
    if (_isShuffle) {
      final rand = math.Random().nextInt(_playlist.length);
      setState(() {
        _currentIndex = rand;
      });
    } else {
      setState(() {
        if (_currentIndex < _playlist.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }
      });
    }
    _playCurrentSong();
  }

  void _previousSong() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        _currentIndex = _playlist.length - 1;
      }
    });
    _playCurrentSong();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = _playlist[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF13071F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _showPlaylist ? 'PLAYLIST' : 'ALBUM',
          style: const TextStyle(
            letterSpacing: 2,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showPlaylist ? Icons.music_note : Icons.queue_music),
            tooltip: _showPlaylist ? 'Trình phát' : 'Danh sách phát',
            onPressed: () {
              setState(() {
                _showPlaylist = !_showPlaylist;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A2A), Color(0xFF0F041A)],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showPlaylist
              ? _buildPlaylistView(currentSong)
              : _buildPlayerView(currentSong),
        ),
      ),
    );
  }

  // ===================== NOW PLAYING VIEW (SCREEN 1) =====================
  Widget _buildPlayerView(SongItem currentSong) {
    return Padding(
      key: const ValueKey('PlayerView'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Vinyl Disc artwork
          Center(
            child: RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF333333),
                      Color(0xFF1E1E1E),
                      Color(0xFF0A0A0A),
                      Color(0xFF222222),
                      Color(0xFF111111),
                    ],
                    stops: [0.0, 0.4, 0.7, 0.85, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF13071F),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _isPlaying ? Icons.music_note : Icons.play_arrow,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Title & Artist
          Column(
            children: [
              Text(
                currentSong.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currentSong.artist.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          // Progress Bar / Slider
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: const Color(0xFFE91E63),
                  inactiveTrackColor: Colors.white12,
                  thumbColor: const Color(0xFFE91E63),
                ),
                child: Slider(
                  min: 0.0,
                  max: _totalDuration.inSeconds > 0
                      ? _totalDuration.inSeconds.toDouble()
                      : 100.0,
                  value: _currentPosition.inSeconds.toDouble().clamp(
                    0.0,
                    (_totalDuration.inSeconds > 0
                        ? _totalDuration.inSeconds.toDouble()
                        : 100.0),
                  ),
                  onChanged: (val) {
                    _audioPlayer.seek(Duration(seconds: val.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _totalDuration.inSeconds > 0
                          ? _formatDuration(_totalDuration)
                          : currentSong.duration,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Controls (Shuffle, Prev, Play/Pause, Next, Repeat)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: _isShuffle ? const Color(0xFFE91E63) : Colors.white38,
                ),
                onPressed: () {
                  setState(() {
                    _isShuffle = !_isShuffle;
                  });
                },
              ),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: _previousSong,
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  ),
                ),
                child: IconButton(
                  iconSize: 42,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _pauseSong();
                    } else {
                      _playCurrentSong();
                    }
                  },
                ),
              ),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: _nextSong,
              ),
              IconButton(
                icon: Icon(
                  _isRepeat ? Icons.repeat_one : Icons.repeat,
                  color: _isRepeat ? const Color(0xFFE91E63) : Colors.white38,
                ),
                onPressed: () {
                  setState(() {
                    _isRepeat = !_isRepeat;
                  });
                },
              ),
            ],
          ),

          // Bottom Bar (Playlist Toggle & Stop)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white60),
                tooltip: 'Dừng phát',
                onPressed: _stopSong,
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: 'Danh sách bài hát',
                onPressed: () {
                  setState(() {
                    _showPlaylist = true;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== PLAYLIST VIEW (SCREEN 2) =====================
  Widget _buildPlaylistView(SongItem currentSong) {
    return Column(
      key: const ValueKey('PlaylistView'),
      children: [
        // Mini player bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF220E38),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE91E63),
                child: Icon(
                  _isPlaying ? Icons.music_note : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSong.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentSong.artist,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white70),
                onPressed: _previousSong,
              ),
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: const Color(0xFFE91E63),
                  size: 32,
                ),
                onPressed: () {
                  if (_isPlaying) {
                    _pauseSong();
                  } else {
                    _playCurrentSong();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white70),
                onPressed: _nextSong,
              ),
            ],
          ),
        ),

        // Song list
        Expanded(
          child: ListView.builder(
            itemCount: _playlist.length,
            itemBuilder: (context, index) {
              final song = _playlist[index];
              final isCurrent = index == _currentIndex;

              return Container(
                color: isCurrent
                    ? const Color(0xFFE91E63).withValues(alpha: 0.15)
                    : Colors.transparent,
                child: ListTile(
                  leading: SizedBox(
                    width: 30,
                    child: Text(
                      '${index + 1}.',
                      style: TextStyle(
                        color: isCurrent
                            ? const Color(0xFFE91E63)
                            : Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      color: isCurrent ? const Color(0xFFE91E63) : Colors.white,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: TextStyle(
                      color: isCurrent ? Colors.white70 : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.duration,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.more_vert,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                    _playCurrentSong();
                  },
                ),
              );
            },
          ),
        ),

        // Back to album button
        SafeArea(
          child: TextButton.icon(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            label: const Text(
              'Thu nhỏ danh sách',
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () {
              setState(() {
                _showPlaylist = false;
              });
            },
          ),
        ),
      ],
    );
  }
}
