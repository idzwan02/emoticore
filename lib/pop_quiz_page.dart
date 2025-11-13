// In: lib/pop_quiz_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'quiz_model.dart'; // Your new model
import 'quiz_results_page.dart'; // The page we will create next
import 'custom_page_route.dart';
import 'dart:math'; // To shuffle the questions

class PopQuizPage extends StatefulWidget {
  const PopQuizPage({super.key});

  @override
  State<PopQuizPage> createState() => _PopQuizPageState();
}

class _PopQuizPageState extends State<PopQuizPage> {
  // --- Theme Colors ---
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color cardBackgroundColor = Color(0xFFFCFCFC);
  static const Color questionTextColor = Color(0xFF333333);
  static const Color optionTextColor = Color(0xFF444444);
  static const Color correctColor = Colors.green;
  static const Color incorrectColor = Colors.red;
  static const Color unselectedOptionBorderColor = Color(0xFFD0D0D0);

  // --- State Variables ---
  String _state = 'loading'; // loading, ready, error
  List<PopQuizQuestion> _allQuestions = [];
  List<PopQuizQuestion> _quizQuestions = []; // The 5 random questions for this quiz
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _score = 0; // Number of correct answers
  int? _selectedAnswerIndex; // Index of the answer the user tapped
  bool _answerWasSelected = false; // To disable other buttons
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadQuestionsFromFirestore();
  }

  Future<void> _loadQuestionsFromFirestore() async {
    if (!mounted) return;
    setState(() => _state = 'loading');
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('quiz_bank').get();
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          _state = 'error';
          _errorMessage = "No questions found in the quiz bank.";
        });
        return;
      }
      
      _allQuestions =
          snapshot.docs.map((doc) => PopQuizQuestion.fromSnapshot(doc)).toList();
      _startNewQuiz();

    } catch (e) {
      if (mounted) {
        setState(() {
          _state = 'error';
          _errorMessage = "Failed to load quiz: ${e.toString()}";
        });
      }
    }
  }

  void _startNewQuiz() {
    if (_allQuestions.isEmpty) return;
    
    // Shuffle the list and take 5 questions
    final shuffledList = List<PopQuizQuestion>.from(_allQuestions)..shuffle(Random());
    _quizQuestions = shuffledList.take(5).toList();
    
    if (mounted) {
      setState(() {
        _state = 'ready';
        _currentPage = 0;
        _score = 0;
        _answerWasSelected = false;
        _selectedAnswerIndex = null;
      });
    }
  }

  void _handleAnswerTap(int selectedIndex, int correctIndex) {
    if (_answerWasSelected) return; // Don't allow changing answer

    bool isCorrect = (selectedIndex == correctIndex);
    
    setState(() {
      _answerWasSelected = true;
      _selectedAnswerIndex = selectedIndex;
      if (isCorrect) {
        _score++;
      }
    });

    // Wait 1.5 seconds, then move to the next page
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return; // Check if the widget is still in the tree
      if (_currentPage == _quizQuestions.length - 1) {
        // Last question - go to results
        Navigator.pushReplacement(
          context,
          FadeRoute(
            page: QuizResultsPage(
              correctAnswers: _score,
              totalQuestions: _quizQuestions.length,
            ),
          ),
        );
      } else {
        // Reset state *before* navigating
        setState(() {
          _answerWasSelected = false;
          _selectedAnswerIndex = null;
        });

        // Move to next question
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Pop Quiz!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case 'loading':
        // --- THIS IS THE FIX ---
        return Center(child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150));
      case 'error':
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          ),
        );
      case 'ready':
      default:
        return Column(
          children: [
            // --- Progress Bar ---
            LinearProgressIndicator(
              value: (_currentPage + 1) / _quizQuestions.length,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(appPrimaryColor),
            ),
            // --- PageView for Questions ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // No swiping
                itemCount: _quizQuestions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return SingleChildScrollView(
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildQuestionPageContent(_quizQuestions[index]),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
    }
  }

  Widget _buildQuestionPageContent(PopQuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Make column wrap its content
      children: [
        // --- Question Card ---
        Card(
          color: cardBackgroundColor,
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w500,
                color: questionTextColor,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        // --- Answer Options ---
        Column(
          children: question.answers.asMap().entries.map((entry) {
            int answerIndex = entry.key;
            String answerText = entry.value;
            return _buildAnswerOption(answerText, answerIndex, question.correctIndex);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnswerOption(String answerText, int answerIndex, int correctIndex) {
    Color borderColor = unselectedOptionBorderColor;
    Color fillColor = cardBackgroundColor;
    IconData? trailingIcon;

    if (_answerWasSelected) {
      if (answerIndex == _selectedAnswerIndex) {
        // This is the one the user tapped
        borderColor = (answerIndex == correctIndex) ? correctColor : incorrectColor;
        fillColor = (answerIndex == correctIndex) ? correctColor.withOpacity(0.1) : incorrectColor.withOpacity(0.1);
        trailingIcon = (answerIndex == correctIndex) ? Icons.check_circle : Icons.cancel;
      } else if (answerIndex == correctIndex) {
        // This is the correct answer, but user didn't tap it
        borderColor = correctColor;
        fillColor = correctColor.withOpacity(0.1);
        trailingIcon = Icons.check_circle;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 2.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleAnswerTap(answerIndex, correctIndex),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      answerText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: optionTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    Icon(trailingIcon, color: borderColor, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}