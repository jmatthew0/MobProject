import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'mainfigure.dart';
import 'dart:async';

class MainDancePage extends StatefulWidget {
  final String danceId;
  const MainDancePage({Key? key, required this.danceId}) : super(key: key);

  @override
  _MainDancePageState createState() => _MainDancePageState();
}

class _MainDancePageState extends State<MainDancePage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? dance;
  List<dynamic> figures = [];
  VideoPlayerController? _videoController;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  bool _showFloatingButton = false;
  Timer? _fabTimer;

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
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

    fetchDance();
    fetchFigures();
    _animationController.forward();
    _pulseController.repeat(reverse: true);

    _fabTimer = Timer(const Duration(seconds: 2), () {
      safeSetState(() => _showFloatingButton = true);
    });
  }

  Future<void> fetchDance() async {
    final response = await supabase
        .from('dances')
        .select()
        .eq('id', widget.danceId)
        .single();

    if (!mounted) return;

    safeSetState(() {
      dance = response;
    });

    final url = dance?['main_video_url'] as String?;
    if (url == null || url.isEmpty) return;

    _videoController?.dispose();
    final controller = VideoPlayerController.network(url);

    await controller.initialize();

    if (!mounted) {
      controller.dispose();
      return;
    }

    safeSetState(() {
      _videoController = controller;
    });
  }

  Future<void> fetchFigures() async {
    final response = await supabase
        .from('dance_figures')
        .select()
        .eq('dance_id', widget.danceId)
        .order('figure_number', ascending: true);

    if (!mounted) return;

    safeSetState(() {
      figures = response;
    });
  }

  @override
  void dispose() {
    _fabTimer?.cancel();
    _videoController?.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (dance == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8B4513),
                Color(0xFFD2691E),
                Color(0xFFDEB887),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Loading Dance Details...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Match homepage gradient exactly
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
              child: Image.asset(
                'assets/indakbg2.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Working X button copied from BinungeyPage

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
                        // Title section
                        // In BinungeyPage, the X button is inside the SliverToBoxAdapter, not as a Positioned widget.
// Replace your existing title section in MainDancePage with this structure:

// Title section
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
                                        print(
                                            "X button pressed!"); // Debug print
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
                                      const Icon(
                                        Icons.theater_comedy,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          dance!['title'] ??
                                              'Traditional Dance',
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
                                      width: double.infinity,
                                      height: 220,
                                      color: Colors.black,
                                      child: (_videoController != null &&
                                              _videoController!
                                                  .value.isInitialized)
                                          ? CustomVideoPlayer(
                                              controller: _videoController!)
                                          : Container(
                                              color: Colors.black87,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Colors.amber,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'Loading video...',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                        // Performance Details section (NEW)
                        SliverToBoxAdapter(
                          child: _buildPerformanceDetailsCard(dance!),
                        ),
                        // Historical information section
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildEnhancedInfoCard(
                              context,
                              'Historical Background',
                              dance!['history'] ??
                                  'No historical information available.',
                              Icons.history_edu,
                            ),
                          ),
                        ),
                        // References section
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.library_books,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'References',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  dance!['references'] ??
                                      'No references available.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
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
                                      const Icon(
                                        Icons.video_library,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Dance Figures',
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Figures list
                        if (figures.isEmpty)
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.video_library_outlined,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No figures available',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Dance figures will appear here when available',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
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
                                      figure['name'] ??
                                          'Figure ${figure['figure_number'] ?? ''}',
                                      figure['video_url'] ?? '',
                                      figure['name'] ?? '',
                                      figure['description'] ?? '',
                                      figure['id'],
                                      index,
                                    ),
                                  );
                                },
                                childCount: figures.length,
                              ),
                            ),
                          ),
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
    String figureId,
    int index,
  ) {
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MainFigurePage(
                    figureId: figureId,
                    figureName: figureName,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Figure number
                  Container(
                    width: 50,
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
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          figureName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to learn this figure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Play button
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
              children: const [
                Icon(Icons.info, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Quick Info',
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
                _buildInfoRow(Icons.title, 'Title', dance!['title'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow(
                    Icons.video_library, 'Figures', '${figures.length}'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.play_circle, 'Has Video',
                    _videoController != null ? 'Yes' : 'No'),
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

  Widget _buildPerformanceDetailsCard(Map<String, dynamic> dance) {
    String displayOrNA(String? value) =>
        (value != null && value.trim().isNotEmpty) ? value : "N/A";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.92),
            Colors.white.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFFD4A017)),
              SizedBox(width: 8),
              Text(
                'Performance Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.timer, color: Colors.brown[400], size: 20),
              const SizedBox(width: 8),
              Text('Duration: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.brown[700])),
              Text(displayOrNA(dance['duration']),
                  style: TextStyle(color: Colors.brown[900])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people, color: Colors.brown[400], size: 20),
              const SizedBox(width: 8),
              Text('Performers: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.brown[700])),
              Text(displayOrNA(dance['performers']),
                  style: TextStyle(color: Colors.brown[900])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.brown[400], size: 20),
              const SizedBox(width: 8),
              Text('Origin: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.brown[700])),
              Text(displayOrNA(dance['origin'] ?? dance['island']),
                  style: TextStyle(color: Colors.brown[900])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.music_note, color: Colors.brown[400], size: 20),
              const SizedBox(width: 8),
              Text('Music: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.brown[700])),
              Expanded(
                  child: Text(displayOrNA(dance['music']),
                      style: TextStyle(color: Colors.brown[900]))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.checkroom, color: Colors.brown[400], size: 20),
              const SizedBox(width: 8),
              Text('Costumes: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.brown[700])),
              Expanded(
                  child: Text(displayOrNA(dance['costumes']),
                      style: TextStyle(color: Colors.brown[900]))),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Enhanced Reusable Video Player Widget ---

class CustomVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  const CustomVideoPlayer({Key? key, required this.controller})
      : super(key: key);

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  bool _isFullscreen = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              _EnhancedControlsOverlay(
                controller: controller,
                onFullscreen: () async {
                  setState(() => _isFullscreen = true);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        body: SafeArea(
                          child: Stack(
                            children: [
                              Center(
                                child: AspectRatio(
                                  aspectRatio: controller.value.aspectRatio,
                                  child: InteractiveViewer(
                                    panEnabled: true,
                                    scaleEnabled: true,
                                    minScale: 1.0,
                                    maxScale: 3.0,
                                    child: VideoPlayer(controller),
                                  ),
                                ),
                              ),
                              _EnhancedControlsOverlay(
                                controller: controller,
                                onFullscreen: () => Navigator.pop(context),
                                fullscreen: true,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: VideoProgressIndicator(
                                    controller,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: Colors.amber.shade600,
                                      bufferedColor: Colors.white54,
                                      backgroundColor: Colors.black26,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  setState(() => _isFullscreen = false);
                },
                fullscreen: false,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.amber.shade600,
                      bufferedColor: Colors.white54,
                      backgroundColor: Colors.black26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancedControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onFullscreen;
  final bool fullscreen;
  const _EnhancedControlsOverlay({
    Key? key,
    required this.controller,
    this.onFullscreen,
    this.fullscreen = false,
  }) : super(key: key);

  @override
  State<_EnhancedControlsOverlay> createState() =>
      _EnhancedControlsOverlayState();
}

class _EnhancedControlsOverlayState extends State<_EnhancedControlsOverlay>
    with TickerProviderStateMixin {
  bool _visible = true;
  late VoidCallback _listener;
  Timer? _hideTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _listener = () {
      if (!widget.controller.value.isPlaying) {
        _show();
      }
    };
    widget.controller.addListener(_listener);
    if (widget.controller.value.isPlaying) {
      _startHideTimer();
    }
    _fadeController.forward();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    _hideTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _show() {
    if (!mounted) return;
    setState(() => _visible = true);
    _fadeController.forward();
    _startHideTimer();
  }

  void _hide() {
    if (!mounted) return;
    setState(() => _visible = false);
    _fadeController.reverse();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        _hide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_visible) {
          _hide();
        } else {
          _show();
        }
      },
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: _visible
                  ? LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3 * _fadeAnimation.value),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3 * _fadeAnimation.value),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Play/Pause button
                Center(
                  child: AnimatedOpacity(
                    opacity: _fadeAnimation.value,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          widget.controller.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 64,
                        ),
                        onPressed: () {
                          if (!mounted) return;
                          setState(() {
                            if (widget.controller.value.isPlaying) {
                              widget.controller.pause();
                              _show();
                            } else {
                              widget.controller.play();
                              _startHideTimer();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
                // Fullscreen button
                if (widget.onFullscreen != null)
                  Positioned(
                    right: 16,
                    bottom: widget.fullscreen ? 16 : 32,
                    child: AnimatedOpacity(
                      opacity: _fadeAnimation.value,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                        ),
                        child: IconButton(
                          icon: Icon(
                            widget.fullscreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: widget.onFullscreen,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
