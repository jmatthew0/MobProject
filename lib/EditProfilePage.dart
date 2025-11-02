import 'package:flutter/material.dart';
import 'EditUsernamePage.dart';
import 'ChangePasswordPage.dart';

class EditProfilePage extends StatelessWidget {
  final String username;
  final String email;
  final String memberSince;
  final int? age;
  final String? gender;

  const EditProfilePage({
    Key? key,
    required this.username,
    required this.email,
    required this.memberSince,
    this.age,
    this.gender,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              child: Image.asset('assets/indakbg2.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown),
                        ),
                        const SizedBox(height: 24),
                        ListTile(
                          title: const Text('Member Since'),
                          subtitle: Text(memberSince),
                          enabled: false,
                        ),
                        ListTile(
                          title: const Text('Username'),
                          subtitle: Text(username),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EditUsernamePage(
                                      currentUsername: username)),
                            );

                            if (result != null && result is String) {
                              Navigator.pop(context, {'username': result});

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
                        ListTile(
                          title: const Text('Email'),
                          subtitle: Text(email),
                          enabled: false,
                        ),
                        ListTile(
                          title: const Text('Age'),
                          subtitle: Text(age != null ? '$age years old' : 'Not specified'),
                          enabled: false,
                        ),
                        ListTile(
                          title: const Text('Gender'),
                          subtitle: Text(gender ?? 'Not specified'),
                          enabled: false,
                        ),
                        ListTile(
                          title: const Text('Password'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePasswordPage()),
                            );
                          },
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
