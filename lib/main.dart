import 'package:flutter/material.dart';
// Ensure these imports match your folder structure exactly
import 'features/home/home_screen.dart';
import 'features/trips/trips_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/social/island_pass_screen.dart';

void main() {
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

  // The 5 Screens
  final List<Widget> _screens = [
    const HomeScreen(),                      // Index 0: Home (Naxos Cards)
    const IslandPassScreen(),                // Index 1: Camera/Post
    const Center(child: Text("Map Screen")), // Index 2: Map (Big Button)
    const TripsScreen(),                     // Index 3: Calendar/Trips
    const Center(child: Text("Profile Screen")), // Index 4: Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We use a Stack to float the custom Nav Bar over the content
      body: Stack(
        children: [
          // 1. THE SCREEN CONTENT
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),

          // 2. THE FLOATING NAV BAR (Bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              selectedIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        ],
      ),
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
                decoration: BoxDecoration(
                  color: isMapSelected ? primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryBlue, width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))],
                ),
                child: Icon(
                  Icons.map_outlined,
                  size: 36,
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