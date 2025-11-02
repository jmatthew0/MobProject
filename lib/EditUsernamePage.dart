import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditUsernamePage extends StatefulWidget {
  final String currentUsername;
  const EditUsernamePage({Key? key, required this.currentUsername})
      : super(key: key);

  @override
  State<EditUsernamePage> createState() => _EditUsernamePageState();
}

class _EditUsernamePageState extends State<EditUsernamePage> {
  final _formKey = GlobalKey<FormState>();
  late String _newUsername;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _newUsername = widget.currentUsername;
  }

  bool get _hasChanges => _newUsername.trim() != widget.currentUsername.trim();

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a username';
    if (value.length < 6) return 'Minimum 6 characters';
    if (value.length > 16) return 'Maximum 16 characters';
    return null;
  }

  Future<void> _saveUsername() async {
    if (!_formKey.currentState!.validate()) return;

    // Don't proceed if no changes were made
    if (!_hasChanges) return;

    setState(() => _isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User not logged in!"),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final userId = user.id;

    try {
      // Check if username is unique in users table
      final existing = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('username', _newUsername)
          .neq('id', userId)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Username already taken!"),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Update Auth user metadata (both username and display_name)
      final authUpdate = await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          'username': _newUsername,
          'display_name': _newUsername,
        }),
      );

      if (authUpdate.user == null) {
        throw 'Failed to update username in Auth.';
      }

      // Update custom users table
      await Supabase.instance.client
          .from('users')
          .update({'username': _newUsername}).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return the updated username to EditProfilePage
        Navigator.pop(context, _newUsername);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
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
                            'Change Username',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: widget.currentUsername,
                            maxLength: 16,
                            decoration: const InputDecoration(
                              labelText: 'New Username',
                              counterText: '',
                            ),
                            validator: _validateUsername,
                            onChanged: (value) {
                              setState(() {
                                _newUsername = value;
                              });
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_newUsername.length}/16',
                              style: TextStyle(
                                fontSize: 13,
                                color: _newUsername.length > 16
                                    ? Colors.red
                                    : Colors.grey[700],
                              ),
                            ),
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
                                      onPressed:
                                          _hasChanges ? _saveUsername : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _hasChanges
                                            ? const Color(0xFFD4A017)
                                            : Colors.grey[400],
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            Colors.grey[400],
                                        disabledForegroundColor:
                                            Colors.grey[600],
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
