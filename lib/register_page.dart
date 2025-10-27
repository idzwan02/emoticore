// In: lib/register_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cloud_firestore/cloud_firestore.dart'; // For saving data
import 'custom_page_route.dart'; // <-- Import the custom FadeRoute
import 'dashboard_page.dart'; // <-- Import the destination page

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    // Clean up all controllers
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- Sign-up function with FadeRoute Navigation ---
  Future<void> _signUp() async {
    BuildContext? dialogContext; // To capture dialog context

    // Show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx; // Capture context
        return const Center(child: CircularProgressIndicator());
      },
    );

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      // Dismiss loading circle first using captured context if available
      if (dialogContext != null && Navigator.canPop(dialogContext!)) Navigator.pop(dialogContext!);
      _showErrorDialog("Passwords do not match.");
      return;
    }

    // Check if date of birth is entered
    if (_dateController.text.isEmpty) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) Navigator.pop(dialogContext!);
      _showErrorDialog("Please select your date of birth.");
      return;
    }

    try {
      // 1. Create user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Update the user's Auth profile with their name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(_nameController.text.trim());

        // 3. Save custom user data to Cloud Firestore
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        await firestore.collection("users").doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dateOfBirth': _dateController.text.trim(),
          'uid': userCredential.user!.uid,
          'joinedAt': Timestamp.now(),
        });
      }

      // 4. Pop loading circle and Navigate to Dashboard using FadeRoute
      if (mounted) {
         // Dismiss loading circle using captured context
        if (dialogContext != null && Navigator.canPop(dialogContext!)) {
           Navigator.pop(dialogContext!);
        }

        Navigator.pushAndRemoveUntil( // Keep pushAndRemoveUntil
          context,
          FadeRoute(page: const EmoticoreMainPage()), // USE FadeRoute HERE
          (route) => false, // Remove all previous routes (Login, Register)
        );
      }

    } on FirebaseAuthException catch (e) {
      // Dismiss loading circle using captured context
      if (dialogContext != null && Navigator.canPop(dialogContext!)) Navigator.pop(dialogContext!);
      _showErrorDialog(e.message ?? "An error occurred during registration.");
    } catch (e) {
      // Catch any other errors (like Firestore errors)
      // Dismiss loading circle using captured context
      if (dialogContext != null && Navigator.canPop(dialogContext!)) Navigator.pop(dialogContext!);
      _showErrorDialog("An unexpected error occurred: ${e.toString()}");
    }
  }
  // --- End Sign-up Function ---


  // Helper method to show an error dialog
  void _showErrorDialog(String message) {
    // Ensure the widget is still mounted before showing dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registration Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color tealBlue = Color(0xFF5E8C95);
    const Color lightGray = Color(0xFFD9D6D6); // Define lightGray here

    return Scaffold(
      backgroundColor: tealBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button uses standard Navigator.pop, no FadeRoute needed here
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(100),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                    children: [
                      const Text("Create new\nAccount",
                        style: TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF202020), height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Register to get started",
                        style: TextStyle(fontSize: 14, color: Color(0xFFA0A0A0)),
                      ),
                      const SizedBox(height: 30),

                      // Name field
                      _buildTextField(_nameController, "NAME", "Enter your name", lightGray: lightGray),
                      const SizedBox(height: 20),

                      // Email field
                      _buildTextField(_emailController, "EMAIL", "example@domain.com", lightGray: lightGray,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 20),

                      // Password field
                      _buildTextField(_passwordController, "PASSWORD", "Enter your password", lightGray: lightGray,
                          isPassword: true),
                      const SizedBox(height: 20),

                      // Confirm Password field
                      _buildTextField(_confirmPasswordController, "CONFIRM PASSWORD", "Re-enter your password", lightGray: lightGray,
                          isPassword: true),
                      const SizedBox(height: 20),

                      // Date of Birth field
                      const Text("DATE OF BIRTH",
                        style: TextStyle(fontSize: 12, color: Color(0xFFA0A0A0), letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: _buildInputDecoration("Select your date of birth", lightGray,
                            suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey)),
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 30),

                      // Sign up button
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tealBlue,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _signUp, // Calls the updated sign-up function
                          child: const Text("Sign up",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.white),
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
      ),
    );
  }

  // Helper function to build text fields (pass lightGray)
  Widget _buildTextField(TextEditingController controller, String label, String hintText,
      {bool isPassword = false, TextInputType keyboardType = TextInputType.text, required Color lightGray}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFA0A0A0), letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: _buildInputDecoration(hintText, lightGray), // Pass lightGray
        ),
      ],
    );
  }

  // Helper function for decoration (pass lightGray)
  InputDecoration _buildInputDecoration(String hintText, Color lightGray, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: lightGray, // Use passed color
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0), // Adjust padding if needed
    );
  }

  // Helper function for date picker
  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // Sensible default
      firstDate: DateTime(1920), // Adjust range as needed
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _dateController.text = formattedDate;
        });
      }
    }
  }
}