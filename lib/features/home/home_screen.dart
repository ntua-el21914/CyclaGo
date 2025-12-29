import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
// Σιγουρέψου ότι αυτό το import είναι σωστό για το Project σου
import '../../main.dart';
import '../../core/destination_service.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
   String _displayName = "";
  List<String> _selectedIslands = [];
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _selectRandomIslands();
    Future.microtask(() => _getCurrentIsland());
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onPageChanged);
  }

  // --- 1. ΛΟΓΙΚΗ ΓΙΑ ΤΟ ΟΝΟΜΑ ΧΡΗΣΤΗ ---
  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Ψάχνουμε τον χρήστη με βάση το email του
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        if (mounted) {
          setState(() {
            // Δείξε το firstName, αλλιώς το username
            _displayName = userData['username'] ?? userData['email'] ?? '';
          }
          );
        }
      }
    }
  }

  // --- SELECT RANDOM ISLANDS ---
  void _selectRandomIslands({String? currentIsland}) {
    final allIslands = List<String>.from(DestinationService.islands);
    allIslands.shuffle();
    if (currentIsland != null && allIslands.contains(currentIsland)) {
      allIslands.remove(currentIsland);
      allIslands.insert(0, currentIsland);
    }
    _selectedIslands = allIslands.take(4).toList();
  }

  Future<void> _getCurrentIsland() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        String? currentIsland = DestinationService.findNearestIsland(position.latitude, position.longitude);
        if (currentIsland != null && mounted) {
          setState(() {
            _selectRandomIslands(currentIsland: currentIsland);
          });
        }
      }
    } catch (e) {
      // If location fails, keep random selection
    }
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    const Color backgroundColor = Color(0xFFF6F9FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true, // Allow body to extend behind nav bar
      
      // --- NAVIGATION BAR ---
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),

      body: SafeArea(
        bottom: false,
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent, Colors.transparent],
              stops: [0.0, 0.95, 0.95, 1.0], // Sharp cutoff at 90%
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER (Hello User) ---
              RichText(
                text: TextSpan(
                  style: GoogleFonts.hammersmithOne(fontSize: 24, color: Colors.black),
                  children: [
                    const TextSpan(text: 'Hello,\n'),
                    TextSpan(
                      text: _displayName, // Δυναμικό όνομα
                      style: GoogleFonts.hammersmithOne(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // --- ISLAND IMAGES SCROLLABLE ---
              SizedBox(
                height: 330,
                child: PageView(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  children: List.generate(4, (index) {
                    final island = _selectedIslands[index];
                    final imageUrl = DestinationService.islandImages[island.toLowerCase()] ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(child: Icon(Icons.error)),
                                  );
                                },
                              )
                            else
                              Container(
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.image_not_supported)),
                              ),
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Text(
                                island,
                                style: GoogleFonts.hammersmithOne(
                                  color: primaryBlue,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    const Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 6.0,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 10),

              // Page Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPage.round() ? primaryBlue : Colors.grey.withOpacity(0.5),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              // --- EVENTS SECTION WRAPPED IN BOX ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0), // Εσωτερικό κενό
                decoration: BoxDecoration(
                  color: Colors.white, // Λευκό φόντο
                  borderRadius: BorderRadius.circular(20), // Στρογγυλεμένες γωνίες
                  border: Border.all(
                    color: primaryBlue, // Το μπλε περίγραμμα
                    width: 2, // Πάχος περιγράμματος
                  ),
                  // Προαιρετικά: Λίγη σκιά για να ξεχωρίζει
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Τίτλος Events (Μέσα στο κουτί πλέον)
                    Text(
                      'Events',
                      style: GoogleFonts.hammersmithOne(
                        color: primaryBlue,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Οι κάρτες
                    const _InfoCard(
                      title: "Beach Sunset Party",
                      subtitle: "Today • Agios Prokopios",
                      icon: Icons.beach_access,
                    ),
                    const SizedBox(height: 10),
                    const _InfoCard(
                      title: "Panigyri",
                      subtitle: "Tomorrow • Chora",
                      icon: Icons.music_note,
                    ),
                    const SizedBox(height: 10),
                    const _InfoCard(
                      title: "Diving Competition",
                      subtitle: "Friday • Agios Prokopios",
                      icon: Icons.scuba_diving,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- CHALLENGES SECTION WRAPPED IN BOX ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryBlue,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Challenges',
                      style: GoogleFonts.hammersmithOne(
                        color: primaryBlue,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    const _InfoCard(
                      title: "Visit 5 Beaches",
                      subtitle: "Progress: 2/5",
                      icon: Icons.flag,
                    ),
                    const SizedBox(height: 10),
                    const _InfoCard(
                      title: "Photo Collection Master",
                      subtitle: "Progress: 12/20",
                      icon: Icons.camera_enhance,
                    ),
                    const SizedBox(height: 10),
                    const _InfoCard(
                      title: "Taste Local Cuisine",
                      subtitle: "Progress: 1/10",
                      icon: Icons.restaurant,
                    ),
                  ],
                ),
              ),

              // Extra space at bottom so the Floating Nav Bar doesn't cover the last item
              
            ],
          ),
        ),
      ),
      )
    );
  }
}

// --- REUSABLE CARD WIDGET ---
class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.hammersmithOne(
              color: primaryBlue,
              fontSize: 15,
            ),
          ),
          Row(
            children: [
              Text(
                subtitle,
                textAlign: TextAlign.right,
                style: GoogleFonts.hammersmithOne(
                  color: primaryBlue,
                  fontSize: 12, 
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 14, color: primaryBlue),
            ],
          ),
        ],
      ),
    );
  }
}