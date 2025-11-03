// In: lib/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'auth_gate.dart';
import 'custom_page_route.dart'; // Import your custom fade route

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Define your app's main color
  static const Color appPrimaryColor = Color(0xFF5A9E9E);

  @override
  void initState() {
    super.initState();
    _navigateToHome(); // Start the timer to navigate
  }

  void _navigateToHome() async {
    // Wait for 3 seconds (or however long your animation is)
    await Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Navigate to AuthGate, which will decide on Login or Dashboard
        Navigator.pushReplacement(
          context,
          FadeRoute(page: const AuthGate()), // Use your fade animation
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appPrimaryColor, // Match the native splash color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your Lottie Animation
            Lottie.asset(
              'assets/animations/open.json', // Your animation file
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}