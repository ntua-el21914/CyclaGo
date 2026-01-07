import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cyclago/core/destination_service.dart';
import 'package:cyclago/core/trip_service.dart';
import 'trip_planner_screen.dart';
import 'trip_map_screen.dart';

class TripViewScreen extends StatefulWidget {
  final String tripId;
  final String tripName;
  final String islandName;
  final DateTime startDate;
  final DateTime endDate;

  const TripViewScreen({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.islandName,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<TripViewScreen> createState() => _TripViewScreenState();
}

class _TripViewScreenState extends State<TripViewScreen> {
  final MapController _mapController = MapController();
  final Color primaryBlue = const Color(0xFF1269C7);
  
  // Island centers for map positioning - all 23 Cyclades islands
  static const Map<String, LatLng> _islandCenters = {
    'amorgos': LatLng(36.8333, 25.8833),
    'anafi': LatLng(36.3567, 25.7823),
    'antiparos': LatLng(37.0378, 25.0789),
    'delos': LatLng(37.3956, 25.2667),
    'donoussa': LatLng(36.9289, 25.8089),
    'folegandros': LatLng(36.6214, 24.9206),
    'ios': LatLng(36.7235, 25.2829),
    'iraklia': LatLng(36.8456, 25.4523),
    'kea': LatLng(37.6289, 24.3289),
    'kimolos': LatLng(36.7945, 24.5712),
    'koufonisia': LatLng(36.9356, 25.5923),
    'kythnos': LatLng(37.3978, 24.4301),
    'milos': LatLng(36.7452, 24.4275),
    'mykonos': LatLng(37.4467, 25.3289),
    'naxos': LatLng(37.05, 25.45),
    'paros': LatLng(37.0853, 25.1522),
    'santorini': LatLng(36.3932, 25.4615),
    'schinoussa': LatLng(36.8734, 25.5089),
    'serifos': LatLng(37.1478, 24.4823),
    'sifnos': LatLng(36.9678, 24.6923),
    'sikinos': LatLng(36.6878, 25.1089),
    'syros': LatLng(37.4415, 24.9411),
    'tinos': LatLng(37.5404, 25.1630),
  };
  
  LatLng get _mapCenter {
    final key = widget.islandName.toLowerCase();
    return _islandCenters[key] ?? const LatLng(37.05, 25.45);
  }
  
  int _selectedDay = 1;
  bool _isDayDropdownOpen = false;
  bool _isLoading = true;
  bool _isPanelExpanded = true;
  String? _highlightedDestinationId;
  
  // Safe accessor for day index (prevents RangeError)
  int get _safeDayIndex => _tripDays.isEmpty ? 0 : (_selectedDay - 1).clamp(0, _tripDays.length - 1);
  Map<String, dynamic> get _safeCurrentDay => _tripDays.isEmpty ? {'day': 1, 'name': '', 'date': DateTime.now()} : _tripDays[_safeDayIndex];
  
  List<Map<String, dynamic>> _tripDays = [];
  
  List<Destination> _beaches = [];
  List<Destination> _restaurants = [];
  List<Destination> _landmarks = [];
  
  final Map<String, List<String>> _selectedSpots = {};
  
  // Key is just day number (unified across all categories - matching trip_map_screen)
  String get _selectionKey => '$_selectedDay';
  List<String> get _currentSelectedIds => _selectedSpots[_selectionKey] ?? [];
  
  // Get all destinations across all categories
  List<Destination> get _allDestinations => [..._beaches, ..._restaurants, ..._landmarks];
  
  // All selected destinations (unified list)
  List<Destination> get _selectedDestinations {
    final allDest = _allDestinations;
    if (allDest.isEmpty) return [];
    
    final selectedIds = _currentSelectedIds;
    final selected = <Destination>[];
    
    for (final id in selectedIds) {
      final dest = allDest.where((d) => d.id == id);
      if (dest.isNotEmpty) selected.add(dest.first);
    }
    return selected;
  }
  
  int get _selectedCount => _currentSelectedIds.length;
  
  void _removeSelection(String id) {
    setState(() {
      final key = _selectionKey;
      if (_selectedSpots.containsKey(key)) {
        _selectedSpots[key]!.remove(id);
      }
    });
    _saveSelections();
  }
  
  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex >= _selectedCount || newIndex > _selectedCount) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final key = _selectionKey;
      if (_selectedSpots.containsKey(key)) {
        final item = _selectedSpots[key]!.removeAt(oldIndex);
        _selectedSpots[key]!.insert(newIndex, item);
      }
    });
    _saveSelections();
  }
  
  Future<void> _loadSelections() async {
    try {
      final selections = await TripService.getSpotSelections(widget.tripId);
      setState(() {
        _selectedSpots.clear();
        _selectedSpots.addAll(selections);
      });
    } catch (e) {
      debugPrint('Error loading selections: $e');
    }
  }
  
  Future<void> _saveSelections() async {
    try {
      await TripService.saveSpotSelections(tripId: widget.tripId, selections: _selectedSpots);
    } catch (e) {
      debugPrint('Error saving selections: $e');
    }
  }
  
  @override
  void initState() {
    super.initState();
    _initializeDays();
    _loadDestinations();
    _loadSelections();
  }
  
  void _initializeDays() {
    final tripLength = widget.endDate.difference(widget.startDate).inDays + 1;
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    _tripDays = List.generate(tripLength, (index) {
      final date = widget.startDate.add(Duration(days: index));
      return {'day': index + 1, 'name': weekdays[date.weekday - 1], 'date': date};
    });
  }
  
  Future<void> _loadDestinations() async {
    setState(() => _isLoading = true);
    try {
      final allDestinations = await DestinationService.getAllDestinations(widget.islandName);
      setState(() {
        _beaches = allDestinations['beaches'] ?? [];
        _restaurants = allDestinations['restaurants'] ?? [];
        _landmarks = allDestinations['landmarks'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
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
                markers: _selectedDestinations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dest = entry.value;
                  final isHighlighted = _highlightedDestinationId == dest.id;
                  return Marker(
                    point: LatLng(dest.lat, dest.lng),
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.location_on, color: isHighlighted ? Colors.green : primaryBlue, size: 50),
                        Positioned(
                          top: 8,
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.hammersmithOne(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Trip name header at top (simple text)
          Positioned(
            top: 15,
            left: 20,
            right: 20,
            child: Text(
              widget.tripName,
              textAlign: TextAlign.center,
              style: GoogleFonts.hammersmithOne(
                color: Colors.black,
                fontSize: 22,
                shadows: [Shadow(color: Colors.white, blurRadius: 4)],
              ),
            ),
          ),

          // Tap outside to close dropdown
          if (_isDayDropdownOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isDayDropdownOpen = false),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),

          // DAY SELECTOR
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text('DAY:', style: GoogleFonts.hammersmithOne(color: Colors.black, fontSize: 24)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: primaryBlue),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isDayDropdownOpen = !_isDayDropdownOpen),
                              child: Container(
                                height: 60,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text('$_selectedDay', style: GoogleFonts.hammersmithOne(color: Colors.white, fontSize: 24)),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            _safeCurrentDay['name'] ?? '',
                                            style: GoogleFonts.hammersmithOne(color: Colors.black, fontSize: 24),
                                          ),
                                          const Spacer(),
                                          if (_tripDays.isNotEmpty)
                                            Text(
                                              '${(_safeCurrentDay['date'] as DateTime).day}/${(_safeCurrentDay['date'] as DateTime).month}',
                                              style: GoogleFonts.hammersmithOne(color: Colors.grey[600], fontSize: 18),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(_isDayDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: primaryBlue, size: 28),
                                  ],
                                ),
                              ),
                            ),
                            if (_isDayDropdownOpen)
                              Container(
                                constraints: const BoxConstraints(maxHeight: 300),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _tripDays.length,
                                  itemBuilder: (context, index) {
                                    final dayData = _tripDays[index];
                                    final isSelected = dayData['day'] == _selectedDay;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedDay = dayData['day'];
                                          _isDayDropdownOpen = false;
                                        });
                                      },
                                      child: Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.transparent,
                                          border: Border(top: BorderSide(width: 1, color: primaryBlue.withOpacity(0.3))),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                                              child: Center(child: Text('${dayData['day']}', style: GoogleFonts.hammersmithOne(color: Colors.white, fontSize: 24))),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Text(dayData['name'], style: GoogleFonts.hammersmithOne(color: isSelected ? primaryBlue : Colors.black, fontSize: 22)),
                                                  const Spacer(),
                                                  Text('${(dayData['date'] as DateTime).day}/${(dayData['date'] as DateTime).month}', style: GoogleFonts.hammersmithOne(color: isSelected ? primaryBlue : Colors.grey[600], fontSize: 16)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BOTTOM PANEL
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isPanelExpanded ? MediaQuery.of(context).size.height * 0.45 : 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: primaryBlue, width: 1),
              ),
              child: Column(
                children: [
                  // Drag handle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
                    onVerticalDragEnd: (details) {
                      // Drag down = collapse, drag up = expand
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! > 100) {
                          // Dragging down - collapse
                          setState(() => _isPanelExpanded = false);
                        } else if (details.primaryVelocity! < -100) {
                          // Dragging up - expand
                          setState(() => _isPanelExpanded = true);
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 6,
                          decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  // Header with back, edit, delete - icons centered with equal distance from center
                  if (_isPanelExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: Row(
                        children: [
                          IconButton(icon: Icon(Icons.arrow_back_ios, color: primaryBlue), onPressed: () => Navigator.pop(context)),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: primaryBlue, size: 28),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TripPlannerScreen(
                                          tripId: widget.tripId,
                                          existingTripName: widget.tripName,
                                          existingIsland: widget.islandName,
                                          existingStartDate: widget.startDate,
                                          existingEndDate: widget.endDate,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 40),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 28),
                                  onPressed: () => _showDeleteConfirmation(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48), // Balance back button width
                        ],
                      ),
                    ),
                  // Unified list - no category buttons needed
                  if (_isPanelExpanded) const SizedBox(height: 10),
                  // Selected spots list
                  if (_isPanelExpanded)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.white))
                            : _selectedCount == 0
                                ? Center(
                                    child: Text(
                                      'No spots selected\nAdd spots in Trip Planner!',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.hammersmithOne(color: Colors.white70, fontSize: 18),
                                    ),
                                  )
                                : ReorderableListView.builder(
                                    padding: const EdgeInsets.only(top: 10),
                                    itemCount: _selectedCount,
                                    onReorder: _onReorder,
                                    proxyDecorator: (child, index, animation) => Material(
                                      color: Colors.transparent,
                                      elevation: 6,
                                      shadowColor: Colors.black45,
                                      borderRadius: BorderRadius.circular(20),
                                      child: child,
                                    ),
                                    itemBuilder: (context, index) {
                                      final dest = _selectedDestinations[index];
                                      return _buildSpotCard(
                                        key: ValueKey(dest.id),
                                        id: dest.id,
                                        index: index,
                                        number: index + 1,
                                        name: dest.name,
                                        category: dest.category,
                                      );
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

  Widget _buildSpotCard({
    required Key key,
    required String id,
    required int index,
    required int number,
    required String name,
    required String category,
  }) {
    final isHighlighted = _highlightedDestinationId == id;
    
    // Get category icon
    IconData categoryIcon;
    switch (category) {
      case 'beaches':
        categoryIcon = Icons.beach_access;
        break;
      case 'restaurants':
        categoryIcon = Icons.restaurant;
        break;
      case 'landmarks':
        categoryIcon = Icons.account_balance;
        break;
      default:
        categoryIcon = Icons.place;
    }
    
    return ReorderableDelayedDragStartListener(
      key: key,
      index: index,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _highlightedDestinationId = _highlightedDestinationId == id ? null : id;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isHighlighted ? Colors.green : primaryBlue, width: isHighlighted ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: isHighlighted ? Colors.green : primaryBlue, shape: BoxShape.circle),
                child: Center(child: Text('$number', style: GoogleFonts.hammersmithOne(color: Colors.white, fontSize: 20))),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(name, style: GoogleFonts.hammersmithOne(color: isHighlighted ? Colors.green : primaryBlue, fontSize: 20))),
              // Category icon on the right
              Icon(categoryIcon, color: isHighlighted ? Colors.green : primaryBlue, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Trip', style: GoogleFonts.hammersmithOne()),
        content: Text('Are you sure you want to delete "${widget.tripName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: primaryBlue)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await TripService.deleteTrip(widget.tripId);
              if (mounted) {
                Navigator.popUntil(context, (route) => route.isFirst); // Go to calendar
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
