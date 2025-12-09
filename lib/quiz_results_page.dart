// In: lib/quiz_results_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'pop_quiz_page.dart'; 
import 'custom_page_route.dart';
import 'streak_service.dart'; 
import 'gamification_service.dart'; // <-- 1. IMPORT THIS

class QuizResultsPage extends StatefulWidget {
  final int correctAnswers;
  final int totalQuestions;

  const QuizResultsPage({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  @override
  State<QuizResultsPage> createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  // --- Theme Colors ---
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color cardBackgroundColor = Color(0xFFFCFCFC);
  static const Color statNumberColor = Color(0xFF4A69FF);

  // --- Gamification ---
  static const int pointsPerQuestion = 10;
  static const int perfectBonus = 50;

  int _totalPointsEarned = 0;
  bool _isPerfectScore = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _calculateAndSavePoints();
  }

  Future<void> _calculateAndSavePoints() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    
    _isPerfectScore = (widget.correctAnswers == widget.totalQuestions);
    _totalPointsEarned = (widget.correctAnswers * pointsPerQuestion);
    
    if (_isPerfectScore && widget.totalQuestions > 0) {
      _totalPointsEarned += perfectBonus;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return; 
    }

    try {
      // --- 2. UPDATE: Use GamificationService ---
      if (_totalPointsEarned > 0) {
        // This awards points AND checks for badges
        await GamificationService.awardPoints(user, _totalPointsEarned);
      }

      // Keep streak alive (even if they didn't get points, taking a quiz counts as activity)
      await StreakService.updateDailyStreak(user);
      // --- END UPDATE ---

    } catch (e) {
      print("Failed to save points: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        elevation: 1.0,
        title: const Text('Quiz Results',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: cardBackgroundColor,
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Show Lottie Animation ---
                  _isPerfectScore
                      ? Lottie.asset('assets/animations/trophy.json', height: 150)
                      : Lottie.asset('assets/animations/star.json', height: 150),
                  
                  const SizedBox(height: 16.0),
                  Text(
                    _isPerfectScore ? "Perfect Score!" : "Well Done!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    "You got ${widget.correctAnswers} out of ${widget.totalQuestions} correct.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  const Divider(),
                  const SizedBox(height: 32.0),
                  
                  if (_isSaving)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: [
                        Text(
                          "+$_totalPointsEarned",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: statNumberColor,
                          ),
                        ),
                        Text(
                          "Points Earned",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16.0, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 32.0),
                  
                  // --- "Play Again" Button ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        FadeRoute(page: const PopQuizPage()),
                      );
                    },
                    label: const Text(
                      "Play Again",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  
                  // --- "Done" Button ---
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Done",
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}