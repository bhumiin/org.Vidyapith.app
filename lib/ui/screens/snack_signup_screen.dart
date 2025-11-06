import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/branded_app_bar.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../theme/shadcn_theme.dart';

/// Snack Signup Screen - This screen helps parents sign up to provide snacks for Vidyapith events.
/// 
/// What this screen does:
/// - Shows a button to open the snack signup calendar (Google Calendar appointment scheduler)
/// - Displays instructions on how to sign up for snacks
/// - Lists all the approved snack items organized by groups (Group 1, Group 2, Group 3)
/// - Provides contact information for snack coordinators who can answer questions
/// - Reminds users to check their spam folder for reminder notifications
/// - Emphasizes that all snacks must be nut-free
/// 
/// How users interact with it:
/// - Tap the "Snack Signup" button to open the Google Calendar scheduling page
/// - Tap email buttons to open their email app to contact coordinators
/// - Tap phone buttons to call coordinators directly
/// - Scroll down to see all the snack groups and contact information
class SnackSignupScreen extends StatefulWidget {
  const SnackSignupScreen({super.key});

  @override
  State<SnackSignupScreen> createState() => _SnackSignupScreenState();
}

/// Internal state class that manages the snack signup screen's behavior and display.
class _SnackSignupScreenState extends State<SnackSignupScreen> {
  /// The web address (URL) that opens the Google Calendar appointment scheduler.
  /// When users tap the "Snack Signup" button, this opens the calendar where they can
  /// choose a date and time slot to sign up for providing snacks.
  static const String _snackSignupUrl =
      'https://calendar.google.com/calendar/appointments/schedules/AcZssZ0giqp7l4h3UOoIwKEYNVlFWHenOlRFGadfv_D6K0iIADBdqW8UKSc8hWqKB5ZgGi3cqsx54vnb';

