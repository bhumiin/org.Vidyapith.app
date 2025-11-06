import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ShadCN-inspired theme system for Flutter
/// 
/// This class provides a complete design system for the app, including:
/// - Color palette for light and dark themes
/// - Spacing system for consistent padding/margins
/// - Border radius values for rounded corners
/// - Typography settings (font sizes, weights, line heights)
/// - Shadow definitions for elevation effects
/// - Complete Material 3 theme configurations
/// 
/// Usage: Use ShadCNTheme.lightTheme or ShadCNTheme.darkTheme in your MaterialApp
class ShadCNTheme {
  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================
  // These colors define the appearance of the app in light mode.
  // The "Foreground" colors are used for text/icons that appear ON TOP of the
  // main color (e.g., text on a button, icon on a background).
  
  /// Main brand color - used for primary buttons, links, and important UI elements
  static const Color primary = Color(0xFF0F172A);
  
  /// Text/icon color that appears on top of primary-colored backgrounds
  /// (e.g., white text on a dark blue button)
  static const Color primaryForeground = Color(0xFFF8FAFC);
  
  /// Secondary color - used for less prominent buttons or alternative actions
  static const Color secondary = Color(0xFFF1F5F9);
  
  /// Text/icon color that appears on top of secondary-colored backgrounds
  static const Color secondaryForeground = Color(0xFF0F172A);
  
  /// Muted/subtle background color - used for less important areas
  static const Color muted = Color(0xFFF8FAFC);
  
  /// Muted text color - used for secondary text, hints, or less important content
  static const Color mutedForeground = Color(0xFF64748B);
  
  /// Accent color - used to highlight or emphasize certain elements
  static const Color accent = Color(0xFFF1F5F9);
  
  /// Text/icon color that appears on top of accent-colored backgrounds
  static const Color accentForeground = Color(0xFF0F172A);
  
  /// Destructive/error color - used for delete buttons, error messages, warnings
  static const Color destructive = Color(0xFFEF4444);
  
  /// Text/icon color that appears on top of destructive-colored backgrounds
  static const Color destructiveForeground = Color(0xFFF8FAFC);
  
  /// Border color - used for dividers, card borders, input field borders
  static const Color border = Color(0xFFE2E8F0);
  
  /// Input field border color - specifically for text input borders
  static const Color input = Color(0xFFE2E8F0);
  
  /// Ring/focus ring color - the color that appears when an element is focused
  /// (e.g., when you tab to a text field, it shows a ring around it)
  static const Color ring = Color(0xFF0F172A);
  
  /// Main background color of the app - the "canvas" behind everything
  static const Color background = Color(0xFFFFFFFF);
  
  /// Default text color - the color used for most text in the app
  static const Color foreground = Color(0xFF0F172A);
  
  /// Card background color - used for card components
  static const Color card = Color(0xFFFFFFFF);
  
  /// Text color used inside cards
  static const Color cardForeground = Color(0xFF0F172A);
  
  /// Popover/dropdown background color - used for menus, tooltips, etc.
  static const Color popover = Color(0xFFFFFFFF);
  
  /// Text color used inside popovers
  static const Color popoverForeground = Color(0xFF0F172A);

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================
  // These colors define the appearance of the app in dark mode.
  // In dark mode, colors are typically inverted (dark backgrounds, light text).
  // Each color has the same purpose as its light theme counterpart above.
  
  /// Main brand color for dark mode
  static const Color darkPrimary = Color(0xFFF8FAFC);
  
  /// Text/icon color on primary-colored backgrounds in dark mode
  static const Color darkPrimaryForeground = Color(0xFF0F172A);
  
  /// Secondary color for dark mode
  static const Color darkSecondary = Color(0xFF1E293B);
  
  /// Text/icon color on secondary-colored backgrounds in dark mode
  static const Color darkSecondaryForeground = Color(0xFFF8FAFC);
  
  /// Muted background color for dark mode
  static const Color darkMuted = Color(0xFF1E293B);
  
  /// Muted text color for dark mode
  static const Color darkMutedForeground = Color(0xFF94A3B8);
  
  /// Accent color for dark mode
  static const Color darkAccent = Color(0xFF1E293B);
  
