import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

class CircularCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CircularCropScreen({super.key, required this.imageBytes});

  @override
  State<CircularCropScreen> createState() => _CircularCropScreenState();
}

class _CircularCropScreenState extends State<CircularCropScreen> {
  final GlobalKey _cropKey = GlobalKey();
  double _scale = 1.5;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;
  bool _isProcessing = false;
  
  static const double _circleSize = 280.0;
  static const double _imageSize = 400.0;
  static const Color primaryBlue = Color(0xFF1269C7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Crop Profile Photo',
          style: GoogleFonts.hammersmithOne(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: primaryBlue),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: primaryBlue,
          ),
        ),
      ),
      body: Column(
        children: [
          // Crop area with gesture detection OUTSIDE the clip
          Expanded(
            child: GestureDetector(
              onScaleStart: _isProcessing ? null : (details) {
                _startFocalPoint = details.focalPoint;
                _startOffset = _offset;
                _startScale = _scale;
              },
              onScaleUpdate: _isProcessing ? null : (details) {
                setState(() {
                  // Handle zoom
                  _scale = (_startScale * details.scale).clamp(0.8, 5.0);
                  
                  // Handle pan
                  final delta = details.focalPoint - _startFocalPoint;
                  _offset = _startOffset + delta;
                });
              },
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The actual cropped area (what gets saved)
                      RepaintBoundary(
                        key: _cropKey,
                        child: Container(
                          width: _circleSize,
                          height: _circleSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE0E0E0),
                          ),
                          child: ClipOval(
                            child: OverflowBox(
                              maxWidth: _imageSize,
                              maxHeight: _imageSize,
                              child: Transform.translate(
                                offset: _offset,
                                child: Transform.scale(
                                  scale: _scale,
                                  child: Image.memory(
                                    widget.imageBytes,
                                    fit: BoxFit.cover,
                                    width: _imageSize,
                                    height: _imageSize,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Circle border overlay
                      Container(
                        width: _circleSize + 4,
                        height: _circleSize + 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryBlue,
                            width: 3,
                          ),
                        ),
                      ),
                      // Loading overlay
                      if (_isProcessing)
                        Container(
                          width: _circleSize,
                          height: _circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // OK Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _cropAndReturn(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  disabledBackgroundColor: primaryBlue.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'OK',
                        style: GoogleFonts.hammersmithOne(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cropAndReturn() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      Uint8List resultBytes;

      if (kIsWeb) {
        // On web, toImage doesn't work reliably, so return original image
        // The image will still be displayed as circular in the profile
        resultBytes = widget.imageBytes;
      } else {
        // On mobile, capture the cropped circular area
        RenderRepaintBoundary boundary =
            _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData == null) {
          throw Exception('Failed to capture image');
        }
        resultBytes = byteData.buffer.asUint8List();
      }
      
      if (mounted) {
        Navigator.pop(context, resultBytes);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
