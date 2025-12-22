import 'dart:io';
import 'dart:convert'; // Για το JSON decode
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- ΝΕΟ
import 'package:firebase_auth/firebase_auth.dart';     // <--- ΝΕΟ
import 'package:http/http.dart' as http; // Για το Upload
import 'preview_screen.dart'; 

class VerificationScreen extends StatefulWidget {
  final String imagePath;

  const VerificationScreen({super.key, required this.imagePath});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isUploading = false; // State για το loading

  // --- CLOUDINARY SETTINGS ---
  final String cloudName = "dkeski4ji"; 
  final String uploadPreset = "CyclagoUserImages"; 

  // --- ΛΟΓΙΚΗ UPLOAD ---
  Future<void> _uploadAndContinue() async {
    setState(() => _isUploading = true);

    try {
      // --- 1. UPLOAD TO CLOUDINARY ---
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', widget.imagePath));

      print("📤 Uploading to Cloudinary...");
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        final String uploadedUrl = jsonResponse['secure_url']; // Το Link της φώτο
        
        print("✅ Cloudinary Success! URL: $uploadedUrl");

        // --- 2. SAVE TO FIRESTORE (Το νέο κομμάτι) ---
        // Βρίσκουμε ποιος είναι ο χρήστης
        final user = FirebaseAuth.instance.currentUser;
        final String username = user?.displayName ?? "Cyclist"; // Αν δεν έχει όνομα, βάλε "Cyclist"

        await FirebaseFirestore.instance.collection('posts').add({
          'imageUrl': uploadedUrl,      // Το Link από το Cloudinary
          'username': username,         // Το όνομα του χρήστη
          'island': 'Naxos',            // Hardcoded για τώρα
          'likes': 0,                   // Αρχικά likes
          'timestamp': FieldValue.serverTimestamp(), // Η ώρα που ανέβηκε
        });
        
        print("✅ Firestore Success! Post saved.");

        if (mounted) {
          // --- 3. GO TO PREVIEW ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreviewScreen(imagePath: widget.imagePath),
            ),
          );
        }
      } else {
        print("❌ Cloudinary Failed: ${response.statusCode}");
        throw Exception("Failed to upload to Cloudinary");
      }
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
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
          // 1. Η Φωτογραφία
          Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
          ),

          // 2. Κουμπί Πίσω
          Positioned(
            top: 50,
            left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),

          // 3. Κουμπί Check / Upload
          Positioned(
            bottom: 40,
            right: 30,
            child: InkWell(
              // Αν ανεβάζει ήδη, δεν κάνουμε τίποτα
              onTap: _isUploading ? null : _uploadAndContinue,
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                // Αν ανεβάζει δείξε Spinner, αλλιώς δείξε Check
                child: _isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Icon(Icons.check, color: Colors.white, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}