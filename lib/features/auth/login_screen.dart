import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. Need Firestore for the lookup
import '../../main.dart'; 
import 'package:flutter_svg/flutter_svg.dart';
import 'register_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // renamed to 'identifier' because it could be email OR username
  final _identifierController = TextEditingController(); 
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String input = _identifierController.text.trim();
    String password = _passwordController.text.trim();
    String? emailToUse;

    try {
      // --- STEP 1: Determine if it is Email or Username ---
      if (input.contains('@')) {
        // It looks like an email, use it directly
        emailToUse = input;
      } else {
        // It looks like a username, look it up in the database
        print("🔍 Searching for username: $input");
        
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (result.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found', 
            message: 'Username not found.'
          );
        }

        // We found the user! Get their email.
        emailToUse = result.docs.first.get('email');
        print("✅ Username found! Linked to: $emailToUse");
      }

      // --- STEP 2: Login with the resolved Email ---
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToUse!,
        password: password,
      );

      if (mounted) {
        print("✅ Login Successful");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScaffold()),
        );
      }

    } on FirebaseAuthException catch (e) {
      print("❌ Login Error: ${e.code}");
      String message = e.message ?? "Login failed";
      
      // Make error messages friendlier
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = "Incorrect username or password.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
       print("❌ General Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    const Color placeholderGrey = Color(0xFFD0D0D0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 46.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // --- LOGO ---
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryBlue, width: 2),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/CyclaGoLogo.svg',
                    fit: BoxFit.cover, // Changed to cover to fill the container
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_bike, size: 60, color: primaryBlue),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  'Login',
                  style: GoogleFonts.hammersmithOne(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: primaryBlue,
                  ),
                ),

                const SizedBox(height: 40),

                // --- USERNAME / EMAIL FIELD ---
                TextFormField(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    hintText: 'Username or Email', // UPDATED HINT
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
                  controller: _passwordController,
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

                // --- CREATE ACCOUNT ROW ---
                FittedBox(
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
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

                const SizedBox(height: 100),

                // --- LOGIN BUTTON ---
                InkWell(
                  onTap: _isLoading ? null : _handleLogin,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading 
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 40,
                        ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}