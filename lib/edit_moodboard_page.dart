// In: lib/edit_moodboard_page.dart

import 'dart:io'; // Import for File
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as p; // Import the path package

class EditMoodboardPage extends StatefulWidget {
  final QueryDocumentSnapshot? document; // Null if new entry

  const EditMoodboardPage({super.key, this.document});

  @override
  State<EditMoodboardPage> createState() => _EditMoodboardPageState();
}

class _EditMoodboardPageState extends State<EditMoodboardPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  final List<dynamic> _images = []; // Holds Strings (URLs) and Files (new)
  final ImagePicker _picker = ImagePicker();

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
      _contentController.text = data['content'] ?? '';
      _documentId = widget.document!.id;
      _pageTitle = 'Edit Moodboard';
      
      final List<dynamic> imageList = data['imageUrls'] ?? [];
      for (var url in imageList) {
        _images.add(url as String);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // --- 1. UPDATED: _pickImage now takes an ImageSource ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source, // Use the provided source
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path)); // Add the File object to the list
        });
      }
    } catch (e) {
      _showErrorDialog("Error picking image: ${e.toString()}");
    }
  }
  // --- END UPDATE ---

  // --- 2. NEW: Dialog to choose camera/gallery ---
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery); // Call with Gallery
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera); // Call with Camera
              },
            ),
          ],
        ),
      ),
    );
  }
  // --- END NEW ---
  
  Future<String> _uploadFile(File file, String userId) async {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('moodboard_images')
        .child(userId)
        .child(fileName);

    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
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

    try {
      List<String> finalImageUrls = [];
      
      for (var image in _images) {
        if (image is String) {
          finalImageUrls.add(image);
        } else if (image is File) {
          String downloadUrl = await _uploadFile(image, user.uid);
          finalImageUrls.add(downloadUrl);
        }
      }

      final data = {
        'title': _titleController.text,
        'content': _contentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'imageUrls': finalImageUrls,
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
        actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")), ],
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
                
                // Content Field
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Add notes here...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  maxLines: 8,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                
                const SizedBox(height: 24),
                const Text(
                  'Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Image Grid Display
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ..._images.map((image) => _buildImageThumbnail(image)).toList(),
                    _buildAddImageButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(dynamic image) {
    const double size = 100.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // The Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              width: size,
              height: size,
              child: image is String
                  ? CachedNetworkImage( // It's an existing URL
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                    )
                  : Image.file( // It's a new File
                      image as File,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          // Remove Button
          Positioned(
            top: -4,
            right: -4,
            child: IconButton(
              icon: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 14),
              ),
              onPressed: () {
                setState(() {
                  _images.remove(image);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    const double size = 100.0;
    return InkWell(
      // --- 3. UPDATED: Call the dialog ---
      onTap: _showImageSourceDialog,
      // --- END UPDATE ---
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600),
              const SizedBox(height: 4),
              Text('Add', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}