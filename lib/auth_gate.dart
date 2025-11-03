// In: lib/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // <-- Import Lottie
import 'login_page.dart';
import 'dashboard_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the snapshot is still loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            // --- UPDATED ---
            return Center(
              child: Lottie.asset(
                'assets/animations/loading.json',
                width: 150,
                height: 150,
              ),
            );
            // --- END UPDATE ---
          }

          // If the user IS logged in
          if (snapshot.hasData) {
            return const EmoticoreMainPage();
          }

          // If the user is NOT logged in
          return const LoginPage();
        },
      ),
    );
  }
}