  /// Text/icon color on accent-colored backgrounds in dark mode
  static const Color darkAccentForeground = Color(0xFFF8FAFC);
  
  /// Destructive/error color for dark mode
  static const Color darkDestructive = Color(0xFF7F1D1D);
  
  /// Text/icon color on destructive-colored backgrounds in dark mode
  static const Color darkDestructiveForeground = Color(0xFFF8FAFC);
  
  /// Border color for dark mode
  static const Color darkBorder = Color(0xFF1E293B);
  
  /// Input field border color for dark mode
  static const Color darkInput = Color(0xFF1E293B);
  
  /// Focus ring color for dark mode
  static const Color darkRing = Color(0xFF94A3B8);
  
  /// Main background color for dark mode (dark blue/black)
  static const Color darkBackground = Color(0xFF0F172A);
  
  /// Default text color for dark mode (light/white)
  static const Color darkForeground = Color(0xFFF8FAFC);
  
  /// Card background color for dark mode
  static const Color darkCard = Color(0xFF0F172A);
  
  /// Text color used inside cards in dark mode
  static const Color darkCardForeground = Color(0xFFF8FAFC);
  
  /// Popover background color for dark mode
  static const Color darkPopover = Color(0xFF0F172A);
  
  /// Text color used inside popovers in dark mode
  static const Color darkPopoverForeground = Color(0xFFF8FAFC);

  // ============================================================================
  // SPACING SYSTEM
  // ============================================================================
  // These values define consistent spacing throughout the app.
  // Use them for padding, margins, and gaps between elements.
  // Inspired by Tailwind CSS spacing scale (4px base unit).
  // Example: Use space4 for padding, space2 for small gaps, etc.
  
  /// Smallest spacing unit (4 pixels) - used for tiny gaps
  static const double space1 = 4.0;
  
  /// Small spacing (8 pixels) - used for small gaps, thin padding
  static const double space2 = 8.0;
  
  /// Medium-small spacing (12 pixels) - used for compact spacing
  static const double space3 = 12.0;
  
  /// Standard spacing (16 pixels) - most commonly used for padding/margins
  static const double space4 = 16.0;
  
  /// Medium spacing (20 pixels) - slightly larger than standard
  static const double space5 = 20.0;
  
  /// Medium-large spacing (24 pixels) - used for section spacing
  static const double space6 = 24.0;
  
  /// Large spacing (32 pixels) - used for larger gaps between sections
  static const double space8 = 32.0;
  
  /// Extra large spacing (40 pixels) - used for major section separation
  static const double space10 = 40.0;
  
  /// Very large spacing (48 pixels) - used for significant gaps
  static const double space12 = 48.0;
  
  /// Extra extra large spacing (64 pixels) - used for major page sections
  static const double space16 = 64.0;
  
  /// Huge spacing (80 pixels) - used for very large separations
  static const double space20 = 80.0;
  
  /// Maximum spacing (96 pixels) - used for extreme separations
  static const double space24 = 96.0;
  
  /// Ultra spacing (128 pixels) - rarely used, maximum separation
  static const double space32 = 128.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  // These values define how rounded corners are on various UI elements.
  // Higher values = more rounded. Use these for consistent rounded corners
  // on buttons, cards, input fields, etc.
  
  /// No border radius - completely square corners
  static const double radiusNone = 0.0;
  
  /// Small border radius (2 pixels) - very subtle rounding
  static const double radiusSm = 2.0;
  
  /// Default border radius (4 pixels) - standard rounded corners
  static const double radius = 4.0;
  
  /// Medium border radius (6 pixels) - moderately rounded
  static const double radiusMd = 6.0;
  
  /// Large border radius (8 pixels) - noticeably rounded
  static const double radiusLg = 8.0;
  
  /// Extra large border radius (12 pixels) - very rounded
  static const double radiusXl = 12.0;
  
  /// 2X large border radius (16 pixels) - extremely rounded
  static const double radius2xl = 16.0;
  
  /// 3X large border radius (24 pixels) - maximum rounding
  static const double radius3xl = 24.0;
  
