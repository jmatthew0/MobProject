import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'binungey.dart';
import 'tiklos.dart';
import 'suakusua.dart';
import 'pahid.dart';
import 'maindance.dart';
import 'tiklostut.dart';

class DancesPage extends StatefulWidget {
  const DancesPage({Key? key}) : super(key: key);

  @override
  _DancesPageState createState() => _DancesPageState();
}

class _DancesPageState extends State<DancesPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _dances = [];
  bool _loading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _featuredDances = [
    {
      'name': 'Binungey',
      'imagePath': 'assets/binungeybg.png',
      'island': 'Luzon',
      'page': const BinungeyPage(),
    },
    {
      'name': 'Pahid',
      'imagePath': 'assets/pahidbg.png',
      'island': 'Visayas',
      'page': const PahidPage(),
    },
    {
      'name': 'Sua Ku Sua',
      'imagePath': 'assets/sua_ku_sua.jpeg',
      'island': 'Mindanao',
      'page': const SuaKuSuaPage(),
    },
    {
      'name': 'Tiklos: By Figure',
      'imagePath': 'assets/tiklos.png',
      'island': 'Visayas',
      'page': const TiklosPage(),
    },
    {
      'name': 'Tiklos: Step-by-Step',
      'imagePath': 'assets/tiklos.png',
      'island': 'Visayas',
      'page': const TiklosTutPage(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fetchDances();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _animationController.forward();
  }

  Future<void> _fetchDances() async {
    final dancesResponse = await Supabase.instance.client
        .from('dances')
        .select('id, title, island')
        .eq('status', 'approved') // Only fetch approved dances
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> dancesWithImages = [];
    for (final dance in dancesResponse as List) {
      final imagesResponse = await Supabase.instance.client
          .from('dance_images')
          .select('image_url')
          .eq('dance_id', dance['id'])
          .order('created_at', ascending: true)
          .limit(1);

      String imageUrl = 'assets/indakbg2.jpg';
      if (imagesResponse is List && imagesResponse.isNotEmpty) {
        imageUrl = imagesResponse.first['image_url'] ?? imageUrl;
      }

      dancesWithImages.add({
        'id': dance['id'],
        'name': dance['title'] ?? '',
        'imagePath': imageUrl,
        'island': dance['island'] ?? '',
        'page': null,
      });
    }

    if (!mounted) return;

    setState(() {
      _dances = dancesWithImages;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _currentSort = 'All';

  void _handleSort(String value) {
    setState(() {
      _currentSort = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Combine all dances first
    List<Map<String, dynamic>> allDances = [
      ..._featuredDances.map((d) => {...d, 'isFeatured': true}),
      ..._dances.map((d) => {...d, 'isFeatured': false}),
    ];

    // Apply search filter first
    List<Map<String, dynamic>> filtered = allDances.where((dance) {
      return (dance['name'] ?? '')
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    // Apply unified sorting/filtering logic for all dances
    if (_currentSort == 'All') {
      filtered.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (_currentSort == 'A-Z') {
      filtered.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (_currentSort == 'Z-A') {
      filtered.sort((a, b) => (b['name'] ?? '').compareTo(a['name'] ?? ''));
    } else if (_currentSort == 'Luzon' ||
        _currentSort == 'Visayas' ||
        _currentSort == 'Mindanao') {
      filtered = filtered.where((dance) {
        final island = (dance['island'] ?? '').toString().trim().toLowerCase();
        return island == _currentSort.toLowerCase();
      }).toList();
      filtered.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (_currentSort == 'Feature Icon') {
      filtered = filtered.where((dance) {
        return dance['isFeatured'] == true;
      }).toList();
      filtered.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
          // Animated background pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 0.02,
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/indakbg2.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          // Decorative elements
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
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
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          if (_loading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Folk Dances...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _fetchDances,
                color: Colors.amber,
                backgroundColor: Colors.white,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Custom app bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // Title with traditional styling
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade700,
                                      Colors.amber.shade400
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.music_note,
                                        color: Colors.white, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Philippine Folk Dances',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Enhanced search bar
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.9),
                                      Colors.white.withOpacity(0.7),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText:
                                              "Discover traditional dances...",
                                          hintStyle: TextStyle(
                                            color: Colors.brown.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: Colors.brown.shade700,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 20,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Colors.brown.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.shade600,
                                            Colors.amber.shade400
                                          ],
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _currentSort == 'A-Z'
                                              ? Icons.sort_by_alpha
                                              : Icons.sort_by_alpha_outlined,
                                          color: Colors.white,
                                        ),
                                        tooltip: _currentSort == 'A-Z'
                                            ? 'Sort Z-A'
                                            : 'Sort A-Z',
                                        onPressed: () {
                                          setState(() {
                                            if (_currentSort == 'A-Z' ||
                                                _currentSort == 'Z-A') {
                                              _currentSort =
                                                  _currentSort == 'A-Z'
                                                      ? 'Z-A'
                                                      : 'A-Z';
                                            } else {
                                              _currentSort = 'A-Z';
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Enhanced filter buttons with All category
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildEnhancedSortButton(
                                        'All', 'All', Icons.public),
                                    _buildEnhancedSortButton(
                                        'Luzon', 'Luzon', Icons.landscape),
                                    _buildEnhancedSortButton(
                                        'Visayas', 'Visayas', Icons.waves),
                                    _buildEnhancedSortButton(
                                        'Mindanao', 'Mindanao', Icons.terrain),
                                    _buildFeatureSortButton(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Dance list
                      if (filtered.isEmpty)
                        SliverToBoxAdapter(
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 60),
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No dances found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Try adjusting your search or filters",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final dance = filtered[index];
                                return AnimatedContainer(
                                  duration: Duration(
                                      milliseconds: 300 + (index * 50)),
                                  child: _buildEnhancedDanceCard(
                                    context,
                                    dance['name'],
                                    dance['imagePath'],
                                    dance['page'],
                                    island: dance['island'],
                                    isFeatured: dance['isFeatured'] == true,
                                    danceId: dance['id'],
                                    index: index,
                                  ),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                      // Bottom padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSortButton(String label, String value, IconData icon) {
    final isActive = _currentSort == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive
                ? Colors.amber.shade600
                : Colors.white.withOpacity(0.2),
            foregroundColor:
                isActive ? Colors.white : Colors.white.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isActive
                    ? Colors.amber.shade800
                    : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            elevation: isActive ? 6 : 2,
            shadowColor: Colors.black.withOpacity(0.3),
          ),
          onPressed: () => _handleSort(value),
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSortButton() {
    final isActive = _currentSort == 'Feature Icon';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive
                ? Colors.amber.shade600
                : Colors.white.withOpacity(0.2),
            foregroundColor:
                isActive ? Colors.white : Colors.white.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isActive
                    ? Colors.amber.shade800
                    : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            elevation: isActive ? 6 : 2,
            shadowColor: Colors.black.withOpacity(0.3),
          ),
          onPressed: () => _handleSort('Feature Icon'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/dance.png',
                width: 20,
                height: 20,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 6),
              Text(
                'Featured',
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDanceCard(
    BuildContext context,
    String name,
    String imagePath,
    Widget? dancePage, {
    String? island,
    bool isFeatured = false,
    String? danceId,
    int index = 0,
  }) {
    final isNetworkImage = imagePath.startsWith('http');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0), // Reduced margin
      child: Material(
        elevation: 6, // Reduced elevation
        borderRadius: BorderRadius.circular(12), // Smaller border radius
        shadowColor: Colors.black.withOpacity(0.25),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isFeatured ? Colors.amber.shade600 : Colors.transparent,
              width: isFeatured ? 2 : 0,
            ),
          ),
          child: InkWell(
            onTap: () {
              if (dancePage != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => dancePage),
                );
              } else if (danceId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MainDancePage(danceId: danceId)),
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12), // Reduced padding
              child: Row(
                children: [
                  // Smaller image container
                  Container(
                    width: 60, // Reduced from 80
                    height: 60, // Reduced from 80
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // Smaller radius
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.15), // Lighter shadow
                          blurRadius: 4, // Reduced blur
                          offset: const Offset(1, 1), // Smaller offset
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          isNetworkImage
                              ? Image.network(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.brown.shade100,
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.brown.shade400,
                                        size: 24, // Smaller icon
                                      ),
                                    );
                                  },
                                )
                              : Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black
                                      .withOpacity(0.05), // Lighter overlay
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // Reduced spacing
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16, // Reduced font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown.shade800,
                                ),
                              ),
                            ),
                            if (isFeatured)
                              Container(
                                padding:
                                    const EdgeInsets.all(4), // Smaller padding
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade600,
                                  borderRadius: BorderRadius.circular(
                                      16), // Smaller radius
                                ),
                                child: Image.asset(
                                  'assets/dance.png',
                                  width: 16, // Smaller icon
                                  height: 16,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6), // Reduced spacing
                        if (island != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getIslandColor(island).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getIslandColor(island),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getIslandIcon(island),
                                  size: 12,
                                  color: _getIslandColor(island),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  island != null && island.isNotEmpty
                                      ? '${island.trim()[0].toUpperCase()}${island.trim().substring(1).toLowerCase()}'
                                      : '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getIslandColor(island),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Smaller arrow indicator
                  Container(
                    padding: const EdgeInsets.all(6), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(16), // Smaller radius
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.brown.shade700,
                      size: 20, // Smaller icon
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

  Color _getIslandColor(String? island) {
    switch (island?.trim().toLowerCase()) {
      case 'luzon':
        return Colors.lightBlue.shade300;
      case 'visayas':
        return Colors.yellow.shade300;
      case 'mindanao':
        return Colors.red.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  IconData _getIslandIcon(String island) {
    switch (island) {
      case 'Luzon':
        return Icons.landscape;
      case 'Visayas':
        return Icons.waves;
      case 'Mindanao':
        return Icons.terrain;
      default:
        return Icons.place;
    }
  }
}
