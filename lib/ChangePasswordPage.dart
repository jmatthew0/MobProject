import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _isLoading = false;

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _showPasswordRequirements = false;

  final FocusNode _newPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _newPasswordFocusNode.addListener(() {
      setState(() {
        _showPasswordRequirements = _newPasswordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _newPasswordFocusNode.dispose();
    super.dispose();
  }

  Widget _buildPasswordRequirements() {
    if (!_showPasswordRequirements) return const SizedBox.shrink();

    final requirements = [
      {
        'text': '8-24 characters',
        'isValid': _newPassword.length >= 8 && _newPassword.length <= 24,
      },
      {
        'text': 'One lowercase letter',
        'isValid': RegExp(r'[a-z]').hasMatch(_newPassword),
      },
      {
        'text': 'One uppercase letter',
        'isValid': RegExp(r'[A-Z]').hasMatch(_newPassword),
      },
      {
        'text': 'One number',
        'isValid': RegExp(r'[0-9]').hasMatch(_newPassword),
      },
      {
        'text': 'One special character',
        'isValid': RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_newPassword),
      },
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 8),
          ...requirements.map((req) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      req['isValid'] as bool
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: req['isValid'] as bool ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      req['text'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            req['isValid'] as bool ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) {
        throw 'Session expired. Please log in again.';
      }

      // ✅ Re-authenticate with current password
      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _currentPassword,
      );

      if (authRes.session == null) {
        throw 'Current password is incorrect. Please check and try again.';
      }

      // ✅ Update to new password
      final updateRes = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPassword),
      );

      if (updateRes.user == null) {
        throw 'Failed to update password.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Password updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        // Provide more specific error messages
        if (errorMessage
            .toLowerCase()
            .contains('current password is incorrect')) {
          errorMessage =
              '❌ Current password is incorrect. Please check and try again.';
        } else if (errorMessage
            .toLowerCase()
            .contains('invalid login credentials')) {
          errorMessage =
              '❌ Current password is incorrect. Please verify your password.';
        } else if (errorMessage.toLowerCase().contains('session')) {
          errorMessage = '⚠️ Your session has expired. Please log in again.';
        } else if (errorMessage.toLowerCase().contains('network') ||
            errorMessage.toLowerCase().contains('connection')) {
          errorMessage =
              '🌐 Network error. Please check your connection and try again.';
        } else if (errorMessage.toLowerCase().contains('failed to update')) {
          errorMessage = '❌ Failed to update password. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
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
          // Background image with opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/indakbg2.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  color: Colors.white.withOpacity(0.7),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Current Password
                          TextFormField(
                            obscureText: !_showCurrent,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showCurrent
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                    () => _showCurrent = !_showCurrent),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter current password'
                                : null,
                            onChanged: (value) => _currentPassword = value,
                          ),

                          const SizedBox(height: 16),

                          // New Password
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                focusNode: _newPasswordFocusNode,
                                obscureText: !_showNew,
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showNew
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () =>
                                        setState(() => _showNew = !_showNew),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter new password';
                                  }
                                  if (value.length < 8 || value.length > 24) {
                                    return 'Password must be 8-24 characters';
                                  }
                                  if (value == _currentPassword) {
                                    return 'Cannot be same as current password';
                                  }

                                  // Check for uppercase letter
                                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                    return 'Must contain at least 1 uppercase letter';
                                  }

                                  // Check for lowercase letter
                                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                                    return 'Must contain at least 1 lowercase letter';
                                  }

                                  // Check for number
                                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                                    return 'Must contain at least 1 number';
                                  }

                                  // Check for special character
                                  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                                      .hasMatch(value)) {
                                    return 'Must contain at least 1 special character';
                                  }

                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _newPassword = value;
                                  });
                                },
                              ),
                              _buildPasswordRequirements(),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            obscureText: !_showConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirm
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                    () => _showConfirm = !_showConfirm),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm your password';
                              }
                              if (value != _newPassword) {
                                return 'Passwords do not match';
                              }
                              if (value.length > 24) {
                                return 'Maximum 24 characters';
                              }
                              return null;
                            },
                            onChanged: (value) => _confirmPassword = value,
                          ),

                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Cancel'),
                              ),
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton(
                                      onPressed: _changePassword,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFD4A017),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Save'),
                                    ),
                            ],
                          ),
                        ],
                      ),
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
