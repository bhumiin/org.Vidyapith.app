import 'package:flutter/material.dart';
import '../components/branded_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../theme/shadcn_theme.dart';
import '../components/copyright_widget.dart';

/// Bookstore Screen - This screen displays information about the Vidyapith bookstore.
/// 
/// What this screen does:
/// - Shows an "About Us" section explaining what the bookstore offers
/// - Displays the bookstore location/address
/// - Shows bookstore hours of operation
/// - Provides contact email with a button to send an email
/// - Fetches all bookstore information from the Vidyapith website automatically
/// 
/// How users interact with it:
/// - Scroll through bookstore information
/// - Tap "Email Bookstore" button to open email app and contact the bookstore
/// - Pull down to refresh and get the latest bookstore information
class BookstoreScreen extends StatefulWidget {
  const BookstoreScreen({super.key});

  @override
  State<BookstoreScreen> createState() => _BookstoreScreenState();
}

class _BookstoreScreenState extends State<BookstoreScreen> {
  static const String _bookstoreThumbnailUrl =
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/4853020.jpg?562';

  late final WebsiteScraper _scraper;
  BookstoreContent? _content;
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
      final content = await _scraper.getBookstoreContent(
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
          _errorMessage = 'Unable to load bookstore details.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBrandedAppBar(title: const Text('Bookstore')),
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

    final BookstoreContent? content = _content;
    if (content == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadCard(
            child: Text(
              'Bookstore information is currently unavailable. Please pull to refresh.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAboutCard(context, content),
        if (content.locationLines.isNotEmpty) ...[
          const SizedBox(height: ShadCNTheme.space3),
          _buildLocationCard(context, content.locationLines),
        ],
        if (content.hours.isNotEmpty) ...[
          const SizedBox(height: ShadCNTheme.space3),
          _buildHoursCard(context, content.hours),
        ],
        if (content.contactEmail != null &&
            content.contactEmail!.isNotEmpty) ...[
          const SizedBox(height: ShadCNTheme.space3),
          _buildContactCard(context, content.contactEmail!),
        ],
        const SizedBox(height: ShadCNTheme.space4),
        CopyrightWidget(),
      ],
    );
  }

  /// Builds the "About Us" card with bookstore description and thumbnail image.
  /// Shows what the bookstore offers and displays a photo of the bookstore.
  Widget _buildAboutCard(BuildContext context, BookstoreContent content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.5);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: ShadCNTheme.fontBold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Us', style: titleStyle),
          const SizedBox(height: ShadCNTheme.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                _bookstoreThumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Container(
                    color: theme.scaffoldBackgroundColor,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.scaffoldBackgroundColor,
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
          Text(content.about, style: textStyle),
        ],
      ),
    );
  }

  /// Builds the location card showing the bookstore address.
  /// Displays the address with a location icon for easy identification.
  Widget _buildLocationCard(BuildContext context, List<String> locationLines) {
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
          Text('Location', style: titleStyle),
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
                    for (int i = 0; i < locationLines.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == locationLines.length - 1
                              ? 0
                              : ShadCNTheme.space1,
                        ),
                        child: Text(
                          locationLines[i],
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

  /// Builds the hours card showing when the bookstore is open.
  /// Displays operating hours with a clock icon for easy identification.
  Widget _buildHoursCard(BuildContext context, List<String> hours) {
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
          Text('Hours', style: titleStyle),
          const SizedBox(height: ShadCNTheme.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule, size: 20),
              const SizedBox(width: ShadCNTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < hours.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == hours.length - 1
                              ? 0
                              : ShadCNTheme.space1,
                        ),
                        child: Text(
                          hours[i],
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

  /// Builds the contact card with bookstore email and a button to send an email.
  /// Shows the contact email address and provides a button to open the email app.
  Widget _buildContactCard(BuildContext context, String email) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: ShadCNTheme.fontBold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark
          ? ShadCNTheme.darkMutedForeground
          : ShadCNTheme.mutedForeground,
    );

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Questions?', style: titleStyle),
          const SizedBox(height: ShadCNTheme.space2),
          Text('Contact us at $email', style: bodyStyle),
          const SizedBox(height: ShadCNTheme.space3),
          ShadButton(
            text: 'Email Bookstore',
            fullWidth: true,
            onPressed: () => _launchEmail(context, email),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);

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
        content: Text('Unable to open email client. Please try again later.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