  /// Builds and displays the entire snack signup screen.
  /// This method creates the visual layout including the header, button, and all content sections.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: buildBrandedAppBar(title: const Text('Snack Signup')),
      backgroundColor: isDark
          ? const Color(0xFF101922)
          : const Color(0xFFF5F7F8),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(ShadCNTheme.space4),
          child: _buildBody(context, isDark),
        ),
      ),
    );
  }

  /// Builds the main content area of the screen.
  /// Arranges the signup button and all instructional content vertically.
  Widget _buildBody(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Snack Signup Button - The main action button that opens the calendar scheduler
        _buildSignupButton(context, isDark),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Static Text Content - All the instructions, snack lists, and contact info
        _buildContent(isDark),
      ],
    );
  }

  /// Creates the main "Snack Signup" button that opens the Google Calendar scheduler.
  /// When tapped, this button opens the external calendar page where users can select
  /// a date and time to sign up for providing snacks.
  Widget _buildSignupButton(BuildContext context, bool isDark) {
    return ShadButton(
      text: 'Snack Signup',
      fullWidth: true,
      onPressed: _openSnackSignupUrl,
      icon: const Icon(Icons.calendar_today, size: 18),
    );
  }

  /// Opens the Google Calendar snack signup page in the user's web browser.
  /// This method is called when the user taps the "Snack Signup" button.
  /// If the page cannot be opened (no internet connection, browser unavailable, etc.),
  /// it shows an error message to the user.
  Future<void> _openSnackSignupUrl() async {
    final uri = Uri.parse(_snackSignupUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showLaunchError();
      }
    } catch (_) {
      if (mounted) {
        _showLaunchError();
      }
    }
  }

  /// Shows an error message if the snack signup calendar page cannot be opened.
  /// This displays a temporary message at the bottom of the screen telling the user
  /// that the link couldn't be opened, usually due to network issues or browser problems.
  void _showLaunchError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open link. Please try again later.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Builds all the instructional content on the screen.
  /// This includes:
  /// - Introduction text about checking spam folder for notifications
  /// - Instructions on when and where to bring snacks
  /// - Important reminder that all snacks must be nut-free
  /// - List of approved snack items organized by groups
  /// - Contact information for snack coordinators
  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Introduction - Reminds users to check spam folder for reminder emails
        _buildSection(
          isDark,
          'Thank you for showing interest in signing up. Please check your SPAM folder for reminder notifications.',
        ),
        const SizedBox(height: ShadCNTheme.space4),
        
        // Instructions - Tells users when (before 8:30 AM) and where (Vidyapith Kitchen) to bring snacks
        _buildSection(
          isDark,
          'Bring Snacks before 8:30 AM and leave them in Vidyapith Kitchen.',
        ),
        const SizedBox(height: ShadCNTheme.space4),
        
        // Nut Free Note - Important safety reminder that all snacks must be nut-free
        _buildSection(
          isDark,
          'Note: Please Ensure All Items Are Nut Free. Please Confirm Before Purchasing.',
          isBold: true,
        ),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Registered Snack List Header - Title for the list of approved snack items
        _buildSection(
          isDark,
          'Registered Snack List for the Sunday Sign-UP',
          isBold: true,
          fontSize: 18,
        ),
        const SizedBox(height: ShadCNTheme.space2),
        // Explanation that coordinators will call a week before to specify which items to buy
        _buildSection(
          isDark,
          'List of allowed Items: We will call you a week before your due date on the items you need to purchase.',
        ),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Group 1 - First category of approved snacks (cookies, cupcakes, brownies)
        _buildGroupHeader(isDark, 'Group 1'),
        const SizedBox(height: ShadCNTheme.space2),
        _buildNumberedItem(isDark, 1, 'Chips Ahoy - 1 lb x 15 boxes (family size) (550 pieces)'),
        _buildNumberedItem(isDark, 2, 'Oreo Cookies - 4 Costco boxes (3 LB 14.76 Oz each box) (550 pieces)'),
        _buildNumberedItem(isDark, 3, 'Vanilla Cup Cakes – No Frosting – 276 pieces - Shoprite'),
        _buildNumberedItem(isDark, 4, 'Gourmet Chocolate Chunk Cookie - 12 Costco boxes (36 Oz/24 count per box)'),
        _buildNumberedItem(isDark, 5, 'Brownies - Shoprite - 1-1/2 inch x 1-1/2 inch - 3 Trays (275 pieces) - No Frosting or Sprinkles'),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Group 2 - Second category of approved snacks (crackers and savory items)
        _buildGroupHeader(isDark, 'Group 2'),
        const SizedBox(height: ShadCNTheme.space2),
        _buildNumberedItem(isDark, 1, 'Cheeze-IT - 3 boxes Costco (48 Oz each box)'),
        _buildNumberedItem(isDark, 2, 'Gold Fish - 2 boxes Costco (66 Oz each box)'),
        _buildNumberedItem(isDark, 3, 'RITZ Crackers - 3 boxes Costco (61.65 Oz each box)'),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Group 3 - Third category of approved snacks (milk, napkins, and cups)
        _buildGroupHeader(isDark, 'Group 3'),
        const SizedBox(height: ShadCNTheme.space2),
        _buildNumberedItem(isDark, 1, '2% Milk - 5 Gallons'),
        _buildNumberedItem(isDark, 2, 'Napkins - 300 counts'),
        _buildNumberedItem(isDark, 3, 'Cups 7 oz. - 300 counts (Shoprite PaperBird)'),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Proceed Instructions - Tells users how to complete the signup process on the calendar page
        _buildSection(
          isDark,
          'To Proceed: Please select the date and one of the timings available - 8:00 am or 8:15 am and enter the requested details.',
          isBold: true,
        ),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Contact Information - Header for the snack coordinator contact cards
        _buildSection(
          isDark,
          'For questions, reach out to',
          isBold: true,
        ),
        const SizedBox(height: ShadCNTheme.space4),
        _buildContactCard(
          isDark,
          'Nixita Trivedi',
          'nixitaaunty@vidyapith.org',
          '201-485-9007',
        ),
        const SizedBox(height: ShadCNTheme.space3),
        _buildContactCard(
          isDark,
          'Priya Prasad',
          'priya.prasad@vidyapith.org',
          '201-962-5096',
        ),
        const SizedBox(height: ShadCNTheme.space3),
        _buildContactCard(
          isDark,
          'Rushika Patel',
          'rushika.patel@vidyapith.org',
          '908-227-4818',
        ),
        const SizedBox(height: ShadCNTheme.space3),
        _buildContactCard(
          isDark,
          'Ranjana Patel',
          'ranjana.patel@vidyapith.org',
          '973-931-7078',
        ),
        const SizedBox(height: ShadCNTheme.space4),
        _buildSection(
          isDark,
          'Snack Coordinator will be calling you week in advance',
          isBold: true,
        ),
      ],
    );
  }

  /// Creates a text section with consistent styling.
  /// This is used throughout the screen to display instructions, notes, and other text content.
  /// Parameters:
  /// - isDark: Whether the app is in dark mode (affects text color)
  /// - text: The text content to display
  /// - isBold: Whether to make the text bold (default: false)
  /// - fontSize: The size of the text (default: 16)
  Widget _buildSection(
    bool isDark,
    String text, {
    bool isBold = false,
    double fontSize = 16,
  }) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF424242),
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Creates a header for a snack group (Group 1, Group 2, or Group 3).
  /// This displays the group name in blue, bold text to visually separate different snack categories.
  Widget _buildGroupHeader(bool isDark, String title) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? const Color(0xFF0B73DA) : const Color(0xFF0B73DA),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Creates a numbered list item for snack options.
  /// Each approved snack item is displayed with its number (1, 2, 3, etc.) and detailed description
  /// including brand, quantity, and where to purchase (e.g., "Costco", "Shoprite").
  Widget _buildNumberedItem(bool isDark, int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: ShadCNTheme.space4,
        top: ShadCNTheme.space1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF424242),
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF424242),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a contact card for a snack coordinator.
  /// Each card displays:
  /// - The coordinator's name with a person icon
  /// - An email button that opens the user's email app to send an email
  /// - A phone button that opens the phone dialer to make a call
  /// Users can tap these buttons to easily contact coordinators with questions about snacks.
  Widget _buildContactCard(
    bool isDark,
    String name,
    String email,
    String phone,
  ) {
    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF0B73DA),
                size: 20,
              ),
              const SizedBox(width: ShadCNTheme.space2),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF424242),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ShadCNTheme.space3),
          // Email Button
          ShadButton(
            text: email,
            fullWidth: true,
            variant: ShadButtonVariant.outline,
            icon: const Icon(Icons.email_outlined, size: 18),
            onPressed: () => _launchEmail(email),
          ),
          const SizedBox(height: ShadCNTheme.space2),
          // Phone Button
          ShadButton(
            text: phone,
            fullWidth: true,
            variant: ShadButtonVariant.outline,
            icon: const Icon(Icons.phone_outlined, size: 18),
            onPressed: () => _launchPhone(phone),
          ),
        ],
      ),
    );
  }

  /// Opens the user's email app with a new message addressed to the specified email.
  /// This is called when the user taps an email button on a contact card.
  /// If the email app cannot be opened, it shows an error message.
  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showError('Unable to open email client.');
      }
    } catch (_) {
      if (mounted) {
        _showError('Unable to open email client.');
      }
    }
  }

  /// Opens the user's phone dialer with the specified phone number pre-filled.
  /// This is called when the user taps a phone button on a contact card.
  /// The phone number is cleaned (removes spaces, dashes, etc.) before opening the dialer.
  /// If the dialer cannot be opened, it shows an error message.
  Future<void> _launchPhone(String phone) async {
    // Remove any non-digit characters except + (so "201-485-9007" becomes "2014859007")
    final cleanedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanedPhone);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showError('Unable to open phone dialer.');
      }
    } catch (_) {
      if (mounted) {
        _showError('Unable to open phone dialer.');
      }
    }
  }

  /// Displays a temporary error message at the bottom of the screen.
  /// Used when email or phone actions fail (e.g., no email app installed, dialer unavailable).
  /// The message appears briefly and then disappears automatically.
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

