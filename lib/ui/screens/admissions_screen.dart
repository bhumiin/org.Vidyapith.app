import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../theme/shadcn_theme.dart';
import '../components/branded_app_bar.dart';
import '../components/copyright_widget.dart';

/// Admissions Screen - Displays admissions information scraped from the website.
///
/// What this screen does:
/// - Mirrors the website layout: I. / II. / III. each on its own line
/// - Preserves bold and underline emphasis from the site (without maroon color)
/// - Shows optional inquiry form buttons when URLs are available
/// - Shows the contact address for admissions inquiries
/// - Fetches admissions information from the Vidyapith website automatically
///
/// How users interact with it:
/// - Scroll through the admissions notice and address
/// - Tap form buttons (when present) to open registration forms in a browser
/// - Pull down to refresh and get the latest admissions information
class AdmissionsScreen extends StatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  State<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends State<AdmissionsScreen> {
  late final WebsiteScraper _scraper;
  AdmissionsContent? _content;
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
      final content = await _scraper.getAdmissionsContent(
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
          _errorMessage = 'Unable to load admissions information.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBrandedAppBar(title: const Text('Admissions')),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadCard(
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
          ),
        ],
      );
    }

    final AdmissionsContent? content = _content;
    if (content == null || (!content.hasBody && content.addressLines.isEmpty)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadCard(
            child: Text(
              'Admissions information is currently unavailable. Please pull to refresh.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.hasBody) ...[
          _buildBodyCard(context, content),
          const SizedBox(height: ShadCNTheme.space3),
        ],
        if (content.addressLines.isNotEmpty) ...[
          _buildAddressCard(context, content.addressLines),
        ],
        const SizedBox(height: ShadCNTheme.space4),
        CopyrightWidget(),
      ],
    );
  }

  /// Builds a single card mirroring the website admissions notice.
  ///
  /// Keeps I. / II. / III. as separate paragraphs and underlines key phrases,
  /// but uses the same bodyMedium / muted description styling as other screens.
  Widget _buildBodyCard(BuildContext context, AdmissionsContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = isDark
        ? ShadCNTheme.darkMutedForeground
        : ShadCNTheme.mutedForeground;
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.5,
      color: bodyColor,
      fontWeight: FontWeight.normal,
    );

    final children = <Widget>[];
    for (var i = 0; i < content.paragraphs.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(height: ShadCNTheme.space3));
      }
      children.add(
        Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              for (final span in content.paragraphs[i].spans)
                TextSpan(
                  text: span.text,
                  style: TextStyle(
                    decoration: span.isUnderlined
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: bodyColor,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (content.kgFormUrl != null && content.kgFormUrl!.isNotEmpty) {
      children.add(const SizedBox(height: ShadCNTheme.space4));
      children.add(
        ShadButton(
          text: '2026-27 KG INQUIRY FORM',
          fullWidth: true,
          onPressed: () => _launchUrl(context, content.kgFormUrl!),
        ),
      );
    }

    if (content.alternateRouteFormUrl != null &&
        content.alternateRouteFormUrl!.isNotEmpty) {
      children.add(const SizedBox(height: ShadCNTheme.space3));
      children.add(
        ShadButton(
          text: '2026-27 Alternate Route Inquiry Form',
          fullWidth: true,
          onPressed: () => _launchUrl(context, content.alternateRouteFormUrl!),
        ),
      );
    }

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (mounted) {
        _showLaunchError(context);
      }
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showLaunchError(context);
      }
    } catch (_) {
      if (mounted) {
        _showLaunchError(context);
      }
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open link. Please try again later.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, List<String> addressLines) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: ShadCNTheme.fontBold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final bodyColor = isDark
        ? ShadCNTheme.darkCardForeground
        : ShadCNTheme.cardForeground;

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact', style: titleStyle),
          const SizedBox(height: ShadCNTheme.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 20),
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
                            color: bodyColor,
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
}