  /// Full border radius (9999 pixels) - creates a perfect circle/pill shape
  /// Used for fully rounded buttons or circular elements
  static const double radiusFull = 9999.0;

  // ============================================================================
  // FONT SIZES
  // ============================================================================
  // These values define text sizes throughout the app.
  // Use them with Text widgets to ensure consistent typography.
  // Example: Text('Hello', style: TextStyle(fontSize: ShadCNTheme.textBase))
  
  /// Extra small text (12 pixels) - used for captions, fine print
  static const double textXs = 12.0;
  
  /// Small text (14 pixels) - used for secondary text, labels
  static const double textSm = 14.0;
  
  /// Base/default text size (16 pixels) - standard body text
  static const double textBase = 16.0;
  
  /// Large text (18 pixels) - used for emphasized body text
  static const double textLg = 18.0;
  
  /// Extra large text (20 pixels) - used for small headings
  static const double textXl = 20.0;
  
  /// 2X large text (24 pixels) - used for section headings
  static const double text2xl = 24.0;
  
  /// 3X large text (30 pixels) - used for page titles
  static const double text3xl = 30.0;
  
  /// 4X large text (36 pixels) - used for major headings
  static const double text4xl = 36.0;
  
  /// 5X large text (48 pixels) - used for hero text
  static const double text5xl = 48.0;
  
  /// 6X large text (60 pixels) - used for very large displays
  static const double text6xl = 60.0;
  
  /// 7X large text (72 pixels) - used for huge displays
  static const double text7xl = 72.0;
  
  /// 8X large text (96 pixels) - used for maximum display size
  static const double text8xl = 96.0;
  
  /// 9X large text (128 pixels) - rarely used, maximum display size
  static const double text9xl = 128.0;

  // ============================================================================
  // FONT WEIGHTS
  // ============================================================================
  // These values control how bold or thin text appears.
  // Lower numbers = thinner text, higher numbers = bolder text.
  // Use with TextStyle: TextStyle(fontWeight: ShadCNTheme.fontBold)
  
  /// Thin font weight (100) - very light, thin text
  static const FontWeight fontThin = FontWeight.w100;
  
  /// Extra light font weight (200) - very light text
  static const FontWeight fontExtralight = FontWeight.w200;
  
  /// Light font weight (300) - light text
  static const FontWeight fontLight = FontWeight.w300;
  
  /// Normal/regular font weight (400) - standard text weight (most common)
  static const FontWeight fontNormal = FontWeight.w400;
  
  /// Medium font weight (500) - slightly bold text
  static const FontWeight fontMedium = FontWeight.w500;
  
  /// Semi-bold font weight (600) - moderately bold text
  static const FontWeight fontSemibold = FontWeight.w600;
  
  /// Bold font weight (700) - bold text (most common for emphasis)
  static const FontWeight fontBold = FontWeight.w700;
  
  /// Extra bold font weight (800) - very bold text
  static const FontWeight fontExtrabold = FontWeight.w800;
  
  /// Black font weight (900) - maximum boldness, heaviest text
  static const FontWeight fontBlack = FontWeight.w900;

  // ============================================================================
  // LINE HEIGHTS
  // ============================================================================
  // These values control the vertical spacing between lines of text.
  // Higher values = more space between lines (better readability).
  // Use with TextStyle: TextStyle(height: ShadCNTheme.leadingNormal)
  // Fixed pixel values (leading3-leading10) set exact line height.
  // Multiplier values (leadingNone-leadingLoose) are relative to font size.
  
  /// Fixed line height: 12 pixels
  static const double leading3 = 12.0;
  
  /// Fixed line height: 16 pixels
  static const double leading4 = 16.0;
  
  /// Fixed line height: 20 pixels
  static const double leading5 = 20.0;
  
  /// Fixed line height: 24 pixels
  static const double leading6 = 24.0;
  
  /// Fixed line height: 28 pixels
  static const double leading7 = 28.0;
  
  /// Fixed line height: 32 pixels
  static const double leading8 = 32.0;
  
  /// Fixed line height: 36 pixels
  static const double leading9 = 36.0;
  
  /// Fixed line height: 40 pixels
  static const double leading10 = 40.0;
  
