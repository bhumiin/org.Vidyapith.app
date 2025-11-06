import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../theme/shadcn_theme.dart';
import '../components/card.dart';
import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/logo_leading.dart';

/// Events Screen - This screen displays a list of special events from the Vidyapith website.
/// 
/// What this screen does:
/// - Shows a scrollable list of events with images, titles, and descriptions
/// - Fetches event information from the Vidyapith website automatically
/// - Displays event images that load from the internet
/// - Shows loading indicators while events are being fetched
/// - Handles errors gracefully if events cannot be loaded
/// 
/// How users interact with it:
/// - Scroll through the list to see all events
/// - Pull down to refresh and get the latest events from the website
/// - View event images and details for each event
/// - Tap the notification icon (currently not functional) for future notification features
class EventsScreen extends StatefulWidget {
  /// Allows other parts of the app to request that this screen scroll to the top.
  /// Used when the user switches to the Events tab.
  final ValueNotifier<bool>? scrollNotifier;

  const EventsScreen({super.key, this.scrollNotifier});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

/// Internal state class that manages the events screen's behavior and display.
class _EventsScreenState extends State<EventsScreen> {
  /// Service that fetches events from the Vidyapith website.
  /// It scrapes the website to get event images, titles, and descriptions.
  final WebsiteScraper _scraper = WebsiteScraper();
  
  /// Controller that manages scrolling on the page.
  /// Allows the screen to programmatically scroll when needed.
  final ScrollController _scrollController = ScrollController();

  /// The events data that was fetched from the website.
  /// This is null until content is loaded.
  EventsContent? _eventsContent;
  
  /// Tracks whether we're currently loading events from the website.
  /// Shows a loading spinner while true.
  bool _isLoading = true;
  
  /// Stores any error message if loading events fails.
  /// Displayed to the user if something goes wrong (network error, etc.).
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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

    if (forceRefresh || _eventsContent == null) {
      setState(() {
        _isLoading = true;
        if (forceRefresh) {
          _errorMessage = null;
        }
      });
    }

    try {
      final content = await _scraper.getEventsContent(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _eventsContent = content;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load events.';
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
                _buildEventsList(context, isDark),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                'Events',
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

  /// Builds the list of events displayed on the screen.
  /// Shows loading state, empty state, error state, or the actual events list as appropriate.
  Widget _buildEventsList(BuildContext context, bool isDark) {
    final events = _eventsContent?.events ?? [];
    final bool isLoadingEvents = _isLoading && events.isEmpty;
    final bool showEmptyState =
        !_isLoading && events.isEmpty && _errorMessage == null;
    final bool showErrorState =
        !_isLoading && events.isEmpty && _errorMessage != null;

    return Padding(
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
            _buildStatusMessage('No events found.', isDark),
          if (!isLoadingEvents && showErrorState)
            _buildStatusMessage(
              'Unable to refresh events. Please try again later.',
              isDark,
            ),
        ],
      ),
    );
  }

  /// Builds a single event card showing the event image, title, and description.
  /// Each event is displayed as a card with the image at the top and text content below.
  Widget _buildEventCard(
    BuildContext context,
    bool isDark,
    Event event,
  ) {
    return ShadCard(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF5F7F8),
                width: double.infinity,
                child: _EventImage(imageUrl: event.imageUrl, isDark: isDark),
              ),
            ),
            // Event Content
            Padding(
              padding: const EdgeInsets.all(ShadCNTheme.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF424242),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: ShadCNTheme.space2),
                    Text(
                      event.description,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a loading placeholder while events are being fetched.
  /// Displays a spinner inside a card-shaped container that matches the event card size.
  Widget _buildLoadingEventPlaceholder(bool isDark) {
    return ShadCard(
      child: Container(
        height: 200,
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

  /// Shows a status message (either "No events" or error message).
  /// Used when there are no events to display or when loading fails.
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
}

/// Widget that displays an event image with loading and error handling.
/// This widget:
/// - Shows a loading spinner while the image is downloading from the internet
/// - Displays the image once it's loaded
/// - Shows a broken image icon if the image fails to load
/// - Applies a subtle dark overlay to make the image more readable
class _EventImage extends StatelessWidget {
  const _EventImage({
    required this.imageUrl,
    required this.isDark,
  });

  /// The web address (URL) of the event image to display.
  final String imageUrl;
  
  /// Whether the app is in dark mode (affects background colors while loading).
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F7F8);
    final Color overlayColor =
        isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.1);

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(overlayColor, BlendMode.srcOver),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.low,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(color: backgroundColor);
              },
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: backgroundColor),
            ),
          ),
        ),
        Image.network(
          imageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          filterQuality: FilterQuality.high,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              color: backgroundColor,
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: backgroundColor,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              size: 48,
            ),
          ),
        ),
      ],
    );
  }
}

