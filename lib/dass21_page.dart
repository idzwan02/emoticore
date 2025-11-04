// In: lib/dass21_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart'; // Make sure you have this import

class Dass21Page extends StatefulWidget {
  const Dass21Page({super.key});

  @override
  State<Dass21Page> createState() => _Dass21PageState();
}

class _Dass21PageState extends State<Dass21Page> {
  // --- Page View Controller ---
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, int> _answers = {}; // Stores {questionIndex: score}

  // --- Theme Colors ---
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color cardBackgroundColor = Color(0xFFFCFCFC);
  static const Color questionTextColor = Color(0xFF333333);
  static const Color optionTextColor = Color(0xFF444444);
  static const Color selectedOptionBorderColor = appPrimaryColor;
  static const Color unselectedOptionBorderColor = Color(0xFFD0D0D0);
  static const Color selectedOptionFillColor = Color(0xFFE0F2F2);
  static const Duration _animationDuration = Duration(milliseconds: 200);

  // --- DASS-21 Questions (Keep as before) ---
  final List<String> _questions = [
    "I found it hard to wind down", "I was aware of dryness of my mouth", "I couldn't seem to experience any positive feeling at all",
    "I experienced breathing difficulty (eg, excessively rapid breathing, breathlessness in the absence of physical exertion)", "I found it difficult to work up the initiative to do things",
    "I tended to over-react to situations", "I experienced trembling (eg, in the hands)", "I felt that I was using a lot of nervous energy",
    "I was worried about situations in which I might panic and make a fool of myself", "I felt that I had nothing to look forward to",
    "I found myself getting agitated", "I found it difficult to relax", "I felt down-hearted and blue",
    "I was intolerant of anything that kept me from getting on with what I was doing", "I felt I was close to panic",
    "I was unable to become enthusiastic about anything", "I felt I wasn't worth much as a person", "I felt that I was rather touchy",
    "I was aware of the action of my heart in the absence of physical exertion (eg, sense of heart rate increase, heart missing a beat)",
    "I felt scared without any good reason", "I felt that life was meaningless"
  ];

  // --- UPDATED: Answer labels WITHOUT the score prefix ---
  final List<String> _answerLabels = [
    'Did not apply to me at all',
    'Applied to me to some degree, or some of the time',
    'Applied to me to a considerable degree, or a good part of time',
    'Applied to me very much, or most of the time',
  ];

  // Mapping from Question Index (0-20) to Scale (D, A, S) (Keep as before)
  final Map<int, String> _questionIndexToScale = {
    0: 'S', 1: 'A', 2: 'D', 3: 'A', 4: 'D', 5: 'S', 6: 'A', 7: 'S', 8: 'A',
    9: 'D', 10: 'S', 11: 'S', 12: 'D', 13: 'S', 14: 'A', 15: 'D', 16: 'D',
    17: 'S', 18: 'A', 19: 'A', 20: 'D'
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage == 2;
    bool currentPageAnswered = _checkIfCurrentPageAnswered();

    return Scaffold(
      backgroundColor: appBackgroundColor, // Use your theme background color
      appBar: AppBar(
        backgroundColor: appPrimaryColor, // Use your theme AppBar color
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // White icon
          onPressed: _showExitConfirmationDialog,
        ),
        title: const Text(
          'DASS-21 Assessment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false, // Align left
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text(
                '${_currentPage + 1}/3',
                style: const TextStyle(
                  color: Colors.white70, // White text
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
        // --- Progress Bar ---
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            backgroundColor: Colors.white.withOpacity(0.3), // Lighter background
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // White progress
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() { _currentPage = page; });
        },
        children: [
          _buildQuestionPage(0),
          _buildQuestionPage(1),
          _buildQuestionPage(2),
        ],
      ),
      // --- Styled Navigation Buttons ---
      bottomNavigationBar: _buildNavigationButtons(isLastPage, currentPageAnswered),
    );
  }

