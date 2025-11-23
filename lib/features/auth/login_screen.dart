import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import for navigation to HomeScreen
import 'package:cyclago/main.dart'; // Import for navigation to MainScaffold

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Helper variables for your specific colors
    const Color primaryBlue = Color(0xFF1269C7);
    const Color placeholderGrey = Color(0xFFD0D0D0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // Allows scrolling when keyboard opens
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 46.0), // Matches your left: 46 roughly
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Top spacing

                // --- LOGO SECTION ---
                // Matches your 150x150 container with blue border
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryBlue, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Image.asset(
                      'assets/images/cyclago_logo.png', // Ensure you have this image!
                      fit: BoxFit.contain,
                      // Fallback icon if image is missing
                      errorBuilder: (c, o, s) => const Icon(Icons.image, size: 50, color: primaryBlue),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // --- TITLE ---
                Text(
                  'Login',
                  style: GoogleFonts.hammersmithOne(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: primaryBlue,
                  ),
                ),

                const SizedBox(height: 40),

                // --- USERNAME FIELD ---
                // Matches the Container with rounded border from your code
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: GoogleFonts.hammersmithOne(
                      fontSize: 24,
                      color: placeholderGrey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: primaryBlue, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: primaryBlue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- PASSWORD FIELD ---
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: GoogleFonts.hammersmithOne(
                      fontSize: 24,
                      color: placeholderGrey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: primaryBlue, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: primaryBlue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- "Don't have an account?" ROW ---
                FittedBox( // Ensures text fits on smaller screens
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'You don’t have an account? ',
                        style: GoogleFonts.hammersmithOne(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                           // Navigate to Register Screen
                           // Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                        },
                        child: Text(
                          'Create one!',
                          style: GoogleFonts.hammersmithOne(
                            fontSize: 16,
                            color: primaryBlue,
                            decoration: TextDecoration.underline,
                            decorationColor: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Spacing before button

                // --- BLUE ARROW BUTTON ---
                // Matches your 75x75 circle
                InkWell(
                  onTap: () {
                    // Navigate to Home
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScaffold()),
                    );
                  },
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}