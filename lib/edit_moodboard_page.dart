// In: lib/edit_moodboard_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

class EditMoodboardPage extends StatefulWidget {
  final QueryDocumentSnapshot? document; // Null if new entry

  const EditMoodboardPage({super.key, this.document});

  @override
  State<EditMoodboardPage> createState() => _EditMoodboardPageState();
}

class _EditMoodboardPageState extends State<EditMoodboardPage> {
  final TextEditingController _titleController = TextEditingController();
  // --- NEW: Add Content Controller ---
  final TextEditingController _contentController = TextEditingController();
  // --- END NEW ---
  
  List<TextEditingController> _imageUrlControllers = [TextEditingController()];
  bool _isSaving = false;
  String? _documentId;
  String _pageTitle = 'New Moodboard';

  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color cardBackgroundColor = Color(0xFFFCFCFC);

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      final data = widget.document!.data() as Map<String, dynamic>;
      _titleController.text = data['title'] ?? '';
      _documentId = widget.document!.id;
      _pageTitle = 'Edit Moodboard';
      
      // --- NEW: Load content ---
      _contentController.text = data['content'] ?? '';
      // --- END NEW ---

      final List<dynamic> imageList = data['imageUrls'] ?? [];
      if (imageList.isNotEmpty) {
        _imageUrlControllers = imageList.map((url) {
          return TextEditingController(text: url as String? ?? '');
        }).toList();
      }
      // Ensure at least one controller exists
      if (_imageUrlControllers.isEmpty) {
         _imageUrlControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose(); // --- NEW: Dispose content ---
    for (var controller in _imageUrlControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveMoodboard() async {
    if (_titleController.text.isEmpty) {
      _showErrorDialog("Please enter a title.");
      return;
    }

    setState(() => _isSaving = true);
    _showLoadingDialog();

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      _showErrorDialog("You must be logged in.");
      return;
    }

    List<String> imageUrls = _imageUrlControllers
        .map((controller) => controller.text.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    try {
      final data = {
        'title': _titleController.text,
        'content': _contentController.text.trim(), // --- NEW: Save content ---
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'imageUrls': imageUrls,
      };

      if (_documentId == null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid)
            .collection('moodboards').add(data);
      } else {
        await FirebaseFirestore.instance.collection('users').doc(user.uid)
            .collection('moodboards').doc(_documentId).update(data);
      }

      if (mounted) {
        Navigator.pop(context); // Pop loading
        Navigator.pop(context); // Pop back to gallery
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Pop loading
      _showErrorDialog("Error saving moodboard: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  // (Keep _addUrlField, _removeUrlField, _showLoadingDialog, _showErrorDialog as they were)
  void _addUrlField() { setState(() { _imageUrlControllers.add(TextEditingController()); }); }
  void _removeUrlField(int index) { setState(() { _imageUrlControllers[index].dispose(); _imageUrlControllers.removeAt(index); }); }
  void _showLoadingDialog() { showDialog( context: context, barrierDismissible: false, builder: (context) => Center(child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150)), ); }
  void _showErrorDialog(String message) { if (!mounted) return; showDialog( context: context, builder: (context) => AlertDialog( title: const Text("Error"), content: Text(message), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")), ], ), ); }


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
        title: Text(
          _pageTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white, size: 30),
            onPressed: _isSaving ? null : _saveMoodboard,
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
                // Title Field
                TextField(
                  controller: _titleController,
                  autofocus: _documentId == null,
                  decoration: const InputDecoration(
                    hintText: 'Moodboard Title',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 24, fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // --- NEW: Content Field ---
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Add notes here...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  maxLines: 8, // Give it some initial space
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                // --- END NEW ---

                const SizedBox(height: 24),
                const Text(
                  'Image URLs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _imageUrlControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _imageUrlControllers[index],
                              decoration: InputDecoration(
                                hintText: 'https://...',
                                labelText: 'Image URL ${index + 1}',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          if (_imageUrlControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeUrlField(index),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.add_link),
                  label: const Text('Add another URL'),
                  onPressed: _addUrlField,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}