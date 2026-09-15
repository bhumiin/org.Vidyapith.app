import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/branded_app_bar.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../components/copyright_widget.dart';
import '../theme/shadcn_theme.dart';

/// Archive Screen - Displays scraped entries from the Vidyapith Archives page.
///
/// What this screen does:
/// - Shows a short intro paragraph from archives.html
/// - Lists archive titles as tappable cards in a 2-column grid
/// - Opens each archive page in the system browser when tapped
///
/// How users interact with it:
/// - Read the intro at the top
/// - Tap any title card to open that archive in an external browser
/// - Pull down to refresh and reload the latest archives list
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  late final WebsiteScraper _scraper;
  ArchivesContent? _content;
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

  /// Loads archives content from cache or the live website.
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
      final content = await _scraper.getArchivesContent(
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
          _errorMessage = 'Unable to load archives.';
        }
      });
    }
  }

  /// Opens [url] in the system browser, or shows an error snackbar.
  Future<void> _openInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showLaunchError();
      return;
    }

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open this archive link.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBrandedAppBar(title: const Text('Archive')),
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

    final ArchivesContent? content = _content;
    if (content == null || content.items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadCard(
            child: Text(
              'Archives are currently unavailable. Please pull to refresh.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space4),
          CopyrightWidget(),
        ],
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.intro.isNotEmpty) ...[
          Text(
            content.intro,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: isDark
                  ? ShadCNTheme.darkCardForeground
                  : ShadCNTheme.cardForeground,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space4),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: ShadCNTheme.space3,
            mainAxisSpacing: ShadCNTheme.space3,
            childAspectRatio: 1.6,
          ),
          itemCount: content.items.length,
          itemBuilder: (context, index) {
            final item = content.items[index];
            return _buildArchiveCard(context, isDark, item);
          },
        ),
        const SizedBox(height: ShadCNTheme.space4),
        CopyrightWidget(),
      ],
    );
  }

  /// Builds a single archive title card that opens [item.url] in the browser.
  Widget _buildArchiveCard(
    BuildContext context,
    bool isDark,
    ArchiveItem item,
  ) {
    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space3),
      onTap: () => _openInBrowser(item.url),
      child: Center(
        child: Text(
          item.title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: ShadCNTheme.fontSemibold,
                color: isDark
                    ? ShadCNTheme.darkCardForeground
                    : const Color(0xFF0B73DA),
              ),
        ),
      ),
    );
  }
}
