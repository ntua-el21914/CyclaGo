import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

class TripMapScreen extends StatefulWidget {
  final String tripName;
  final String islandName;

  const TripMapScreen({
    super.key,
    required this.tripName,
    required this.islandName,
  });

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  final MapController _mapController = MapController();
  final Color primaryBlue = const Color(0xFF1269C7);
  
  // Center of Naxos
  final LatLng _naxosCenter = const LatLng(37.05, 25.45);
  
  int _selectedCategory = 0; // 0 = beaches, 1 = restaurants, 2 = landmarks
  int _selectedDay = 1;
  
  // Sample destinations list
  final List<Map<String, dynamic>> _destinations = [
    {'name': 'Plaka Beach', 'lat': 37.0456, 'lng': 25.3632},
    {'name': 'Agios Prokopios Beach', 'lat': 37.0744, 'lng': 25.3562},
    {'name': 'Agia Anna Beach', 'lat': 37.0567, 'lng': 25.3589},
    {'name': 'Mikri Vigla Beach', 'lat': 37.0234, 'lng': 25.3712},
    {'name': 'Saint George Beach', 'lat': 37.0912, 'lng': 25.3645},
    {'name': 'Cedar Forest of Alyko', 'lat': 37.0123, 'lng': 25.3801},
    {'name': 'Kastraki Beach', 'lat': 37.0089, 'lng': 25.3756},
    {'name': 'Paralía Alykó', 'lat': 37.0056, 'lng': 25.3823},
    {'name': 'Paralia Panormos', 'lat': 36.9987, 'lng': 25.3901},
    {'name': 'Hawaii Beach', 'lat': 36.9923, 'lng': 25.3945},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // THE MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _naxosCenter,
              initialZoom: 11.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cyclago.app',
              ),
              MarkerLayer(
                markers: _destinations.asMap().entries.map((entry) {
                  int index = entry.key;
                  var dest = entry.value;
                  return Marker(
                    point: LatLng(dest['lat'], dest['lng']),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.hammersmithOne(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // DAY SELECTOR (Top)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Text(
                  'DAY:',
                  style: GoogleFonts.hammersmithOne(
                    color: Colors.black,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryBlue, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: DropdownButton<int>(
                          value: _selectedDay,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: List.generate(7, (index) => index + 1)
                              .map((day) => DropdownMenuItem(
                                    value: day,
                                    child: Text('Day $day'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedDay = value!);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM PANEL
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: primaryBlue, width: 1),
              ),
              child: Column(
                children: [
                  // Header: Back, Title, Check
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: primaryBlue),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Plan your trip',
                          style: GoogleFonts.hammersmithOne(
                            color: Colors.black,
                            fontSize: 28,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Save and go back to calendar
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category Icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCategoryButton(0, Icons.beach_access),
                        _buildCategoryButton(1, Icons.restaurant),
                        _buildCategoryButton(2, Icons.account_balance),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Destinations List
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: _destinations.length,
                        itemBuilder: (context, index) {
                          return _buildDestinationCard(index + 1, _destinations[index]['name']);
                        },
                      ),
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

  Widget _buildCategoryButton(int index, IconData icon) {
    bool isSelected = _selectedCategory == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = index),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryBlue, width: 1),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : primaryBlue,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildDestinationCard(int number, String name) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue, width: 1),
      ),
      child: Row(
        children: [
          // Number circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.hammersmithOne(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Destination name
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.hammersmithOne(
                color: primaryBlue,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
