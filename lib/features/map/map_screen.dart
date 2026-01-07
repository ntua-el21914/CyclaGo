import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cyclago/core/destination_service.dart';
import 'package:cyclago/features/camera/camera_screen.dart';

class MapScreen extends StatefulWidget {
  final Function(bool) onToggleNavBar;
  final double? userLat;
  final double? userLng;
  final bool hasPosted;
  final Function(int)? onSwitchTab;
  final String? currentIsland;

  const MapScreen({
    super.key, 
    required this.onToggleNavBar,
    this.userLat,
    this.userLng,
    this.hasPosted = false,
    this.onSwitchTab,
    this.currentIsland,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  final Color primaryBlue = const Color(0xFF1269C7);
  
  // State
  String? _selectedIsland;
  String? _userIsland; // The island user is ACTUALLY on (from GPS)
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isExploreExpanded = false;
  int _selectedCategory = 0; // 0=beaches, 1=restaurants, 2=landmarks
  bool _isLoading = false;
  bool _hasInitializedFromLocation = false;
  bool _hasPostedRecently = false;
  bool _showingSpotsList = false; // false = default (camera/chat), true = spots list
  
  // Check if user is on the selected island
  bool get _isUserOnSelectedIsland => 
      _userIsland != null && 
      _selectedIsland != null && 
      _userIsland!.toLowerCase() == _selectedIsland!.toLowerCase();
  
  // Destinations from Firebase
  List<Destination> _beaches = [];
  List<Destination> _restaurants = [];
  List<Destination> _landmarks = [];
  
  // Chat controller
  final TextEditingController _chatController = TextEditingController();
  
  // All 23 Cyclades islands
  static List<String> get _islands => DestinationService.islands;
  
  // Island centers for map positioning
  static Map<String, LatLng> get _islandCenters => DestinationService.islandCenters;
  
  LatLng get _currentCenter {
    if (_selectedIsland == null) return const LatLng(37.05, 25.45); // Default Naxos
    return _islandCenters[_selectedIsland!.toLowerCase()] ?? const LatLng(37.05, 25.45);
  }
  
  List<Destination> get _currentDestinations {
    switch (_selectedCategory) {
      case 0: return _beaches;
      case 1: return _restaurants;
      case 2: return _landmarks;
      default: return _beaches;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
    // Try to detect island from user's location
    _initFromUserLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check location whenever the screen becomes visible
    _refreshLocation();
  }

  void _refreshLocation() {
    if (widget.userLat != null && widget.userLng != null) {
      final nearestIsland = DestinationService.findNearestIsland(widget.userLat!, widget.userLng!);
      if (nearestIsland != null) {
        if (_userIsland != nearestIsland) {
          setState(() {
            _userIsland = nearestIsland;
            _hasInitializedFromLocation = true;
          });
          // Auto-select the nearest island if none is selected
          if (_selectedIsland == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _selectIsland(nearestIsland);
            });
          }
        }
      }
    }
  }

  Future<void> _checkRecentPost() async {
    if (_selectedIsland == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .where('island', isEqualTo: _selectedIsland)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _hasPostedRecently = querySnapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking recent posts: $e');
    }
  }
  
  void _initFromUserLocation() {
    if (widget.userLat != null && widget.userLng != null && !_hasInitializedFromLocation) {
      final nearestIsland = DestinationService.findNearestIsland(widget.userLat!, widget.userLng!);
      if (nearestIsland != null) {
        _hasInitializedFromLocation = true;
        _userIsland = nearestIsland; // Store user's actual island
        // Auto-select the nearest island
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _selectIsland(nearestIsland);
        });
      }
    }
  }
  


  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    
    setState(() {
      _suggestions = _islands
          .where((island) => island.toLowerCase().contains(query))
          .toList();
      _showSuggestions = _suggestions.isNotEmpty;
    });
  }
  
  void _selectIsland(String island) {
    setState(() {
      _selectedIsland = island;
      _searchController.text = island;
      _showSuggestions = false;
      _isExploreExpanded = true;
      _isLoading = true;
    });
    
    // Move map to island
    final center = _islandCenters[island.toLowerCase()];
    if (center != null) {
      _mapController.move(center, 12.0);
    }
    
    FocusScope.of(context).unfocus();
    widget.onToggleNavBar(false); // Hide nav bar
    
    // Check if user has posted recently in this island
    _checkRecentPost();
    
    // Load destinations from Firebase
    _loadDestinations(island);
  }
  
  Future<void> _loadDestinations(String island) async {
    try {
      final beaches = await DestinationService.getBeaches(island);
      final restaurants = await DestinationService.getRestaurants(island);
      final landmarks = await DestinationService.getLandmarks(island);
      
      if (mounted) {
        setState(() {
          _beaches = beaches;
          _restaurants = restaurants;
          _landmarks = landmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _closeExplorePanel() {
    setState(() {
      _isExploreExpanded = false;
      _selectedIsland = null;
      _searchController.clear();
    });
    widget.onToggleNavBar(true); // Show nav bar again
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
              initialCenter: const LatLng(37.05, 25.45), // Naxos default
              initialZoom: 9.5, // Zoomed out to see all Cyclades
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, __) {
                setState(() => _showSuggestions = false);
                if (!_isExploreExpanded) {
                  widget.onToggleNavBar(true);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cyclago.app',
              ),
              // Show markers for current destinations
              if (_selectedIsland != null && !_isLoading)
                MarkerLayer(
                  markers: _currentDestinations.map((dest) => 
                    Marker(
                      point: LatLng(dest.lat, dest.lng),
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => _showDestinationDetails(dest),
                        child: Column(
                          children: [
                            Icon(Icons.location_on, color: primaryBlue, size: 40),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                dest.name,
                                style: GoogleFonts.hammersmithOne(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).toList(),
                ),
            ],
          ),

          // SEARCH BAR + AUTOCOMPLETE
          Positioned(
            top: 45,
            left: 25,
            right: 25,
            child: Column(
              children: [
                // Search Bar
                Container(
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
                      // Back button when explore is open
                      if (_isExploreExpanded)
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: primaryBlue),
                          onPressed: _closeExplorePanel,
                        )
                      else
                        const SizedBox(width: 20),
                      
                      Icon(Icons.search, color: primaryBlue, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onTap: () => setState(() => _showSuggestions = _suggestions.isNotEmpty),
                          decoration: InputDecoration(
                            hintText: 'Search island...',
                            hintStyle: GoogleFonts.hammersmithOne(
                              color: Colors.grey,
                              fontSize: 20,
                            ),
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.hammersmithOne(fontSize: 20),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _showSuggestions = false);
                            // Also close explore panel when clearing search
                            if (_isExploreExpanded) {
                              _closeExplorePanel();
                            }
                          },
                        ),
                    ],
                  ),
                ),
                
                // Autocomplete Suggestions Dropdown
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: primaryBlue, width: 1),
                      boxShadow: const [
                        BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.location_on, color: primaryBlue),
                          title: Text(
                            _suggestions[index],
                            style: GoogleFonts.hammersmithOne(fontSize: 18),
                          ),
                          onTap: () => _selectIsland(_suggestions[index]),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // EXPLORE PANEL (Bottom) - shows when island selected
          if (_selectedIsland != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  // Drag down to collapse, drag up to expand
                  if (details.delta.dy > 5 && _isExploreExpanded) {
                    setState(() => _isExploreExpanded = false);
                  } else if (details.delta.dy < -5 && !_isExploreExpanded) {
                    setState(() => _isExploreExpanded = true);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _isExploreExpanded ? 320 : 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: primaryBlue, width: 1),
                    boxShadow: const [
                      BoxShadow(color: Color(0x3F000000), blurRadius: 10, offset: Offset(0, -2))
                    ],
                  ),
                  child: Column(
                    children: [
                      // ENTIRE WHITE HEADER AREA - TAP TO RETURN TO DEFAULT MODE (only if on island)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // Only reset to default mode if user is ON this island
                          if (_isUserOnSelectedIsland && _showingSpotsList) {
                            setState(() => _showingSpotsList = false);
                          }
                        },
                        child: Column(
                          children: [
                            // Drag handle - toggles collapse
                            GestureDetector(
                              onTap: () => setState(() => _isExploreExpanded = !_isExploreExpanded),
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
                            
                            // Header (only when expanded)
                            if (_isExploreExpanded)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: _closeExplorePanel,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: primaryBlue, width: 3),
                                      ),
                                      child: Icon(Icons.close, size: 20, color: primaryBlue),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Explore',
                                    style: GoogleFonts.hammersmithOne(
                                      fontSize: 28,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  const SizedBox(width: 36), // Balance
                                ],
                              ),
                            ),
                            
                            // Category buttons (only when expanded)
                            if (_isExploreExpanded)
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
                            if (_isExploreExpanded) const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    
                    // CONTENT: Depends on whether user is ON this island
                    // If NOT on island: always show spots list
                    // If ON island: show mode switching (spots OR camera/chat)
                    if (_isExploreExpanded)
                    Expanded(
                      child: (!_isUserOnSelectedIsland || _showingSpotsList)
                          ? // Show spots list (always if not on island, or if in spots mode)
                            Container(
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              ),
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                    : _currentDestinations.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No destinations found',
                                              style: GoogleFonts.hammersmithOne(color: Colors.white70, fontSize: 16),
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                                            itemCount: _currentDestinations.length,
                                            itemBuilder: (context, index) {
                                              final dest = _currentDestinations[index];
                                              return GestureDetector(
                                                onTap: () {
                                                  _mapController.move(LatLng(dest.lat, dest.lng), 14.0);
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(25),
                                                    border: Border.all(color: primaryBlue.withOpacity(0.3), width: 1),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          dest.name,
                                                          style: GoogleFonts.hammersmithOne(
                                                            fontSize: 18,
                                                            color: primaryBlue,
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(Icons.arrow_forward_ios, color: primaryBlue, size: 18),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                              )
                            : // MODE 1: Default - show camera/chat (only if on island)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: primaryBlue, width: 1),
                                ),
                                child: _hasPostedRecently
                                    ? // UNLOCKED: Show Embedded Chat
                                      _buildEmbeddedChat()
                                    : // LOCKED: Show Post to view camera button
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            // Navigate directly to camera screen
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => CameraScreen(currentIsland: widget.currentIsland)),
                                            );
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: primaryBlue,
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                "Post to view",
                                                style: GoogleFonts.hammersmithOne(fontSize: 14, color: primaryBlue),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryButton(int index, IconData icon) {
    // Show as selected if:
    // - Not on island (spots always shown, show selected category)
    // - OR on island and showing spots list with this category
    bool isSelected = _selectedCategory == index && 
        (!_isUserOnSelectedIsland || _showingSpotsList);
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategory = index;
        _showingSpotsList = true; // Switch to spots list mode
      }),
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
  
  // EMBEDDED CHAT WIDGET
  Widget _buildEmbeddedChat() {
    if (_selectedIsland == null) return const SizedBox();
    
    final islandLower = _selectedIsland!.toLowerCase();
    
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            "$_selectedIsland Chat",
            style: GoogleFonts.hammersmithOne(fontSize: 16, color: primaryBlue, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Messages list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('destinations')
                .doc(islandLower)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: primaryBlue));
              }
              
              final messages = snapshot.data!.docs;
              
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    "No messages yet. Say hello!",
                    style: GoogleFonts.hammersmithOne(color: Colors.grey, fontSize: 14),
                  ),
                );
              }
              
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data() as Map<String, dynamic>;
                  final username = msg['senderName'] ?? 'Anonymous';
                  final text = msg['text'] ?? '';
                  final isMe = msg['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                  
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe ? primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: isMe ? null : Border.all(color: primaryBlue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              "@$username",
                              style: GoogleFonts.hammersmithOne(
                                fontSize: 10,
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            text,
                            style: GoogleFonts.hammersmithOne(
                              fontSize: 13,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Message input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: GoogleFonts.hammersmithOne(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: GoogleFonts.hammersmithOne(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: primaryBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty || _selectedIsland == null) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final islandLower = _selectedIsland!.toLowerCase();
    String username = "Cyclist";
    
    // Get username from Firestore
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        username = userDoc.data()?['username'] ?? "Cyclist";
      }
    } catch (e) {
      print("Error getting username: $e");
    }
    
    // Send message
    await FirebaseFirestore.instance
        .collection('destinations')
        .doc(islandLower)
        .collection('messages')
        .add({
      'text': _chatController.text.trim(),
      'senderName': username,
      'senderId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    _chatController.clear();
  }
  
  void _showDestinationDetails(Destination dest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 380,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                dest.name,
                style: GoogleFonts.hammersmithOne(fontSize: 28, color: primaryBlue),
              ),
              const SizedBox(height: 15),
              // Image from Cloudinary
              if (dest.imageUrl != null && dest.imageUrl!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: primaryBlue, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(
                      dest.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: primaryBlue,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 50),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(Icons.image, color: Colors.grey[400], size: 50),
                  ),
                ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  dest.description ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hammersmithOne(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}