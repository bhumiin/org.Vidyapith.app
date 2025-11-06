import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../theme/shadcn_theme.dart';
import 'admissions_screen.dart';
import '../components/logo_leading.dart';

/// Contact Screen - This screen provides all contact information and ways to reach Vidyapith.
/// 
/// What this screen does:
/// - Displays a hero image of Vidyapith at the top
/// - Shows quick contact options (phone and map buttons)
/// - Provides instructions for reporting absences or tardiness
/// - Links to the admissions page
/// - Shows class registration forms (Monday Scriptural Class, Tabla Class)
/// - Displays email contacts (Registration Email, Alumni Email)
/// - Shows the mailing address
/// - Displays any general notices or announcements
/// - Fetches all contact information from the Vidyapith website automatically
/// 
/// How users interact with it:
/// - Tap phone button to call Vidyapith office
/// - Tap "View on Map" to open the address in Google Maps
/// - Tap email buttons to open email app with pre-filled recipient
/// - Tap form buttons to open registration forms in a browser
/// - Tap "View Admissions" to navigate to the admissions screen
/// - Pull down to refresh and get the latest contact information
class ContactScreen extends StatefulWidget {
  /// Allows other parts of the app to request that this screen scroll to the top.
  /// Used when the user switches to the Contact tab.
  final ValueNotifier<bool>? scrollNotifier;

  const ContactScreen({super.key, this.scrollNotifier});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

/// Internal state class that manages the contact screen's behavior and display.
class _ContactScreenState extends State<ContactScreen> {
  /// Service that fetches contact information from the Vidyapith website.
  /// It scrapes the website to get phone numbers, addresses, emails, form URLs, etc.
  late final WebsiteScraper _scraper;
  
  /// Controller that manages scrolling on the page.
  /// Allows the screen to programmatically scroll when needed.
  final ScrollController _scrollController = ScrollController();
  
  /// The contact information that was fetched from the website.
  /// This is null until content is loaded.
  ContactContent? _content;
  
  /// Tracks whether we're currently loading contact information from the website.
  /// Shows a loading spinner while true.
  bool _isLoading = true;
  
  /// Stores any error message if loading contact information fails.
  /// Displayed to the user if something goes wrong (network error, etc.).
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scraper = WebsiteScraper();
    _loadContent();
    widget.scrollNotifier?.addListener(_onScrollRequested);
  }

  @override
  void dispose() {
    widget.scrollNotifier?.removeListener(_onScrollRequested);
    _scrollController.dispose();
    _scraper.dispose();
    super.dispose();
  }

