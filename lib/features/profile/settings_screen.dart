import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/global_data.dart'; // Import your ProfileCache here
import '../auth/login_screen.dart';
import 'circular_crop_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    ProfileCache.clear(); // Clear cache on logout
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Helper to update Firestore and local cache simultaneously
  Future<void> _updateUserData(String field, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({field: value});
    }

    // UPDATE LOCAL CACHE IMMEDIATELY
    if (field == 'username') ProfileCache.displayName = value;
    if (field == 'bio') ProfileCache.bio = value;
    if (field == 'profilepicture') ProfileCache.profilePictureUrl = value;
  }

  Future<void> _handleEditProfilePhoto(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile Photo', style: GoogleFonts.hammersmithOne()),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt, color: Color(0xFF1269C7)),
            label: Text('Camera', style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7))),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library, color: Color(0xFF1269C7)),
            label: Text('Gallery', style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7))),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, maxWidth: 500, imageQuality: 70); // Reduced size to deload
      if (image == null) return;

      final imageBytes = await image.readAsBytes();
      if (!context.mounted) return;

      final croppedBytes = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CircularCropScreen(imageBytes: imageBytes)),
      );

      if (croppedBytes == null || !context.mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1269C7))),
      );

      // Cloudinary Upload
      const String cloudName = "dkeski4ji";
      const String uploadPreset = "CyclagoUserImages";
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', croppedBytes, filename: 'profile.png'));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final String uploadedUrl = json.decode(responseData)['secure_url'];

        await _updateUserData('profilepicture', uploadedUrl);

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo Updated!')));
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint("Photo error: $e");
    }
  }

  Future<void> _handleEditProfileName(BuildContext context) async {
    final controller = TextEditingController(text: ProfileCache.displayName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Name', style: GoogleFonts.hammersmithOne()),
        content: TextField(
          controller: controller,
          maxLength: 20,
          decoration: const InputDecoration(hintText: "New username"),
          style: GoogleFonts.hammersmithOne(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.hammersmithOne(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('Save', style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7)))),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await _updateUserData('username', newName);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name Updated!')));
    }
  }

  Future<void> _handleEditDescription(BuildContext context) async {
    final controller = TextEditingController(text: ProfileCache.bio);

    final newBio = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Bio', style: GoogleFonts.hammersmithOne()),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Tell us about your trips..."),
          style: GoogleFonts.hammersmithOne(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.hammersmithOne(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('Save', style: GoogleFonts.hammersmithOne(color: const Color(0xFF1269C7)))),
        ],
      ),
    );

    if (newBio != null) {
      await _updateUserData('bio', newBio);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bio Updated!')));
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
            // --- HEADER (Matches IslandPass height and Line) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(width: 1.5, color: primaryBlue)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: primaryBlue, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Settings',
                    style: GoogleFonts.hammersmithOne(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // --- SETTINGS LIST ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SettingsItem(icon: Icons.person, title: 'Profile name', onTap: () => _handleEditProfileName(context)),
                  const SizedBox(height: 15),
                  _SettingsItem(icon: Icons.description, title: 'Profile description', onTap: () => _handleEditDescription(context)),
                  const SizedBox(height: 15),
                  _SettingsItem(icon: Icons.photo_camera, title: 'Profile photo', onTap: () => _handleEditProfilePhoto(context)),
                  const SizedBox(height: 15),
                  _SettingsItem(icon: Icons.logout, title: 'Log out', onTap: () => _handleLogout(context)),
                  const SizedBox(height: 15),
                  _SettingsItem(icon: Icons.delete_forever, title: 'Delete account', iconColor: Colors.red, onTap: () {}),
                ],
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

  const _SettingsItem({required this.icon, required this.title, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryBlue, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? primaryBlue, size: 24),
            const SizedBox(width: 20),
            Expanded(child: Text(title, style: GoogleFonts.hammersmithOne(fontSize: 18))),
            Icon(Icons.chevron_right, color: iconColor ?? primaryBlue),
          ],
        ),
      ),
    );
  }
}