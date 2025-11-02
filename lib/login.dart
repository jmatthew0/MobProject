import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'homepage.dart';
import 'signup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLIPino',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String? initialErrorMessage;
  
  const LoginScreen({super.key, this.initialErrorMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Show initial error message if provided
    if (widget.initialErrorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showErrorMessage(widget.initialErrorMessage!);
        }
      });
    }
  }

  void _login() async {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (_emailError == null && _passwordError == null) {
      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (response.session != null) {
          // Check if email is confirmed
          final user = response.user;
          if (user != null && user.emailConfirmedAt == null) {
            _showErrorMessage(
                'Your account is not yet confirmed. Please check your email for the confirmation link.');
            await Supabase.instance.client.auth.signOut();
            return;
          }

          // Get user id from Supabase Auth
          final userId = user?.id;

          // Fetch user role and status from users table
          try {
            final userDataResponse = await Supabase.instance.client
                .from('users')
                .select('role, status')
                .eq('id', userId!)
                .single();

            if (!mounted) return;

            final String userRole = userDataResponse['role']?.toString().toLowerCase() ?? '';
            final String userStatus = userDataResponse['status']?.toString().toLowerCase() ?? '';

            // Block disabled accounts
            if (userStatus == 'disabled') {
              await Supabase.instance.client.auth.signOut();
              _showErrorMessage('Access denied. Please check your email.');
              return;
            }

            // Block maintenance status
            if (userStatus == 'maintenance') {
              await Supabase.instance.client.auth.signOut();
              _showErrorMessage('The app is currently under maintenance. Please try again later.');
              return;
            }

            // Block admin and superadmin accounts (mobile app is for users only)
            if (userRole == 'admin' || userRole == 'superadmin') {
              await Supabase.instance.client.auth.signOut();
              _showErrorMessage('Access denied. Please contact support for assistance.');
              return;
            }

            // Allow only regular users
            if (userRole == 'user') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              await Supabase.instance.client.auth.signOut();
              _showErrorMessage('Access denied. Please contact support for assistance.');
            }
          } catch (userError) {
            if (!mounted) return;
            await Supabase.instance.client.auth.signOut();
            _showErrorMessage('User data not found. Please contact support.');
            return;
          }
        } else {
          _showErrorMessage('Email or password is incorrect');
        }
      } catch (e) {
        if (!mounted) return;
        _showErrorMessage('Email or password is incorrect');
      }
    }
  }

  void _showErrorMessage(String message) {
    print('🔴🔴🔴 SHOWING ERROR MESSAGE: $message'); // DEBUG
    
    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Show the new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    return null;
  }

  void _openForgotPassword() async {
    final url = Uri.parse('https://web-cap-master.vercel.app/forgot-password');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open browser')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
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
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/indakbg2.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/FLIPinoNLogo.png', width: 200),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                errorText: _emailError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                errorText: _passwordError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _openForgotPassword,
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                      color: Color(0xFFD4A017),
                                      decoration: TextDecoration.underline),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4A017),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Login',
                                  style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?",
                                    style: TextStyle(color: Colors.black)),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SignUpScreen()),
                                    );
                                  },
                                  child: const Text("Sign Up",
                                      style:
                                          TextStyle(color: Color(0xFFD4A017))),
                                ),
                              ],
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
        ],
      ),
    );
  }
}
