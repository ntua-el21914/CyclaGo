import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.hammersmithOne(),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.hammersmithOne(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.hammersmithOne(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleEditDescription(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get current description
    String currentDescription = '';
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userData = querySnapshot.docs.first.data();
      currentDescription = userData['bio'] ?? '';
    }

    final controller = TextEditingController(text: currentDescription);

    if (!context.mounted) return;

    final newDescription = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Description',
          style: GoogleFonts.hammersmithOne(),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your bio...',
            hintStyle: GoogleFonts.hammersmithOne(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1269C7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1269C7), width: 2),
            ),
          ),
          style: GoogleFonts.hammersmithOne(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              'Save',
              style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7)),
            ),
          ),
        ],
      ),
    );

    if (newDescription != null && context.mounted) {
      try {
        // Update Firestore
        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.update({
            'bio': newDescription,
          });
        } else {
          // Create new user document if it doesn't exist
          await FirebaseFirestore.instance.collection('users').add({
            'email': user.email,
            'bio': newDescription,
          });
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Description updated!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating description: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: primaryBlue,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    left: 15,
                    top: 15,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back,
                          size: 28,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  // Title
                  Center(
                    child: Text(
                      'Settings',
                      style: GoogleFonts.hammersmithOne(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Settings Options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    const SizedBox(height: 11),
                    // Profile Photo
                    _SettingsItem(
                      icon: Icons.photo_camera,
                      title: 'Profile photo',
                      onTap: () {
                        // TODO: Implement profile photo change
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profile photo - Coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Profile Name
                    _SettingsItem(
                      icon: Icons.person,
                      title: 'Profile name',
                      onTap: () {
                        // TODO: Implement profile name change
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profile name - Coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Profile Description
                    _SettingsItem(
                      icon: Icons.description,
                      title: 'Profile description',
                      onTap: () => _handleEditDescription(context),
                    ),
                    const SizedBox(height: 12),
                    // Log Out
                    _SettingsItem(
                      icon: Icons.logout,
                      title: 'Log out',
                      onTap: () => _handleLogout(context),
                    ),
                    const SizedBox(height: 12),
                    // Delete Account
                    _SettingsItem(
                      icon: Icons.delete_forever,
                      title: 'Delete account',
                      iconColor: Colors.red,
                      onTap: () => _handleDeleteAccount(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: primaryBlue,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 68,
              height: 60,
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor ?? primaryBlue,
                ),
              ),
            ),
            // Title
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.hammersmithOne(
                  color: Colors.black,
                  fontSize: 23,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Arrow
            Container(
              width: 50,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_right,
                size: 28,
                color: iconColor ?? primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
