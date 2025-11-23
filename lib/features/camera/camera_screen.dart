import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// 1. IMPORT THE PREVIEW SCREEN
import 'package:cyclago/features/camera/preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Get list of cameras
    _cameras = await availableCameras();
    
    if (_cameras != null && _cameras!.isNotEmpty) {
      // Use the first camera (Back Camera)
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    // Show loading spinner until camera is ready
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
          // 1. LIVE CAMERA FEED
          CameraPreview(_controller!),

          // 2. BACK BUTTON (Top Left Arrow)
          Positioned(
            top: 50, 
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 40),
              onPressed: () {
                // FIX 1: Close the camera screen
                Navigator.pop(context);
              },
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Flash Icon
                  IconButton(
                    onPressed: () {}, // Flash logic can go here later
                    icon: const Icon(Icons.flash_on, color: primaryBlue, size: 40),
                  ),

                  // FIX 2: SHUTTER BUTTON (The Blue Circle)
                  GestureDetector(
                    onTap: () async {
                      try {
                        // A. Take the Picture
                        final image = await _controller!.takePicture();
                        
                        if (!mounted) return;

                        // B. Go to Preview Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PreviewScreen(imagePath: image.path),
                          ),
                        );
                      } catch (e) {
                        print("Error taking picture: $e");
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryBlue, 
                          width: 10, 
                        ),
                        color: Colors.transparent,
                      ),
                    ),
                  ),

                  // Flip Camera Icon
                  IconButton(
                    onPressed: () {}, // Flip logic can go here later
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