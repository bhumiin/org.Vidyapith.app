import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ShadCN-inspired theme system for Flutter
class ShadCNTheme {
  // Color palette inspired by ShadCN
  static const Color primary = Color(0xFF0F172A);
  static const Color primaryForeground = Color(0xFFF8FAFC);
  static const Color secondary = Color(0xFFF1F5F9);
  static const Color secondaryForeground = Color(0xFF0F172A);
  static const Color muted = Color(0xFFF8FAFC);
  static const Color mutedForeground = Color(0xFF64748B);
  static const Color accent = Color(0xFFF1F5F9);
  static const Color accentForeground = Color(0xFF0F172A);
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color input = Color(0xFFE2E8F0);
  static const Color ring = Color(0xFF0F172A);
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0F172A);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF0F172A);
  static const Color popover = Color(0xFFFFFFFF);
  static const Color popoverForeground = Color(0xFF0F172A);

  // Dark theme colors
  static const Color darkPrimary = Color(0xFFF8FAFC);
  static const Color darkPrimaryForeground = Color(0xFF0F172A);
  static const Color darkSecondary = Color(0xFF1E293B);
  static const Color darkSecondaryForeground = Color(0xFFF8FAFC);
  static const Color darkMuted = Color(0xFF1E293B);
  static const Color darkMutedForeground = Color(0xFF94A3B8);
  static const Color darkAccent = Color(0xFF1E293B);
  static const Color darkAccentForeground = Color(0xFFF8FAFC);
  static const Color darkDestructive = Color(0xFF7F1D1D);
  static const Color darkDestructiveForeground = Color(0xFFF8FAFC);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkInput = Color(0xFF1E293B);
  static const Color darkRing = Color(0xFF94A3B8);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkForeground = Color(0xFFF8FAFC);
  static const Color darkCard = Color(0xFF0F172A);
  static const Color darkCardForeground = Color(0xFFF8FAFC);
  static const Color darkPopover = Color(0xFF0F172A);
  static const Color darkPopoverForeground = Color(0xFFF8FAFC);

  // Spacing system (inspired by Tailwind CSS)
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;
  static const double space20 = 80.0;
  static const double space24 = 96.0;
  static const double space32 = 128.0;

  // Border radius
  static const double radiusNone = 0.0;
  static const double radiusSm = 2.0;
  static const double radius = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 12.0;
  static const double radius2xl = 16.0;
  static const double radius3xl = 24.0;
  static const double radiusFull = 9999.0;

  // Font sizes
  static const double textXs = 12.0;
  static const double textSm = 14.0;
  static const double textBase = 16.0;
  static const double textLg = 18.0;
  static const double textXl = 20.0;
  static const double text2xl = 24.0;
  static const double text3xl = 30.0;
  static const double text4xl = 36.0;
  static const double text5xl = 48.0;
  static const double text6xl = 60.0;
  static const double text7xl = 72.0;
  static const double text8xl = 96.0;
  static const double text9xl = 128.0;

  // Font weights
  static const FontWeight fontThin = FontWeight.w100;
  static const FontWeight fontExtralight = FontWeight.w200;
  static const FontWeight fontLight = FontWeight.w300;
  static const FontWeight fontNormal = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemibold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;
  static const FontWeight fontExtrabold = FontWeight.w800;
  static const FontWeight fontBlack = FontWeight.w900;

  // Line heights
  static const double leading3 = 12.0;
  static const double leading4 = 16.0;
  static const double leading5 = 20.0;
  static const double leading6 = 24.0;
  static const double leading7 = 28.0;
  static const double leading8 = 32.0;
  static const double leading9 = 36.0;
  static const double leading10 = 40.0;
  static const double leadingNone = 1.0;
  static const double leadingTight = 1.25;
  static const double leadingSnug = 1.375;
  static const double leadingNormal = 1.5;
  static const double leadingRelaxed = 1.625;
  static const double leadingLoose = 2.0;

  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadow2xl = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 25,
      offset: Offset(0, 25),
    ),
  ];

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        surface: background,
        onSurface: foreground,
        background: background,
        onBackground: foreground,
        error: destructive,
        onError: destructiveForeground,
        outline: border,
      ),
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: destructive, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space3,
          vertical: space2,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: textLg,
          fontWeight: fontSemibold,
          color: foreground,
        ),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: darkPrimaryForeground,
        secondary: darkSecondary,
        onSecondary: darkSecondaryForeground,
        surface: darkBackground,
        onSurface: darkForeground,
        background: darkBackground,
        onBackground: darkForeground,
        error: darkDestructive,
        onError: darkDestructiveForeground,
        outline: darkBorder,
      ),
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkPrimaryForeground,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkRing, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkDestructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: darkDestructive, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space3,
          vertical: space2,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkForeground,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: textLg,
          fontWeight: fontSemibold,
          color: darkForeground,
        ),
      ),
    );
  }
}
