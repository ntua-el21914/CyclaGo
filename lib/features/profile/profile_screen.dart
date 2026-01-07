import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = "Traveller";
  String _bio = "";
  int _postCount = 0;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        if (mounted) {
          setState(() {
            _displayName =
                userData['username'] ?? userData['email'] ?? "Traveller";
            _bio = userData['bio'] ?? "";
            _postCount = userData['postCount'] ?? 0;
            _profilePictureUrl = userData['profilePictureUrl'];
          });
        }
      }
    }
  }

  Widget _buildPostsSection() {
    if (_postCount == 0) {
      // No posts - show centered message
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No posts yet!',
            style: GoogleFonts.hammersmithOne(
              color: const Color(0xFF737373),
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    } else {
      // Has posts - show trip content
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Title
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              'Trip to Naxos',
              style: GoogleFonts.hammersmithOne(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Trip Images Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: SizedBox(
              height: 124,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage("https://placehold.co/124x124"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage("https://placehold.co/124x124"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage("https://placehold.co/124x124"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Settings Icon Row
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, right: 20),
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsScreen(),
                                    ),
                                  );
                                  // Refresh data when returning from settings
                                  _fetchUserData();
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(),
                                  child: const Icon(Icons.settings),
                                ),
                              ),
                            ),
                          ),
                          // Profile Picture
                          Padding(
                            padding: const EdgeInsets.only(left: 43),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE0E0E0),
                                border: Border.all(
                                  color: const Color(0xFF1269C7),
                                  width: 2,
                                ),
                                image: _profilePictureUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_profilePictureUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _profilePictureUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Color(0xFF9E9E9E),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Name - Dynamic from Firebase
                          Padding(
                            padding: const EdgeInsets.only(left: 43),
                            child: Text(
                              _displayName,
                              style: GoogleFonts.hammersmithOne(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Bio - Dynamic from Firebase
                          Padding(
                            padding: const EdgeInsets.only(left: 43, right: 20),
                            child: Text(
                              _bio,
                              style: GoogleFonts.hammersmithOne(
                                color: const Color(0xFF737373),
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom border
                    Container(
                      height: 1,
                      color: const Color(0xFF1269C7),
                    ),
                    const SizedBox(height: 17),
                    // Conditional: Show posts or "No posts yet!"
                    _buildPostsSection(),
                    // Add padding at bottom for nav bar
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
