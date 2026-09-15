import 'package:flutter/material.dart';
import '../components/branded_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../theme/shadcn_theme.dart';
import '../components/copyright_widget.dart';

/// Donate Screen - donation options for supporting Vidyapith.
///
/// Methods:
/// - Zelle Transfer (email + QR)
/// - Appreciated Financial Securities (email)
/// - Matching Grants (More Info link)
/// - Recurring Monthly Donation (More Info link)
/// - PayPal Giving Fund (More Info link)
/// - Mail a Check (address)
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

  static const String _zelleCopy =
      'Donate by Zelle using the email below, or scan the QR code. '
      'Vidyapith receives the full amount — no fees are deducted.';

  static const String _securitiesCopy =
      'To donate appreciated financial securities, email Vidyapith using '
      'the address below to receive brokerage transfer information.';

  static const String _matchingCopy =
      'If your company provides matching grants for employee donations and '
      'you would like to secure a matching gift for Vidyapith, open the '
      'matching donation form below.';

  static const String _recurringCopy =
      'Make a recurring monthly donation for steady year-round support. '
      'One-time donations via credit card or Venmo are also available. '
      'Please consider covering transaction fees so Vidyapith fully '
      'benefits from your gift.';

  static const String _paypalCopy =
      'Donate by credit card via PayPal Giving Fund. Vidyapith receives '
      'the full amount — no fees are deducted.';

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
      if (content.zelleInstruction != null ||
          content.zelleEmail != null ||
          content.zelleQrImageUrl != null)
        _buildZelleSection(context, content),
      if (content.securitiesInstruction != null ||
          content.securitiesEmail != null)
        _buildSecuritiesSection(context, content),
      if (content.matchingGrantInstruction != null ||
          content.matchingFormUrl != null)
        _buildMethodCard(
          context,
          title: 'Matching Grants',
          instruction: _matchingCopy,
          url: content.matchingFormUrl,
          icon: Icons.handshake,
        ),
      if (content.recurringInstruction != null || content.recurringUrl != null)
        _buildMethodCard(
          context,
          title: 'Recurring Monthly Donation',
          instruction: _recurringCopy,
          url: content.recurringUrl,
          icon: Icons.calendar_month,
        ),
      if (content.paypalGivingInstruction != null ||
          content.paypalGivingUrl != null)
        _buildMethodCard(
          context,
          title: 'PayPal Giving Fund',
          instruction: _paypalCopy,
          url: content.paypalGivingUrl,
          icon: Icons.volunteer_activism,
        ),
      if (content.checkInstruction != null ||
          content.checkMailingAddress.isNotEmpty)
        _buildCheckSection(context, content),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          sections[i],
          if (i != sections.length - 1)
            const SizedBox(height: ShadCNTheme.space4),
        ],
        const SizedBox(height: ShadCNTheme.space4),
        CopyrightWidget(),
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

  Widget _buildMethodHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
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
    );
  }

  Widget _buildBodyText(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.5,
        color: isDark
            ? ShadCNTheme.darkMutedForeground
            : ShadCNTheme.mutedForeground,
      ),
    );
  }

  /// Dedicated email row with a Copy button.
  Widget _buildEmailCopyRow(BuildContext context, String email) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(ShadCNTheme.space3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF),
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
    );
  }

  /// Builds the Zelle transfer donation section.
  Widget _buildZelleSection(BuildContext context, DonateContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String? email = content.zelleEmail;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMethodHeader(
            context,
            title: 'Zelle Transfer',
            icon: Icons.account_balance,
          ),
          const SizedBox(height: ShadCNTheme.space3),
          _buildBodyText(context, _zelleCopy),
          if (email != null) ...[
            const SizedBox(height: ShadCNTheme.space3),
            _buildEmailCopyRow(context, email),
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

  /// Builds the appreciated financial securities section.
  Widget _buildSecuritiesSection(BuildContext context, DonateContent content) {
    final String? email = content.securitiesEmail ?? content.zelleEmail;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMethodHeader(
            context,
            title: 'Appreciated Financial Securities',
            icon: Icons.trending_up,
          ),
          const SizedBox(height: ShadCNTheme.space3),
          _buildBodyText(context, _securitiesCopy),
          if (email != null) ...[
            const SizedBox(height: ShadCNTheme.space3),
            _buildEmailCopyRow(context, email),
          ],
        ],
      ),
    );
  }

  /// Builds the check donation section.
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

    String? checkInstructionText;
    if (content.checkInstruction != null) {
      String text = content.checkInstruction!;
      text = text.replaceAll(
        RegExp(r'vivekananda\s+vidyapith', caseSensitive: false),
        '',
      );
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) {
        checkInstructionText = text;
      }
    }

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMethodHeader(
            context,
            title: 'Mail a Check',
            icon: Icons.local_post_office_outlined,
          ),
          if (checkInstructionText != null) ...[
            const SizedBox(height: ShadCNTheme.space3),
            _buildBodyText(context, checkInstructionText),
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

  /// Builds a method card with optional More Info for an outgoing URL.
  Widget _buildMethodCard(
    BuildContext context, {
    required String title,
    required String instruction,
    String? url,
    required IconData icon,
  }) {
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMethodHeader(context, title: title, icon: icon),
          const SizedBox(height: ShadCNTheme.space3),
          _buildBodyText(context, instruction),
          if (url != null) ...[
            const SizedBox(height: ShadCNTheme.space4),
            Align(
              alignment: Alignment.center,
              child: ShadButton(
                text: 'More Info',
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _launchExternalUrl(url),
              ),
            ),
          ],
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

  /// Copies an email address to the clipboard and shows confirmation.
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
