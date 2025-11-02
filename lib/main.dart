import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'login.dart';
import 'homepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // System.out.println("Edrian Formilleza")
  // import react from 'React'
  // npm install react-router-dom
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLIPino',
      debugShowCheckedModeBanner: false,
      home: SessionHandler(),
    );
  }
}

class SessionHandler extends StatefulWidget {
  @override
  State<SessionHandler> createState() => _SessionHandlerState();
}

class _SessionHandlerState extends State<SessionHandler> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
    _checkConnectivity();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showNoInternetDialog(context);
        }
      });
    }
  }

  void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.wifi_off, color: Colors.red, size: 32),
            SizedBox(width: 10),
            Text("No Internet", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "You are disconnected.\nPlease connect to WiFi or mobile data to continue.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Optionally, re-check connectivity here
            },
            child: const Text("Retry", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Validate user role and status before allowing access
      return FutureBuilder<bool>(
        future: _validateUserAccess(session.user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a branded loading screen instead of blank white
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x115D4037),
                      Color(0x11D7A86E),
                      Color(0x11263238),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFD4A017), // Gold color matching your theme
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            print(
                '✅ Session found! User: ${session.user.userMetadata?['display_name'] ?? session.user.email}');
            return ValidatedHomeScreen(
              displayName: session.user.userMetadata?['display_name'] ?? session.user.email ?? 'User',
            );
          } else {
            // User is blocked - determine the reason and show appropriate message
            return FutureBuilder<String>(
              future: _getBlockReason(session.user.id),
              builder: (context, reasonSnapshot) {
                if (reasonSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x115D4037),
                            Color(0x11D7A86E),
                            Color(0x11263238),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD4A017),
                        ),
                      ),
                    ),
                  );
                }

                // Sign out and show login with specific error message
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await Supabase.instance.client.auth.signOut();
                });

                final errorMessage = reasonSnapshot.data ?? 'Access denied. Please contact support for assistance.';
                return LoginScreen(
                  initialErrorMessage: errorMessage,
                );
              },
            );
          }
        },
      );
    } else {
      print('❌ No session found.');
      return LoginScreen();
    }
  }

  Future<bool> _validateUserAccess(String userId) async {
    try {
      final userDataResponse = await Supabase.instance.client
          .from('users')
          .select('role, status')
          .eq('id', userId)
          .single();

      final String userRole = userDataResponse['role']?.toString().toLowerCase() ?? '';
      final String userStatus = userDataResponse['status']?.toString().toLowerCase() ?? '';

      // Block disabled accounts
      if (userStatus == 'disabled') {
        print('❌ Blocked: Disabled account');
        return false;
      }

      // Block maintenance status
      if (userStatus == 'maintenance') {
        print('🔧 Blocked: User status is maintenance');
        return false;
      }

      // Block admin and superadmin accounts (mobile app is for users only)
      if (userRole == 'admin' || userRole == 'superadmin') {
        print('❌ Blocked: Admin/Superadmin account');
        return false;
      }

      // Allow only regular users with 'enabled' status
      if (userRole == 'user') {
        print('✅ Validated: Regular user');
        return true;
      }

      print('❌ Blocked: Invalid account type');
      return false;
    } catch (e) {
      print('❌ Error validating user: $e');
      return false;
    }
  }

  Future<String> _getBlockReason(String userId) async {
    try {
      final userDataResponse = await Supabase.instance.client
          .from('users')
          .select('role, status')
          .eq('id', userId)
          .single();

      final String userRole = userDataResponse['role']?.toString().toLowerCase() ?? '';
      final String userStatus = userDataResponse['status']?.toString().toLowerCase() ?? '';

      // Check for disabled account
      if (userStatus == 'disabled') {
        return 'Access denied. Please check your email.';
      }

      // Check for maintenance status
      if (userStatus == 'maintenance') {
        return 'The app is currently under maintenance. Please try again later.';
      }

      // Check for admin/superadmin trying to access mobile app
      if (userRole == 'admin' || userRole == 'superadmin') {
        return 'Access denied. Please contact support for assistance.';
      }

      // Default message
      return 'Access denied. Please contact support for assistance.';
    } catch (e) {
      print('❌ Error getting block reason: $e');
      return 'Access denied. Please contact support for assistance.';
    }
  }
}

// Helper widget to show HomeScreen with a welcome message
class ValidatedHomeScreen extends StatefulWidget {
  final String displayName;

  const ValidatedHomeScreen({super.key, required this.displayName});

  @override
  State<ValidatedHomeScreen> createState() => _ValidatedHomeScreenState();
}

class _ValidatedHomeScreenState extends State<ValidatedHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Show welcome message after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${widget.displayName}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen();
  }
}
