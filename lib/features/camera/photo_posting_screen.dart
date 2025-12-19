import 'dart:io';
import 'dart:convert'; // Για το JSON decode
import 'package:flutter/material.dart';
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
    setState(() => _isUploading = true); // Ξεκινάει το loading

    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', widget.imagePath));

      print("📤 Uploading to Cloudinary...");
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        final String uploadedUrl = jsonResponse['secure_url'];
        
        print("✅ Upload Success! URL: $uploadedUrl");

        if (mounted) {
          // Επιτυχία! Πάμε στο Preview Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreviewScreen(imagePath: widget.imagePath),
            ),
          );
        }
      } else {
        print("❌ Upload Failed: ${response.statusCode}");
        throw Exception("Failed to upload");
      }
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false); // Σταματάει το loading
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