import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Ensure these imports match your folder structure exactly
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/camera/island_pass_screen.dart';
import 'package:cyclago/features/map/map_screen.dart';

//Firebase-Database
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Attempt to connect to Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // If we get here, it worked!
    print("FIREBASE CONNECTED SUCCESSFULLY");
    
  } catch (e) {
    // If it fails, print the error
    print("❌❌❌ FIREBASE CONNECTION FAILED ❌❌❌");
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
      // -------------------------------------------------------
      // CHANGE THIS LINE TO TEST DIFFERENT SCREENS:
      // Use 'const LoginScreen()' to start from Login
      // Use 'const MainScaffold()' to start straight at the Dashboard
      // -------------------------------------------------------
      home: const LoginScreen(), 
    );
  }
}

// --- THE MAIN HUB (With the Custom Floating Nav Bar) ---
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  bool _isNavBarVisible = true; // 1. New variable to control visibility

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // 2. Function to toggle the bar (we will pass this to MapScreen)
  void _toggleNavBar(bool isVisible) {
    if (_isNavBarVisible != isVisible) {
      setState(() => _isNavBarVisible = isVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Pass the toggle function to MapScreen
    final List<Widget> screens = [
      const HomeScreen(), // Index 0
      const IslandPassScreen(), // Index 1
      MapScreen(onToggleNavBar: _toggleNavBar), // Index 2: Updated Constructor!
      const Center(child: Text("Calendar Screen")), // Index 3
      const Center(child: Text("Profile Screen")), // Index 4
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      extendBody: true,
      // 4. Wrap NavBar in AnimatedContainer or Visibility
      bottomNavigationBar: _isNavBarVisible 
          ? CustomNavBar(selectedIndex: _selectedIndex, onTap: _onItemTapped)
          : null, // If false, the bar disappears completely
      body: screens[_selectedIndex],
    );
  }
}

// --- YOUR CUSTOM NAV BAR WIDGET ---
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
          // A. The White Pill Container
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
                const SizedBox(width: 60), // Space for Map Button
                _NavBarItem(icon: Icons.calendar_today_rounded, index: 3, selectedIndex: selectedIndex, onTap: onTap),
                _NavBarItem(icon: Icons.person_rounded, index: 4, selectedIndex: selectedIndex, onTap: onTap),
              ],
            ),
          ),

          // B. The Floating Map Button
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