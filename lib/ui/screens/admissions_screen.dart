import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../theme/shadcn_theme.dart';
import '../components/branded_app_bar.dart';
import '../components/copyright_widget.dart';

/// Admissions Screen - This screen displays all admissions information and forms for Vidyapith.
/// 
/// What this screen does:
/// - Shows information about new admissions
/// - Displays Kindergarten admissions information with a link to the KG inquiry form
/// - Shows Grades 1-5 admissions information with a link to the alternate route inquiry form
/// - Displays the admissions policy
/// - Shows the contact address for admissions inquiries
/// - Fetches all admissions information from the Vidyapith website automatically
/// 
/// How users interact with it:
/// - Scroll through all admissions sections
/// - Tap form buttons (e.g., "2026-27 KG INQUIRY FORM") to open registration forms in a browser
/// - View detailed admissions information for different grade levels
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
    if (content == null) {
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
        if (content.sectionI != null && content.sectionI!.isNotEmpty) ...[
          _buildSectionCard(context, 'New Admissions', content.sectionI!),
          const SizedBox(height: ShadCNTheme.space3),
        ],
        if (content.sectionII != null && content.sectionII!.isNotEmpty) ...[
          _buildSectionCard(
            context,
            'Kindergarten Admissions',
            content.sectionII!,
            formUrl: content.kgFormUrl,
            formButtonText: '2026-27 KG INQUIRY FORM',
          ),
          const SizedBox(height: ShadCNTheme.space3),
        ],
        if (content.sectionIII != null && content.sectionIII!.isNotEmpty) ...[
          _buildSectionCard(
            context,
            'Grades 1-5 Admissions',
            content.sectionIII!,
            formUrl: content.alternateRouteFormUrl,
            formButtonText: '2026-27 Alternate Route Inquiry Form',
          ),
          const SizedBox(height: ShadCNTheme.space3),
        ],
        if (content.sectionIV != null && content.sectionIV!.isNotEmpty) ...[
          _buildSectionCard(
            context,
            'Admissions Policy',
            content.sectionIV!,
          ),
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

  /// Builds a section card for admissions information.
  /// Displays a title, content text, and optionally a form button.
  /// Used for:
  /// - New Admissions section
  /// - Kindergarten Admissions (with KG form button)
  /// - Grades 1-5 Admissions (with alternate route form button)
  /// - Admissions Policy section
  Widget _buildSectionCard(
    BuildContext context,
    String title,
    String content, {
    String? formUrl,
    String? formButtonText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: ShadCNTheme.fontBold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.5,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: ShadCNTheme.space2),
          Text(content, style: textStyle),
          if (formUrl != null && formUrl.isNotEmpty && formButtonText != null) ...[
            const SizedBox(height: ShadCNTheme.space3),
            ShadButton(
              text: formButtonText,
              fullWidth: true,
              onPressed: () => _launchUrl(context, formUrl),
            ),
          ],
        ],
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

