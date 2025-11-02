import 'package:flutter/material.dart';
import 'login.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _showTermsModal = false;
  bool _showPrivacyModal = false;

  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _dobError;
  String? _genderError;

  DateTime? _selectedDob;
  String? _selectedGender;

  final supabase = Supabase.instance.client;

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: Duration(seconds: 2)),
    );
  }

  String? _validateUsername(String value) {
    if (value.isEmpty) return 'Username is required';
    if (value.length < 6 || value.length > 16)
      return 'Username must be 6-16 characters';
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value))
      return 'Only letters and numbers allowed';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
      return 'Invalid email format';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8 || value.length > 24)
      return 'Password must be 8-24 characters';

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least 1 uppercase letter';
    }

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least 1 lowercase letter';
    }

    // Check for number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least 1 number';
    }

    // Check for special character (expanded list including %)
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?~`]').hasMatch(value)) {
      return 'Password must contain at least 1 special character (!@#%^&*()_+-=[]{}|;:,.<>?~`)';
    }

    return null;
  }

  String? _validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) return 'Please confirm your password';
    if (password != confirmPassword) return 'Passwords do not match';
    return null;
  }

  String? _validateDob(DateTime? dob) {
    if (dob == null) return 'Date of birth is required';

    final today = DateTime.now();
    final age = today.year -
        dob.year -
        ((today.month > dob.month ||
                (today.month == dob.month && today.day >= dob.day))
            ? 0
            : 1);

    if (age < 13) return 'You must be at least 13 years old';
    if (age > 120) return 'Please enter a valid date of birth';

    return null;
  }

  String? _validateGender(String? gender) {
    if (gender == null || gender.isEmpty) return 'Please select your gender';
    return null;
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(Duration(days: 13 * 365)),
      helpText: 'Select your date of birth',
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobError = null;
      });
    }
  }

  void _signUp() async {
    setState(() {
      _usernameError = _validateUsername(_usernameController.text);
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError = _validateConfirmPassword(
        _passwordController.text,
        _confirmPasswordController.text,
      );
      _dobError = _validateDob(_selectedDob);
      _genderError = _validateGender(_selectedGender);
    });

    if (_usernameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null ||
        _dobError != null ||
        _genderError != null) return;

    if (!_acceptTerms) {
      _showSnackBar('Please accept the Terms and Conditions to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String username = _usernameController.text;
      final String email = _emailController.text;
      final String password = _passwordController.text;
      final int age = _calculateAge(_selectedDob!);
      final String gender = _selectedGender!;

      // Step 1: Check if username already exists in the users table
      final existingUserResponse = await supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUserResponse != null) {
        _showSnackBar(
            'This username is already taken. Please choose a different username.');
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Sign up in Supabase Auth with username in metadata
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': username,
        },
      );

      if (authResponse.user == null) {
        _showSnackBar('Registration failed. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      // Step 3: Insert into custom users table
      await supabase.from('users').insert({
        'id': authResponse.user!.id,
        'username': username,
        'email': email,
        'age': age,
        'gender': gender,
        'role': 'user',
        'status': 'Enabled',
      });

      _showSnackBar(
        'Registration successful! Please check your email to confirm your account.',
        backgroundColor: Colors.green,
      );

      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => LoginScreen()));
      });
    } on AuthException catch (e) {
      String errorMsg = 'Registration failed. Please try again.';

      if (e.message.toLowerCase().contains('email')) {
        if (e.message.toLowerCase().contains('already') ||
            e.message.toLowerCase().contains('registered') ||
            e.message.toLowerCase().contains('exists')) {
          errorMsg =
              'An account with this email already exists. Please use a different email or try logging in.';
        } else if (e.message.toLowerCase().contains('invalid')) {
          errorMsg = 'Please enter a valid email address.';
        }
      } else if (e.message.toLowerCase().contains('password')) {
        errorMsg =
            'Password does not meet requirements. Please check and try again.';
      }

      _showSnackBar(errorMsg);
    } on PostgrestException catch (e) {
      String errorMsg = 'Failed to create user profile. Please try again.';

      if (e.message.toLowerCase().contains('duplicate key') ||
          e.message.toLowerCase().contains('unique constraint')) {
        if (e.message.toLowerCase().contains('email')) {
          errorMsg =
              'An account with this email already exists. Please use a different email or try logging in.';
        } else if (e.message.toLowerCase().contains('username')) {
          errorMsg =
              'This username is already taken. Please choose a different username.';
        } else {
          errorMsg =
              'An account with these details already exists. Please try different information.';
        }
      }

      _showSnackBar(errorMsg);
    } catch (e) {
      _showSnackBar('Unexpected error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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
            child: Image.asset('assets/indakbg2.jpg', fit: BoxFit.cover),
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
                              'Sign Up',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                errorText: _usernameError,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s'))
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                errorText: _emailError,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            // Date of Birth and Gender Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () => _selectDate(context),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Date of Birth',
                                        errorText: _dobError,
                                        errorMaxLines: 2,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        suffixIcon: Icon(Icons.calendar_today,
                                            size: 20),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 12),
                                      ),
                                      child: Text(
                                        _selectedDob == null
                                            ? 'Select'
                                            : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _selectedDob == null
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Gender',
                                      errorText: _genderError,
                                      errorMaxLines: 2,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                    ),
                                    items: [
                                      'Male',
                                      'Female',
                                      'Other',
                                      'Prefer not to say'
                                    ].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedGender = newValue;
                                        _genderError = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                errorText: _passwordError,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                errorText: _confirmPasswordError,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Terms and Conditions Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFFD4A017),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showTermsModal = true;
                                      });
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'I have read and agree to the ',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 13),
                                        children: [
                                          TextSpan(
                                            text: 'Terms and Conditions',
                                            style: TextStyle(
                                              color: Color(0xFFD4A017),
                                              decoration:
                                                  TextDecoration.underline,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' and ',
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                          WidgetSpan(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _showPrivacyModal = true;
                                                });
                                              },
                                              child: Text(
                                                'Privacy Policy',
                                                style: TextStyle(
                                                  color: Color(0xFFD4A017),
                                                  decoration:
                                                      TextDecoration.underline,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
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
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: (_isLoading || !_acceptTerms)
                                  ? null
                                  : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4A017),
                                disabledBackgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 40),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                  _isLoading ? 'Registering...' : 'Sign Up',
                                  style: const TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Already have an account?",
                                    style: TextStyle(color: Colors.black)),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => LoginScreen())),
                                  child: const Text("Login",
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
          // Terms and Conditions Modal
          if (_showTermsModal)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showTermsModal = false;
                });
              },
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping inside modal
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Terms and Conditions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _showTermsModal = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Terms of Service - FLIPino',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Last Updated: October 10, 2025',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '1. Acceptance of Terms',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'By accessing or using FLIPino ("the Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the Service.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '2. Description of Service',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'FLIPino is an educational platform dedicated to Filipino traditional dance learning and cultural preservation. The Service provides:\n• Dance tutorials and step-by-step instructions\n• Performance tracking and progress analytics\n• Cultural education resources',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '3. User Accounts and Registration',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '3.1 Account Requirements',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• You must provide a valid email address\n• Username must be 6-16 characters long and unique\n• Password must meet security requirements (8-24 characters with uppercase, lowercase, number, and special character)',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '4. Data Collection and Privacy',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '4.1 Personal Information Collected',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Username (6-16 characters, used as display name)\n• Email address\n• Date of Birth (to verify minimum age of 13)\n• Gender (optional)\n• Account creation date and status\n• User role and permissions',
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    '4.2 Performance and Learning Data',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Dance attempt scores and timestamps\n• Figure-specific performance metrics\n• Progress tracking and completion rates\n• User feedback and ratings (0-5 scale)\n• Learning analytics and preferences\n• Video recordings (Mobile App): Temporary video uploads for motion analysis, automatically deleted after processing',
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'For complete details on how we collect, use, and protect your data, please review our Privacy Policy.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '5. Acceptable Use Policy',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '5.1 Permitted Uses',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Educational and cultural learning purposes\n• Personal skill development in Filipino traditional dance\n• Sharing knowledge and cultural appreciation',
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    '5.2 Prohibited Activities',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Uploading false, misleading, or culturally insensitive content\n• Attempting to gain unauthorized access to other user accounts\n• Using the Service for commercial purposes without permission\n• Harassment, bullying, or inappropriate behavior toward other users\n• Violating intellectual property rights',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '6. Cultural Sensitivity and Respect',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Content must respect Filipino cultural traditions\n• Regional variations and interpretations are acknowledged\n• Traditional knowledge is treated with appropriate reverence\n• Primary goal is cultural preservation and education',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '7. Disclaimer and Limitation of Liability',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'The Service is provided "as is" and "as available" without warranties of any kind, either express or implied. FLIPino does not guarantee:\n• Uninterrupted or error-free service\n• Accuracy of dance instruction or cultural information\n• Achievement of specific learning outcomes',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'FLIPino shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the Service.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '8. Changes to These Terms',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'We reserve the right to modify these Terms at any time. When we make changes:\n• We will update the "Last Updated" date at the top of this document\n• Significant changes will be communicated via email\n• Continued use of the Service after changes constitutes acceptance of the new Terms\n• If you do not agree to the updated Terms, you must stop using the Service',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '9. Contact Us',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'If you have any questions about these Terms of Service, you can contact us:',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'By email: flipinoteam@gmail.com',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '10. Governing Law and Jurisdiction',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'These Terms of Service shall be governed by and construed in accordance with the laws of the Republic of the Philippines, without regard to its conflict of law provisions. We comply with the Data Privacy Act of 2012 (Republic Act No. 10173) and regulations enforced by the National Privacy Commission.',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Any disputes, claims, or legal proceedings arising from or related to your use of FLIPino shall be resolved exclusively in the competent courts of the Philippines. By using our Service, you consent to the jurisdiction and venue of such courts.',
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'By using FLIPino, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showTermsModal = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4A017),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'I Understand',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Privacy Policy Modal
          if (_showPrivacyModal)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showPrivacyModal = false;
                });
              },
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping inside modal
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _showPrivacyModal = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Last Updated: October 10, 2025',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service and tells You about Your privacy rights and how the law protects You.',
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'We use Your Personal data to provide and improve the Service. By using the Service, You agree to the collection and use of information in accordance with this Privacy Policy.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Interpretation and Definitions',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Interpretation',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'The words whose initial letters are capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.',
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Definitions',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'For the purposes of this Privacy Policy:',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Account means a unique account created for You to access our Service or parts of our Service.\n• Affiliate means an entity that controls, is controlled by, or is under common control with a party.\n• Company (referred to as either "the Company", "We", "Us" or "Our") refers to FLIPino\n• Cookies are small files placed on Your device by a website.\n• Country refers to: Philippines\n• Device means any device that can access the Service.\n• Personal Data is any information that relates to an identified or identifiable individual.\n• Service refers to the Website and Mobile Application.\n• Service Provider means any person who processes data on behalf of the Company.\n• Usage Data refers to data collected automatically from the use of the Service.\n• Website refers to FLIPino, accessible from https://web-cap-master.vercel.app/\n• You means the individual accessing or using the Service.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Collecting and Using Your Personal Data',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Types of Data Collected',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Personal Data',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'While using Our Service, We may ask You to provide Us with certain personally identifiable information that can be used to contact or identify You. Personally identifiable information may include, but is not limited to:',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Username\n• Email address\n• Date of Birth\n• Gender (Optional)\n• Usage Data',
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Usage Data',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Usage Data is collected automatically when using the Service. Usage Data may include information such as Your Device\'s Internet Protocol address (e.g. IP address), browser type, browser version, the pages of our Service that You visit, the time and date of Your visit, the time spent on those pages, unique device identifiers and other diagnostic data.',
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Performance and Learning Data',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'When you use our dance learning features, we collect and store the following data to track your progress and improve your learning experience:',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Dance Performance Metrics: Your scores, accuracy ratings, and completion status for each dance attempt\n• Practice History: Timestamps and frequency of your dance practice sessions\n• Figure-Specific Performance: Individual performance data for specific dance moves and figures\n• User Ratings and Feedback: Your ratings (0-5 scale) and feedback on dances and learning materials\n• Progress Analytics: Completion rates, improvement trends, and learning patterns\n• Video Processing Data (Mobile App): When you record yourself performing a dance on our mobile app, the video is temporarily uploaded to our server for motion comparison and analysis. This video is automatically deleted immediately after processing is complete and is never stored permanently.',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'This performance data helps us provide personalized learning recommendations, track your progress over time, and improve our educational content.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Third-Party Services',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'We use the following third-party service providers to operate and improve our Service:',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Supabase: User authentication, database management, and secure data storage. GDPR and SOC 2 Type II compliant.\n• EmailJS: Transactional emails such as account verification and password resets.\n• Vercel: Web application hosting infrastructure.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Tracking Technologies and Cookies',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'We use Cookies and similar tracking technologies to track the activity on Our Service and store certain information. We use both Session and Persistent Cookies for essential functionality, policy acceptance tracking, and user preferences.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Use of Your Personal Data',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'The Company may use Personal Data for the following purposes:',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• To provide and maintain our Service\n• To manage Your Account\n• To contact You by email or other forms of electronic communication\n• To provide You with news and special offers\n• To manage Your requests\n• For business transfers',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Security of Your Personal Data',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'The security of Your Personal Data is important to Us. We implement industry-standard security measures including:',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '• Secure Authentication: Handled through Supabase\'s secure infrastructure with industry-standard encryption\n• Database Security: GDPR-compliant and SOC 2 Type II certified infrastructure\n• HTTPS Encryption: All data transmission encrypted using SSL/TLS protocols\n• Access Controls: Strict controls limit who can view or modify your data',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'However, no method of transmission over the Internet is 100% secure. While we strive to protect Your Personal Data, we cannot guarantee its absolute security.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Children\'s Privacy',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13.',
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Contact Us',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'If you have any questions about this Privacy Policy, you can contact us:',
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'By email: flipinoteam@gmail.com',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'By using FLIPino, you acknowledge that you have read and understood this Privacy Policy and agree to its terms.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showPrivacyModal = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4A017),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'I Understand',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
