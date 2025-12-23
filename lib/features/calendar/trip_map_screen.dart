import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cyclago/core/destination_service.dart';
import 'package:cyclago/core/trip_service.dart';

class TripMapScreen extends StatefulWidget {
  final String? tripId;
  final String tripName;
  final String islandName;
  final DateTime startDate;
  final DateTime endDate;

  const TripMapScreen({
    super.key,
    this.tripId,
    required this.tripName,
    required this.islandName,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
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
  
  int _selectedCategory = 0;
  int _selectedDay = 1;
  bool _isDayDropdownOpen = false;
  bool _isLoading = true;
  bool _isPanelExpanded = true;
  String? _highlightedDestinationId;
  
  List<Map<String, dynamic>> _tripDays = [];
  
  List<Destination> _beaches = [];
  List<Destination> _restaurants = [];
  List<Destination> _landmarks = [];
  
  // Selected destinations per day (unified list, not separated by category)
  final Map<String, List<String>> _selectedSpots = {};
  
  // Key is just day number (unified across all categories)
  String get _selectionKey => '$_selectedDay';
  List<String> get _currentSelectedIds => _selectedSpots[_selectionKey] ?? [];
  
  // Get all destinations across all categories for lookup
  List<Destination> get _allDestinations => [..._beaches, ..._restaurants, ..._landmarks];
  
  List<Destination> get _currentDestinations {
    switch (_selectedCategory) {
      case 0: return _beaches;
      case 1: return _restaurants;
      case 2: return _landmarks;
      default: return _beaches;
    }
  }
  
  // Returns: [all selected spots in order] + [unselected spots from current category]
  List<Destination> get _sortedDestinations {
    final selectedIds = _currentSelectedIds;
    final allDest = _allDestinations;
    final categoryDest = _currentDestinations;
    
    // Get all selected destinations in order
    final selected = <Destination>[];
    for (final id in selectedIds) {
      final dest = allDest.where((d) => d.id == id);
      if (dest.isNotEmpty) selected.add(dest.first);
    }
    
    // Get unselected destinations from current category only
    final unselected = <Destination>[];
    for (final dest in categoryDest) {
      if (!selectedIds.contains(dest.id)) unselected.add(dest);
    }
    
    return [...selected, ...unselected];
  }
  
  // Destinations to show on map: current category + selected from other categories
  List<Destination> get _mapDestinations {
    final selectedIds = _currentSelectedIds;
    final allDest = _allDestinations;
    final categoryDest = _currentDestinations;
    
    // Start with all from current category
    final result = <Destination>[...categoryDest];
    
    // Add selected spots from OTHER categories (not current)
    for (final id in selectedIds) {
      final dest = allDest.where((d) => d.id == id);
      if (dest.isNotEmpty && !categoryDest.any((d) => d.id == id)) {
        result.add(dest.first);
      }
    }
    
    return result;
  }
  
  int get _selectedCount => _currentSelectedIds.length;
  
  void _toggleSelection(String id) {
    setState(() {
      final key = _selectionKey;
      if (!_selectedSpots.containsKey(key)) _selectedSpots[key] = [];
      if (_selectedSpots[key]!.contains(id)) {
        _selectedSpots[key]!.remove(id);
      } else {
        // Add at the BOTTOM of the list (newest last)
        _selectedSpots[key]!.add(id);
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
    if (widget.tripId == null) return;
    try {
      final selections = await TripService.getSpotSelections(widget.tripId!);
      setState(() {
        _selectedSpots.clear();
        _selectedSpots.addAll(selections);
      });
    } catch (e) {
      debugPrint('Error loading selections: $e');
    }
  }
  
  Future<void> _saveSelections() async {
    if (widget.tripId == null) return;
    try {
      await TripService.saveSpotSelections(tripId: widget.tripId!, selections: _selectedSpots);
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
      print('Error loading destinations: $e');
      setState(() => _isLoading = false);
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
                markers: _mapDestinations.map((dest) {
                  final isSelected = _currentSelectedIds.contains(dest.id);
                  final isHighlighted = _highlightedDestinationId == dest.id;
                  final selectionIndex = isSelected 
                      ? _currentSelectedIds.indexOf(dest.id) + 1 
                      : null;
                  
                  // Determine marker color
                  Color markerColor;
                  if (isSelected) {
                    markerColor = primaryBlue;
                  } else if (isHighlighted) {
                    markerColor = Colors.green;
                  } else {
                    markerColor = Colors.grey;
                  }
                  
                  return Marker(
                    point: LatLng(dest.lat, dest.lng),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _toggleSelection(dest.id),
                      onLongPress: () {
                        setState(() => _highlightedDestinationId = dest.id);
                      },
                      onLongPressEnd: (_) {
                        setState(() => _highlightedDestinationId = null);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: markerColor,
                            size: 50,
                          ),
                          if (isSelected && selectionIndex != null)
                            Positioned(
                              top: 8,
                              child: Text(
                                '$selectionIndex',
                                style: GoogleFonts.hammersmithOne(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Tap outside dropdown to close it
          if (_isDayDropdownOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isDayDropdownOpen = false),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
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

          // DAY SELECTOR (Top) - Inline expandable dropdown
          Positioned(
            top: 70,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DAY: label
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    'DAY:',
                    style: GoogleFonts.hammersmithOne(
                      color: Colors.black,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Expandable dropdown container
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
                        // Selected day header (always visible)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDayDropdownOpen = !_isDayDropdownOpen;
                            });
                          },
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                // Day number circle
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$_selectedDay',
                                      style: GoogleFonts.hammersmithOne(
                                        color: Colors.white,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                // Day name and date
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        _tripDays[_selectedDay - 1]['name'],
                                        style: GoogleFonts.hammersmithOne(
                                          color: Colors.black,
                                          fontSize: 24,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${(_tripDays[_selectedDay - 1]['date'] as DateTime).day}/${(_tripDays[_selectedDay - 1]['date'] as DateTime).month}',
                                        style: GoogleFonts.hammersmithOne(
                                          color: Colors.grey[600],
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Dropdown arrow
                                Icon(
                                  _isDayDropdownOpen 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down,
                                  color: primaryBlue,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Expanded list (only visible when open)
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
                                      _selectedCategory = 0; // Reset to beaches
                                      _isDayDropdownOpen = false;
                                    });
                                  },
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.transparent,
                                      border: Border(
                                        top: BorderSide(
                                          width: 1,
                                          color: primaryBlue.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        // Day number circle
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${dayData['day']}',
                                              style: GoogleFonts.hammersmithOne(
                                                color: Colors.white,
                                                fontSize: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        // Day name and date
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                dayData['name'],
                                                style: GoogleFonts.hammersmithOne(
                                                  color: isSelected ? primaryBlue : Colors.black,
                                                  fontSize: 22,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${(dayData['date'] as DateTime).day}/${(dayData['date'] as DateTime).month}',
                                                style: GoogleFonts.hammersmithOne(
                                                  color: isSelected ? primaryBlue : Colors.grey[600],
                                                  fontSize: 16,
                                                ),
                                              ),
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
            // Left/Right arrows BELOW the container (when collapsed)
            if (!_isDayDropdownOpen)
              Padding(
                padding: const EdgeInsets.only(left: 60, top: 4), // offset for "DAY:" label
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left, color: _selectedDay > 1 ? primaryBlue : Colors.grey, size: 36),
                      onPressed: _selectedDay > 1 
                          ? () => setState(() { _selectedDay--; _selectedCategory = 0; })
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 40),
                    IconButton(
                      icon: Icon(Icons.arrow_right, color: _selectedDay < _tripDays.length ? primaryBlue : Colors.grey, size: 36),
                      onPressed: _selectedDay < _tripDays.length 
                          ? () => setState(() { _selectedDay++; _selectedCategory = 0; })
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isPanelExpanded 
                  ? MediaQuery.of(context).size.height * 0.45 
                  : 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: primaryBlue, width: 1),
              ),
              child: Column(
                children: [
                  // Drag handle to toggle panel
                  GestureDetector(
                    onTap: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Header: Back, Title, Check
                  if (_isPanelExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
                          // Check button only on last day
                          if (_selectedDay == _tripDays.length)
                            GestureDetector(
                              onTap: () {
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
                            )
                          else
                            const SizedBox(width: 40),
                        ],
                      ),
                    ),

                  // Category Icons (only when expanded)
                  if (_isPanelExpanded)
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
                  if (_isPanelExpanded) const SizedBox(height: 10),

                  // Destinations List (only when expanded)
                  if (_isPanelExpanded)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : _currentDestinations.isEmpty
                              ? Center(
                                  child: Text(
                                    'No destinations found\nAdd some in Firebase!',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.hammersmithOne(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),
                                )
                              : CustomScrollView(
                                  slivers: [
                                    // Selected spots (reorderable) - scrolls with list
                                    if (_selectedCount > 0)
                                      SliverPadding(
                                        padding: const EdgeInsets.only(top: 10),
                                        sliver: SliverReorderableList(
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
                                            final destId = _currentSelectedIds[index];
                                            // Use _allDestinations to find ANY selected item (not just current category)
                                            final destSearch = _allDestinations.where((d) => d.id == destId);
                                            if (destSearch.isEmpty) {
                                              return const SizedBox.shrink(); // Skip if not found
                                            }
                                            final destination = destSearch.first;
                                            return _buildDestinationCard(
                                              key: ValueKey(destination.id),
                                              id: destination.id,
                                              index: index,
                                              number: index + 1,
                                              name: destination.name,
                                              category: destination.category,
                                              isSelected: true,
                                            );
                                          },
                                        ),
                                      ),
                                    // Unselected spots - continues in same scroll
                                    SliverPadding(
                                      padding: EdgeInsets.only(top: _selectedCount > 0 ? 5 : 10, bottom: 20),
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            final destination = _sortedDestinations[_selectedCount + index];
                                            return _buildDestinationCard(
                                              key: ValueKey(destination.id),
                                              id: destination.id,
                                              index: null,
                                              number: null,
                                              name: destination.name,
                                              category: destination.category,
                                              isSelected: false,
                                            );
                                          },
                                          childCount: _sortedDestinations.length - _selectedCount,
                                        ),
                                      ),
                                    ),
                                  ],
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

  Widget _buildDestinationCard({
    required Key key,
    required String id,
    required int? index,
    required int? number,
    required String name,
    required String category,
    required bool isSelected,
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
    
    Widget card = GestureDetector(
      key: key,
      onTap: () => _toggleSelection(id),
      // Only add long press handlers for unselected items (selected uses reorderable)
      onLongPress: isSelected ? null : () {
        setState(() => _highlightedDestinationId = id);
      },
      onLongPressEnd: isSelected ? null : (_) {
        setState(() => _highlightedDestinationId = null);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryBlue 
              : isHighlighted 
                  ? Colors.green.shade100 
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted ? Colors.green : primaryBlue, 
            width: isHighlighted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isSelected && number != null)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: Text('$number', style: GoogleFonts.hammersmithOne(color: primaryBlue, fontSize: 20)),
                ),
              )
            else
              const SizedBox(width: 50, height: 50),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.hammersmithOne(color: isSelected ? Colors.white : primaryBlue, fontSize: 20),
              ),
            ),
            // Category icon on the right
            Icon(categoryIcon, color: isSelected ? Colors.white : primaryBlue, size: 28),
          ],
        ),
      ),
    );
    
    // Wrap selected items in ReorderableDelayedDragStartListener for long-press drag
    if (isSelected && index != null) {
      return ReorderableDelayedDragStartListener(
        key: key,
        index: index,
        child: card,
      );
    }
    
    return card;
  }
}
