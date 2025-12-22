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
   String _displayName = "";

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
            // Δείξε το firstName, αλλιώς το username
            _displayName = userData['username'] ?? userData['email'] ?? '';
          }
          );
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
                      // Εικόνα με τίτλο
                      Container(
                        width: double.infinity,
                        height: 330,
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
                        child: Stack(
                          children: [
                            // 1. Εικονίδιο αν δεν υπάρχει εικόνα (στο κέντρο)
                            if (imageUrl.isEmpty)
                              const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),

                            // 2. Το όνομα του νησιού (Πάνω Αριστερά)
                            Positioned(
                              top: 20,  // Απόσταση από πάνω
                              left: 20, // Απόσταση από αριστερά
                              child: Text(
                                title, // Η μεταβλητή τίτλου από το Firestore
                                style: GoogleFonts.hammersmithOne(
                                  color: primaryBlue, // Λευκό χρώμα για να φαίνεται πάνω στην εικόνα
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  // Προσθέτουμε σκιά (Shadow) για να διαβάζεται ακόμα και σε λευκές εικόνες
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
                    ],
                  );
                },
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