import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import '../../core/global_data.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Optional: if provided, view this user's profile (read-only)

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = "Traveller";
  String _bio = "";
  int _postCount = 0;
  String? _profilePictureUrl;
  Map<String, List<Map<String, dynamic>>> _postsByIsland = {};

  // Check if we're viewing another user's profile
  bool get isViewingOtherProfile => widget.userId != null;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

Future<void> _fetchUserData({bool forceRefresh = false}) async {
    String? targetUserId = widget.userId;
    bool isOwnProfile = targetUserId == null;

    // --- 1. CHECK CACHE FIRST (Only for own profile) ---
    if (isOwnProfile && ProfileCache.isCacheValid && !forceRefresh) {
      setState(() {
        _displayName = ProfileCache.displayName ?? "Traveller";
        _bio = ProfileCache.bio ?? "";
        _profilePictureUrl = ProfileCache.profilePictureUrl;
        _postsByIsland = ProfileCache.postsByIsland;
        _postCount = ProfileCache.postCount;
      });
      return; // Stop here, use cached data
    }

    // --- 2. FETCH FROM FIRESTORE ---
    if (isOwnProfile) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      targetUserId = user.uid;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        _displayName = userData['username'] ?? userData['email'] ?? "Traveller";
        _bio = userData['bio'] ?? "";
        _profilePictureUrl = userData['profilepicture'];
      }
    } else {
      // Fetch other user's profile data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _displayName = userData['username'] ?? "Traveller";
        _bio = userData['bio'] ?? "";
        _profilePictureUrl = userData['profilepicture'];
      }
    }

    // Fetch user's posts
    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: targetUserId)
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

        // --- 3. SAVE TO CACHE (If own profile) ---
        if (isOwnProfile) {
          ProfileCache.displayName = _displayName;
          ProfileCache.bio = _bio;
          ProfileCache.profilePictureUrl = _profilePictureUrl;
          ProfileCache.postsByIsland = _postsByIsland;
          ProfileCache.postCount = _postCount;
          ProfileCache.lastFetchTime = DateTime.now();
        }
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  void _showExpandedImage(List<Map<String, dynamic>> posts, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return _ExpandedImageViewer(
          posts: posts,
          initialIndex: initialIndex,
          onDelete: isViewingOtherProfile
              ? null
              : (post) async {
                  Navigator.of(context).pop();
                  await _deletePost(post);
                },
        );
      },
    );
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Post',
            style: GoogleFonts.hammersmithOne(
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
            style: GoogleFonts.hammersmithOne(
              fontSize: 16,
              color: const Color(0xFF737373),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.hammersmithOne(
                  color: const Color(0xFF737373),
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.hammersmithOne(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Find and delete the post from Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final postsQuery = await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: user.uid)
              .where('imageUrl', isEqualTo: post['imageUrl'])
              .get();

          for (var doc in postsQuery.docs) {
            await doc.reference.delete();
          }

          // Clear cache and refresh the posts
          ProfileCache.clear();
          await _fetchUserData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Post deleted successfully',
                  style: GoogleFonts.hammersmithOne(),
                ),
                backgroundColor: const Color(0xFF1269C7),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error deleting post: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete post',
                style: GoogleFonts.hammersmithOne(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                  children: posts.take(6).toList().asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final post = mapEntry.value;
                    final imageUrl = post['imageUrl'] as String?;
                    return GestureDetector(
                      onTap: imageUrl != null
                          ? () => _showExpandedImage(posts.take(6).toList(), index)
                          : null,
                      child: SizedBox(
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
    const Color primaryBlue = Color(0xFF1269C7);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              color: primaryBlue,
              onRefresh: () => _fetchUserData(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          // Settings Icon (own profile) or Back Button (other's profile)
                          Align(
                            alignment: isViewingOtherProfile ? Alignment.topLeft : Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: 10,
                                left: isViewingOtherProfile ? 10 : 0,
                                right: isViewingOtherProfile ? 0 : 20,
                              ),
                              child: isViewingOtherProfile
                                  ? IconButton(
                                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1269C7)),
                                      onPressed: () => Navigator.pop(context),
                                    )
                                  : GestureDetector(
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
                          // Profile Picture and Stats
                          Padding(
                            padding: const EdgeInsets.only(left: 43, right: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Picture
                                Container(
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
                                const SizedBox(width: 30),
                                // Islands Visited Counter
                                GestureDetector(
                                  onTap: () {
                                    if (_postsByIsland.isEmpty) return;
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        actionsPadding: const EdgeInsets.only(bottom: 12, right: 16),
                                        title: Text(
                                          'Islands Visited',
                                          style: GoogleFonts.hammersmithOne(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: _postsByIsland.entries.map((entry) {
                                            // Find most recent post date
                                            DateTime? mostRecent;
                                            for (var post in entry.value) {
                                              final timestamp = post['timestamp'];
                                              if (timestamp != null) {
                                                final date = (timestamp as Timestamp).toDate();
                                                if (mostRecent == null || date.isAfter(mostRecent)) {
                                                  mostRecent = date;
                                                }
                                              }
                                            }
                                            final dateStr = mostRecent != null
                                                ? DateFormat('MMM yyyy').format(mostRecent)
                                                : '';
                                            
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      entry.key,
                                                      style: GoogleFonts.hammersmithOne(
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        '${entry.value.length} ${entry.value.length == 1 ? 'post' : 'posts'}',
                                                        style: GoogleFonts.hammersmithOne(
                                                          fontSize: 16,
                                                          color: const Color(0xFF737373),
                                                        ),
                                                      ),
                                                      if (dateStr.isNotEmpty)
                                                        Text(
                                                          dateStr,
                                                          style: GoogleFonts.hammersmithOne(
                                                            fontSize: 12,
                                                            color: const Color(0xFF1269C7),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(
                                              'Close',
                                              style: GoogleFonts.hammersmithOne(
                                                color: const Color(0xFF1269C7),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_postsByIsland.length}',
                                        style: GoogleFonts.hammersmithOne(
                                          color: const Color(0xFF1269C7),
                                          fontSize: 28,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        'Islands',
                                        style: GoogleFonts.hammersmithOne(
                                          color: const Color(0xFF737373),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 30),
                                // Posts Counter
                                GestureDetector(
                                  onTap: () {
                                    if (_postsByIsland.isEmpty) return;
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        actionsPadding: const EdgeInsets.only(bottom: 12, right: 16),
                                        title: Text(
                                          'Islands Visited',
                                          style: GoogleFonts.hammersmithOne(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: _postsByIsland.entries.map((entry) {
                                            // Find most recent post date
                                            DateTime? mostRecent;
                                            for (var post in entry.value) {
                                              final timestamp = post['timestamp'];
                                              if (timestamp != null) {
                                                final date = (timestamp as Timestamp).toDate();
                                                if (mostRecent == null || date.isAfter(mostRecent)) {
                                                  mostRecent = date;
                                                }
                                              }
                                            }
                                            final dateStr = mostRecent != null
                                                ? DateFormat('MMM yyyy').format(mostRecent)
                                                : '';
                                            
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      entry.key,
                                                      style: GoogleFonts.hammersmithOne(
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        '${entry.value.length} ${entry.value.length == 1 ? 'post' : 'posts'}',
                                                        style: GoogleFonts.hammersmithOne(
                                                          fontSize: 16,
                                                          color: const Color(0xFF737373),
                                                        ),
                                                      ),
                                                      if (dateStr.isNotEmpty)
                                                        Text(
                                                          dateStr,
                                                          style: GoogleFonts.hammersmithOne(
                                                            fontSize: 12,
                                                            color: const Color(0xFF1269C7),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(
                                              'Close',
                                              style: GoogleFonts.hammersmithOne(
                                                color: const Color(0xFF1269C7),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Text(
                                        '$_postCount',
                                        style: GoogleFonts.hammersmithOne(
                                          color: const Color(0xFF1269C7),
                                          fontSize: 28,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        'Posts',
                                        style: GoogleFonts.hammersmithOne(
                                          color: const Color(0xFF737373),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
            ),
            );
          },
        ),
      ),
    );
  }
}

class _ExpandedImageViewer extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;
  final Function(Map<String, dynamic>)? onDelete;

  const _ExpandedImageViewer({
    required this.posts,
    required this.initialIndex,
    this.onDelete,
  });

  @override
  State<_ExpandedImageViewer> createState() => _ExpandedImageViewerState();
}

class _ExpandedImageViewerState extends State<_ExpandedImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.posts.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final post = widget.posts[index];
                  final imageUrl = post['imageUrl'] as String?;
                  if (imageUrl == null) return const SizedBox();
                  
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Center(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1269C7),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Three-dot Menu Button (only show if delete is available)
                          if (widget.onDelete != null)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {}, // Prevent tap from closing dialog
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1269C7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      widget.onDelete!(widget.posts[_currentIndex]);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Delete Post',
                                            style: GoogleFonts.hammersmithOne(
                                              color: Colors.red,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Island and Date below the image
            const SizedBox(height: 12),
            Text(
              '${widget.posts[_currentIndex]['island'] ?? 'Unknown'}, ${_formatDate(widget.posts[_currentIndex]['timestamp'])}',
              style: GoogleFonts.hammersmithOne(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            // Page indicator dots
            if (widget.posts.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.posts.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? const Color(0xFF1269C7)
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
