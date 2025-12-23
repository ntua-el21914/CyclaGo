import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cyclago/core/global_data.dart';
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/camera/island_pass_screen.dart';
import 'package:cyclago/features/map/map_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/profile/profile_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("FIREBASE CONNECTED SUCCESSFULLY");
  } catch (e) {
    print("Error details: $e");
  }
  runApp(const CyclaGoApp());
}

class CyclaGoApp extends StatelessWidget {
  const CyclaGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyclaGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(), 
    );
  }
}

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _selectedIndex;
  bool _isNavBarVisible = true;
  
  // --- LOCATION STATE ---
  bool _isLocationValid = false; 
  bool _isLoadingLocation = true;
  double? _userLat;
  double? _userLng;

  // Naxos Coordinates (for island pass validation)
  final double naxosLat = 37.1032;
  final double naxosLng = 25.3764;
  final double allowedRadiusInMeters = 50000; // 50km

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkLocationOnLogin(); // <--- Check immediately
  }

  Future<void> _checkLocationOnLogin() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        naxosLat,
        naxosLng,
      );

      if (mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          _isLocationValid = distanceInMeters <= allowedRadiusInMeters;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print("Location Error: $e");
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _toggleNavBar(bool isVisible) {
    if (_isNavBarVisible != isVisible) {
      setState(() => _isNavBarVisible = isVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has posted (unlocked Island Pass)
    final bool hasPosted = GlobalFeedData.posts.isNotEmpty;
    
    final List<Widget> screens = [
      const HomeScreen(),
      // PASS THE LOCATION STATUS HERE
      IslandPassScreen(isLocationValid: _isLocationValid), 
      MapScreen(
        onToggleNavBar: _toggleNavBar, 
        userLat: _userLat, 
        userLng: _userLng,
        hasPosted: hasPosted,
        onSwitchTab: _onItemTapped,
      ),
      const CalendarScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      extendBody: true,
      bottomNavigationBar: _isNavBarVisible 
          ? CustomNavBar(selectedIndex: _selectedIndex, onTap: _onItemTapped)
          : null,
      // If still loading GPS, show spinner, otherwise show screen
      body: _isLoadingLocation 
          ? const Center(child: CircularProgressIndicator()) 
          : screens[_selectedIndex],
    );
  }
}

// ... (Your CustomNavBar class remains exactly the same as you provided)
class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    bool isMapSelected = selectedIndex == 2;

    return SizedBox(
      height: 110, 
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 70,
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBarItem(icon: Icons.home_filled, index: 0, selectedIndex: selectedIndex, onTap: onTap),
                _NavBarItem(icon: Icons.camera_alt_rounded, index: 1, selectedIndex: selectedIndex, onTap: onTap),
                const SizedBox(width: 60), 
                _NavBarItem(icon: Icons.calendar_today_rounded, index: 3, selectedIndex: selectedIndex, onTap: onTap),
                _NavBarItem(icon: Icons.person_rounded, index: 4, selectedIndex: selectedIndex, onTap: onTap),
              ],
            ),
          ),
          Positioned(
            bottom: 45, 
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMapSelected ? primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryBlue, width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))],
                ),
                child: Icon(
                  Icons.map_outlined,
                  size: 60,
                  color: isMapSelected ? Colors.white : primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;

  const _NavBarItem({required this.icon, required this.index, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 30,
          color: isSelected ? Colors.white : primaryBlue,
        ),
      ),
    );
  }
}