import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'figure_page.dart';
import 'package:flutter/services.dart';
import 'dart:async';
// Add these imports for history
import 'package:shared_preferences/shared_preferences.dart';

class TiklosTutPage extends StatefulWidget {
  const TiklosTutPage({Key? key}) : super(key: key);

  @override
  _TiklosTutPageState createState() => _TiklosTutPageState();
}

class _TiklosTutPageState extends State<TiklosTutPage>
    with TickerProviderStateMixin {
  late VideoPlayerController _mainController;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  bool _showFloatingButton = false;

  // For history
  List<String> _danceHistory = [];

  @override
  void initState() {
    super.initState();
    _mainController = VideoPlayerController.asset(
      'assets/videos/Tiklos.mp4',
    )..initialize().then((_) {
        setState(() {});
      });

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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showFloatingButton = true);
      }
    });

    _loadDanceHistory();
  }

  Future<void> _loadDanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _danceHistory = prefs.getStringList('tiklos_dance_history') ?? [];
    });
  }

  Future<void> _addToDanceHistory(String figureName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _danceHistory.add(figureName);
      prefs.setStringList('tiklos_dance_history', _danceHistory);
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String info =
        'For centuries, Tiklos has been a very important factor in the social life of the peasants of Leyte. '
        'Tiklos refers to a group of peasants who agree to work for each other on the farm, including the building of the house. '
        'At noontime the people gather to eat their lunch together and to rest. During this rest period, Tiklos music is played with a flute '
        'accompanied by a guitar and the guimbal or the tambora (kinds of drums). The peasants then dance the Tiklos. '
        'The music of Tiklos is also played to gather the peasants before they start out for work.';

    final List<Map<String, String>> figures = [
      {
        'name': 'Tiklos Fig 1 - Step 1',
        'url': 'assets/videos/TiklosFig1S1.mp4',
        'json': 'TiklosTutFig1.json'
      },
      {
        'name': 'Tiklos Fig 1 - Step 2',
        'url': 'assets/videos/TiklosFig1S2.mp4',
        'json': 'TiklosTutFig2.json'
      },
      {
        'name': 'Tiklos Fig 1 - Step 3',
        'url': 'assets/videos/TiklosFig1S3.mp4',
        'json': 'TiklosTutFig3.json'
      },
      {
        'name': 'Tiklos Fig 1 - Step 4',
        'url': 'assets/videos/TiklosFig1S4.mp4',
        'json': 'TiklosTutFig4.json'
      },
      {
        'name': 'Tiklos Fig 1 - Step 5',
        'url': 'assets/videos/TiklosFig1S5.mp4',
        'json': 'TiklosTutFig5.json'
      },
      {
        'name': 'Tiklos Fig 2 - Step 1',
        'url': 'assets/videos/TiklosFig2S1.mp4',
        'json': 'TiklosTutFig6.json'
      },
      {
        'name': 'Tiklos Fig 2 - Step 2',
        'url': 'assets/videos/TiklosFig2S2.mp4',
        'json': 'TiklosTutFig7.json'
      },
      {
        'name': 'Tiklos Fig 2 - Step 3',
        'url': 'assets/videos/TiklosFig2S3.mp4',
        'json': 'TiklosTutFig8.json'
      },
      {
        'name': 'Tiklos Fig 3 - Step 1',
        'url': 'assets/videos/TiklosFig3S1.mp4',
        'json': 'TiklosTutFig9.json'
      },
      {
        'name': 'Tiklos Fig 3 - Step 2',
        'url': 'assets/videos/TiklosFig3S2.mp4',
        'json': 'TiklosTutFig10.json'
      },
      {
        'name': 'Tiklos Fig 3 - Step 3',
        'url': 'assets/videos/TiklosFig3S3.mp4',
        'json': 'TiklosTutFig11.json'
      },
      {
        'name': 'Tiklos Fig 3 - Step 4',
        'url': 'assets/videos/TiklosFig3S4.mp4',
        'json': 'TiklosTutFig12.json'
      },
      {
        'name': 'Tiklos Fig 4 - Step 1',
        'url': 'assets/videos/TiklosFig4S1.mp4',
        'json': 'TiklosTutFig13.json'
      },
      {
        'name': 'Tiklos Fig 4 - Step 2',
        'url': 'assets/videos/TiklosFig4S2.mp4',
        'json': 'TiklosTutFig14.json'
      },
      {
        'name': 'Tiklos Fig 4 - Step 3',
        'url': 'assets/videos/TiklosFig4S3.mp4',
        'json': 'TiklosTutFig15.json'
      },
      {
        'name': 'Tiklos Fig 4 - Step 4',
        'url': 'assets/videos/TiklosFig4S4.mp4',
        'json': 'TiklosTutFig16.json'
      },
    ];

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
                  Color(0xFF263238)
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
                    child: CustomScrollView(
                      slivers: [
                        // X button and title section
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            child: Column(
                              children: [
                                // X button row
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.white, size: 40),
                                      onPressed: () {
                                        if (_mainController.value.isPlaying) {
                                          _mainController.pause();
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
                                        Icons.school,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Tiklos: Step-by-Step',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
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
                                    child: _mainController.value.isInitialized
                                        ? Stack(
                                            alignment: Alignment.bottomCenter,
                                            children: [
                                              AspectRatio(
                                                aspectRatio: _mainController
                                                    .value.aspectRatio,
                                                child: VideoPlayer(
                                                    _mainController),
                                              ),
                                              VideoProgressIndicator(
                                                  _mainController,
                                                  allowScrubbing: true),
                                              Positioned(
                                                right: 16,
                                                bottom: 16,
                                                child: FloatingActionButton(
                                                  heroTag:
                                                      'tiklostut_video_btn',
                                                  mini: true,
                                                  backgroundColor:
                                                      Colors.black54,
                                                  onPressed: () {
                                                    setState(() {
                                                      _mainController
                                                              .value.isPlaying
                                                          ? _mainController
                                                              .pause()
                                                          : _mainController
                                                              .play();
                                                    });
                                                  },
                                                  child: Icon(
                                                    _mainController
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
                                            height: 200,
                                            color: Colors.black12,
                                            child: const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        // Historical information section
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildEnhancedInfoCard(
                              context,
                              'Historical Information',
                              info,
                              Icons.history_edu,
                            ),
                          ),
                        ),
                        // Figures section header
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.shade600,
                                        Colors.amber.shade400,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.video_library,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tutorial Steps',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    '${figures.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Figures list grouped by figure
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final figure = figures[index];
                                return AnimatedContainer(
                                  duration: Duration(
                                    milliseconds: 300 + (index * 100),
                                  ),
                                  child: _buildEnhancedFigureCard(
                                    context,
                                    figure['name']!,
                                    figure['url']!,
                                    figure['name']!,
                                    '',
                                    figure['json']!,
                                    index,
                                  ),
                                );
                              },
                              childCount: figures.length,
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
          // Floating action button
          if (_showFloatingButton)
            Positioned(
              bottom: 30,
              right: 20,
              child: AnimatedScale(
                scale: _showFloatingButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: FloatingActionButton(
                  heroTag: 'tiklostut_info_btn',
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
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(20),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
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
                              colors: [
                                Colors.amber.shade600,
                                Colors.amber.shade400
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              content.trim(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
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
                        child:
                            Icon(icon, color: Colors.amber.shade700, size: 24),
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
                      Icon(
                        Icons.touch_app,
                        color: Colors.brown.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content.length > 150
                        ? '${content.substring(0, 150)}...'
                        : content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.brown.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  if (content.length > 150) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tap to read more',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFigureCard(
    BuildContext context,
    String figureName,
    String videoUrl,
    String title,
    String description,
    String figureJsonFile,
    int index,
  ) {
    final stepMatch = RegExp(r'Fig (\d+) - Step (\d+)').firstMatch(figureName);
    final figureNum = stepMatch?.group(1) ?? '1';
    final stepNum = stepMatch?.group(2) ?? '${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            onTap: () async {
              // Save to history before navigating
              await _addToDanceHistory(figureName);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FigurePage(
                    videoUrl: videoUrl,
                    title: title,
                    description: description,
                    figureJsonFile: figureJsonFile,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade600, Colors.amber.shade400],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'F$figureNum',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'S$stepNum',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          figureName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to learn this step',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.red.shade600,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
                Icon(Icons.school, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Tutorial Info',
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
                _buildInfoRow(Icons.title, 'Dance', 'Tiklos'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.video_library, 'Total Steps', '16'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.stars, 'Figures', '4'),
                const SizedBox(height: 12),
                _buildInfoRow(
                    Icons.location_on, 'Origin', 'Leyte, Philippines'),
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
