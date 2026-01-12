import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../auth/login_screen.dart';
import 'circular_crop_screen.dart';

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

  Future<void> _handleEditProfilePhoto(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show choice dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Profile Photo',
          style: GoogleFonts.hammersmithOne(),
        ),
        content: Text(
          'Choose how to set your profile photo:',
          style: GoogleFonts.hammersmithOne(fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt, color: Color(0xFF1269C7)),
            label: Text(
              'Camera',
              style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7)),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library, color: Color(0xFF1269C7)),
            label: Text(
              'Gallery',
              style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7)),
            ),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      // Pick image from selected source
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Read image bytes
      final imageBytes = await image.readAsBytes();

      if (!context.mounted) return;

      // Open custom circular crop screen
      final croppedBytes = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (context) => CircularCropScreen(imageBytes: imageBytes),
        ),
      );

      if (croppedBytes == null || !context.mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1269C7),
          ),
        ),
      );

      try {
        debugPrint('Starting upload... bytes: ${croppedBytes.length}');
        
        // Cloudinary configuration (same as post uploads)
        const String cloudName = "dkeski4ji";
        const String uploadPreset = "CyclagoUserImages";
        
        // Upload to Cloudinary
        final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
        final request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(http.MultipartFile.fromBytes(
            'file',
            croppedBytes,
            filename: '${user.uid}_profile.png',
          ));

        debugPrint('📤 Uploading to Cloudinary...');
        final response = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Upload timed out after 30 seconds'),
        );

        if (response.statusCode != 200) {
          throw Exception('Upload failed with status ${response.statusCode}');
        }

        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        final String uploadedUrl = jsonResponse['secure_url'];
        debugPrint('Got Cloudinary URL: $uploadedUrl');

        // Update Firestore with new 'profilepicture' field
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.update({
            'profilepicture': uploadedUrl,
          });
        } else {
          await FirebaseFirestore.instance.collection('users').add({
            'email': user.email,
            'profilepicture': uploadedUrl,
          });
        }

        debugPrint('Firestore updated!');

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated!')),
          );
        }
      } catch (uploadError) {
        debugPrint('Upload error: $uploadError');
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $uploadError'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('General error: $e');
      if (context.mounted) {
        // Try to close dialog if it exists
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleEditProfileName(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get current profile name
    String currentName = '';
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userData = querySnapshot.docs.first.data();
      currentName = userData['username'] ?? '';
    }

    final controller = TextEditingController(text: currentName);

    if (!context.mounted) return;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Profile Name',
          style: GoogleFonts.hammersmithOne(),
        ),
        content: TextField(
          controller: controller,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: 'Enter your name...',
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(
              'Save',
              style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7)),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && context.mounted) {
      try {
        // Update Firestore
        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.update({
            'username': newName,
          });
        } else {
          // Create new user document if it doesn't exist
          await FirebaseFirestore.instance.collection('users').add({
            'email': user.email,
            'username': newName,
          });
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile name updated!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile name: $e')),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                    // Profile Name
                    _SettingsItem(
                      icon: Icons.person,
                      title: 'Profile name',
                      onTap: () => _handleEditProfileName(context),
                    ),
                    const SizedBox(height: 12),
                    // Profile Description
                    _SettingsItem(
                      icon: Icons.description,
                      title: 'Profile description',
                      onTap: () => _handleEditDescription(context),
                    ),
                    const SizedBox(height: 12),
                    // Profile Photo
                    _SettingsItem(
                      icon: Icons.photo_camera,
                      title: 'Profile photo',
                      onTap: () => _handleEditProfilePhoto(context),
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
