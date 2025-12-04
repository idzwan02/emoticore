// In: lib/register_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'custom_page_route.dart';
import 'dashboard_page.dart';
import 'gamification_data.dart'; // <-- 1. IMPORT THIS

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- Theme Colors ---
  static const Color tealBlue = Color(0xFF5E8C95);
  static const Color lightGray = Color(0xFFD9D6D6);

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateController = TextEditingController();
  final _mantraController = TextEditingController(); // Added Mantra controller

  // State variables
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _selectedAvatarId = 'default'; // Default avatar ID

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    _mantraController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx;
        return Center(
          child: Lottie.asset(
            'assets/animations/loading.json',
            width: 150,
            height: 150,
          ),
        );
      },
    );
    if (_passwordController.text != _confirmPasswordController.text) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) Navigator.pop(dialogContext!);
      _showErrorDialog("Passwords do not match.");
      return;
    }

    if (_dateController.text.isEmpty) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) Navigator.pop(dialogContext!);
      _showErrorDialog("Please select your date of birth.");
      return;
    }
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(_nameController.text.trim());

        FirebaseFirestore firestore = FirebaseFirestore.instance;
        await firestore.collection("users").doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dateOfBirth': _dateController.text.trim(),
          'uid': userCredential.user!.uid,
          'joinedAt': Timestamp.now(),
          'selectedAvatarId': _selectedAvatarId,
          // Initialize gamification fields
          'currentStreak': 0,
          'longestStreak': 0,
          'lastCheckInDate': null,
          'totalPoints': 0,
          'unlockedBadges': [],
          'mantra': _mantraController.text.trim().isEmpty 
              ? "One day at a time." 
              : _mantraController.text.trim(),
        });
      }

      if (mounted) {
        if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
        }
        
        if (userCredential.user != null) {
          Navigator.pushAndRemoveUntil(
            context,
            FadeRoute(page: EmoticoreMainPage(user: userCredential.user!)),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) Navigator.pop(dialogContext!);
      _showErrorDialog(
          e.message ?? "An error occurred during registration.");
    } catch (e) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) Navigator.pop(dialogContext!);
      _showErrorDialog("An unexpected error occurred: ${e.toString()}");
    }
  }

  void _showErrorDialog(String message) {
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

  // --- 2. UPDATED AVATAR DIALOG ---
  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Avatar"),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              alignment: WrapAlignment.center,
              // Use masterAvatarAssets from gamification_data.dart
              children: masterAvatarAssets.entries.map((entry) {
                final String avatarId = entry.key;
                final String assetPath = entry.value;
                bool isSelected = _selectedAvatarId == avatarId;
                
                // CHECK LOCK STATUS
                // New users have 0 points, so any cost > 0 is locked
                int cost = avatarUnlockThresholds[avatarId] ?? 0;
                bool isLocked = cost > 0; 

                return GestureDetector(
                  onTap: () {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Earn $cost points to unlock this later!"),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return; // Stop selection
                    }
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedAvatarId = avatarId;
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: isSelected
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: tealBlue, width: 3),
                              )
                            : null,
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey.shade300,
                          child: Opacity(
                            // Dim locked avatars
                            opacity: isLocked ? 0.4 : 1.0,
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.transparent,
                              backgroundImage: AssetImage(assetPath),
                            ),
                          ),
                        ),
                      ),
                      // Show Lock Icon
                      if (isLocked)
                        const Positioned.fill(
                          child: Icon(Icons.lock, color: Colors.black54, size: 24),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Create new\nAccount",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202020),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Register to get started",
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFFA0A0A0)),
                      ),
                      const SizedBox(height: 30),
                      
                      // Avatar Selection
                      Center(
                        child: GestureDetector(
                          onTap: _showAvatarSelectionDialog, 
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 60, 
                                backgroundColor: lightGray,
                                backgroundImage: AssetImage(
                                    masterAvatarAssets[_selectedAvatarId] ??
                                        masterAvatarAssets['default']!),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: tealBlue.withOpacity(0.8),
                                  child: const Icon(Icons.edit,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      _buildTextField(
                          _nameController,
                          "NAME",
                          "Enter your name",
                          lightGray: lightGray),
                      const SizedBox(height: 20),
                      _buildTextField(_emailController, "EMAIL",
                          "example@domain.com",
                          lightGray: lightGray,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 20),
                      _buildTextField(
                        _passwordController,
                        "PASSWORD",
                        "Enter your password",
                        lightGray: lightGray,
                        obscureText: !_isPasswordVisible, 
                        suffixIcon: IconButton(
                          icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey.shade600),
                          onPressed: () {
                            setState(
                                () => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        _confirmPasswordController,
                        "CONFIRM PASSWORD",
                        "Re-enter your password",
                        lightGray: lightGray,
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton( 
                          icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey.shade600),
                          onPressed: () {
                            setState(() => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Mantra Field
                      _buildTextField(
                        _mantraController,
                        "PERSONAL MANTRA",
                        "E.g. I am enough",
                        lightGray: lightGray,
                      ),
                      const SizedBox(height: 20),

                      // Date of Birth field
                      const Text(
                        "DATE OF BIRTH",
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA0A0A0),
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: _buildInputDecoration(
                            "Select your date of birth", lightGray,
                            suffixIcon: const Icon(Icons.calendar_today,
                                color: Colors.grey)),
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
                          onPressed: _signUp,
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
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

  Widget _buildTextField(
      TextEditingController controller, String label, String hintText,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text,
      required Color lightGray,
      Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFFA0A0A0), letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: _buildInputDecoration(hintText, lightGray,
              suffixIcon: suffixIcon),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hintText, Color lightGray,
      {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      if (mounted) {
        setState(() {
          _dateController.text = formattedDate;
        });
      }
    }
  }
}