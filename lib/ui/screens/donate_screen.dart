import 'package:flutter/material.dart';
import '../components/branded_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../theme/shadcn_theme.dart';

/// Donate Screen - This screen provides all donation options and methods for supporting Vidyapith.
/// 
/// What this screen does:
/// - Displays an introduction explaining how donations support Vidyapith
/// - Shows multiple donation methods:
///   - Zelle Transfer: With email address and QR code for easy scanning
///   - Mail a Check: With mailing address displayed
///   - PayPal Giving Fund: With link to donate online (no fees deducted)
///   - Credit Card: With link to donate online (fees deducted)
///   - Matching Grants: With link to matching donation form
/// - Fetches all donation information from the Vidyapith website automatically
/// 
/// How users interact with it:
/// - Scroll through all donation options
/// - Tap "Copy" button to copy Zelle email address to clipboard
/// - Scan QR code for Zelle donations (if available)
/// - Tap "Open Link" buttons to open donation pages in a browser
/// - Pull down to refresh and get the latest donation information
class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  late final WebsiteScraper _scraper;
  DonateContent? _content;
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
      final DonateContent content = await _scraper.getDonateContent(
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
          _errorMessage = 'Unable to load donation details.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: buildBrandedAppBar(title: const Text('Donate')),
      backgroundColor: isDark
          ? const Color(0xFF101922)
          : const Color(0xFFF5F7F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadContent(forceRefresh: true),
          color: const Color(0xFF0B73DA),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(ShadCNTheme.space4),
            child: _buildBody(context),
          ),
        ),
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
            Text(_errorMessage!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: ShadCNTheme.space4),
            ShadButton(
              text: 'Try Again',
              onPressed: () => _loadContent(forceRefresh: true),
            ),
          ],
        ),
      );
    }

    final DonateContent? content = _content;
    if (content == null) {
      return ShadCard(
        child: Text(
          'Donation information is currently unavailable. Please pull to refresh.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final List<Widget> sections = [
      if (content.introParagraphs.isNotEmpty)
        _buildIntroSection(context, content),
      if (content.zelleInstruction != null || content.zelleEmail != null)
        _buildZelleSection(context, content),
      if (content.checkInstruction != null ||
          content.checkMailingAddress.isNotEmpty)
        _buildCheckSection(context, content),
      if (content.paypalGivingInstruction != null ||
          content.paypalGivingUrl != null)
        _buildOnlineMethodCard(
          context,
          title: 'PayPal Giving Fund',
          instruction: content.paypalGivingInstruction,
          note: content.paypalGivingNote,
          url: content.paypalGivingUrl,
          icon: Icons.volunteer_activism,
        ),
      if (content.creditCardInstruction != null ||
          content.creditCardUrl != null)
        _buildOnlineMethodCard(
          context,
          title: 'Credit Card',
          instruction: content.creditCardInstruction,
          note: content.creditCardNote,
          url: content.creditCardUrl,
          icon: Icons.credit_card,
        ),
      if (content.matchingGrantInstruction != null ||
          content.matchingFormUrl != null)
        _buildOnlineMethodCard(
          context,
          title: 'Matching Grants',
          instruction: content.matchingGrantInstruction,
          url: content.matchingFormUrl,
          icon: Icons.handshake,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          sections[i],
          if (i != sections.length - 1)
            const SizedBox(height: ShadCNTheme.space4),
        ],
      ],
    );
  }

  Widget _buildIntroSection(BuildContext context, DonateContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Vivekananda Vidyapith',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: ShadCNTheme.fontBold,
              color: isDark
                  ? ShadCNTheme.darkCardForeground
                  : ShadCNTheme.cardForeground,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space3),
          for (int i = 0; i < content.introParagraphs.length; i++) ...[
            Text(
              content.introParagraphs[i],
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark
                    ? ShadCNTheme.darkMutedForeground
                    : ShadCNTheme.mutedForeground,
              ),
            ),
            if (i != content.introParagraphs.length - 1)
              const SizedBox(height: ShadCNTheme.space2),
          ],
        ],
      ),
    );
  }

  /// Builds the Zelle transfer donation section.
  /// Shows:
  /// - Instructions for using Zelle
  /// - The Zelle email address in a copyable box with a "Copy" button
  /// - A QR code image (if available) that users can scan with their phone's Zelle app
  Widget _buildZelleSection(BuildContext context, DonateContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String? email = content.zelleEmail;

    String? sanitizedInstruction = content.zelleInstruction;
    if (sanitizedInstruction != null) {
      sanitizedInstruction = sanitizedInstruction.replaceAll(
        RegExp(r'[^@\s]+@[^@\s]+\.[^@\s]+'),
        'below email',
      );
      sanitizedInstruction = sanitizedInstruction.replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      sanitizedInstruction = sanitizedInstruction.trim();
    }

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
                  Icons.account_balance,
                  color: isDark
                      ? ShadCNTheme.darkCardForeground
                      : const Color(0xFF0B73DA),
                ),
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Text(
                  'Zelle Transfer',
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
          if (sanitizedInstruction != null) ...[
            const SizedBox(height: ShadCNTheme.space3),
            Text(
              sanitizedInstruction!,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark
                    ? ShadCNTheme.darkMutedForeground
                    : ShadCNTheme.mutedForeground,
              ),
            ),
          ],
          if (email != null) ...[
            const SizedBox(height: ShadCNTheme.space3),
            Container(
              padding: const EdgeInsets.all(ShadCNTheme.space3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: isDark
                        ? ShadCNTheme.darkMutedForeground
                        : const Color(0xFF0B73DA),
                  ),
                  const SizedBox(width: ShadCNTheme.space3),
                  Flexible(
                    child: SelectableText(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: ShadCNTheme.fontSemibold,
                        color: isDark
                            ? ShadCNTheme.darkCardForeground
                            : ShadCNTheme.cardForeground,
                      ),
                    ),
                  ),
                  const SizedBox(width: ShadCNTheme.space3),
                  ShadButton(
                    text: 'Copy',
                    size: ShadButtonSize.sm,
                    variant: ShadButtonVariant.secondary,
                    icon: Icon(
                      Icons.copy,
                      size: theme.textTheme.bodyMedium?.fontSize ?? 16,
                    ),
                    onPressed: () => _copyToClipboard(email),
                  ),
                ],
              ),
            ),
          ],
          if (content.zelleQrImageUrl != null) ...[
            const SizedBox(height: ShadCNTheme.space4),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  content.zelleQrImageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      color: isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFE8F1FF),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
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
              ),
            ),
            const SizedBox(height: ShadCNTheme.space2),
            Text(
              'Simply scan the QR code below.',
              style: theme.textTheme.bodySmall?.copyWith(
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

  /// Builds the check donation section.
  /// Shows:
  /// - Instructions for mailing a check
  /// - The mailing address in a formatted box (Vidyapith name and address)
  Widget _buildCheckSection(BuildContext context, DonateContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final List<String> addressLines = content.checkMailingAddress;
    final bool hasNameLine =
        addressLines.isNotEmpty &&
        addressLines.first.toLowerCase().contains('vivekananda vidyapith');
    final List<String> remainingAddressLines = hasNameLine
        ? addressLines.skip(1).toList()
        : addressLines;

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
                  Icons.local_post_office_outlined,
                  color: isDark
                      ? ShadCNTheme.darkCardForeground
                      : const Color(0xFF0B73DA),
                ),
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Text(
                  'Mail a Check',
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
          if (content.checkInstruction != null) ...[
            const SizedBox(height: ShadCNTheme.space3),
            Text(
              (() {
                String text = content.checkInstruction!;
                text = text.replaceAll(
                  RegExp(r'vivekananda\s+vidyapith', caseSensitive: false),
                  '',
                );
                text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
                return text;
              })(),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark
                    ? ShadCNTheme.darkMutedForeground
                    : ShadCNTheme.mutedForeground,
              ),
            ),
          ],
          if (content.checkMailingAddress.isNotEmpty) ...[
            const SizedBox(height: ShadCNTheme.space3),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(ShadCNTheme.space3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Vivekananda Vidyapith',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: ShadCNTheme.fontSemibold,
                        color: isDark
                            ? ShadCNTheme.darkCardForeground
                            : ShadCNTheme.cardForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (remainingAddressLines.isNotEmpty)
                      const SizedBox(height: ShadCNTheme.space1),
                    for (int i = 0; i < remainingAddressLines.length; i++) ...[
                      Text(
                        remainingAddressLines[i],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? ShadCNTheme.darkCardForeground
                              : ShadCNTheme.cardForeground,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (i != remainingAddressLines.length - 1)
                        const SizedBox(height: ShadCNTheme.space1),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a card for online donation methods (PayPal, Credit Card, Matching Grants).
  /// Each method shows:
  /// - An icon and title
  /// - Instructions on how to donate
  /// - Optional notes or warnings
  /// - A button to open the donation link in a browser
  Widget _buildOnlineMethodCard(
    BuildContext context, {
    required String title,
    String? instruction,
    String? note,
    String? url,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isPayPal = title == 'PayPal Giving Fund';
    final bool isCreditCard = title == 'Credit Card';
    final bool isMatchingGrants = title == 'Matching Grants';

    String? displayInstruction = instruction;
    String? trailingInstruction;

    // Override body text per request
    if (isPayPal) {
      displayInstruction =
          'To donate ONLINE by PAYPAL GIVING FUND CLICK HERE. Please note: Vidyapith receives the full amount of Paypal Giving Fund donations - no fees are deducted.';
      trailingInstruction = null;
      note = null;
    } else if (isCreditCard) {
      displayInstruction =
          'To donate by CREDIT CARD, you can do so HERE. Please note: credit card fees are deducted from such  donations, decreasing the amount received  by  Vidyapith.';
      trailingInstruction = null;
      note = null;
    } else if (isMatchingGrants) {
      displayInstruction =
          'If your company provides MATCHING GRANTS for employee donations and you would like to secure a matching gift for Vidyapith, please fill out this Matching Donation Form.';
      trailingInstruction = null;
      note = null;
    }

    final List<Widget> bodyChildren = [];

    if (displayInstruction != null) {
      bodyChildren.add(const SizedBox(height: ShadCNTheme.space3));
      bodyChildren.add(
        Text(
          displayInstruction,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: isDark
                ? ShadCNTheme.darkMutedForeground
                : ShadCNTheme.mutedForeground,
          ),
        ),
      );
    }

    if (note != null) {
      bodyChildren.add(const SizedBox(height: ShadCNTheme.space2));
      bodyChildren.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ShadCNTheme.space3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? ShadCNTheme.darkMutedForeground
                  : ShadCNTheme.mutedForeground,
            ),
          ),
        ),
      );
    }

    if (trailingInstruction != null && trailingInstruction.isNotEmpty) {
      bodyChildren.add(const SizedBox(height: ShadCNTheme.space2));
      bodyChildren.add(
        Text(
          trailingInstruction,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: isDark
                ? ShadCNTheme.darkMutedForeground
                : ShadCNTheme.mutedForeground,
          ),
        ),
      );
    }

    if (url != null) {
      bodyChildren.add(const SizedBox(height: ShadCNTheme.space4));
      bodyChildren.add(
        Align(
          alignment: Alignment.center,
          child: ShadButton(
            text: 'Open Link',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _launchExternalUrl(url),
          ),
        ),
      );
    }

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
                  icon,
                  color: isDark
                      ? ShadCNTheme.darkCardForeground
                      : const Color(0xFF0B73DA),
                ),
              ),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Text(
                  title,
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
          ...bodyChildren,
        ],
      ),
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        _showLaunchError();
      }
      return;
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!launched) {
        _showLaunchError();
      }
    } catch (_) {
      if (!mounted) return;
      _showLaunchError();
    }
  }

  void _showLaunchError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open link. Please try again later.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Copies the Zelle email address to the user's clipboard.
  /// This is called when the user taps the "Copy" button next to the email address.
  /// Shows a confirmation message that the email was copied.
  Future<void> _copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
