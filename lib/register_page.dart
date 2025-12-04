// In: lib/register_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'custom_page_route.dart';
import 'dashboard_page.dart';

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
  final _mantraController = TextEditingController();

  // State variables for password fields
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String _selectedAvatarId = 'user'; // Default avatar ID

  // Avatar Map
  final Map<String, String> _availableAvatarAssets = {
    'default': 'assets/avatars/user.png',
    'astronaut (2)': 'assets/avatars/astronaut (2).png',
    'astronaut': 'assets/avatars/astronaut.png',
    'bear': 'assets/avatars/bear.png',
    'boy': 'assets/avatars/boy.png',
    'cat (2)': 'assets/avatars/cat (2).png',
    'cat': 'assets/avatars/cat.png',
    'chicken': 'assets/avatars/chicken.png',
    'cow': 'assets/avatars/cow.png',
    'dog (1)': 'assets/avatars/dog (1).png',
    'dog (2)': 'assets/avatars/dog (2).png',
    'dog': 'assets/avatars/dog.png',
    'dragon': 'assets/avatars/dragon.png',
    'eagle': 'assets/avatars/eagle.png',
    'fox': 'assets/avatars/fox.png',
    'gamer': 'assets/avatars/gamer.png',
    'gorilla': 'assets/avatars/gorilla.png',
    'hen': 'assets/avatars/hen.png',
    'hippopotamus': 'assets/avatars/hippopotamus.png',
    'human': 'assets/avatars/human.png',
    'koala': 'assets/avatars/koala.png',
    'lion': 'assets/avatars/lion.png',
    'man (1)': 'assets/avatars/man (1).png',
    'man (2)': 'assets/avatars/man (2).png',
    'man (3)': 'assets/avatars/man (3).png',
    'man (4)': 'assets/avatars/man (4).png',
    'man (5)': 'assets/avatars/man (5).png',
    'man (6)': 'assets/avatars/man (6).png',
    'man (7)': 'assets/avatars/man (7).png',
    'man (8)': 'assets/avatars/man (8).png',
    'man (9)': 'assets/avatars/man (9).png',
    'man (10)': 'assets/avatars/man (10).png',
    'man (11)': 'assets/avatars/man (11).png',
    'man (12)': 'assets/avatars/man (12).png',
    'man (13)': 'assets/avatars/man (13).png',
    'man': 'assets/avatars/man.png',
    'meerkat': 'assets/avatars/meerkat.png',
    'owl': 'assets/avatars/owl.png',
    'panda': 'assets/avatars/panda.png',
    'polar-bear': 'assets/avatars/polar-bear.png',
    'profile (2)': 'assets/avatars/profile (2).png',
    'profile': 'assets/avatars/profile.png',
    'puffer-fish': 'assets/avatars/puffer-fish.png',
    'rabbit': 'assets/avatars/rabbit.png',
    'robot': 'assets/avatars/robot.png',
    'shark': 'assets/avatars/shark.png',
    'sloth': 'assets/avatars/sloth.png',
    'user (1)': 'assets/avatars/user (1).png',
    'user (2)': 'assets/avatars/user (2).png',
    'user': 'assets/avatars/user.png',
    'woman (1)': 'assets/avatars/woman (1).png',
    'woman (2)': 'assets/avatars/woman (2).png',
    'woman (3)': 'assets/avatars/woman (3).png',
    'woman (4)': 'assets/avatars/woman (4).png',
    'woman (5)': 'assets/avatars/woman (5).png',
    'woman (6)': 'assets/avatars/woman (6).png',
    'woman': 'assets/avatars/woman.png',
  };

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
          'currentStreak': 0,
          'lastCheckInDate': null, // Use null to show they've never checked in
          'totalPoints': 0,
          'longestStreak': 0,
          'unlockedBadges': [],
          'mantra': _mantraController.text.trim().isEmpty 
              ? "One day at a time." // Default if empty
              : _mantraController.text.trim(),
        });
      }

      if (mounted) {
        if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
        }
        
        // --- THIS IS THE FIX ---
        if (userCredential.user != null) {
          Navigator.pushAndRemoveUntil(
            context,
            FadeRoute(page: EmoticoreMainPage(user: userCredential.user!)),
            (route) => false,
          );
        }
        // --- END FIX ---
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
                                    _availableAvatarAssets[_selectedAvatarId] ??
                                        _availableAvatarAssets['default']!),
                                onBackgroundImageError: (e, s) {
                                  print(
                                      "Error loading register asset: ${_availableAvatarAssets[_selectedAvatarId]}");
                                },
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
                      const SizedBox(height: 20),
                      _buildTextField(
                        _mantraController,
                        "PERSONAL MANTRA",
                        "E.g., I am enough",
                        lightGray: lightGray,
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

  // (This function is unchanged)
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
              children: _availableAvatarAssets.entries.map((entry) {
                final String avatarId = entry.key;
                final String assetPath = entry.value;
                bool isSelected = _selectedAvatarId == avatarId;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedAvatarId = avatarId;
                    });
                  },
                  child: Container(
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
                      backgroundImage: AssetImage(assetPath),
                      onBackgroundImageError: (e, s) {
                        print("Error loading asset in dialog: $assetPath");
                      },
                    ),
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

  // (This function is unchanged)
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

  // (This function is unchanged)
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

  // (This function is unchanged)
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