  // --- Helper to build the content for a single page ---
  Widget _buildQuestionPage(int pageIndex) {
    int questionsPerPage = 7;
    int startIndex = pageIndex * questionsPerPage;
    int endIndex = startIndex + questionsPerPage > _questions.length
                   ? _questions.length
                   : startIndex + questionsPerPage;

    return SingleChildScrollView(
      key: PageStorageKey('page_$pageIndex'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show instructions only on the first page, inside a card
          if (pageIndex == 0) ...[
             Card(
               elevation: 1.0,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               color: cardBackgroundColor,
               margin: const EdgeInsets.only(bottom: 16),
               child: const Padding(
                 padding: EdgeInsets.all(16.0),
                 child: Text(
                  "Please read each statement and select the option which indicates how much the statement applied to you over the past week.",
                  style: TextStyle(fontSize: 15.0, color: Color(0xFF555555), height: 1.4),
                  textAlign: TextAlign.center,
                ),
               ),
             ),
          ],
          
          // Generate the 7 questions for this page
          for (int i = startIndex; i < endIndex; i++)
            _buildQuestionCard(i), // Call helper to build a Card for each question
        ],
      ),
    );
  }

  // --- NEW: Helper to build a Card for a Single Question ---
  Widget _buildQuestionCard(int questionIndex) {
    return Card(
      color: cardBackgroundColor,
      elevation: 2.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text
            Text(
              '${questionIndex + 1}. ${_questions[questionIndex]}',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
                color: questionTextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20.0),
            
            // --- Answer Options (Animated Buttons) ---
            Column(
              children: _answerLabels.asMap().entries.map((entry) {
                int scoreValue = entry.key; // 0, 1, 2, or 3
                String optionText = entry.value;
                bool isSelected = _answers[questionIndex] == scoreValue;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: AnimatedContainer(
                    duration: _animationDuration,
                    decoration: BoxDecoration(
                       color: isSelected ? selectedOptionFillColor : cardBackgroundColor,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(
                          color: isSelected ? selectedOptionBorderColor : unselectedOptionBorderColor,
                          width: isSelected ? 2.0 : 1.5,
                       )
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _answers[questionIndex] = scoreValue;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isSelected ? selectedOptionBorderColor : unselectedOptionBorderColor,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: optionTextColor,
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  // --- END NEW HELPER ---

  // --- Styled Back/Next Buttons (Keep as before) ---
  Widget _buildNavigationButtons(bool isLastPage, bool currentPageAnswered) {
    return Container(
      color: appBackgroundColor, // Use theme background
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0).copyWith(bottom: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 140,
            height: 48,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // White background
                foregroundColor: Colors.black54,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              onPressed: _currentPage > 0 ? _goToPreviousPage : null,
              child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(
            width: 140,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              onPressed: currentPageAnswered
                 ? (isLastPage
                      ? (_answers.length == _questions.length ? _submitResults : null)
                      : _goToNextPage)
                 : null,
              child: Text(
                isLastPage ? 'Finish' : 'Next',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Page Navigation Functions (Keep as before) ---
  void _goToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage( duration: const Duration(milliseconds: 400), curve: Curves.easeInOut, );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage( duration: const Duration(milliseconds: 400), curve: Curves.easeInOut, );
    }
  }

  bool _checkIfCurrentPageAnswered() {
    int questionsPerPage = 7;
    int startIndex = _currentPage * questionsPerPage;
    int endIndex = startIndex + questionsPerPage > _questions.length ? _questions.length : startIndex + questionsPerPage;
    for (int i = startIndex; i < endIndex; i++) {
      if (!_answers.containsKey(i)) { return false; }
    }
    return true;
  }
  // --- END Navigation ---


  // --- Submit Function (Keep as before) ---
  Future<void> _submitResults() async {
    if (_answers.length != _questions.length) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Please answer all questions.')), ); return; }
    int depressionSum = 0; int anxietySum = 0; int stressSum = 0;
    _answers.forEach((index, score) {
      String scale = _questionIndexToScale[index]!;
      switch (scale) { case 'D': depressionSum += score; break; case 'A': anxietySum += score; break; case 'S': stressSum += score; break; }
    });
    int finalDepressionScore = depressionSum * 2; int finalAnxietyScore = anxietySum * 2; int finalStressScore = stressSum * 2;
    Map<String, int> answersWithStringKeys = _answers.map((key, value) => MapEntry(key.toString(), value));
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      showDialog( context: context, barrierDismissible: false, builder: (context) => Center(child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150)) );
      try {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('dass21_results')
            .add({
                'depressionScore': finalDepressionScore, 'anxietyScore': finalAnxietyScore, 'stressScore': finalStressScore,
                'timestamp': FieldValue.serverTimestamp(), 'rawAnswers': answersWithStringKeys,
            });
         if(Navigator.canPop(context)) Navigator.pop(context); // Pop loading
         // Show results dialog
         _showResultsDialog(finalDepressionScore, finalAnxietyScore, finalStressScore);

      } catch (e) {
          if(Navigator.canPop(context)) Navigator.pop(context); // Pop loading
          print("Error saving DASS-21 results: $e");
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error saving results: ${e.toString()}'), backgroundColor: Colors.red), );
      }
    } else { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.red), ); }
  }

  // --- UPDATED Results Dialog (to show scores) ---
  Future<void> _showResultsDialog(int depression, int anxiety, int stress) {
     return showDialog<void>(
        context: context,
        barrierDismissible: false, // User must tap button
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Assessment Completed!'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Your scores (multiplied by 2) are:'),
                  const SizedBox(height: 15),
                  Text('Depression: $depression', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Anxiety: $anxiety', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Stress: $stress', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  const Text('These scores have been saved and your dashboard chart will be updated.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK', style: TextStyle(color: appPrimaryColor, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop(); // Close results dialog
                  if (Navigator.canPop(context)) {
                     Navigator.of(context).pop(); // Pop quiz page
                  }
                },
              ),
            ],
          );
        },
      );
  }

  // --- Exit Confirmation Dialog (Keep as before) ---
   Future<void> _showExitConfirmationDialog() async {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Assessment?'), content: const Text('Your progress will be lost if you exit now.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (shouldPop ?? false) { if(Navigator.canPop(context)) Navigator.pop(context); }
  }

} // End of _Dass21PageState