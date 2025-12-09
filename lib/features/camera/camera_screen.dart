import 'dart:io'; // Απαραίτητο για το File
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
// Αν θέλεις να πηγαίνει σε Preview Screen μετά, κάνε uncomment την επόμενη γραμμή
// import 'package:cyclago/features/camera/preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isUploading = false; // Για να δείχνουμε το spinner

  // --- ☁️ CLOUDINARY SETTINGS ☁️ ---
  // Βάλε τα δικά σου εδώ!
  final String cloudName = "dkeski4ji"; 
  final String uploadPreset = "CyclagoUserImages"; 

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // --- ΛΟΓΙΚΗ: ΤΡΑΒΗΓΜΑ & UPLOAD ---
  Future<void> _takeAndUploadPhoto() async {
    if (!_controller!.value.isInitialized || _isUploading) return;

    setState(() => _isUploading = true); // Εμφάνισε loading

    try {
      // 1. Τράβα τη φωτογραφία
      final XFile photo = await _controller!.takePicture();
      
      // 2. Ανέβασέ την στο Cloudinary
      // Προσοχή: Αυτό δουλεύει μόνο σε Android/iOS Emulator (όχι Web)
      await _uploadToCloudinary(File(photo.path));

    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadToCloudinary(File imageFile) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    print("📤 Uploading to Cloudinary...");
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      final String uploadedUrl = jsonResponse['secure_url'];
      
      print("✅ Upload Success! URL: $uploadedUrl");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Photo Uploaded! ☁️"), backgroundColor: Colors.green),
        );
        // Εδώ μπορείς να κάνεις Navigate αν θες:
        // Navigator.push(... PreviewScreen ...);
      }
    } else {
      print("❌ Upload Failed: ${response.statusCode}");
      throw Exception("Failed to upload");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    // Loading State
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. CAMERA FEED
          CameraPreview(_controller!),

          // 2. BACK BUTTON (Top Left)
          Positioned(
            top: 50, 
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 40),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 3. BOTTOM CONTROLS
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flash Icon
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.flash_on, color: primaryBlue, size: 40),
                  ),

                  // SHUTTER BUTTON (Με Loading Indicator)
                  GestureDetector(
                    onTap: _takeAndUploadPhoto, // Καλεί τη συνάρτηση upload
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryBlue, width: 10),
                        color: Colors.transparent,
                      ),
                      child: _isUploading 
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: primaryBlue),
                          )
                        : null,
                    ),
                  ),

                  // Flip Camera Icon
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.cached, color: primaryBlue, size: 40),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}