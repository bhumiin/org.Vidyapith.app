import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/branded_app_bar.dart';
import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../theme/shadcn_theme.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../components/copyright_widget.dart';

/// Dynamic Link Detail Screen - Shows details and links from a dynamically detected homepage link.
/// 
/// This screen displays:
/// - The page title/heading
/// - Main content text from the linked page
/// - All clickable links found on the page as buttons
/// 
/// Users can tap the link buttons to open them in an external browser or navigate
/// to in-app screens if they are internal links.
class DynamicLinkDetailScreen extends StatefulWidget {
  /// The dynamic link that was detected from the homepage.
  final DynamicLink dynamicLink;

  const DynamicLinkDetailScreen({
    super.key,
    required this.dynamicLink,
  });

  @override
  State<DynamicLinkDetailScreen> createState() =>
      _DynamicLinkDetailScreenState();
}

class _DynamicLinkDetailScreenState extends State<DynamicLinkDetailScreen> {
  late final WebsiteScraper _scraper;
  Future<List<Map<String, String>>>? _linksFuture;
  bool _isLoading = true;
  String? _errorMessage;
  String? _pageTitle;
  String? _pageContent;

  @override
  void initState() {
    super.initState();
    _scraper = WebsiteScraper();
    _loadPageContent();
  }

  @override
  void dispose() {
    _scraper.dispose();
    super.dispose();
  }

  /// Loads the page content and extracts links.
  Future<void> _loadPageContent() async {
    try {
      // Fetch links from the page
      _linksFuture = _scraper.fetchPageLinks(widget.dynamicLink.url);

      // Also try to fetch and parse the page content for display
      try {
        final content = await _scraper.fetchPageContent(widget.dynamicLink.url);
        _pageTitle = content['title'];
        _pageContent = content['content'];
      } catch (_) {
        // If content extraction fails, that's okay - we'll still show links
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load page content. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: buildBrandedAppBar(
        title: Text(
          widget.dynamicLink.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(isDark)
          : _errorMessage != null
              ? _buildErrorState(theme, isDark)
              : _buildContent(theme, isDark),
    );
  }

  /// Shows loading state while fetching page content.
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA),
          ),
          const SizedBox(height: ShadCNTheme.space4),
          Text(
            'Loading content...',
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows error state if content loading fails.
  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ShadCNTheme.space4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark
                  ? const Color(0xFFEF9A9A)
                  : const Color(0xFFB91C1C),
            ),
            const SizedBox(height: ShadCNTheme.space4),
            Text(
              _errorMessage ?? 'Unable to load content',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ShadCNTheme.space4),
            ShadButton(
              text: 'Retry',
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadPageContent();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main content view with page content and links.
  Widget _buildContent(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title if available - centered
          if (_pageTitle != null && _pageTitle!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: ShadCNTheme.space4),
              child: Center(
                child: Text(
                  _pageTitle!,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF424242),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.015,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],

          // Page content if available
          if (_pageContent != null && _pageContent!.isNotEmpty) ...[
            ShadCard(
              padding: const EdgeInsets.all(ShadCNTheme.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Split content by double newlines to create paragraphs
                  ..._pageContent!
                      .split(RegExp(r'\n\n+'))
                      .where((paragraph) => paragraph.trim().isNotEmpty)
                      .map((paragraph) {
                    final trimmed = paragraph.trim();
                    // Check if it's a bullet point
                    final isBullet = trimmed.startsWith('•');
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: trimmed == _pageContent!.split(RegExp(r'\n\n+')).last.trim()
                            ? 0
                            : ShadCNTheme.space3,
                      ),
                      child: Text(
                        trimmed,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFF424242),
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: isBullet ? FontWeight.normal : FontWeight.normal,
                        ),
                        textAlign: isBullet ? TextAlign.left : TextAlign.justify,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: ShadCNTheme.space5),
          ],

          // Links section
          if (_linksFuture != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: ShadCNTheme.space3),
              child: Text(
                'Links on this page',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF424242),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.015,
                ),
              ),
            ),
            FutureBuilder<List<Map<String, String>>>(
              future: _linksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(ShadCNTheme.space4),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(ShadCNTheme.space4),
                    child: Text(
                      'Unable to load links: ${snapshot.error}',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final links = snapshot.data ?? [];
                if (links.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(ShadCNTheme.space4),
                    child: Text(
                      'No links found on this page.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return Column(
                  children: links.asMap().entries.map((entry) {
                    final index = entry.key;
                    final link = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == links.length - 1
                            ? 0
                            : ShadCNTheme.space3,
                      ),
                      child: _buildLinkButton(
                        context,
                        link['text'] ?? 'Untitled Link',
                        link['url'] ?? '',
                        isDark,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: ShadCNTheme.space5),
          ],

          CopyrightWidget(),
          const SizedBox(height: ShadCNTheme.space4),
        ],
      ),
    );
  }

  /// Builds a button for a link.
  Widget _buildLinkButton(
    BuildContext context,
    String text,
    String url,
    bool isDark,
  ) {
    return ShadButton(
      text: text,
      onPressed: () => _handleLinkTap(context, url),
      variant: ShadButtonVariant.outline,
      icon: Icon(
        Icons.open_in_new,
        size: 18,
        color: isDark
            ? const Color(0xFF60A5FA)
            : const Color(0xFF0B73DA),
      ),
      fullWidth: true,
    );
  }

  /// Handles when a link button is tapped.
  Future<void> _handleLinkTap(BuildContext context, String url) async {
    // Check if this is an internal link
    if (url.startsWith('internal://')) {
      // Handle internal navigation similar to home screen
      // For now, just open external links
      // Internal link handling can be added if needed
      return;
    }

    // Parse and open external URL
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid URL'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open link. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open link. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

