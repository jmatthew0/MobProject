import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not launch $url';
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
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

          // Fiesta Pattern Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset('assets/indakbg2.jpg', fit: BoxFit.cover),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              size: 24, color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close',
                        ),
                      ),
                    ],
                  ),
                ),

                // Title block
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    children: [
                      const Text(
                        "Indak Hamaka Dance Company",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                blurRadius: 10,
                                color: Colors.black26,
                                offset: Offset(0, 3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: Colors.amber.shade400, width: 1),
                        ),
                        child: Text(
                          "About Us",
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Dance • Heritage • Community",
                        style: TextStyle(
                          color: Colors.white.withOpacity(.85),
                          fontSize: 14,
                          letterSpacing: .4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    children: [
                      const SectionTitle(title: "Established 2015"),
                      const SectionText(
                        text:
                            "Considered as Taytay's PREMIER DANCE GROUP committed to promote Taytay's Garments Industry and cultural heritage through dance.",
                      ),
                      const SizedBox(height: 14),
                      const _SectionDividerChip(text: "Highlights & Awards"),
                      const SizedBox(height: 10),
                      const _CollageGrid(count: 18, basePath: 'assets/award'),
                      const SizedBox(height: 20),
                      _GlassContactCard(
                        children: [
                          const _ContactHeader(),
                          const Divider(
                            color: Colors.black87,
                            thickness: 1,
                            height: 24,
                            indent: 30,
                            endIndent: 30,
                          ),
                          const ContactTile(
                            icon: Icons.email,
                            iconColor: Colors.blue,
                            title: "Email",
                            subtitle: "indakbanakdancecompany.staana@gmail.com",
                            textColor: Colors.black,
                          ),
                          const ContactTile(
                            icon: Icons.phone,
                            iconColor: Colors.green,
                            title: "Phone",
                            subtitle: "0961 327 4019",
                            textColor: Colors.black,
                          ),
                          ContactTile(
                            icon: Icons.location_on,
                            iconColor: Colors.red,
                            title: "Address",
                            subtitle:
                                "INDAK HAMAKA Dance Company, Bldg. A, New Taytay Public Market, 3rd",
                            textColor: Colors.black,
                            onTap: () => _openUrl(
                                "https://maps.app.goo.gl/c67r5Q1RNURXatGo8"),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 + safeBottom),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Reusable bits =====

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: [
            Shadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 2))
          ],
        ),
      ),
    );
  }
}

class SectionText extends StatelessWidget {
  final String text;
  const SectionText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white70,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SectionDividerChip extends StatelessWidget {
  final String text;
  const _SectionDividerChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _Line()),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.amber.shade400, width: 2),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.brown.shade800,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
        ),
        const Expanded(child: _Line()),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.3,
      color: Colors.white.withOpacity(.5),
    );
  }
}

class _ContactHeader extends StatelessWidget {
  const _ContactHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.mail_outline, color: Colors.black87, size: 24),
        SizedBox(width: 10),
        Text(
          "Get in Touch",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _GlassContactCard extends StatelessWidget {
  final List<Widget> children;
  const _GlassContactCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: const Color.fromRGBO(255, 193, 7, 1), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color textColor;
  final VoidCallback? onTap;

  const ContactTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textColor.withOpacity(.9), fontSize: 15),
      ),
      trailing: IconButton(
        tooltip: "Copy",
        icon: const Icon(Icons.copy_rounded, size: 18),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: subtitle));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title copied to clipboard'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
      ),
    );
  }
}

class _CollageGrid extends StatelessWidget {
  final int count;
  final String basePath;

  const _CollageGrid({required this.count, required this.basePath});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width >= 1000) {
          crossAxisCount = 6;
        } else if (width >= 700) {
          crossAxisCount = 5;
        } else if (width >= 520) {
          crossAxisCount = 4;
        }

        return GridView.builder(
          itemCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, i) => _CollageImage(
            path: '$basePath${i + 1}.jpg',
            index: i,
            totalCount: count,
            basePath: basePath,
          ),
        );
      },
    );
  }
}

class _CollageImage extends StatelessWidget {
  final String path;
  final int index;
  final int totalCount;
  final String basePath;

  const _CollageImage({
    required this.path,
    required this.index,
    required this.totalCount,
    required this.basePath,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: path,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black.withOpacity(.85),
            pageBuilder: (_, __, ___) => _FullImagePage(
              initialIndex: index,
              totalCount: totalCount,
              basePath: basePath,
            ),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ));
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(path, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _FullImagePage extends StatefulWidget {
  final int initialIndex;
  final int totalCount;
  final String basePath;

  const _FullImagePage({
    required this.initialIndex,
    required this.totalCount,
    required this.basePath,
  });

  @override
  State<_FullImagePage> createState() => _FullImagePageState();
}

class _FullImagePageState extends State<_FullImagePage> {
  late int currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(.85),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemCount: widget.totalCount,
              itemBuilder: (context, index) {
                final String imagePath = '${widget.basePath}${index + 1}.jpg';
                return Center(
                  child: Hero(
                    tag: imagePath,
                    child: InteractiveViewer(
                      minScale: 0.7,
                      maxScale: 4.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Counter at top
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1} / ${widget.totalCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
