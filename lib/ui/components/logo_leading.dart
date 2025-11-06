import 'package:flutter/material.dart';

/// A widget that displays the Vidyapith logo in the app bar's leading position.
/// 
/// This widget automatically shows a back button if there's a previous route
/// in the navigation stack. It's perfect for maintaining consistent branding
/// across your app while providing intuitive navigation.
/// 
/// Example usage:
/// ```dart
/// LogoLeading(
///   logoHeight: 40,
///   showBackButton: true, // Optional: override auto-detection
/// )
/// ```
class LogoLeading extends StatelessWidget {
  const LogoLeading({
    super.key,
    this.logoHeight = 40,
    this.showBackButton,
  });

  /// Height of the logo image in pixels (default: 40)
  final double logoHeight;
  
  /// Whether to show the back button. If null, automatically detects if back navigation is possible.
  final bool? showBackButton;

  @override
  Widget build(BuildContext context) {
    // Automatically detect if we can go back, or use the provided value
    final shouldShowBackButton = showBackButton ?? Navigator.of(context).canPop();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show back button if navigation is possible
        if (shouldShowBackButton) const BackButton(),
        // Logo image with dynamic spacing based on back button presence
        Padding(
          padding: EdgeInsets.only(left: shouldShowBackButton ? 4.0 : 0.0),
          child: Image.asset(
            'assets/images/logo.png',
            height: logoHeight,
            fit: BoxFit.contain, // Maintain aspect ratio
            semanticLabel: 'Vidyapith logo', // For accessibility
          ),
        ),
      ],
    );
  }
}


