import 'dart:async';
import 'package:flutter/material.dart';
import 'dances.dart';
import 'profile.dart';
import 'binungey.dart';
import 'tiklos.dart';
import 'suakusua.dart';
import 'pahid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  Timer? _tipTimer;
  int _tipSetIndex = 0;
  int _carouselIndex = 0;
  bool _userInteracting = false;

  // Early Access Modal Animation Controllers
  late AnimationController _modalAnimationController;
  late Animation<double> _modalScaleAnimation;
  late Animation<double> _modalOpacityAnimation;

  // Early Access Banner Animation Controllers
  AnimationController? _earlyAccessController;
  Animation<double>? _earlyAccessAnimation;

  final List<String> _carouselImages = [
    'assets/indak1.jpg',
    'assets/indak2.jpg',
    'assets/indak3.jpg',
    'assets/indak4.jpg',
    'assets/indak5.jpg',
    'assets/indak6.jpg',
    'assets/indak7.jpg',
    'assets/indak8.jpg',
  ];

  List<Map<String, dynamic>> _recentActivities = [];
  bool _loadingActivity = true;

  final List<String> tips = [
    "Keep your knees slightly bent during Tinikling to avoid injuries and improve timing!",
    "Practice with a mirror to improve your dance posture.",
    "Warm up before dancing to prevent muscle strain.",
    "Focus on your footwork for better rhythm.",
    "Smile and enjoy the dance—confidence shows!",
    "Record yourself to spot areas for improvement.",
    "Listen to the music carefully to match your steps.",
    "Stay hydrated during practice sessions.",
    "Practice regularly, even for a few minutes a day.",
    "Ask for feedback from friends or instructors.",
  ];

  final PageController _featuredController =
      PageController(viewportFraction: 0.75);
  int _featuredIndex = 0;

  final List<Map<String, dynamic>> _featuredDances = [
    {
      "imagePath": "assets/binungeybg.png",
      "title": "Binungey",
      "description":
          "Celebrate Ilocano tradition with bamboo-cooked rice and rhythmic steps.",
      "page": const BinungeyPage(),
    },
    {
      "imagePath": "assets/tiklos.png",
      "title": "Tiklos",
      "description":
          "A communal dance from Leyte showcasing bayanihan through rhythm and teamwork.",
      "page": const TiklosPage(),
    },
    {
      // Remove the image for Sua Ku Sua
      "imagePath": null, // or simply omit this key
      "title": "Sua Ku Sua",
      "description":
          "A Tausug courtship dance mimicking the swaying of the pomelo tree.",
      "page": const SuaKuSuaPage(),
    },
    {
      "imagePath": "assets/pahidbg.png",
      "title": "Pahid",
      "description": "Pahid description & History here",
      "page": const PahidPage(),
    },
  ];

  // 1. Add a GlobalKey for the "Want to learn how to dance?" section at the top of _HomeScreenState:
  final GlobalKey _learnDanceKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize modal animations
    _modalAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _modalScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _modalAnimationController, curve: Curves.elasticOut),
    );
    _modalOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _modalAnimationController, curve: Curves.easeInOut),
    );

    // Initialize early access banner animation
    _earlyAccessController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _earlyAccessAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _earlyAccessController!, curve: Curves.easeInOut),
    );
    _earlyAccessController!.repeat(reverse: true);

    _fetchRecentActivity();
    _startCarouselAutoScroll();

    // Set featured folk dances carousel to a high initial page for endless effect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_featuredController.hasClients) {
        _featuredController.jumpToPage(1000 * _featuredDances.length);
      }
      if (_pageController.hasClients) {
        _pageController.jumpToPage(1000 * _carouselImages.length);
      }
    });

    // Timer for tips every 3 minutes
    _tipTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        setState(() {
          _tipSetIndex = (_tipSetIndex + 1) % (tips.length ~/ 3);
        });
      }
    });
  }

  void _startCarouselAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!_userInteracting && _pageController.hasClients) {
        final currentPage = _pageController.page?.toInt() ?? 0;
        _pageController.animateToPage(
          currentPage + 1,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onCarouselPageChanged(int index) {
    setState(() {
      _carouselIndex = index;
    });
  }

  void _onCarouselUserInteraction() {
    _userInteracting = true;
    _carouselTimer?.cancel();
    // Resume auto-scroll after 6 seconds of inactivity
    Future.delayed(const Duration(seconds: 6), () {
      _userInteracting = false;
      _startCarouselAutoScroll();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _featuredController.dispose();
    _modalAnimationController.dispose();
    _earlyAccessController?.dispose();
    _carouselTimer?.cancel();
    _tipTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRecentActivity() async {
    setState(() => _loadingActivity = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final uri =
        Uri.parse('https://flipino-be.onrender.com/user_history?user_id=$userId');
    if (userId == null) {
      if (mounted) {
        setState(() {
          _recentActivities = [];
          _loadingActivity = false;
        });
      }
      return;
    }
    try {
      final response = await http.get(uri);
      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _recentActivities = (data['latest_scores'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
            _loadingActivity = false;
          });
        } else {
          setState(() {
            _recentActivities = [];
            _loadingActivity = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentActivities = [];
          _loadingActivity = false;
        });
      }
    }
  }

  void _showEarlyAccessModal() {
    if (!mounted) return;

    // Ensure animations are initialized before showing modal
    if (_modalAnimationController.isCompleted ||
        _modalAnimationController.isDismissed) {
      _modalAnimationController.reset();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        _modalAnimationController.forward();
        return _buildEarlyAccessModal(context);
      },
    );
  }

  Widget _buildEarlyAccessModal(BuildContext context) {
    return AnimatedBuilder(
      animation: _modalAnimationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor:
              Colors.black.withOpacity(0.7 * _modalOpacityAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _modalScaleAnimation.value,
              child: Opacity(
                opacity: _modalOpacityAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.amber.shade50,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.amber.shade300,
                      width: 2,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated logo/icon
                        TweenAnimationBuilder(
                          duration: Duration(milliseconds: 1200),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Transform.rotate(
                              angle: value * 0.1,
                              child: Transform.scale(
                                scale: 0.8 + (value * 0.2),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.shade400,
                                        Colors.amber.shade600,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Title with gradient text effect
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.amber.shade600,
                              Colors.amber.shade800
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Welcome to FLIPino',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            'Early Access Edition',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description with better formatting
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 32,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You\'re getting an exclusive first look at our revolutionary dance performance experience!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.construction,
                                      size: 20,
                                      color: Colors.orange.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Some features like AI dance analysis and performance scoring are still being fine-tuned.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange.shade800,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Thank you message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade50,
                                Colors.amber.shade100
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color: Colors.red.shade400,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Thanks for helping us shape the future of FLIPino!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade800,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _modalAnimationController.reset();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: Colors.amber.withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.explore, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Let\'s Explore Dances!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> getCurrentTips() {
    // Show 3 tips at a time, rotate every 3 minutes
    int tipsPerSet = 3;
    int start = _tipSetIndex * tipsPerSet;
    List<String> currentTips = [];
    for (int i = 0; i < tipsPerSet; i++) {
      int idx = (start + i) % tips.length;
      currentTips.add(tips[idx]);
    }
    return currentTips;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> currentTips = getCurrentTips();

    return Scaffold(
      body: Stack(
        children: [
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
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/indakbg2.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          IndexedStack(
            index: _currentIndex,
            children: [
              _homeScreenContent(currentTips),
              const DancesPage(),
              const ProfileScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5D4037), Color(0xFFD7A86E), Color(0xFF263238)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.grey[300],
          selectedFontSize: 14,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.play_arrow), label: 'Dances'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _homeScreenContent(List<String> tipsToShow) {
    final double cardWidth =
        MediaQuery.of(context).size.width - 28.0; // match tips/recent activity
    final double carouselHeight = 200; // Match tips/recent activity height

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchRecentActivity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFF8B5E3C),
                          width: 4,
                        ),
                        boxShadow: [
                          // White shadow (inner glow effect)
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 20,
                            offset: Offset(0, 0),
                            spreadRadius: 8,
                          ),
                          // Original brown shadow
                          BoxShadow(
                            color: Color(0xFF8B5E3C).withOpacity(0.25),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/FLIPinoNLogo.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "FLIPino",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFD600),
                        fontFamily: 'serif',
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Color(0xFF5D4037).withOpacity(0.4),
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "in partnership with Indak Hamaka",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'serif',
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Color(0xFFD7A86E).withOpacity(0.2),
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD600),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: carouselHeight,
                width: cardWidth,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is UserScrollNotification ||
                        notification is ScrollStartNotification) {
                      _onCarouselUserInteraction();
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _carouselIndex = index % _carouselImages.length;
                      });

                      // Seamless loop: jump to middle when reaching edges
                      if (index == 0) {
                        Future.delayed(Duration.zero, () {
                          _pageController
                              .jumpToPage(1000 * _carouselImages.length);
                        });
                      }
                    },
                    itemBuilder: (context, index) {
                      final int imageIndex = index % _carouselImages.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            _carouselImages[imageIndex],
                            fit: BoxFit.cover,
                            width: cardWidth,
                            height: carouselHeight,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // EARLY ACCESS Banner
              AnimatedBuilder(
                animation:
                    _earlyAccessAnimation ?? const AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _earlyAccessAnimation?.value ?? 1.0,
                    child: GestureDetector(
                      onTap: () => _showEarlyAccessModal(),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.amber.shade600,
                              Colors.orange.shade500,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(
                                  0.4 * (_earlyAccessAnimation?.value ?? 1.0)),
                              blurRadius:
                                  15 * (_earlyAccessAnimation?.value ?? 1.0),
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EARLY ACCESS',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Tap to learn more!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.touch_app,
                              color: Colors.white.withOpacity(0.8),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // --- Recent Activity FIRST ---
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.brown.shade300, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Recent Activity",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_loadingActivity)
                      const Center(child: CircularProgressIndicator())
                    else if (_recentActivities.isEmpty)
                      SizedBox(
                        height: 80,
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () {
                            final context = _learnDanceKey.currentContext;
                            if (context != null) {
                              Scrollable.ensureVisible(
                                context,
                                duration: const Duration(milliseconds: 600),
                                alignment: 0.3,
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Center(
                            child: Text(
                              "Try simulating a dance!",
                              style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ..._recentActivities.take(5).map((activity) {
                      final dance = activity['dance_name'] ?? 'Unknown Dance';
                      final score = activity['score'] ?? '';
                      final attemptedAt = activity['attempted_at'] ?? '';
                      final date = attemptedAt.isNotEmpty
                          ? DateTime.tryParse(attemptedAt)
                          : null;
                      String timeAgo = '';
                      if (date != null) {
                        final now = DateTime.now();
                        final diff = now.difference(date);
                        if (diff.inDays == 0) {
                          timeAgo = "Today";
                        } else if (diff.inDays == 1) {
                          timeAgo = "Yesterday";
                        } else {
                          timeAgo = "${diff.inDays} days ago";
                        }
                      }
                      return ListTile(
                        leading:
                            const Icon(Icons.music_note, color: Colors.brown),
                        title: Text(dance),
                        subtitle: Text("Score: $score%"),
                        trailing: Text(timeAgo),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // --- Tips SECOND ---
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color.fromRGBO(255, 138, 0, 0), width: 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.deepOrange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Here are some tips:",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...tipsToShow.map((tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  "• $tip",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              KeyedSubtree(
                key: _learnDanceKey,
                child: Column(
                  children: [
                    const Text(
                      "Want to learn how to dance?",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: _featuredController,
                        itemBuilder: (context, index) {
                          final int actualIndex =
                              index % _featuredDances.length;
                          return Center(
                            child: _buildPromoCard(
                              imagePath: _featuredDances[actualIndex]
                                  ["imagePath"],
                              title: _featuredDances[actualIndex]["title"],
                              description: _featuredDances[actualIndex]
                                  ["description"],
                              page: _featuredDances[actualIndex]["page"],
                              width: cardWidth,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade100.withOpacity(0.8),
                      Colors.brown.shade100.withOpacity(0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.brown.shade600, width: 2),
                  image: const DecorationImage(
                    image: AssetImage("assets/wow.jpg"),
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomRight,
                    opacity: 0.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Celebrate Filipino Culture",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Discover the rich heritage of Philippine folk dances like Binungey, Pahid, Tiklos and Sua Ku Sua. Embrace your roots with every step!",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 15),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(255, 193, 7, 1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                        ),
                        onPressed: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                        icon: const Icon(Icons.explore),
                        label: const Text("Explore Folk Dances"),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard({
    required String? imagePath,
    required String title,
    required String description,
    required Widget page,
    required double width,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: imagePath != null
            ? DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4), BlendMode.darken),
              )
            : null,
        color: imagePath == null ? Colors.brown.shade200 : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent)),
            const SizedBox(height: 4),
            Text(description,
                style: const TextStyle(fontSize: 12, color: Colors.white)),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(255, 193, 7, 1),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => page),
                );
              },
              child: const Text("Try it now!",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
