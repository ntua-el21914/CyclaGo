import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cyclago/core/global_data.dart';
import '../../main.dart'; // Import MainScaffold so we can navigate to it!

class VerificationScreen extends StatefulWidget {
  final String imagePath;
  const VerificationScreen({super.key, required this.imagePath});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isUploading = false;
  
  final String cloudName = "dkeski4ji"; 
  final String uploadPreset = "CyclagoUserImages"; 

  Future<void> _uploadAndContinue() async {
    setState(() => _isUploading = true);

    try {
      // 1. Upload to Cloudinary
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', widget.imagePath));

      print("📤 Uploading...");
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        final String uploadedUrl = jsonResponse['secure_url'];

        // 2. GET REAL USERNAME FROM FIRESTORE
        final user = FirebaseAuth.instance.currentUser;
        String finalUsername = "Cyclist"; // Default fallback

        if (user != null) {
          try {
            // Read the user's document from the 'users' collection
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid) 
                .get();

            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>;
              // Grab the 'username' field you showed in the screenshot
              if (data.containsKey('username')) {
                finalUsername = data['username']; 
              }
            }
          } catch (e) {
            print("⚠️ Error fetching username: $e");
          }
        }

        // 3. Save Post with the REAL Username
        await FirebaseFirestore.instance.collection('posts').add({
          'imageUrl': uploadedUrl,
          'username': finalUsername, // Saves "Admin" or whatever is in DB
          'island': 'Naxos',
          'likes': 0,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          // 4. Unlock local gate
          GlobalFeedData.posts.add(widget.imagePath);

          // 5. Navigate to Main App (Tab 1 = Island Pass)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScaffold(initialIndex: 1),
            ),
            (route) => false, 
          );
        }
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      print("❌ Error: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(widget.imagePath), fit: BoxFit.cover),
          
          Positioned(
            top: 50, left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),

          Positioned(
            bottom: 40, right: 30,
            child: InkWell(
              onTap: _isUploading ? null : _uploadAndContinue,
              child: Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: _isUploading
                    ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white))
                    : const Icon(Icons.check, color: Colors.white, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}