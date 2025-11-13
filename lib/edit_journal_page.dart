// In: lib/edit_journal_page.dart
import 'dart:io'; // Import for File operations
import 'package:emoticore/streak_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For displaying existing images

class EditJournalPage extends StatefulWidget {
  final QueryDocumentSnapshot? document; // Null if new entry
  
  // --- 1. ADD THESE NEW PARAMETERS ---
  final String? prefilledTitle;
  final String? prefilledContent;

  const EditJournalPage({
    super.key, 
    this.document,
    this.prefilledTitle, // Add to constructor
    this.prefilledContent, // Add to constructor
  });
  // --- END ADD ---

  @override
  State<EditJournalPage> createState() => _EditJournalPageState();
}

class _EditJournalPageState extends State<EditJournalPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;
  String? _documentId;
  bool _isImportant = false;
  bool _isBookmarked = false;
  File? _pickedImageFile; 
  String? _existingImageUrl; 
  bool _imageWasRemoved = false; 
  final ImagePicker _picker = ImagePicker(); 
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color cardBackgroundColor = Color(0xFFFCFCFC);

  @override
  void initState() {
    super.initState();
    
    // --- 2. UPDATE THIS LOGIC ---
    if (widget.document != null) {
      // Editing an existing entry
      final data = widget.document!.data() as Map<String, dynamic>;
      _titleController.text = data['title'] ?? '';
      _contentController.text = data['content'] ?? '';
      _documentId = widget.document!.id;
      _isImportant = data['isImportant'] ?? false;
      _isBookmarked = data['isBookmarked'] ?? false;
      _existingImageUrl = data['imageUrl']; 
    } else {
      // This is a new entry, check for pre-filled text
      _titleController.text = widget.prefilledTitle ?? '';
      _contentController.text = widget.prefilledContent ?? '';
    }
    // --- END UPDATE ---
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  // ... (rest of the file is unchanged) ...
  // (Function _pickImage, _showImageSourceDialog, _saveEntry, etc...)
  // ... (build method is unchanged) ...
  
  // --- NO OTHER CHANGES ARE NEEDED IN THIS FILE ---
  
  // (Keep _deleteEntry, _showLoadingDialog, _showErrorDialog as they were)
  Future<void> _deleteEntry() async {
    if (_documentId == null) return;
    bool? deleteConfirmed = await showDialog<bool>( context: context, builder: (context) => AlertDialog( title: const Text('Delete Entry?'), content: const Text('Are you sure you want to delete this journal entry? This cannot be undone.'), actions: [ TextButton( onPressed: () => Navigator.pop(context, false), child: const Text('Cancel'), ), TextButton( onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete'), ), ], ), );
    if (deleteConfirmed != true) return;
    setState(() => _isSaving = true); _showLoadingDialog();
    User? user = FirebaseAuth.instance.currentUser; if (user == null) return;
    try {
      // TODO: Add logic here to delete the image from Firebase Storage if it exists
      await FirebaseFirestore.instance .collection('users') .doc(user.uid) .collection('journal_entries') .doc(_documentId) .delete();
      if (mounted) { Navigator.pop(context); Navigator.pop(context); }
    } catch (e) { if (mounted) Navigator.pop(context); _showErrorDialog("Error deleting entry: ${e.toString()}");
    } finally { if (mounted) setState(() => _isSaving = false); }
  }
  void _showLoadingDialog() { showDialog( context: context, barrierDismissible: false, builder: (context) => Center( child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150), ), );
  }
  void _showErrorDialog(String message) { if (!mounted) return; showDialog( context: context, builder: (context) => AlertDialog( title: const Text("Error"), content: Text(message), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")), ], ), );
  }
  
  // (This function remains unchanged)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024, // Resize for faster uploads and less storage
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
          _imageWasRemoved = false; // A new image was picked, so don't remove
          _existingImageUrl = null; // Clear existing image to show the new one
        });
      }
    } catch (e) {
      _showErrorDialog("Error picking image: ${e.toString()}");
    }
  }
  
  // (This function remains unchanged)
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
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // (This function remains unchanged)
  Future<void> _saveEntry() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      _showErrorDialog("Please fill out both the title and content.");
      return;
    }
    setState(() => _isSaving = true);
    _showLoadingDialog();
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context); // Pop loading
      _showErrorDialog("You must be logged in to save an entry.");
      return;
    }
    try {
      String? finalImageUrl = _existingImageUrl; // Start with the image we already have
      if (_pickedImageFile != null) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('journal_images') // Folder for all journal images
            .child(user.uid) // Subfolder for this user
            .child(fileName); // The file
        UploadTask uploadTask = storageRef.putFile(_pickedImageFile!);
        TaskSnapshot snapshot = await uploadTask;
        finalImageUrl = await snapshot.ref.getDownloadURL(); // Get the public URL
      }
      else if (_imageWasRemoved) {
        finalImageUrl = null;
      }
      final entryData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'isImportant': _isImportant,
        'isBookmarked': _isBookmarked,
        'imageUrl': finalImageUrl, // Save the final URL (or null)
      };
      if (_documentId == null) {
        // New Entry
        await FirebaseFirestore.instance.collection('users').doc(user.uid)
            .collection('journal_entries').add(entryData);
      } else {
        // Existing Entry
        await FirebaseFirestore.instance.collection('users').doc(user.uid)
            .collection('journal_entries').doc(_documentId).update(entryData);
      }

      await StreakService.updateDailyStreak(user);

      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        Navigator.pop(context); // Pop back to journal list
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Pop loading dialog
      _showErrorDialog("Error saving entry: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // (This build method remains unchanged)
  @override
  Widget build(BuildContext context) {
    String formattedDate = '';
    if (widget.document != null) {
      final data = widget.document!.data() as Map<String, dynamic>;
      Timestamp? ts = data['timestamp'];
      if (ts != null) { formattedDate = DateFormat('MMMM d, yyyy  h:mm a').format(ts.toDate()); }
    }
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        leading: IconButton( icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context), ),
        title: Text( _documentId == null ? 'New Entry' : 'Edit Entry', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), ),
        actions: [
          IconButton( icon: Icon( _isImportant ? Icons.star_rounded : Icons.star_border_rounded, color: _isImportant ? Colors.yellow.shade600 : Colors.white, ), tooltip: 'Important', onPressed: () { setState(() { _isImportant = !_isImportant; }); }, ),
          IconButton( icon: Icon( _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _isBookmarked ? Colors.white : Colors.white.withOpacity(0.7), ), tooltip: 'Bookmark', onPressed: () { setState(() { _isBookmarked = !_isBookmarked; }); }, ),
          if (_documentId != null) IconButton( icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: _isSaving ? null : _deleteEntry, ),
          IconButton( icon: const Icon(Icons.check, color: Colors.white, size: 30), onPressed: _isSaving ? null : _saveEntry, ),
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
                _buildImageDisplay(),
                TextField(
                  controller: _titleController,
                  autofocus: _documentId == null,
                  decoration: const InputDecoration(
                    hintText: 'Entry Title',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 24, fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (formattedDate.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                    child: Text( formattedDate, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontStyle: FontStyle.italic), ),
                  ),
                if (formattedDate.isEmpty) const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // (This helper widget remains unchanged)
  Widget _buildImageDisplay() {
    bool showImage = (_pickedImageFile != null || (_existingImageUrl != null && !_imageWasRemoved));
    if (!showImage) {
      return Center(
        child: TextButton.icon(
          icon: Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade700),
          label: Text("Add Photo", style: TextStyle(color: Colors.grey.shade700)),
          onPressed: _showImageSourceDialog,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
      );
    }
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: double.infinity,
            height: 200, 
            color: Colors.grey.shade200, 
            child: _pickedImageFile != null
                ? Image.file( 
                    _pickedImageFile!,
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage( 
                    imageUrl: _existingImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(child: Lottie.asset('assets/animations/loading.json', width: 60, height: 60)),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _pickedImageFile = null;
              _existingImageUrl = null;
              _imageWasRemoved = true;
            });
          },
          icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 28),
          tooltip: 'Remove Image',
        ),
      ],
    );
  }
}