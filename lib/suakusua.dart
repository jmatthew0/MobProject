// suakusua.dart
import 'package:flutter/material.dart';
import 'figure_page.dart';
import 'dart:async';

class SuaKuSuaPage extends StatefulWidget {
  const SuaKuSuaPage({Key? key}) : super(key: key);

  @override
  _SuaKuSuaPageState createState() => _SuaKuSuaPageState();
}

class _SuaKuSuaPageState extends State<SuaKuSuaPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  bool _showFloatingButton = false;

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

    _animationController.forward();
    _pulseController.repeat(reverse: true);

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showFloatingButton = true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String info =
        'Sua-Ku-Sua, meaning "My Pomelo Tree," is a traditional courtship dance of the Tausug people from Jolo, Sulu in the southern Philippines. '
        'The dance is inspired by the swaying leaves and branches of the pomelo tree, a symbol of gentleness, grace, and femininity. '
        'Dancers—usually pairs of males and females—use fans to imitate the movement of the tree, portraying flirtation, admiration, and courtly love.\n\n'
        'Historically performed during festive occasions such as weddings or community gatherings, Sua-Ku-Sua reflects the multicultural influences of Chinese, Muslim, and Malay traditions found in the southern Philippines. '
        'The music, movements, and attire—such as the malong and fans—highlight the harmonious blend of these cultures. The dance is not just an artistic performance, but also a reflection of nature\'s beauty and the rich courtship rituals of the Tausug people.';

    final List<Map<String, String>> figures = [
      {
        'name': 'Figure 1: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig1.mp4',
        'json': 'SuaKuSuaBoyFig1.json'
      },
      {
        'name': 'Figure 2: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig2.mp4',
        'json': 'SuaKuSuaBoyFig2.json'
      },
      {
        'name': 'Figure 3: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig3.mp4',
        'json': 'SuaKuSuaBoyFig3.json'
      },
      {
        'name': 'Figure 4: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig4.mp4',
        'json': 'SuaKuSuaBoyFig4.json'
      },
      {
        'name': 'Figure 5: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig5.mp4',
        'json': 'SuaKuSuaBoyFig5.json'
      },
      {
        'name': 'Figure 6: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig6.mp4',
        'json': 'SuaKuSuaBoyFig6.json'
      },
      {
        'name': 'Figure 7: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig7.mp4',
        'json': 'SuaKuSuaBoyFig7.json'
      },
      {
        'name': 'Figure 8: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig8.mp4',
        'json': 'SuaKuSuaBoyFig8.json'
      },
      {
        'name': 'Figure 9: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig9.mp4',
        'json': 'SuaKuSuaBoyFig9.json'
      },
      {
        'name': 'Figure 10: Boy',
        'url': 'assets/videos/SuaKuSuaBoyFig10.mp4',
        'json': 'SuaKuSuaBoyFig10.json'
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
                                        print(
                                            "X button pressed!"); // Debug print
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
                                        Icons.theater_comedy,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Sua Ku Sua',
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
                        // Video placeholder section
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
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.brown, width: 2),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.video_library_outlined,
                                              size: 48,
                                              color: Colors.white60,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'No Main Video Available',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
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
                        // Figures list
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
                  heroTag: 'suakusua_info_btn', // <-- Unique heroTag here
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
              children: [
                Icon(Icons.info, color: Colors.white, size: 24),
                const SizedBox(width: 12),
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
                _buildInfoRow(Icons.title, 'Dance', 'Sua Ku Sua'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.video_library, 'Figures', '10'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, 'Origin', 'Sulu, Philippines'),
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