  void _onScrollRequested() {
    scrollToTop();
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadContent({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (forceRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (_content == null) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final content = await _scraper.getContactContent(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _content = content;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_content == null) {
          _errorMessage = 'Unable to load contact information.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101922)
          : const Color(0xFFF5F7F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadContent(forceRefresh: true),
          color: const Color(0xFF0B73DA),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isDark),
                Padding(
                  padding: const EdgeInsets.all(ShadCNTheme.space4),
                  child: _buildBody(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadCNTheme.space4,
        vertical: ShadCNTheme.space2,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : const Color(0xFFF5F7F8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const LogoLeading(showBackButton: false),
          const SizedBox(width: ShadCNTheme.space2),
          Expanded(
            child: Center(
              child: Text(
                'Contact Us',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF424242),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.015,
                ),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _content == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _content == null) {
      return ShadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ShadCNTheme.space3),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: ShadCNTheme.space4),
            ShadButton(
              text: 'Try Again',
              onPressed: () => _loadContent(forceRefresh: true),
            ),
          ],
        ),
      );
    }

    final ContactContent? content = _content;
    if (content == null) {
      return ShadCard(
        child: Text(
          'Contact information is currently unavailable. Please pull to refresh.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final List<Widget> cards = [];

    // Hero Image at the top
    cards.add(_buildHeroImage(context));

    // Quick Contact Card (Phone + Map)
    if (content.phone != null || content.addressLines.isNotEmpty) {
      cards.add(const SizedBox(height: ShadCNTheme.space3));
      cards.add(_buildQuickContactCard(context, content));
    }

    // Absence/Tardy Card
    cards.add(const SizedBox(height: ShadCNTheme.space3));
    cards.add(_buildAbsenceTardyCard(context, content));

    // Admissions Card
    if (content.admissionsUrl != null) {
      cards.add(const SizedBox(height: ShadCNTheme.space3));
      cards.add(_buildAdmissionsCard(context));
    }

    // Forms Card
    if (content.mondayScripturalClassFormUrl != null ||
        content.tablaClassFormUrl != null) {
      cards.add(const SizedBox(height: ShadCNTheme.space3));
      cards.add(_buildFormsCard(context, content));
    }

    // Emails Card
    if (content.registrationEmail != null || content.alumniEmail != null) {
      cards.add(const SizedBox(height: ShadCNTheme.space3));
      cards.add(_buildEmailsCard(context, content));
    }

    // Address Card
    if (content.addressLines.isNotEmpty) {
      cards.add(const SizedBox(height: ShadCNTheme.space3));
      cards.add(_buildAddressCard(context, content.addressLines));
    }

    // Notice Card
    if (content.generalNotice != null) {
      cards.add(const SizedBox(height: ShadCNTheme.space3));
      cards.add(_buildNoticeCard(context, content));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cards,
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const String heroImageUrl =
        'https://www.vidyapith.org/uploads/5/2/1/3/52135817/published/3318585.jpg?1612541087';

    return ClipRRect(
      borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
      child: Image.network(
        heroImageUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            height: 200,
            color: isDark
                ? const Color(0xFF1F2937)
                : const Color(0xFFE8F1FF),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: isDark
                ? const Color(0xFF1F2937)
                : const Color(0xFFE8F1FF),
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: theme.textTheme.bodySmall?.color,
            ),
          );
        },
      ),
    );
  }

  /// Builds the quick contact card with phone and map buttons.
  /// This card appears at the top and provides the fastest way to call or find Vidyapith.
  Widget _buildQuickContactCard(
      BuildContext context, ContactContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x2E0B73DA)
                      : const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(ShadCNTheme.space3),
                child: Icon(
                  Icons.contact_phone_outlined,
                  color: isDark
                      ? ShadCNTheme.darkCardForeground
                      : const Color(0xFF0B73DA),
                ),
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Text(
                  'Quick Contact',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: ShadCNTheme.fontSemibold,
                    color: isDark
                        ? ShadCNTheme.darkCardForeground
                        : ShadCNTheme.cardForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ShadCNTheme.space3),
          if (content.phone != null) ...[
            ShadButton(
              text: 'Call ${content.phone}',
              fullWidth: true,
              icon: const Icon(Icons.phone),
              onPressed: () => _launchPhone(content.phone!),
            ),
            const SizedBox(height: ShadCNTheme.space2),
          ],
          if (content.addressLines.isNotEmpty) ...[
            ShadButton(
              text: 'View on Map',
              fullWidth: true,
              variant: ShadButtonVariant.outline,
              icon: const Icon(Icons.map_outlined),
              onPressed: () => _launchMap(content.addressLines),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the absence/tardy reporting card.
  /// Shows instructions on how to report when a child will be absent or late.
  /// Parents must call the office AND email the homeroom teacher by 8:30am.
  Widget _buildAbsenceTardyCard(
      BuildContext context, ContactContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x2E0B73DA)
                      : const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(ShadCNTheme.space3),
                child: Icon(
                  Icons.notification_important_outlined,
                  color: isDark
                      ? ShadCNTheme.darkCardForeground
                      : const Color(0xFF0B73DA),
                ),
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Text(
                  'Absence or Tardy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: ShadCNTheme.fontSemibold,
                    color: isDark
                        ? ShadCNTheme.darkCardForeground
                        : ShadCNTheme.cardForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ShadCNTheme.space3),
          Text(
            'To report an Absence or Tardy:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: ShadCNTheme.fontSemibold,
              color: isDark
                  ? ShadCNTheme.darkCardForeground
                  : ShadCNTheme.cardForeground,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.phone_outlined,
                size: 18,
                color: isDark
                    ? ShadCNTheme.darkMutedForeground
                    : ShadCNTheme.mutedForeground,
              ),
              const SizedBox(width: ShadCNTheme.space2),
              Expanded(
                child: Text(
                  'Call Vidyapith\'s Office at 973-628-1877 by 8:30am AND',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: isDark
                        ? ShadCNTheme.darkMutedForeground
                        : ShadCNTheme.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ShadCNTheme.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.email_outlined,
                size: 18,
                color: isDark
                    ? ShadCNTheme.darkMutedForeground
                    : ShadCNTheme.mutedForeground,
              ),
              const SizedBox(width: ShadCNTheme.space2),
              Expanded(
                child: Text(
                  'Email your child\'s homeroom teacher as early as possible, latest by 8:30am',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: isDark
                        ? ShadCNTheme.darkMutedForeground
                        : ShadCNTheme.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the admissions card with a button to navigate to the admissions screen.
  /// Provides information about admissions inquiries and links to the admissions page.
  Widget _buildAdmissionsCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x2E0B73DA)
                      : const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(ShadCNTheme.space3),
                child: Icon(
                  Icons.school_outlined,
                  color: isDark
                      ? ShadCNTheme.darkCardForeground
                      : const Color(0xFF0B73DA),
                ),
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Text(
                  'Admissions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: ShadCNTheme.fontSemibold,
                    color: isDark
                        ? ShadCNTheme.darkCardForeground
                        : ShadCNTheme.cardForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ShadCNTheme.space3),
          Text(
            'For admissions inquiries, please visit our Admissions page.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: isDark
                  ? ShadCNTheme.darkMutedForeground
                  : ShadCNTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space3),
          ShadButton(
            text: 'View Admissions',
            fullWidth: true,
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _navigateToAdmissions(context),
          ),
        ],
      ),
    );
  }

  /// Builds the class forms card with buttons to open registration forms.
  /// Shows buttons for Monday Scriptural Class Form and Tabla Class Form if available.
  /// Each button opens the form in an external browser.
  Widget _buildFormsCard(BuildContext context, ContactContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x2E0B73DA)
                      : const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(ShadCNTheme.space3),
                child: Icon(
                  Icons.assignment_outlined,
                  color: isDark
                      ? ShadCNTheme.darkCardForeground
                      : const Color(0xFF0B73DA),
                ),
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Text(
                  'Class Forms',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: ShadCNTheme.fontSemibold,
                    color: isDark
                        ? ShadCNTheme.darkCardForeground
                        : ShadCNTheme.cardForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ShadCNTheme.space3),
          if (content.mondayScripturalClassFormUrl != null) ...[
            ShadButton(
              text: 'Monday Scriptural Class Form',
              fullWidth: true,
              icon: const Icon(Icons.open_in_new),
              onPressed: () =>
                  _launchUrl(content.mondayScripturalClassFormUrl!),
            ),
            const SizedBox(height: ShadCNTheme.space2),
          ],
          if (content.tablaClassFormUrl != null) ...[
            ShadButton(
              text: 'Tabla Class Form',
              fullWidth: true,
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _launchUrl(content.tablaClassFormUrl!),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the email contacts card with buttons to open email app.
  /// Shows buttons for Registration Email and Alumni Email if available.
  /// Each button opens the user's email app with the address pre-filled.
  Widget _buildEmailsCard(BuildContext context, ContactContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x2E0B73DA)
                      : const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(ShadCNTheme.space3),
                child: Icon(
                  Icons.email_outlined,
                  color: isDark
                      ? ShadCNTheme.darkCardForeground
                      : const Color(0xFF0B73DA),
                ),
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Text(
                  'Email Contacts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: ShadCNTheme.fontSemibold,
                    color: isDark
                        ? ShadCNTheme.darkCardForeground
                        : ShadCNTheme.cardForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ShadCNTheme.space3),
          if (content.registrationEmail != null) ...[
            ShadButton(
              text: 'Registration Email',
              fullWidth: true,
              icon: const Icon(Icons.email),
              onPressed: () => _launchEmail(content.registrationEmail!),
            ),
            const SizedBox(height: ShadCNTheme.space2),
          ],
          if (content.alumniEmail != null) ...[
            ShadButton(
              text: 'Alumni Email',
              fullWidth: true,
              icon: const Icon(Icons.email),
              onPressed: () => _launchEmail(content.alumniEmail!),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the mailing address card.
  /// Displays the complete Vidyapith mailing address with a location icon.
  Widget _buildAddressCard(BuildContext context, List<String> addressLines) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mailing Address',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: ShadCNTheme.fontBold,
              color: isDark
                  ? ShadCNTheme.darkCardForeground
                  : ShadCNTheme.cardForeground,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.place_outlined,
                size: 20,
                color: isDark
                    ? ShadCNTheme.darkMutedForeground
                    : ShadCNTheme.mutedForeground,
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < addressLines.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == addressLines.length - 1
                              ? 0
                              : ShadCNTheme.space1,
                        ),
                        child: Text(
                          addressLines[i],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? ShadCNTheme.darkCardForeground
                                : ShadCNTheme.cardForeground,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the general notice card.
  /// Displays any important announcements or notices from Vidyapith.
  Widget _buildNoticeCard(BuildContext context, ContactContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x2E0B73DA)
                      : const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(ShadCNTheme.space3),
                child: Icon(
                  Icons.info_outlined,
                  color: isDark
                      ? ShadCNTheme.darkCardForeground
                      : const Color(0xFF0B73DA),
                ),
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Text(
                  'Notice',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: ShadCNTheme.fontSemibold,
                    color: isDark
                        ? ShadCNTheme.darkCardForeground
                        : ShadCNTheme.cardForeground,
                  ),
                ),
              ),
            ],
          ),
          if (content.generalNotice != null) ...[
            const SizedBox(height: ShadCNTheme.space3),
            Text(
              content.generalNotice!,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark
                    ? ShadCNTheme.darkMutedForeground
                    : ShadCNTheme.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Opens the user's phone dialer with the Vidyapith phone number pre-filled.
  /// This is called when the user taps the phone button in the quick contact card.
  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showLaunchError('Unable to open phone dialer.');
      }
    } catch (_) {
      if (mounted) {
        _showLaunchError('Unable to open phone dialer.');
      }
    }
  }

  /// Opens Google Maps with the Vidyapith address pre-filled.
  /// This is called when the user taps the "View on Map" button.
  /// The address is formatted and opened in the user's default map app.
  Future<void> _launchMap(List<String> addressLines) async {
    final address = addressLines.join(', ');
    final uri = Uri(
      scheme: 'https',
      host: 'maps.google.com',
      queryParameters: {'q': address},
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showLaunchError('Unable to open map.');
      }
    } catch (_) {
      if (mounted) {
        _showLaunchError('Unable to open map.');
      }
    }
  }

  /// Opens the user's email app with a new message addressed to the specified email.
  /// This is called when the user taps an email button (Registration Email, Alumni Email, etc.).
  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showLaunchError('Unable to open email client.');
      }
    } catch (_) {
      if (mounted) {
        _showLaunchError('Unable to open email client.');
      }
    }
  }

  /// Opens a URL in the user's external browser.
  /// This is used for registration forms and other external links.
  /// If the URL is invalid or cannot be opened, shows an error message.
  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (mounted) {
        _showLaunchError('Invalid URL.');
      }
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showLaunchError('Unable to open link.');
      }
    } catch (_) {
      if (mounted) {
        _showLaunchError('Unable to open link.');
      }
    }
  }

  /// Navigates to the Admissions screen when the user taps "View Admissions".
  /// Opens a new screen showing detailed admissions information and forms.
  void _navigateToAdmissions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdmissionsScreen(),
      ),
    );
  }

  /// Displays a temporary error message at the bottom of the screen.
  /// Used when phone, email, map, or URL actions fail (e.g., no app installed).
  /// The message appears briefly and then disappears automatically.
  void _showLaunchError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

