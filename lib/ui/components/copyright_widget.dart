import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// A reusable copyright widget that displays copyright information.
/// 
/// This widget shows "Copyright @ Vivekananda Vidyapith 2024" at the bottom
/// of screens. It automatically adapts to light and dark themes.
/// 
/// Example usage:
/// ```dart
/// CopyrightWidget()
/// ```
class CopyrightWidget extends StatelessWidget {
  const CopyrightWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Use muted foreground color for subtle appearance
    final textColor = isDark 
        ? ShadCNTheme.darkMutedForeground 
        : ShadCNTheme.mutedForeground;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ShadCNTheme.space4,
      ),
      child: Center(
        child: Text(
          'Copyright @ Vivekananda Vidyapith 2024',
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

