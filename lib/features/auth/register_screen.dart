import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../main.dart'; // For navigation to MainScaffold

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // input controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  // --- REGISTER LOGIC ---
  Future<void> _handleRegister() async {
    // 1. Basic Validation
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Create User in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Save Username and extra info to Firestore Database
      // This is crucial for your "Login with Username" feature to work later!
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid) // Use the same ID as Auth
          .set({
        'uid': userCredential.user!.uid,
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'firstName': _usernameController.text.trim(), // Default name
        'role': 'Cyclist',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        print("✅ Registration Successful");
        // Navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScaffold()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Registration failed";
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    const Color placeholderGrey = Color(0xFFD0D0D0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP BAR (Back Button) ---
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 30),
                child: InkWell(
                  onTap: () => Navigator.pop(context), // Go back to login
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- LOGO CENTERED ---
              Center(
                child: Container(
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
              ),

                const SizedBox(height: 40),

              // --- TITLE ---
              Center(
                child: Text(
                  'Register',
                  style: GoogleFonts.hammersmithOne(
                    fontSize: 32,
                    color: primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- INPUT FIELDS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 46.0),
                child: Column(
                  children: [
                    // 1. USERNAME
                    _buildCustomInput(
                      controller: _usernameController,
                      hintText: 'Username',
                    ),
                    
                    const SizedBox(height: 10), // Spacing from design

                    // 2. EMAIL (Moved to 2nd position as requested)
                    _buildCustomInput(
                      controller: _emailController,
                      hintText: 'Email',
                      inputType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 10),

                    // 3. PASSWORD
                    _buildCustomInput(
                      controller: _passwordController,
                      hintText: 'Password',
                      isPassword: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // --- BOTTOM RIGHT BUTTON ---
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 46, bottom: 40),
                  child: InkWell(
                    onTap: _isLoading ? null : _handleRegister,
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
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : const Icon(
                              Icons.check, // Or Arrow forward
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget to keep code clean and match your design exactly
  Widget _buildCustomInput({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
    const Color primaryBlue = Color(0xFF1269C7);
    const Color placeholderGrey = Color(0xFFD0D0D0);

    return Container(
      height: 60, // Fixed height from design
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryBlue, width: 1),
      ),
      child: Center(
        child: TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: inputType,
          style: GoogleFonts.hammersmithOne(fontSize: 20, color: Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.hammersmithOne(
              fontSize: 24,
              color: placeholderGrey,
            ),
            border: InputBorder.none, // Remove default underline
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            // Optional: Add suffix icon if you want
          ),
        ),
      ),
    );
  }
}