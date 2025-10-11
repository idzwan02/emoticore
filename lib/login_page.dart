import 'package:flutter/material.dart';
import 'register_page.dart'; 
import 'forgot_password_page.dart';// <-- make sure you have this file created

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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

            // Logo section
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
                        'assets/brain_icon.png',
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
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202020),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Sign in to continue.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFA0A0A0),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Name field
                      const Text(
                        "NAME",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA0A0A0),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Enter your name",
                          filled: true,
                          fillColor: lightGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password field
                      const Text(
                        "PASSWORD",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA0A0A0),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
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

                      // Login button
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tealBlue,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            // Add login logic here
                          },
                          child: const Text(
                            "Log in",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Forgot password and Signup
                      Column(
                        children: [
                          TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Color(0xFFA0A0A0)),
                          ),
                        ),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterPage()),
                              );
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(color: Color(0xFFA0A0A0)),
                            ),
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
