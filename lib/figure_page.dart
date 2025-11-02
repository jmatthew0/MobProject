import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:camera/camera.dart';
import 'camera_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';

class FigurePage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final String figureJsonFile;

  const FigurePage({
    Key? key,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.figureJsonFile,
  }) : super(key: key);

  @override
  _FigurePageState createState() => _FigurePageState();
}

class _FigurePageState extends State<FigurePage> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  VoidCallback? _videoListener;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _recordButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _recordButtonAnimation;
  late Animation<Color?> _recordButtonColorAnimation;
  bool _showFloatingButton = false;

  List<Map<String, dynamic>> _latestScores = [];
  int _highestScore = 0;
  bool _loadingScores = true;
  bool _showAllHistory = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupVideoController();
    _fetchUserHistory();
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
    _recordButtonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _recordButtonAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _recordButtonController, curve: Curves.easeInOut),
    );
    _recordButtonColorAnimation = ColorTween(
      begin: Colors.red.shade600,
      end: Colors.red.shade800,
    ).animate(_recordButtonController);

    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _recordButtonController.repeat(reverse: true);

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showFloatingButton = true);
      }
    });
  }

  void _setupVideoController() {
    _videoController = VideoPlayerController.asset(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
    _videoListener = () {
      if (_videoController != null &&
          _videoController!.value.position ==
              _videoController!.value.duration) {
        if (mounted) {
          setState(() {
            // Video ended logic
          });
        }
      }
    };
    _videoController?.addListener(_videoListener!);
  }

  @override
  void dispose() {
    if (_videoListener != null) {
      _videoController?.removeListener(_videoListener!);
    }
    _videoController?.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _recordButtonController.dispose();
    super.dispose();
  }

  Future<void> _navigateToCameraPage() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showCustomSnackBar(
            'No cameras available', Icons.camera_alt, Colors.red);
        return;
      }
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPage(
            camera: frontCamera,
            figureJsonFile: widget.figureJsonFile,
            videoUrl: widget.videoUrl,
          ),
        ),
      );
    } catch (e) {
      _showCustomSnackBar('Error accessing camera', Icons.error, Colors.red);
    }
  }

  void _showCustomSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _fetchUserHistory() async {
    setState(() {
      _loadingScores = true;
    });
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _latestScores = [];
        _highestScore = 0;
        _loadingScores = false;
      });
      return;
    }
    final figureFile = widget.figureJsonFile;
    String danceName = '';
    if (figureFile.toLowerCase().startsWith('tiklostut')) {
      danceName = 'Tiklos: Step-by-Step';
    } else if (figureFile.toLowerCase().startsWith('tiklos')) {
      danceName = 'Tiklos';
    } else if (figureFile.toLowerCase().startsWith('binungey')) {
      danceName = 'Binungey';
    } else if (figureFile.toLowerCase().startsWith('pahid')) {
      danceName = 'Pahid';
    } else if (figureFile.toLowerCase().startsWith('suakusua')) {
      danceName = 'Sua Ku Sua';
    }
    final uri = Uri.parse(
        'https://flipino-be.onrender.com/user_history?user_id=$userId&dance_name=${Uri.encodeComponent(danceName)}&figure_name=${Uri.encodeComponent(figureFile)}');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final filteredScores =
            List<Map<String, dynamic>>.from(data['latest_scores'])
                .where((score) =>
                    score['dance_name'] == danceName &&
                    score['figure_name'] == figureFile)
                .toList();
        // Sort by attempted_at descending and take latest 10
        filteredScores.sort((a, b) => b['attempted_at']
            .toString()
            .compareTo(a['attempted_at'].toString()));
        final latest10 = filteredScores.take(10).toList();
        setState(() {
          _latestScores = latest10;
          _highestScore = filteredScores.isNotEmpty
              ? filteredScores
                  .map((s) => s['score'] as int)
                  .reduce((a, b) => a > b ? a : b)
              : 0;
          _loadingScores = false;
        });
      } else {
        setState(() {
          _latestScores = [];
          _highestScore = 0;
          _loadingScores = false;
        });
      }
    } catch (e) {
      setState(() {
        _latestScores = [];
        _highestScore = 0;
        _loadingScores = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
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
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
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
                    child: RefreshIndicator(
                      onRefresh: _fetchUserHistory,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Title section
                          SliverToBoxAdapter(
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 10, 20, 20),
                              child: Column(
                                children: [
                                  // Back button row
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back,
                                            color: Colors.white, size: 40),
                                        onPressed: () {
                                          if (_videoController != null &&
                                              _videoController!
                                                  .value.isPlaying) {
                                            _videoController!.pause();
                                          }
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Title
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
                                        Icon(
                                          Icons.sports_gymnastics,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            widget.title,
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
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
                                        child: (_videoController != null &&
                                                _videoController!
                                                    .value.isInitialized)
                                            ? Stack(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                children: [
                                                  AspectRatio(
                                                    aspectRatio:
                                                        _videoController!
                                                            .value.aspectRatio,
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
                                                        backgroundColor: Colors
                                                            .white
                                                            .withOpacity(0.3),
                                                        bufferedColor: Colors
                                                            .amber.shade200,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: 16,
                                                    bottom: 16,
                                                    child: FloatingActionButton(
                                                      heroTag:
                                                          'figure_video_btn',
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
                                                                .value.isPlaying
                                                            ? Icons.pause
                                                            : Icons.play_arrow,
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
                                                        CircularProgressIndicator()),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                          // Description section (if provided)
                          if (widget.description.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildEnhancedInfoCard(
                                  context,
                                  'Description',
                                  widget.description,
                                  Icons.description,
                                ),
                              ),
                            ),
                          // Record Dance Button
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              child: AnimatedBuilder(
                                animation: _recordButtonAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _recordButtonAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        gradient: LinearGradient(
                                          colors: [
                                            _recordButtonColorAnimation.value ??
                                                Colors.red.shade600,
                                            Colors.red.shade400,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          onTap: _navigateToCameraPage,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16, horizontal: 32),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.videocam,
                                                    color: Colors.white,
                                                    size: 28),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Record Dance',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Dance History Section
                          SliverToBoxAdapter(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildHistorySection(),
                            ),
                          ),
                          // Bottom padding
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Floating action button
          if (_showFloatingButton)
            Positioned(
              bottom: 30,
              right: 20,
              child: AnimatedScale(
                scale: _showFloatingButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: FloatingActionButton(
                  heroTag: 'figure_info_btn',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildQuickInfoSheet(),
                    );
                  },
                  backgroundColor: Colors.amber.shade600,
                  child: Icon(Icons.info_outline, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoCard(
      BuildContext context, String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        shadowColor: Colors.black.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.amber.shade700, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.brown.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_loadingScores) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Colors.amber.shade600),
              const SizedBox(height: 16),
              Text(
                'Loading dance history...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        shadowColor: Colors.black.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.history,
                          color: Colors.purple.shade700, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Dance History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_highestScore > 0)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade600,
                                Colors.amber.shade400
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Best: $_highestScore%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_latestScores.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No dance attempts yet.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...List.generate(
                    _showAllHistory
                        ? _latestScores.length
                        : (_latestScores.length > 5 ? 5 : _latestScores.length),
                    (index) {
                      final score = _latestScores[index];
                      final scoreValue = score['score'] as int;
                      final timestamp = score['attempted_at']
                          .toString()
                          .substring(0, 19)
                          .replaceAll("T", " ");

                      Color scoreColor = Colors.red.shade600;
                      IconData scoreIcon = Icons.trending_down;
                      if (scoreValue >= 80) {
                        scoreColor = Colors.green.shade600;
                        scoreIcon = Icons.trending_up;
                      } else if (scoreValue >= 60) {
                        scoreColor = Colors.orange.shade600;
                        scoreIcon = Icons.trending_flat;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: scoreColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(scoreIcon, color: scoreColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$scoreValue%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: scoreColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    timestamp,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (_latestScores.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllHistory = !_showAllHistory;
                            });
                          },
                          icon: Icon(
                            _showAllHistory
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.amber.shade700,
                          ),
                          label: Text(
                            _showAllHistory ? 'Show Less' : 'See More',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.amber.shade50,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfoSheet() {
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
              children: [
                Icon(Icons.sports_gymnastics, color: Colors.white, size: 24),
                const SizedBox(width: 12),
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
                _buildInfoRow(Icons.title, 'Figure', widget.title),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.star, 'Best Score',
                    '${_highestScore > 0 ? _highestScore : 'Not attempted'}${_highestScore > 0 ? '%' : ''}'),
                const SizedBox(height: 12),
                _buildInfoRow(
                    Icons.history, 'Total Attempts', '${_latestScores.length}'),
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
