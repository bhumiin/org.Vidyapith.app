import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/branded_app_bar.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../theme/shadcn_theme.dart';

/// Snack Signup Screen - displays snack signup information and link to Google Calendar
class SnackSignupScreen extends StatefulWidget {
  const SnackSignupScreen({super.key});

  @override
  State<SnackSignupScreen> createState() => _SnackSignupScreenState();
}

class _SnackSignupScreenState extends State<SnackSignupScreen> {
  static const String _snackSignupUrl =
      'https://calendar.google.com/calendar/appointments/schedules/AcZssZ0giqp7l4h3UOoIwKEYNVlFWHenOlRFGadfv_D6K0iIADBdqW8UKSc8hWqKB5ZgGi3cqsx54vnb';

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

  Widget _buildBody(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Snack Signup Button
        _buildSignupButton(context, isDark),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Static Text Content
        _buildContent(isDark),
      ],
    );
  }

  Widget _buildSignupButton(BuildContext context, bool isDark) {
    return ShadButton(
      text: 'Snack Signup',
      fullWidth: true,
      onPressed: _openSnackSignupUrl,
      icon: const Icon(Icons.calendar_today, size: 18),
    );
  }

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

  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Introduction
        _buildSection(
          isDark,
          'Thank you for showing interest in signing up. Please check your SPAM folder for reminder notifications.',
        ),
        const SizedBox(height: ShadCNTheme.space4),
        
        // Instructions
        _buildSection(
          isDark,
          'Bring Snacks before 8:30 AM and leave them in Vidyapith Kitchen.',
        ),
        const SizedBox(height: ShadCNTheme.space4),
        
        // Nut Free Note
        _buildSection(
          isDark,
          'Note: Please Ensure All Items Are Nut Free. Please Confirm Before Purchasing.',
          isBold: true,
        ),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Registered Snack List Header
        _buildSection(
          isDark,
          'Registered Snack List for the Sunday Sign-UP',
          isBold: true,
          fontSize: 18,
        ),
        const SizedBox(height: ShadCNTheme.space2),
        _buildSection(
          isDark,
          'List of allowed Items: We will call you a week before your due date on the items you need to purchase.',
        ),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Group 1
        _buildGroupHeader(isDark, 'Group 1'),
        const SizedBox(height: ShadCNTheme.space2),
        _buildNumberedItem(isDark, 1, 'Chips Ahoy - 1 lb x 15 boxes (family size) (550 pieces)'),
        _buildNumberedItem(isDark, 2, 'Oreo Cookies - 4 Costco boxes (3 LB 14.76 Oz each box) (550 pieces)'),
        _buildNumberedItem(isDark, 3, 'Vanilla Cup Cakes – No Frosting – 276 pieces - Shoprite'),
        _buildNumberedItem(isDark, 4, 'Gourmet Chocolate Chunk Cookie - 12 Costco boxes (36 Oz/24 count per box)'),
        _buildNumberedItem(isDark, 5, 'Brownies - Shoprite - 1-1/2 inch x 1-1/2 inch - 3 Trays (275 pieces) - No Frosting or Sprinkles'),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Group 2
        _buildGroupHeader(isDark, 'Group 2'),
        const SizedBox(height: ShadCNTheme.space2),
        _buildNumberedItem(isDark, 1, 'Cheeze-IT - 3 boxes Costco (48 Oz each box)'),
        _buildNumberedItem(isDark, 2, 'Gold Fish - 2 boxes Costco (66 Oz each box)'),
        _buildNumberedItem(isDark, 3, 'RITZ Crackers - 3 boxes Costco (61.65 Oz each box)'),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Group 3
        _buildGroupHeader(isDark, 'Group 3'),
        const SizedBox(height: ShadCNTheme.space2),
        _buildNumberedItem(isDark, 1, '2% Milk - 5 Gallons'),
        _buildNumberedItem(isDark, 2, 'Napkins - 300 counts'),
        _buildNumberedItem(isDark, 3, 'Cups 7 oz. - 300 counts (Shoprite PaperBird)'),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Proceed Instructions
        _buildSection(
          isDark,
          'To Proceed: Please select the date and one of the timings available - 8:00 am or 8:15 am and enter the requested details.',
          isBold: true,
        ),
        const SizedBox(height: ShadCNTheme.space6),
        
        // Contact Information
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

  Future<void> _launchPhone(String phone) async {
    // Remove any non-digit characters except +
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

