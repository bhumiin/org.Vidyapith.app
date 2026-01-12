// Import statements - These bring in all the tools and components needed
// to build the splash screen, including animation and navigation
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/shadcn_theme.dart';
import '../../main.dart';

/// Splash Screen - The first screen users see when the app launches
/// 
/// This screen displays:
/// - Vidyapith 50th anniversary logo/image
/// - Smooth fade-in and scale animation, followed by fade-out
/// - Automatically navigates to MainScreen with smooth fade transition
/// 
/// Features:
/// - Fade-in animation: opacity 0 → 1 over 1.2 seconds
/// - Scale animation: scale 0.8 → 1.5 over 1.2 seconds
/// - Both animations run simultaneously at the start
/// - Fade-out animation: opacity 1 → 0 over 1.0 seconds at the end
/// - Smooth cross-fade transition to main screen
/// - Respects light/dark theme for background color
/// - Full screen coverage with centered image
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Called once when the splash screen is first created
  /// Sets up a timer to navigate to MainScreen with smooth fade transition
  @override
  void initState() {
    super.initState();
    // Start navigation during fade-out for smooth cross-fade effect
    // Fade-in: 1.2s, stay visible: 0.6s, fade-out starts at 1.8s
    // Navigate at 2.0s so main screen fades in as splash fades out
    Future.delayed(const Duration(milliseconds: 2000), () {
      // Only navigate if the widget is still mounted (not disposed)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          _createFadeRoute(const MainScreen()),
        );
      }
    });
  }

  /// Creates a custom fade route for smooth page transitions
  /// This provides a seamless cross-fade effect instead of the default slide transition
  PageRouteBuilder _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 1000), // Matches fade-out duration
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade in the new page as the old page fades out
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Builds the splash screen UI
  /// Creates a full-screen container with the animated logo
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Check if device is using dark mode or light mode
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Background color changes based on theme (dark or light)
      backgroundColor: isDark
          ? ShadCNTheme.darkBackground // Dark blue-gray
          : ShadCNTheme.background, // White
      body: SafeArea(
        // SafeArea ensures content isn't hidden by device notches or status bars
        child: Center(
          // Center the image on the screen
          child: Image.asset(
            'assets/images/vvp_50th.png',
            // Fit the image to screen while maintaining aspect ratio
            // This ensures the image scales properly on different screen sizes
            fit: BoxFit.contain,
            // Add some padding around the image (20% of screen width on each side)
            width: MediaQuery.of(context).size.width * 0.6,
          )
              // Fade in animation: opacity goes from 0 to 1
              .animate()
              .fadeIn(
                duration: 1200.ms, // 1.2 seconds
                curve: Curves.easeOut, // Smooth easing curve
              )
              // Scale animation: scale goes from 0.8 to 1.5
              .scale(
                begin: const Offset(0.8, 0.8), // Start at 80% size
                end: const Offset(1.5, 1.5), // End at 150% size
                duration: 1200.ms, // 1.2 seconds
                curve: Curves.easeOut, // Smooth easing curve
              )
              // Wait 0.6 seconds (total 1.8 seconds elapsed)
              .then(delay: 600.ms)
              // Fade out animation: opacity goes from 1 to 0
              .fadeOut(
                duration: 1000.ms, // 1.0 seconds
                curve: Curves.easeIn, // Smooth easing curve
              ),
        ),
      ),
    );
  }
}

