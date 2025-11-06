import 'package:flutter/material.dart';

import 'logo_leading.dart';

/// Creates a branded app bar with the Vidyapith logo in the leading position.
/// 
/// This function returns a custom AppBar that includes the logo and supports
/// all standard AppBar features like title, actions, and bottom widgets.
/// 
/// Example usage:
/// ```dart
/// buildBrandedAppBar(
///   title: Text('My Screen'),
///   actions: [IconButton(...)],
///   backgroundColor: Colors.white,
/// )
/// ```
PreferredSizeWidget buildBrandedAppBar({
  /// Optional title widget to display in the center of the app bar
  Widget? title,
  /// Optional action buttons (icons) to display on the right side
  List<Widget>? actions,
  /// Optional bottom widget (like a TabBar)
  PreferredSizeWidget? bottom,
  /// Background color for the app bar
  Color? backgroundColor,
  /// Width reserved for the leading widget (logo + back button)
  double leadingWidth = 140,
}) {
  return AppBar(
    automaticallyImplyLeading: false, // We handle leading manually with LogoLeading
    leading: const LogoLeading(), // Our custom logo widget
    leadingWidth: leadingWidth, // Space for logo + back button
    title: title,
    centerTitle: true, // Center the title
    actions: actions, // Right side actions
    bottom: bottom, // Bottom widget (e.g., tabs)
    backgroundColor: backgroundColor,
  );
}


