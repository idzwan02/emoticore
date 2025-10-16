import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this package for date formatting

// 1. Convert to StatefulWidget
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 2. Create a TextEditingController
  final TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color tealBlue = Color(0xFF5E8C95);
    const Color lightGray = Color(0xFFD9D6D6);

    return Scaffold(
      backgroundColor: tealBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button + spacing
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            // White curved container
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
                      const Text(
                        "Create new",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202020),
                          height: 1.2,
                        ),
                      ),
                      const Text(
                        "Account",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202020),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Register to get started",
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

                      // Email field
                      const Text(
                        "EMAIL",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA0A0A0),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "example@domain.com",
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
                      const SizedBox(height: 20),

                      // Date of Birth field
                      const Text(
                        "DATE OF BIRTH",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA0A0A0),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dateController, // Assign the controller
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: "Select your date of birth",
                          filled: true,
                          fillColor: lightGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                        ),
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          // 3. Update the controller's text if a date is picked
                          if (pickedDate != null) {
                            String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
                            setState(() {
                              _dateController.text = formattedDate;
                            });
                          }
                        },
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
                          onPressed: () {},
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
}