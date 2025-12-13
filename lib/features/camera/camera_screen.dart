import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// import 'package:http/http.dart' as http; // Δεν χρειάζεται εδώ πια το upload
// import 'dart:convert'; // Ούτε αυτό

// 1. ΠΡΟΣΘΕΣΕ ΑΥΤΟ ΤΟ IMPORT
import 'photo_posting_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  // bool _isUploading = false; // Δεν χρειάζεται πια εδώ

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

  // --- ΤΡΟΠΟΠΟΙΗΜΕΝΗ ΛΟΓΙΚΗ ---
  // Αντί για Upload, κάνουμε Navigate
  Future<void> _takePhotoAndVerify() async {
    if (!_controller!.value.isInitialized) return;

    try {
      // 1. Τράβα τη φωτογραφία
      final XFile photo = await _controller!.takePicture();
      
      if (!mounted) return;

      // 2. ΑΝΟΙΞΕ ΤΟ VERIFICATION SCREEN
      // Στέλνουμε το path της φωτογραφίας στην επόμενη οθόνη
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(imagePath: photo.path),
        ),
      );

    } catch (e) {
      print("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

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
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.flash_on, color: primaryBlue, size: 40),
                  ),

                  // SHUTTER BUTTON
                  GestureDetector(
                    onTap: _takePhotoAndVerify, // <--- Καλεί τη νέα συνάρτηση
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryBlue, width: 10),
                        color: Colors.transparent,
                      ),
                    ),
                  ),

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