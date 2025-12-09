import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

class MapScreen extends StatefulWidget {
  // 1. Accept the function from MainScaffold
  final Function(bool) onToggleNavBar;

  const MapScreen({super.key, required this.onToggleNavBar});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 2. Map Controller allows us to move the map programmatically
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Coordinates
  final LatLng _naxosChora = const LatLng(37.1032, 25.3764);
  final LatLng _filoti = const LatLng(37.0519, 25.4967);
  final LatLng _agiosProkopios = const LatLng(37.0744, 25.3562);

  final Color primaryBlue = const Color(0xFF1269C7);

  // 3. Search Logic
  void _handleSearch() {
    String query = _searchController.text.toLowerCase().trim();
    
    // Simple logic: If user types "naxos", move to Naxos
    if (query.contains("naxos")) {
      _mapController.move(_naxosChora, 12.0); // Move map to Chora
      FocusScope.of(context).unfocus(); // Close keyboard
    } else if (query.contains("filoti")) {
      _mapController.move(_filoti, 14.0);
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not found yet! Try 'Naxos'")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // THE MAP
          FlutterMap(
            mapController: _mapController, // <--- Attach controller here
            options: MapOptions(
              initialCenter: _naxosChora,
              initialZoom: 11.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              // Optional: Show nav bar again if they tap the map background
              onTap: (_, __) => widget.onToggleNavBar(true), 
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cyclago.app',
              ),
              MarkerLayer(
                markers: [
                  _buildCustomMarker(_naxosChora, "Chora", "Main Port & Capital"),
                  _buildCustomMarker(_filoti, "Filoti", "Mountain Village"),
                  _buildCustomMarker(_agiosProkopios, "Prokopios", "Crystal Water Beach"),
                ],
              ),
            ],
          ),

          // SEARCH BAR
          Positioned(
            top: 60,
            left: 35,
            right: 35,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: primaryBlue, width: 1),
                boxShadow: const [
                  BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: _handleSearch, // Trigger search on icon click
                    child: Icon(Icons.search, color: primaryBlue, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      // Trigger search on "Enter" key
                      onSubmitted: (_) => _handleSearch(),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: GoogleFonts.hammersmithOne(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.hammersmithOne(fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildCustomMarker(LatLng point, String label, String description) {
    return Marker(
      point: point,
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () {
          // 4. HIDE NAV BAR when pin is clicked
          widget.onToggleNavBar(false);
          _showLocationDetails(label, description);
        },
        child: Column(
          children: [
            Icon(Icons.location_on, color: primaryBlue, size: 45),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: GoogleFonts.hammersmithOne(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDetails(String title, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows sheet to be taller if needed
      builder: (context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(title, style: GoogleFonts.hammersmithOne(fontSize: 32, color: primaryBlue)),
              Text(description, style: GoogleFonts.hammersmithOne(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),
              const Divider(),
              Expanded(
                child: Center(
                  child: Text("User Posts Here...", style: GoogleFonts.hammersmithOne(color: Colors.grey)),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // 5. SHOW NAV BAR AGAIN when bottom sheet closes
      widget.onToggleNavBar(true);
    });
  }
}