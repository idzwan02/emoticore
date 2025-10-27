// In: lib/dass21_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dass21Page extends StatefulWidget {
  const Dass21Page({super.key});

  @override
  State<Dass21Page> createState() => _Dass21PageState();
}

class _Dass21PageState extends State<Dass21Page> {
  // Page View Controller & State
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, int> _answers = {}; // Stores {questionIndex: score}

  // Define theme colors & Styles
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color cardBackgroundColor = Color(0xFFFCFCFC); // Slightly off-white
  static const Color instructionTextColor = Color(0xFF555555); // Darker grey
  static const Color questionTextColor = Color(0xFF222222); // Near black
  static const Color selectedOptionBorderColor = appPrimaryColor;
  static const Color unselectedOptionBorderColor = Color(0xFFD0D0D0); // Lighter grey border
  static const Color selectedOptionFillColor = Color(0xFFE0F2F2); // Very light teal fill
  static const Duration _animationDuration = Duration(milliseconds: 300); // Animation speed


  // DASS-21 Questions (Keep as before)
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

  // Answer options (Keep as before)
  final List<String> _answerOptions = [
    '0 Did not apply to me at all',
    '1 Applied to me to some degree, or some of the time',
    '2 Applied to me to a considerable degree, or a good part of time',
    '3 Applied to me very much, or most of the time',
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
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        leading: IconButton( icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _showExitConfirmationDialog ),
        title: const Text('DASS-21 Assessment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 1.0, // Reduced elevation
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // Consistent padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Padding(
               padding: const EdgeInsets.only(bottom: 16.0), // More space below page indicator
               child: Text(
                 'Page ${_currentPage + 1} of 3',
                 textAlign: TextAlign.center,
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
               ),
             ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) { setState(() { _currentPage = page; }); },
                children: [
                  _buildQuestionPage(0),
                  _buildQuestionPage(1),
                  _buildQuestionPage(2),
                ],
              ),
            ),
            const SizedBox(height: 16.0), // Consistent spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back_ios, size: 16), label: const Text('Previous'),
                  onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                ),
                ElevatedButton.icon(
                  icon: Icon(isLastPage ? Icons.check_circle_outline : Icons.arrow_forward_ios, size: 18),
                  label: Text( isLastPage ? 'Finish Assessment' : 'Next Page', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom( backgroundColor: appPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14) ),
                  onPressed: currentPageAnswered ? (isLastPage ? (_answers.length == _questions.length ? _submitResults : null) : _goToNextPage) : null,
                ),
              ],
            ),
             const SizedBox(height: 12.0), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage(int pageIndex) {
    int questionsPerPage = 7;
    int startIndex = pageIndex * questionsPerPage;
    int endIndex = startIndex + questionsPerPage > _questions.length ? _questions.length : startIndex + questionsPerPage;

    return SingleChildScrollView(
      key: PageStorageKey('page_$pageIndex'), // Helps preserve scroll position
      child: Card(
        color: cardBackgroundColor,
        elevation: 2.0, // Softer shadow
        shadowColor: Colors.black.withOpacity(0.1), // Lighter shadow color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pageIndex == 0) ...[
                 const Text( "Please read each statement and select the option (0, 1, 2, or 3) which indicates how much the statement applied to you over the past week.", style: TextStyle(fontSize: 14.0, color: instructionTextColor, height: 1.4), textAlign: TextAlign.center, ),
                 const SizedBox(height: 20.0), const Divider(), const SizedBox(height: 20.0),
              ],
              for (int i = startIndex; i < endIndex; i++)
                _buildSingleQuestionUI(questionIndex: i, startIndex: startIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleQuestionUI({required int questionIndex, required int startIndex}) {
    bool isSelected(int scoreValue) => _answers[questionIndex] == scoreValue;
    int questionsPerPage = 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${questionIndex + 1}', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.grey.shade700)), // Adjusted style
          const SizedBox(height: 12.0), // Slightly more space

          // --- AnimatedSwitcher for Question Text ---
          AnimatedSwitcher(
            duration: _animationDuration,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child); // Simple fade
              // Or SlideTransition for a different effect
              // return SlideTransition(position: Tween<Offset>(begin: Offset(0.1, 0), end: Offset.zero).animate(animation), child: child);
            },
            child: Text(
              _questions[questionIndex],
              key: ValueKey<int>(questionIndex), // Important for AnimatedSwitcher
              style: const TextStyle( fontSize: 19.0, fontWeight: FontWeight.w500, color: questionTextColor, height: 1.5 ),
            ),
          ),
          // --- End AnimatedSwitcher ---

          const SizedBox(height: 24.0), // More space before answers
          Column(
            children: _answerOptions.asMap().entries.map((entry) {
              int scoreValue = entry.key; String optionText = entry.value;
              bool currentlySelected = isSelected(scoreValue);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                // --- AnimatedContainer for Answer Selection ---
                child: AnimatedContainer(
                  duration: _animationDuration,
                  decoration: BoxDecoration(
                     color: currentlySelected ? selectedOptionFillColor : cardBackgroundColor,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(
                        color: currentlySelected ? selectedOptionBorderColor : unselectedOptionBorderColor,
                        width: currentlySelected ? 2.0 : 1.5,
                     )
                  ),
                  child: Material( // Material for InkWell splash effect
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () { setState(() { _answers[questionIndex] = scoreValue; }); },
                      borderRadius: BorderRadius.circular(12), // Match shape
                      child: Padding( // Add padding inside InkWell
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0), // Adjusted padding
                        child: Row(
                          children: [
                            Icon(
                              currentlySelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: currentlySelected ? selectedOptionBorderColor : unselectedOptionBorderColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12), // Space between icon and text
                            Expanded( // Make text take remaining space
                              child: Text(
                                optionText,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: questionTextColor,
                                  fontWeight: currentlySelected ? FontWeight.w500 : FontWeight.normal, // Slightly bolder when selected
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // --- End AnimatedContainer ---
              );
            }).toList(),
          ),
          // Use calculation based on startIndex for the last item on the page
          if (questionIndex < (startIndex + questionsPerPage - 1) && questionIndex < (_questions.length - 1))
             const Divider(height: 40, thickness: 1, indent: 10, endIndent: 10), // Added indent
        ],
      ),
    );
  }


  // (Keep _goToNextPage, _goToPreviousPage, _checkIfCurrentPageAnswered, _submitResults, _showExitConfirmationDialog as they were)
   void _goToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage( duration: const Duration(milliseconds: 400), curve: Curves.easeInOut, ); // Smoother curve
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage( duration: const Duration(milliseconds: 400), curve: Curves.easeInOut, ); // Smoother curve
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

  Future<void> _submitResults() async {
    // (Submit logic remains the same)
    if (_answers.length != _questions.length) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Please answer all questions.')), ); return; }
    int depressionSum = 0; int anxietySum = 0; int stressSum = 0;
    _answers.forEach((index, score) {
      String scale = _questionIndexToScale[index]!;
      switch (scale) { case 'D': depressionSum += score; break; case 'A': anxietySum += score; break; case 'S': stressSum += score; break; }
    });
    int finalDepressionScore = depressionSum * 2; int finalAnxietyScore = anxietySum * 2; int finalStressScore = stressSum * 2;
    print('Submitting Results...');
    print('Final Scores -> D: $finalDepressionScore, A: $finalAnxietyScore, S: $finalStressScore');
    Map<String, int> answersWithStringKeys = _answers.map((key, value) => MapEntry(key.toString(), value));
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      showDialog( context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()) );
      try {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('dass21_results')
            .add({
                'depressionScore': finalDepressionScore, 'anxietyScore': finalAnxietyScore, 'stressScore': finalStressScore,
                'timestamp': FieldValue.serverTimestamp(), 'rawAnswers': answersWithStringKeys,
            });
         if(Navigator.canPop(context)) Navigator.pop(context); // Pop loading
         ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Results saved!'), backgroundColor: Colors.green), );
         if(Navigator.canPop(context)) Navigator.pop(context); // Pop DASS screen
      } catch (e) {
          if(Navigator.canPop(context)) Navigator.pop(context); // Pop loading
          print("Error saving DASS-21 results: $e");
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error saving results: ${e.toString()}'), backgroundColor: Colors.red), );
      }
    } else { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.red), ); }
  }

   Future<void> _showExitConfirmationDialog() async {
    // (Confirmation dialog remains the same)
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Assessment?'), content: const Text('Your progress will be lost if you exit now.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
        ],
      ),
    );
    if (shouldPop ?? false) { if(Navigator.canPop(context)) Navigator.pop(context); }
  }

} // End of _Dass21PageState