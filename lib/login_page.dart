// In: lib/login_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'register_page.dart'; // Import Register Page
import 'forgot_password_page.dart'; // Import Forgot Password Page
import 'dashboard_page.dart'; // Import Dashboard Page
import 'custom_page_route.dart'; // <-- Import the custom FadeRoute

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for email and password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Sign-in function with Dialog Context Fix and FadeRoute ---
  Future<void> _signIn() async {
    BuildContext? dialogContext; // To hold the dialog's context

    // Show loading circle and capture its context
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx; // Store the dialog context
        return const Center(child: CircularProgressIndicator());
      }
    );

    try {
      // Sign in with email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Optional short delay (can keep or remove based on testing)
      // await Future.delayed(const Duration(milliseconds: 50));

      // Dismiss loading circle using its specific context
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
         Navigator.pop(dialogContext!);
      }

      // Navigate to dashboard using FadeRoute AFTER ensuring dialog is popped
      if (mounted) { // Check if widget is still in the tree
        Navigator.pushReplacement( // Keep pushReplacement
          context,
          FadeRoute(page: const EmoticoreMainPage()), // USE FadeRoute
        );
      }

    } on FirebaseAuthException catch (e) {
       // Dismiss loading circle on error using its specific context
       if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
       }

      // Show error (only if widget is still mounted)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Failed to sign in"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) { // Catch any other potential errors
       // Dismiss loading circle on generic error using its specific context
       if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
       }
       // Show generic error (only if widget is still mounted)
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text("An unexpected error occurred: ${e.toString()}"),
             backgroundColor: Colors.red,
           ),
         );
       }
    }
  }
  // --- End of updated sign-in function ---

  @override
  Widget build(BuildContext context) {
    const Color tealBlue = Color(0xFF5E8C95);
    const Color lightGray = Color(0xFFD9D6D6);

    return Scaffold(
      backgroundColor: tealBlue,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo Section
            Center(
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/brain_icon.png', // Ensure asset exists
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            // White curved container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(100),
                    topLeft: Radius.circular(0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("Login",
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF202020)),
                        ),
                        const SizedBox(height: 5),
                        const Text("Sign in to continue.",
                          style: TextStyle(fontSize: 14, color: Color(0xFFA0A0A0)),
                        ),
                        const SizedBox(height: 30),

                        // Email Field
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("EMAIL",
                            style: TextStyle(fontSize: 12, color: Color(0xFFA0A0A0), letterSpacing: 1.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Enter your email",
                            filled: true,
                            fillColor: lightGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                         const Align(
                           alignment: Alignment.centerLeft,
                           child: Text("PASSWORD",
                            style: TextStyle(fontSize: 12, color: Color(0xFFA0A0A0), letterSpacing: 1.5),
                           ),
                         ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            filled: true,
                            fillColor: lightGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Login Button
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tealBlue,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _signIn,
                            child: const Text("Log in",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Links
                        Column(
                          children: [
                            TextButton(
                              onPressed: () {
                                // --- Use FadeRoute for Forgot Password ---
                                Navigator.push(
                                  context,
                                  FadeRoute(page: const ForgotPasswordPage()), // USE FadeRoute
                                );
                                // --- End FadeRoute ---
                              },
                              child: const Text("Forgot Password?",
                                  style: TextStyle(color: Color(0xFFA0A0A0))),
                            ),
                            TextButton(
                              onPressed: () {
                                // --- Use FadeRoute for Sign Up ---
                                Navigator.push(
                                  context,
                                  FadeRoute(page: const RegisterPage()), // USE FadeRoute
                                );
                                // --- End FadeRoute ---
                              },
                              child: const Text("Sign up",
                                  style: TextStyle(color: Color(0xFFA0A0A0))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}