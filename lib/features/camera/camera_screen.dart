import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
    // 1. Get list of cameras
    _cameras = await availableCameras();
    
    if (_cameras != null && _cameras!.isNotEmpty) {
      // 2. Select the first camera (usually the back camera)
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      // 3. Initialize the controller
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

    // If camera isn't ready, show a loading spinner
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
          // 1. THE LIVE CAMERA FEED (Background)
          CameraPreview(_controller!),

          // 2. TOP LEFT ARROW (Back Button)
          Positioned(
            top: 50, 
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 40),
              onPressed: () {
                // Go back to previous tab or home (since this is a modal/screen)
                // For now, we can just switch tab if managed by MainScaffold, 
                // or pop if pushed.
              },
            ),
          ),

          // 3. BOTTOM CONTROLS (Flash, Shutter, Flip)
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
                  // A. Flash Icon (Left)
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.flash_on, color: primaryBlue, size: 40),
                  ),

                  // B. Shutter Button (Center) - Your Custom Circle Code
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryBlue, 
                        width: 10, // Thick blue border
                      ),
                      color: Colors.transparent,
                    ),
                  ),

                  // C. Flip Camera Icon (Right)
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