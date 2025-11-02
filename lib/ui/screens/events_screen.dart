import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../theme/shadcn_theme.dart';
import '../components/card.dart';
import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../components/logo_leading.dart';

class EventsScreen extends StatefulWidget {
  final ValueNotifier<bool>? scrollNotifier;

  const EventsScreen({super.key, this.scrollNotifier});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final WebsiteScraper _scraper = WebsiteScraper();
  final ScrollController _scrollController = ScrollController();

  EventsContent? _eventsContent;
  bool _isLoading = true;
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

class _EventImage extends StatelessWidget {
  const _EventImage({
    required this.imageUrl,
    required this.isDark,
  });

  final String imageUrl;
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

