import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../theme/shadcn_theme.dart';
import 'admissions_screen.dart';
import '../components/logo_leading.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final WebsiteScraper _scraper;
  ContactContent? _content;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scraper = WebsiteScraper();
    _loadContent();
  }

  @override
  void dispose() {
    _scraper.dispose();
    super.dispose();
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

  void _navigateToAdmissions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdmissionsScreen(),
      ),
    );
  }

  void _showLaunchError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

