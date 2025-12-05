import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Σιγουρέψου ότι αυτό το import είναι σωστό για το Project σου
import '../../main.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _displayName = "Cyclist"; // Default όνομα μέχρι να φορτώσει

  @override
  void initState() {
    super.initState();
    _fetchUserName();
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
            // Δείξε το firstName, αλλιώς το username, αλλιώς "Cyclist"
            _displayName = userData['firstName'] ?? userData['username'] ?? "Cyclist";
          });
        }
      }
    }
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
      extendBody: true, // Για να είναι το nav bar από πάνω
      
      // --- NAVIGATION BAR ---
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),

      body: SafeArea(
        bottom: false,
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

              // --- 2. ΔΥΝΑΜΙΚΗ ΕΙΚΟΝΑ ΑΠΟ FIREBASE ---
              StreamBuilder<DocumentSnapshot>(
                // Ζητάμε το έγγραφο 'naxos' από το collection 'destinations'
                stream: FirebaseFirestore.instance
                    .collection('HomeScreen_Images')
                    .doc('naxos')
                    .snapshots(),
                builder: (context, snapshot) {
                  
                  // Α. Αν φορτώνει ακόμα
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Β. Αν υπάρχει λάθος ή δεν βρέθηκε το έγγραφο
                  if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text("Destination info missing")),
                    );
                  }

                  // Γ. Όλα καλά - Παίρνουμε τα δεδομένα
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  
                  // Προσοχή: Τα ονόματα 'title' και 'imageURL' πρέπει να υπάρχουν στη βάση
                  final String title = data['title'] ?? 'Naxos';
                  final String imageUrl = data['imageURL'] ?? ''; 

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Τίτλος Νησιού
                      Text(
                        title,
                        style: GoogleFonts.hammersmithOne(
                          color: primaryBlue,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Εικόνα Νησιού
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          image: imageUrl.isNotEmpty 
                            ? DecorationImage(
                                image: NetworkImage(imageUrl), // Η εικόνα από το Cloudinary/Firebase
                                fit: BoxFit.cover,
                              )
                            : null, // Αν δεν υπάρχει εικόνα, μην σκάσεις
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        // Αν δεν υπάρχει εικόνα, δείξε ένα εικονίδιο
                        child: imageUrl.isEmpty 
                            ? const Center(child: Icon(Icons.image_not_supported)) 
                            : null,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // --- EVENTS SECTION ---
              Text(
                'Events',
                style: GoogleFonts.hammersmithOne(
                  color: primaryBlue,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 15),
              
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

              const SizedBox(height: 30),

              // --- CHALLENGES SECTION ---
              Text(
                'Challenges',
                style: GoogleFonts.hammersmithOne(
                  color: primaryBlue,
                  fontSize: 28,
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
      ),
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
              Icon(icon, size: 20, color: primaryBlue),
            ],
          ),
        ],
      ),
    );
  }
}