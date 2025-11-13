// In: lib/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentDob; // Expected format 'dd/MM/yyyy'
  
  // --- 1. ADD AVATAR INFO ---
  final String currentAvatarId;
  final Map<String, String> availableAvatarAssets;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentDob,
    required this.currentAvatarId,
    required this.availableAvatarAssets,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _dateController;
  bool _isSaving = false;

  // --- 2. ADD AVATAR STATE ---
  late String _selectedAvatarId;

  // Theme Colors
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color cardBackgroundColor = Color(0xFFFCFCFC);
  static const Color lightGray = Color(0xFFD9D6D6);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _dateController = TextEditingController(text: widget.currentDob);
    _selectedAvatarId = widget.currentAvatarId; // Initialize avatar state
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime initial;
    try {
      initial = DateFormat('dd/MM/yyyy').parse(_dateController.text);
    } catch (e) {
      initial = DateTime(2000);
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
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

  // --- 3. ADD AVATAR DIALOG ---
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
              children: widget.availableAvatarAssets.entries.map((entry) {
                final String avatarId = entry.key;
                final String assetPath = entry.value;
                bool isSelected = _selectedAvatarId == avatarId;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatarId = avatarId;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: isSelected
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: appPrimaryColor, width: 3),
                          )
                        : null,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: AssetImage(assetPath),
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
  // --- END ADD ---

  // --- 4. UPDATE SAVE FUNCTION ---
  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _dateController.text.isEmpty) {
      _showErrorDialog("Please fill out all fields.");
      return;
    }
    
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showErrorDialog("No user logged in.");
      return;
    }
    
    setState(() => _isSaving = true);
    _showLoadingDialog();

    try {
      // Save all three fields
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'dateOfBirth': _dateController.text.trim(),
        'selectedAvatarId': _selectedAvatarId, // <-- Save the avatar
      });
      
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        Navigator.pop(context); // Pop back to profile page
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
      }
      _showErrorDialog("Error saving profile: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white, size: 30),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: cardBackgroundColor,
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 5. ADD AVATAR EDITOR UI ---
                Center(
                  child: GestureDetector(
                    onTap: _showAvatarSelectionDialog,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: AssetImage(
                            widget.availableAvatarAssets[_selectedAvatarId] ??
                            widget.availableAvatarAssets['default']!
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: appPrimaryColor.withOpacity(0.9),
                            child: const Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // --- END ADD ---

                _buildTextField(
                  _nameController,
                  "NAME",
                  "Enter your name",
                  lightGray: lightGray,
                ),
                const SizedBox(height: 20),
                const Text(
                  "DATE OF BIRTH",
                  style: TextStyle(fontSize: 12, color: Color(0xFFA0A0A0), letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: _buildInputDecoration(
                    "Select your date of birth",
                    lightGray,
                    suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                  ),
                  onTap: () => _selectDate(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // (This helper is unchanged)
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hintText, {
    required Color lightGray,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFA0A0A0), letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: _buildInputDecoration(hintText, lightGray),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  // (This helper is unchanged)
  InputDecoration _buildInputDecoration(String hintText, Color lightGray, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
    );
  }
}