  /// Relative line height: 1.0x font size - no extra space (tightest)
  static const double leadingNone = 1.0;
  
  /// Relative line height: 1.25x font size - tight spacing
  static const double leadingTight = 1.25;
  
  /// Relative line height: 1.375x font size - snug spacing
  static const double leadingSnug = 1.375;
  
  /// Relative line height: 1.5x font size - normal spacing (most common)
  static const double leadingNormal = 1.5;
  
  /// Relative line height: 1.625x font size - relaxed spacing
  static const double leadingRelaxed = 1.625;
  
  /// Relative line height: 2.0x font size - loose spacing (most space)
  static const double leadingLoose = 2.0;

  // ============================================================================
  // SHADOWS
  // ============================================================================
  // These shadow definitions create depth and elevation effects.
  // Shadows make elements appear to "float" above the background.
  // Use them with Container's boxShadow property: Container(boxShadow: ShadCNTheme.shadowMd)
  // Higher shadow values = more elevation (element appears further from background).
  // Each shadow has:
  //   - color: The shadow color (with alpha/transparency)
  //   - blurRadius: How soft/blurry the shadow is (higher = softer)
  //   - offset: Where the shadow appears (x, y position)
  
  /// Small shadow - subtle elevation, used for slightly raised elements
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F000000), // Black with very low opacity (6% transparency)
      blurRadius: 1,              // Very sharp shadow
      offset: Offset(0, 1),       // Shadow appears 1 pixel below element
    ),
  ];

  /// Default shadow - standard elevation, used for most elevated elements
  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Color(0x0A000000), // Black with low opacity (4% transparency)
      blurRadius: 1,              // Sharp shadow
      offset: Offset(0, 1),       // Shadow appears 1 pixel below
    ),
    BoxShadow(
      color: Color(0x0A000000), // Second shadow layer for depth
      blurRadius: 2,              // Slightly blurred
      offset: Offset(0, 0),       // No offset (creates subtle glow effect)
    ),
  ];

  /// Medium shadow - moderate elevation, used for cards and panels
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0A000000), // Black with low opacity
      blurRadius: 4,              // More blur for softer shadow
      offset: Offset(0, 2),       // Shadow appears 2 pixels below
    ),
    BoxShadow(
      color: Color(0x0A000000), // Second layer
      blurRadius: 3,              // Additional blur
      offset: Offset(0, 1),       // Slightly offset
    ),
  ];

  /// Large shadow - significant elevation, used for modals and dialogs
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x0A000000), // Black with low opacity
      blurRadius: 10,             // Very blurry, soft shadow
      offset: Offset(0, 4),       // Shadow appears 4 pixels below
    ),
    BoxShadow(
      color: Color(0x0A000000), // Second layer
      blurRadius: 3,              // Additional blur
      offset: Offset(0, 1),       // Slight offset
    ),
  ];

  /// Extra large shadow - very high elevation, used for floating panels
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x0A000000), // Black with low opacity
      blurRadius: 20,             // Extremely blurry shadow
      offset: Offset(0, 10),      // Shadow appears 10 pixels below
    ),
    BoxShadow(
      color: Color(0x0A000000), // Second layer
      blurRadius: 3,              // Additional blur
      offset: Offset(0, 1),       // Slight offset
    ),
  ];

  /// 2X large shadow - maximum elevation, used for important overlays
  static const List<BoxShadow> shadow2xl = [
    BoxShadow(
      color: Color(0x0A000000), // Black with low opacity
      blurRadius: 25,             // Maximum blur
      offset: Offset(0, 25),      // Shadow appears 25 pixels below
    ),
  ];

  // ============================================================================
  // LIGHT THEME CONFIGURATION
  // ============================================================================
  /// Returns a complete Material 3 theme configuration for light mode.
  /// 
  /// This theme applies all the design tokens (colors, spacing, typography, etc.)
  /// to create a cohesive light theme for the entire app.
  /// 
  /// Usage in MaterialApp:
  /// ```dart
  /// MaterialApp(
  ///   theme: ShadCNTheme.lightTheme,
  ///   // ... rest of app
  /// )
  /// ```
  static ThemeData get lightTheme {
    return ThemeData(
      // Enable Material 3 design system (latest Material Design)
      useMaterial3: true,
      
      // Set theme to light mode
      brightness: Brightness.light,
      
      // ========================================================================
      // COLOR SCHEME
      // ========================================================================
      // Defines the main colors used throughout the app.
      // "on" colors are used for text/icons that appear ON TOP of the base color.
      // Example: onPrimary is the text color used on primary-colored buttons.
      colorScheme: const ColorScheme.light(
        primary: primary,                    // Main brand color
        onPrimary: primaryForeground,        // Text/icon color on primary backgrounds
        secondary: secondary,                // Secondary/accent color
        onSecondary: secondaryForeground,    // Text/icon color on secondary backgrounds
        surface: background,                 // Surface color (cards, sheets)
        onSurface: foreground,               // Text color on surfaces
        background: background,              // App background color
        onBackground: foreground,            // Text color on background
        error: destructive,                 // Error/destructive action color
        onError: destructiveForeground,      // Text color on error backgrounds
        outline: border,                    // Border/outline color
      ),
      
      // ========================================================================
      // TYPOGRAPHY (TEXT STYLES)
      // ========================================================================
      // Defines text styles for different text roles in the app.
      // Uses Google Fonts Inter font family for modern, clean typography.
      // Each style has a specific purpose (display = large headings,
      // headline = section titles, body = regular text, label = UI labels).
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: text4xl,
          fontWeight: fontBold,
          color: foreground,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: text3xl,
          fontWeight: fontBold,
          color: foreground,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: text2xl,
          fontWeight: fontBold,
          color: foreground,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: text2xl,
          fontWeight: fontSemibold,
          color: foreground,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: textXl,
          fontWeight: fontSemibold,
          color: foreground,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: textLg,
          fontWeight: fontSemibold,
          color: foreground,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: textLg,
          fontWeight: fontMedium,
          color: foreground,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: textBase,
          fontWeight: fontMedium,
          color: foreground,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: textSm,
          fontWeight: fontMedium,
          color: foreground,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: textBase,
          fontWeight: fontNormal,
          color: foreground,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: textSm,
          fontWeight: fontNormal,
          color: foreground,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: textXs,
          fontWeight: fontNormal,
          color: mutedForeground,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: textSm,
          fontWeight: fontMedium,
          color: foreground,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: textXs,
          fontWeight: fontMedium,
          color: foreground,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: textXs,
          fontWeight: fontMedium,
          color: mutedForeground,
        ),
      ),
      
      // ========================================================================
      // BUTTON THEMES
      // ========================================================================
      // Defines the appearance of different button types throughout the app.
      // Three button types: Elevated (filled), Outlined (bordered), Text (minimal).
      
      // Elevated Button Theme - Filled buttons with solid background
      // Used for primary actions (e.g., "Submit", "Save", "Continue")
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,              // Button background color
          foregroundColor: primaryForeground,   // Text/icon color on button
          elevation: 0,                          // No shadow (flat design)
          shadowColor: Colors.transparent,       // No shadow color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius), // Rounded corners
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,  // 16px horizontal padding
            vertical: space2,    // 8px vertical padding
          ),
        ),
      ),
      
      // Outlined Button Theme - Buttons with border, no fill
      // Used for secondary actions (e.g., "Cancel", "Back")
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,              // Text/icon color
          side: const BorderSide(color: border), // Border color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius), // Rounded corners
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,  // 16px horizontal padding
            vertical: space2,    // 8px vertical padding
          ),
        ),
      ),
      
      // Text Button Theme - Minimal buttons with no border or background
      // Used for tertiary actions or links (e.g., "Learn more", "Skip")
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,              // Text/icon color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius), // Rounded corners
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,  // 16px horizontal padding
            vertical: space2,    // 8px vertical padding
          ),
        ),
      ),
      
      // ========================================================================
      // INPUT FIELD THEME
      // ========================================================================
      // Defines the appearance of text input fields (TextField, TextFormField).
      // Controls borders, padding, colors for different states (normal, focused, error).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,                            // Fill background with color
        fillColor: background,                    // Background color of input
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius), // Rounded corners
          borderSide: const BorderSide(color: input), // Default border color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: input), // Border when not focused
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: ring, width: 2), // Thicker border when focused
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: destructive), // Red border on error
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: destructive, width: 2), // Thicker red border
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space3,  // 12px horizontal padding inside input
          vertical: space2,   // 8px vertical padding inside input
        ),
      ),
      
      // ========================================================================
      // CARD THEME
      // ========================================================================
      // Defines the appearance of Card widgets throughout the app.
      // Cards are used to display grouped content in containers.
      cardTheme: CardThemeData(
        color: card,                             // Card background color
        elevation: 0,                            // No shadow (flat design)
        shadowColor: Colors.transparent,         // No shadow color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg), // More rounded corners (8px)
          side: const BorderSide(color: border), // Border around card
        ),
      ),
      
      // ========================================================================
      // APP BAR THEME
      // ========================================================================
      // Defines the appearance of the AppBar (top navigation bar) throughout the app.
      appBarTheme: AppBarTheme(
        backgroundColor: background,              // AppBar background color
        foregroundColor: foreground,             // Text/icon color in AppBar
        elevation: 0,                            // No shadow (flat design)
        shadowColor: Colors.transparent,         // No shadow color
        surfaceTintColor: Colors.transparent,    // No tint color (Material 3)
        titleTextStyle: GoogleFonts.inter(
          fontSize: textLg,                      // 18px font size
          fontWeight: fontSemibold,              // Semi-bold weight
          color: foreground,                      // Text color
        ),
      ),
    );
  }

  // ============================================================================
  // DARK THEME CONFIGURATION
  // ============================================================================
  /// Returns a complete Material 3 theme configuration for dark mode.
  /// 
  /// This theme applies all the design tokens (colors, spacing, typography, etc.)
  /// to create a cohesive dark theme for the entire app.
  /// Dark mode uses darker backgrounds and lighter text for better night viewing.
  /// 
  /// Usage in MaterialApp:
  /// ```dart
  /// MaterialApp(
  ///   darkTheme: ShadCNTheme.darkTheme,
  ///   themeMode: ThemeMode.dark, // or ThemeMode.system
  ///   // ... rest of app
  /// )
  /// ```
  static ThemeData get darkTheme {
    return ThemeData(
      // Enable Material 3 design system (latest Material Design)
      useMaterial3: true,
      
      // Set theme to dark mode
      brightness: Brightness.dark,
      
      // ========================================================================
      // COLOR SCHEME
      // ========================================================================
      // Defines the main colors used throughout the app in dark mode.
      // Dark mode uses darker backgrounds and lighter text for better contrast.
      // "on" colors are used for text/icons that appear ON TOP of the base color.
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,                    // Main brand color (light in dark mode)
        onPrimary: darkPrimaryForeground,        // Text/icon color on primary backgrounds
        secondary: darkSecondary,                // Secondary/accent color (darker)
        onSecondary: darkSecondaryForeground,    // Text/icon color on secondary backgrounds
        surface: darkBackground,                 // Surface color (dark)
        onSurface: darkForeground,               // Text color on surfaces (light)
        background: darkBackground,              // App background color (dark)
        onBackground: darkForeground,            // Text color on background (light)
        error: darkDestructive,                 // Error/destructive action color
        onError: darkDestructiveForeground,      // Text color on error backgrounds
        outline: darkBorder,                    // Border/outline color (darker)
      ),
      
      // ========================================================================
      // TYPOGRAPHY (TEXT STYLES)
      // ========================================================================
      // Defines text styles for different text roles in dark mode.
      // Uses Google Fonts Inter font family for modern, clean typography.
      // Text colors are lighter in dark mode for better contrast against dark backgrounds.
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: text4xl,
          fontWeight: fontBold,
          color: darkForeground,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: text3xl,
          fontWeight: fontBold,
          color: darkForeground,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: text2xl,
          fontWeight: fontBold,
          color: darkForeground,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: text2xl,
          fontWeight: fontSemibold,
          color: darkForeground,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: textXl,
          fontWeight: fontSemibold,
          color: darkForeground,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: textLg,
          fontWeight: fontSemibold,
          color: darkForeground,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: textLg,
          fontWeight: fontMedium,
          color: darkForeground,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: textBase,
          fontWeight: fontMedium,
          color: darkForeground,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: textSm,
          fontWeight: fontMedium,
          color: darkForeground,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: textBase,
          fontWeight: fontNormal,
          color: darkForeground,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: textSm,
          fontWeight: fontNormal,
          color: darkForeground,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: textXs,
          fontWeight: fontNormal,
          color: darkMutedForeground,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: textSm,
          fontWeight: fontMedium,
          color: darkForeground,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: textXs,
          fontWeight: fontMedium,
          color: darkForeground,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: textXs,
          fontWeight: fontMedium,
          color: darkMutedForeground,
        ),
      ),
      
      // ========================================================================
      // BUTTON THEMES
      // ========================================================================
      // Defines the appearance of different button types in dark mode.
      // Same structure as light theme, but uses dark mode colors.
      
      // Elevated Button Theme - Filled buttons with solid background
      // Used for primary actions (e.g., "Submit", "Save", "Continue")
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,              // Button background (light in dark mode)
          foregroundColor: darkPrimaryForeground,   // Text/icon color (dark in dark mode)
          elevation: 0,                              // No shadow (flat design)
          shadowColor: Colors.transparent,           // No shadow color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius), // Rounded corners
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,  // 16px horizontal padding
            vertical: space2,    // 8px vertical padding
          ),
        ),
      ),
      
      // Outlined Button Theme - Buttons with border, no fill
      // Used for secondary actions (e.g., "Cancel", "Back")
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,              // Text/icon color (light)
          side: const BorderSide(color: darkBorder), // Border color (dark)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius), // Rounded corners
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,  // 16px horizontal padding
            vertical: space2,   // 8px vertical padding
          ),
        ),
      ),
      
      // Text Button Theme - Minimal buttons with no border or background
      // Used for tertiary actions or links (e.g., "Learn more", "Skip")
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,              // Text/icon color (light)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius), // Rounded corners
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,  // 16px horizontal padding
            vertical: space2,   // 8px vertical padding
          ),
        ),
      ),
      
      // ========================================================================
      // INPUT FIELD THEME
      // ========================================================================
      // Defines the appearance of text input fields in dark mode.
      // Controls borders, padding, colors for different states (normal, focused, error).
      // Uses darker backgrounds and borders for dark mode.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,                                // Fill background with color
        fillColor: darkBackground,                   // Dark background color of input
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius), // Rounded corners
          borderSide: const BorderSide(color: darkInput), // Dark border color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkInput), // Dark border when not focused
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkRing, width: 2), // Light ring when focused
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkDestructive), // Dark red border on error
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkDestructive, width: 2), // Thicker error border
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space3,  // 12px horizontal padding inside input
          vertical: space2,    // 8px vertical padding inside input
        ),
      ),
      
      // ========================================================================
      // CARD THEME
      // ========================================================================
      // Defines the appearance of Card widgets in dark mode.
      // Cards use dark backgrounds with light borders for contrast.
      cardTheme: CardThemeData(
        color: darkCard,                             // Dark card background color
        elevation: 0,                                // No shadow (flat design)
        shadowColor: Colors.transparent,             // No shadow color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg), // More rounded corners (8px)
          side: const BorderSide(color: darkBorder),     // Dark border around card
        ),
      ),
      
      // ========================================================================
      // APP BAR THEME
      // ========================================================================
      // Defines the appearance of the AppBar (top navigation bar) in dark mode.
      // Uses dark background with light text for better contrast.
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,              // Dark AppBar background color
        foregroundColor: darkForeground,             // Light text/icon color in AppBar
        elevation: 0,                                // No shadow (flat design)
        shadowColor: Colors.transparent,             // No shadow color
        surfaceTintColor: Colors.transparent,        // No tint color (Material 3)
        titleTextStyle: GoogleFonts.inter(
          fontSize: textLg,                          // 18px font size
          fontWeight: fontSemibold,                  // Semi-bold weight
          color: darkForeground,                     // Light text color
        ),
      ),
    );
  }
}
