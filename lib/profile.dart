import 'package:flutter/material.dart';
import 'about.dart';
import 'login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EditProfilePage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = "User";
  String _userEmail = "";
  String _memberSince = "";
  int? _userAge;
  String? _userGender;
  Map<String, Map<String, dynamic>> _danceProgress = {};
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = session.user;
      _userEmail = user.email ?? "";
      final createdAt = user.createdAt;
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        _memberSince =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }

      // Fetch username, age, and gender from custom users table
      _fetchUsername(user.id);
      _fetchDanceProgress(user.id);
    }
  }

  Future<void> _fetchUsername(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('username, age, gender')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        setState(() {
          if (data['username'] != null) {
            _username = data['username'];
          }
          if (data['age'] != null) {
            _userAge = data['age'];
          }
          if (data['gender'] != null) {
            _userGender = data['gender'];
          }
        });
      }
    } catch (e) {
      // Handle error silently or log if needed
      if (mounted) {
        debugPrint('Error fetching user data: $e');
      }
    }
  }

  Future<void> _fetchDanceProgress(String userId) async {
    try {
      // Define dance structure with figure counts
      final danceData = {
        'Binungey': {'totalFigures': 7, 'displayName': 'Binungey'},
        'Pahid': {'totalFigures': 6, 'displayName': 'Pahid'},
        'Sua Ku Sua': {'totalFigures': 10, 'displayName': 'Sua Ku Sua'},
        'Tiklos': {'totalFigures': 4, 'displayName': 'Tiklos'},
        'Tiklos: Step-by-Step': {
          'totalFigures': 16,
          'displayName': 'Tiklos: Step-by-Step'
        },
      };

      // Fetch user history from Supabase
      final response = await Supabase.instance.client
          .from('user_history')
          .select('dance_name, figure_name, score')
          .eq('user_id', userId)
          .order('attempted_at', ascending: false);

      if (!mounted) return;

      // Process data to calculate progress for each dance
      Map<String, Map<String, dynamic>> progressMap = {};

      for (var dance in danceData.entries) {
        String danceName = dance.key;
        int totalFigures = dance.value['totalFigures'] as int;
        String displayName = dance.value['displayName'] as String;

        // Get all scores for this dance
        List<int> figureScores = List.filled(totalFigures, 0);
        int completedCount = 0;
        int totalScore = 0;

        for (var record in response) {
          if (record['dance_name'] == danceName) {
            // Extract figure number from figure_name
            String figureName = record['figure_name'] ?? '';
            int? figureNum = _extractFigureNumber(figureName);

            if (figureNum != null &&
                figureNum > 0 &&
                figureNum <= totalFigures) {
              int score = record['score'] ?? 0;
              // Keep the highest score for each figure
              if (score > figureScores[figureNum - 1]) {
                figureScores[figureNum - 1] = score;
              }
            }
          }
        }

        // Calculate statistics
        for (int score in figureScores) {
          if (score > 0) {
            completedCount++;
            totalScore += score;
          }
        }

        double completionRate =
            totalFigures > 0 ? (completedCount / totalFigures * 100) : 0;
        double averageScore =
            totalFigures > 0 ? (totalScore / totalFigures) : 0;

        progressMap[danceName] = {
          'displayName': displayName,
          'totalFigures': totalFigures,
          'completedFigures': completedCount,
          'completionRate': completionRate,
          'averageScore': averageScore,
        };
      }

      setState(() {
        _danceProgress = progressMap;
        _isLoadingProgress = false;
      });
    } catch (e) {
      debugPrint('Error fetching dance progress: $e');
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    }
  }

  int? _extractFigureNumber(String figureName) {
    // Extract number from figure name like "BinungeyBoyFig1.json" -> 1
    final match = RegExp(r'Fig(\d+)').firstMatch(figureName);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirm Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Close the dialog
              Navigator.pop(dialogContext);

              // Sign out
              try {
                await Supabase.instance.client.auth.signOut();

                // Navigate to login screen, clearing the entire navigation stack
                if (mounted && context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                debugPrint('Error signing out: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              child: Image.asset('assets/indakbg2.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                children: [
                  Card(
                    color: Colors.white.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.menu,
                                  size: 30, color: Colors.black),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                    color: Color(0xFFD4A017), width: 1.5),
                              ),
                              elevation: 8,
                              offset: const Offset(0, 40),
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'About us',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.info_outline,
                                          color: Colors.brown),
                                      SizedBox(width: 10),
                                      Text('About us',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Sign Out',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.logout, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text('Sign Out',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (String choice) {
                                if (choice == 'About us') {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AboutScreen()));
                                } else if (choice == 'Sign Out') {
                                  _showSignOutConfirmation();
                                }
                              },
                            ),
                          ),
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey,
                            backgroundImage:
                                const AssetImage("assets/FLIPinoNLogo.png"),
                          ),
                          const SizedBox(height: 20),
                          Text(_username,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black54)),
                          if (_memberSince.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 4.0, bottom: 8.0),
                              child: Text("Member since: $_memberSince",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.brown,
                                      fontStyle: FontStyle.italic)),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit Profile"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4A017),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfilePage(
                                    username: _username,
                                    email: _userEmail,
                                    memberSince: _memberSince,
                                    age: _userAge,
                                    gender: _userGender,
                                  ),
                                ),
                              );

                              if (result != null &&
                                  result is Map &&
                                  result['username'] != null) {
                                setState(() {
                                  _username = result['username'];
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Username updated successfully!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Dance Progress Section
                  _buildDanceProgressSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDanceProgressSection() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.show_chart, color: Color(0xFFD4A017), size: 24),
                SizedBox(width: 8),
                Text(
                  'Dance Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoadingProgress
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4A017),
                      ),
                    ),
                  )
                : _danceProgress.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No dance progress yet. Start practicing!',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: _danceProgress.entries.map((entry) {
                          return _buildDanceProgressCard(
                            entry.key,
                            entry.value,
                          );
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildDanceProgressCard(String danceName, Map<String, dynamic> data) {
    String displayName = data['displayName'] ?? danceName;
    int totalFigures = data['totalFigures'] ?? 0;
    int completedFigures = data['completedFigures'] ?? 0;
    double completionRate = data['completionRate'] ?? 0;
    double averageScore = data['averageScore'] ?? 0;

    Color progressColor;
    if (completionRate == 100) {
      progressColor = Colors.green;
    } else if (completionRate >= 50) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completionRate == 100
              ? Colors.green.shade200
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dance name and final score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A017),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${averageScore.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: completionRate / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor,
                          progressColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$completedFigures/$totalFigures figures (${completionRate.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          completionRate > 30 ? Colors.white : Colors.black87,
                      shadows: completionRate > 30
                          ? [const Shadow(color: Colors.black26, blurRadius: 2)]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Status indicator
          Row(
            children: [
              Icon(
                completionRate == 100
                    ? Icons.check_circle
                    : completionRate == 0
                        ? Icons.radio_button_unchecked
                        : Icons.pending,
                size: 16,
                color: completionRate == 100
                    ? Colors.green
                    : completionRate == 0
                        ? Colors.grey
                        : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                completionRate == 100
                    ? 'Completed'
                    : completionRate == 0
                        ? 'Not Started'
                        : 'In Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: completionRate == 100
                      ? Colors.green
                      : completionRate == 0
                          ? Colors.grey
                          : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
