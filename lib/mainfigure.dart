import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class MainFigurePage extends StatefulWidget {
  final String figureId;
  final String figureName;
  const MainFigurePage({
    Key? key,
    required this.figureId,
    required this.figureName,
  }) : super(key: key);

  @override
  _MainFigurePageState createState() => _MainFigurePageState();
}

class _MainFigurePageState extends State<MainFigurePage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? figure;
  VideoPlayerController? _videoController;
  VoidCallback? _videoListener;

  // Animations (mirroring FigurePage)
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    fetchFigure();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);

    // Show floating info button with a small delay (like FigurePage)
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showFloatingButton = true);
    });
  }

  Future<void> fetchFigure() async {
    try {
      final response = await supabase
          .from('dance_figures')
          .select()
          .eq('id', widget.figureId)
          .single();

      final videoUrl = response['video_url'] as String?;
      setState(() {
        figure = response;
      });

      if (videoUrl != null && videoUrl.isNotEmpty) {
        _videoController = VideoPlayerController.network(videoUrl)
          ..initialize().then((_) {
            if (mounted) setState(() {});
          });
        _videoListener = () {
          // Add any end-of-video logic here if desired
        };
        _videoController?.addListener(_videoListener!);
      }
    } catch (e) {
      // Optionally handle errors (show a toast/snackbar)
      setState(() {
        figure = {}; // avoid null checks later
      });
    }
  }

  @override
  void dispose() {
    if (_videoListener != null) {
      _videoController?.removeListener(_videoListener!);
    }
    _videoController?.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = (figure == null);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5D4037),
                  Color(0xFFD7A86E),
                  Color(0xFF263238),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Animated background elements
          Positioned(
            top: 80,
            right: -100,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale =
                    1.0 + (0.1 * (_pulseController.value * 2 - 1).abs());
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.amber.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _pulseController.value * 0.5,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.orange.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Background pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/indakbg2.jpg', fit: BoxFit.cover),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: CustomScrollView(
                      slivers: [
                        // Top: Back + Title chip
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      onPressed: () {
                                        if (_videoController != null &&
                                            _videoController!.value.isPlaying) {
                                          _videoController!.pause();
                                        }
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.shade700,
                                        Colors.amber.shade500,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.sports_gymnastics,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          widget.figureName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Video section
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      color: Colors.black,
                                      child: (!_isVideoReady && !isLoading)
                                          ? Container(
                                              height: 260,
                                              color: Colors.black12,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : (_videoController != null &&
                                                  _videoController!
                                                      .value.isInitialized)
                                              ? Stack(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  children: [
                                                    AspectRatio(
                                                      aspectRatio:
                                                          _videoController!
                                                              .value
                                                              .aspectRatio,
                                                      child: VideoPlayer(
                                                          _videoController!),
                                                    ),
                                                    Positioned(
                                                      left: 0,
                                                      right: 0,
                                                      bottom: 0,
                                                      child:
                                                          VideoProgressIndicator(
                                                        _videoController!,
                                                        allowScrubbing: true,
                                                        colors:
                                                            VideoProgressColors(
                                                          playedColor:
                                                              Colors.amber,
                                                          backgroundColor:
                                                              Colors.white
                                                                  .withOpacity(
                                                                      0.3),
                                                          bufferedColor: Colors
                                                              .amber.shade200,
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      right: 16,
                                                      bottom: 16,
                                                      child:
                                                          FloatingActionButton(
                                                        heroTag:
                                                            'mainfigure_video_btn',
                                                        mini: true,
                                                        backgroundColor:
                                                            Colors.black54,
                                                        onPressed: () {
                                                          setState(() {
                                                            _videoController!
                                                                    .value
                                                                    .isPlaying
                                                                ? _videoController!
                                                                    .pause()
                                                                : _videoController!
                                                                    .play();
                                                          });
                                                        },
                                                        child: Icon(
                                                          _videoController!
                                                                  .value
                                                                  .isPlaying
                                                              ? Icons.pause
                                                              : Icons
                                                                  .play_arrow,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Container(
                                                  height: 260,
                                                  color: Colors.black12,
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),

                        // Bottom padding
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 100),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Floating info button
          if (_showFloatingButton && !isLoading)
            Positioned(
              bottom: 30,
              right: 20,
              child: AnimatedScale(
                scale: _showFloatingButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: FloatingActionButton(
                  heroTag: 'mainfigure_info_btn',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildQuickInfoSheet(),
                    );
                  },
                  backgroundColor: Colors.amber.shade600,
                  child: const Icon(Icons.info_outline, color: Colors.white),
                ),
              ),
            ),

          // Center loading while waiting for Supabase
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  bool get _isVideoReady =>
      _videoController != null && _videoController!.value.isInitialized;

  // ============== Quick Info Sheet (kept) ==============

  Widget _buildQuickInfoSheet() {
    final uploader = (figure?['uploader'] ?? '').toString(); // optional
    final difficulty = (figure?['difficulty'] ?? '').toString(); // optional
    final duration = (figure?['duration'] ?? '').toString(); // optional

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.amber.shade400],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.sports_gymnastics, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Figure Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.title, 'Figure', widget.figureName),
                const SizedBox(height: 12),
                if (uploader.isNotEmpty)
                  _buildInfoRow(Icons.person, 'Uploader', uploader),
                if (uploader.isNotEmpty) const SizedBox(height: 12),
                if (difficulty.isNotEmpty)
                  _buildInfoRow(Icons.fitness_center, 'Difficulty', difficulty),
                if (difficulty.isNotEmpty) const SizedBox(height: 12),
                if (duration.isNotEmpty)
                  _buildInfoRow(Icons.timer, 'Duration', duration),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.brown.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.brown.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.brown.shade800,
            ),
          ),
        ),
      ],
    );
  }
}
