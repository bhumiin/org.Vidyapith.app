import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/shadcn_theme.dart';
import '../components/card.dart';
import '../components/photo_carousel.dart';
import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import 'bookstore_screen.dart';
import 'classes_screen.dart';
import 'class_detail_screen.dart';
import 'donate_screen.dart';
import 'admissions_screen.dart';
import 'snack_signup_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  final ValueNotifier<bool>? scrollNotifier;

  const HomeScreen({super.key, this.refreshNotifier, this.scrollNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebsiteScraper _scraper = WebsiteScraper();
  final ScrollController _scrollController = ScrollController();

  WebsiteContent? _websiteContent;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContent();
    // Listen to refresh notifications
    widget.refreshNotifier?.addListener(_onRefreshRequested);
    // Listen to scroll-to-top notifications
    widget.scrollNotifier?.addListener(_onScrollRequested);
  }

  void _onRefreshRequested() {
    refresh();
  }

  void _onScrollRequested() {
    scrollToTop();
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefreshRequested);
    widget.scrollNotifier?.removeListener(_onScrollRequested);
    _scrollController.dispose();
    _scraper.dispose();
    super.dispose();
  }

  void refresh() {
    // Scroll to top
    scrollToTop();
    // Refresh content
    _loadContent(forceRefresh: true);
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

    if (forceRefresh || _websiteContent == null) {
      setState(() {
        _isLoading = true;
        if (forceRefresh) {
          _errorMessage = null;
        }
      });
    }

    try {
      final content = await _scraper.getWebsiteContent(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _websiteContent = content;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load latest updates.';
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
                _buildWelcomeSection(context, isDark),
                _buildPhotoCarouselSection(context, isDark),
                _buildEventsSection(context, isDark),
                _buildResourcesSection(context, isDark),
                const SizedBox(height: ShadCNTheme.space12),
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
      ),
      child: Row(
        children: [
          // Left spacer to balance the notification button width
          const SizedBox(width: 40, height: 40),
          const SizedBox(width: ShadCNTheme.space2),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 90,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 90,
                      alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFFF5F7F8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Transform.scale(
                        scale: 1.2,
                        alignment: Alignment.center,
                        child: Container(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFFF5F7F8),
                          child: Image.asset(
                            'assets/images/letterhead.png',
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.high,
                            width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.broken_image_outlined,
                          size: 32,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : Colors.grey.shade600,
                        );
                      },
                    ),
                  ),
                    ),
                  ),
                      ),
                    ),
                  ),
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Handle notification tap
              },
              icon: Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.white : const Color(0xFF424242),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isDark) {
    final thought = _websiteContent?.thoughtOfTheDay;
    final displayQuote =
        thought?.text ??
        (_isLoading
            ? 'Loading thought of the day...'
            : 'Thought of the day unavailable right now.');
    final author = thought?.author;
    final bool showError =
        _errorMessage != null && thought == null && !_isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShadCNTheme.space4,
        0,
        ShadCNTheme.space4,
        ShadCNTheme.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote of the day',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF424242),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space1),
          Text(
            displayQuote,
            style: TextStyle(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
              fontSize: 16,
              fontStyle: thought != null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          if (author != null && author.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: ShadCNTheme.space1),
              child: Text(
                '- $author',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ),
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: ShadCNTheme.space1),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFEF9A9A)
                      : const Color(0xFFB91C1C),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCarouselSection(BuildContext context, bool isDark) {
    final List<String> carouselImages = const [
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/8953165_orig.jpg',
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/9467662_orig.jpg',
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/556584_orig.jpg',
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/3318585_orig.jpg',
    ];

    return Container(
      color: isDark ? const Color(0xFF101922) : const Color(0xFFF5F7F8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ShadCNTheme.space4),
        child: carouselImages.isEmpty
            ? _buildCarouselLoadingPlaceholder(isDark)
            : PhotoCarousel(imageUrls: carouselImages, isDark: isDark),
      ),
    );
  }

  Widget _buildCarouselLoadingPlaceholder(bool isDark) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE3F2FD),
        ),
        child: const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsSection(BuildContext context, bool isDark) {
    final events = _websiteContent?.upcomingEvents ?? [];
    final bool isLoadingEvents = _isLoading && events.isEmpty;
    final bool showEmptyState =
        !_isLoading && events.isEmpty && _errorMessage == null;
    final bool showErrorState =
        !_isLoading && events.isEmpty && _errorMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ShadCNTheme.space4,
            ShadCNTheme.space5,
            ShadCNTheme.space4,
            ShadCNTheme.space3,
          ),
          child: Text(
            'Upcoming Events',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF424242),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ShadCNTheme.space4),
          child: Column(
            children: [
              if (isLoadingEvents) _buildLoadingEventPlaceholder(isDark),
              if (!isLoadingEvents && events.isNotEmpty)
                ...List.generate(events.length, (index) {
                  final event = events[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == events.length - 1
                          ? 0
                          : ShadCNTheme.space3,
                    ),
                    child: _buildEventCard(context, isDark, event),
                  );
                }),
              if (!isLoadingEvents && showEmptyState)
                _buildStatusMessage('No upcoming events posted yet.', isDark),
              if (!isLoadingEvents && showErrorState)
                _buildStatusMessage(
                  'Unable to refresh events. Please try again later.',
                  isDark,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    bool isDark,
    UpcomingEvent event,
  ) {
    final (String?, String?) dateParts = _extractDateParts(event);
    final String? month = dateParts.$1;
    final String? day = dateParts.$2;
    final String detailText = event.details ?? '';
    final String description = event.title.trim();

    return ShadCard(
      child: Container(
        padding: const EdgeInsets.all(ShadCNTheme.space4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE0E7FF),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildEventLeadingBadge(isDark, month: month, day: day),
            const SizedBox(width: ShadCNTheme.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detailText.isNotEmpty)
                    Text(
                      detailText,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (detailText.isNotEmpty)
                    const SizedBox(height: ShadCNTheme.space1),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF424242),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLeadingBadge(bool isDark, {String? month, String? day}) {
    if (month != null && day != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space3,
          vertical: ShadCNTheme.space2,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0B73DA).withOpacity(0.2)
              : const Color(0xFF0B73DA).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              month,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF0B73DA),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              day,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF0B73DA),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(ShadCNTheme.space3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0B73DA).withOpacity(0.2)
            : const Color(0xFF0B73DA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.event_available_outlined,
        size: 28,
        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA),
      ),
    );
  }

  Widget _buildLoadingEventPlaceholder(bool isDark) {
    return ShadCard(
      child: Container(
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ShadCNTheme.space2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  (String?, String?) _extractDateParts(UpcomingEvent event) {
    final source = '${event.details ?? ''} ${event.title}'.trim();
    final match = RegExp(
      r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2})',
    ).firstMatch(source);

    if (match == null) return (null, null);
    final monthName = match.group(1) ?? '';
    final day = match.group(2) ?? '';
    final monthAbbrev = monthName.length >= 3
        ? monthName.substring(0, 3)
        : monthName;

    return (monthAbbrev.toUpperCase(), day.padLeft(2, '0'));
  }

  Widget _buildResourcesSection(BuildContext context, bool isDark) {
    final quickLinks = [
      {
        'icon': Icons.restaurant_menu,
        'label': 'SNACK SIGNUP',
        'url': 'internal://snack-signup',
      },
      {
        'icon': Icons.school,
        'label': 'CURRICULAR CLASSES',
        'url': 'internal://class/Curricular Classes',
      },
      {
        'icon': Icons.music_note,
        'label': 'MUSIC CLASSES',
        'url': 'internal://class/Music Classes',
      },
      {
        'icon': Icons.assignment,
        'label': '2025 DIWALI TOPICS',
        'url':
            'https://www.vidyapith.org/uploads/5/2/1/3/52135817/2025-diwali_projects_suggestions.pdf',
      },
      {
        'icon': Icons.local_fire_department,
        'label': 'SUMMER CAMP CLASSES',
        'url': 'internal://class/Summer Camp',
      },
      {
        'icon': Icons.volunteer_activism,
        'label': 'ACT FOOD DRIVE',
        'url': 'https://vidyapith-act.netlify.app/',
      },
      {
        'icon': Icons.storefront,
        'label': 'BOOKSTORE',
        'url': 'internal://bookstore',
      },
      {
        'icon': Icons.app_registration,
        'label': 'ADMISSIONS',
        'url': 'internal://admissions',
      },
      {
        'icon': Icons.favorite_border,
        'label': 'DONATE',
        'url': 'internal://donate',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ShadCNTheme.space4,
            ShadCNTheme.space5,
            ShadCNTheme.space4,
            ShadCNTheme.space4,
          ),
          child: Text(
            'Quick Links',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF424242),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ShadCNTheme.space4),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: ShadCNTheme.space3,
              mainAxisSpacing: ShadCNTheme.space3,
              childAspectRatio: 1.2,
            ),
            itemCount: quickLinks.length,
            itemBuilder: (context, index) {
              final link = quickLinks[index];
              return _buildResourceTile(
                context,
                isDark,
                icon: link['icon'] as IconData,
                label: link['label'] as String,
                url: link['url'] as String,
              );
            },
          ),
        ),
        const SizedBox(height: ShadCNTheme.space4),
      ],
    );
  }

  Widget _buildResourceTile(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String url,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _handleQuickLinkTap(context, url);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0B73DA).withOpacity(0.22)
                : const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE0E7FF),
            ),
          ),
          padding: const EdgeInsets.all(ShadCNTheme.space3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF0B73DA),
                size: 28,
              ),
              const SizedBox(height: ShadCNTheme.space1),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF424242),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuickLinkTap(BuildContext context, String url) async {
    if (url.startsWith('internal://')) {
      if (url == 'internal://classes') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ClassesScreen()));
        return;
      }
      if (url == 'internal://donate') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DonateScreen()));
        return;
      }
      if (url.startsWith('internal://class/')) {
        final className = url.replaceFirst('internal://class/', '');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassDetailScreen(title: className),
          ),
        );
        return;
      }
      if (url == 'internal://bookstore') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BookstoreScreen()));
        return;
      }
      if (url == 'internal://admissions') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdmissionsScreen()));
        return;
      }
      if (url == 'internal://snack-signup') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SnackSignupScreen()));
        return;
      }
      return;
    }

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
}
