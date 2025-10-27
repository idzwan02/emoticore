// In: lib/custom_page_route.dart

import 'package:flutter/material.dart';

class FadeRoute extends PageRouteBuilder {
  final Widget page;

  FadeRoute({required this.page})
      : super(
          // Builds the actual page widget that will be displayed
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page, // Use the page passed into the constructor

          // Builds the transition animation
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation, // The primary animation (0.0 to 1.0)
            Animation<double> secondaryAnimation, // Animation for routes behind this one
            Widget child, // The page widget built by pageBuilder
          ) =>
              FadeTransition(
            opacity: animation, // Use the primary animation to control opacity
            child: child, // Apply the fade to the page content
          ),

          // How long the transition should take
          transitionDuration: const Duration(milliseconds: 300), 
          // Optional: How long the reverse transition takes
          // reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}