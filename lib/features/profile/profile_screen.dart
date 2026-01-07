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
  Map<String, List<Map<String, dynamic>>> _postsByIsland = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user profile data
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
            _profilePictureUrl = userData['profilePictureUrl'];
          });
        }
      }

      // Fetch user's posts and group by island
      try {
        final postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .get();

        final Map<String, List<Map<String, dynamic>>> groupedPosts = {};
        for (var doc in postsSnapshot.docs) {
          final data = doc.data();
          final island = data['island'] ?? 'Unknown';
          groupedPosts.putIfAbsent(island, () => []).add(data);
        }

        if (mounted) {
          setState(() {
            _postsByIsland = groupedPosts;
            _postCount = postsSnapshot.docs.length;
          });
        }
      } catch (e) {
        debugPrint('Error fetching posts: $e');
      }
    }
  }

  Widget _buildPostsSection() {
    if (_postsByIsland.isEmpty) {
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
      // Has posts - show trip content grouped by island
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _postsByIsland.entries.map((entry) {
          final islandName = entry.key;
          final posts = entry.value;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Title
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  'Trip to $islandName',
                  style: GoogleFonts.hammersmithOne(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Trip Images Grid - show up to 3 images per row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: posts.take(6).map((post) {
                    final imageUrl = post['imageUrl'] as String?;
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 44) / 3,
                      height: 124,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: imageUrl == null ? const Color(0xFFE0E0E0) : null,
                        ),
                        child: imageUrl == null
                            ? const Icon(Icons.image, color: Color(0xFF9E9E9E))
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        }).toList(),
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
