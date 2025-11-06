// Import statements - These bring in all the tools and components needed
// to build the home screen, including UI components, data models, and other screens
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

/// Home Screen - The main landing page of the app
/// This screen displays:
/// - Letterhead header image
/// - Daily quote/thought
/// - Photo carousel
/// - Upcoming events from the website
/// - Quick links to various features
/// 
/// Features:
/// - Pull-to-refresh to reload content
/// - Automatic scroll-to-top when tab is selected
/// - Fetches fresh content from the Vidyapith website
class HomeScreen extends StatefulWidget {
  // Notifier that tells this screen to refresh its content
  // Used when user taps Home tab while already on Home
  final ValueNotifier<int>? refreshNotifier;
  
  // Notifier that tells this screen to scroll to the top
  // Used when user switches to Home tab from another tab
  final ValueNotifier<bool>? scrollNotifier;

  const HomeScreen({super.key, this.refreshNotifier, this.scrollNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Service that fetches content from the Vidyapith website
  // It scrapes the website to get events, quotes, and other information
  final WebsiteScraper _scraper = WebsiteScraper();
  
  // Controller that manages scrolling on the page
  // Allows us to programmatically scroll to top or control scroll position
  final ScrollController _scrollController = ScrollController();

  // The website content that was fetched (events, quotes, etc.)
  // This is null until content is loaded
  WebsiteContent? _websiteContent;
  
  // Tracks whether we're currently loading content from the website
  // Shows loading indicators while true
  bool _isLoading = true;
  
  // Stores any error message if loading content fails
  // Displayed to the user if something goes wrong
  String? _errorMessage;

  /// Initialization - Runs once when the screen is first created
  /// Sets up listeners and loads initial content from the website
  @override
  void initState() {
    super.initState();
    // Load content from the website when screen first appears
    _loadContent();
    // Listen for refresh requests (when user taps Home tab while already on Home)
    widget.refreshNotifier?.addListener(_onRefreshRequested);
    // Listen for scroll-to-top requests (when user switches to Home tab)
    widget.scrollNotifier?.addListener(_onScrollRequested);
  }

  /// Called when a refresh is requested from outside this screen
  /// Triggers a full refresh of the content
  void _onRefreshRequested() {
    refresh();
  }

  /// Called when a scroll-to-top is requested from outside this screen
  /// Scrolls the page back to the top
  void _onScrollRequested() {
    scrollToTop();
  }

  /// Cleanup - Runs when the screen is removed from memory
  /// Properly disposes of all listeners and controllers to prevent memory leaks
  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefreshRequested);
    widget.scrollNotifier?.removeListener(_onScrollRequested);
    _scrollController.dispose();
    _scraper.dispose();
    super.dispose();
  }

  /// Public method to refresh the screen
  /// Scrolls to top and reloads all content from the website
  void refresh() {
    // First scroll to top so user sees the refresh happening
    scrollToTop();
    // Then reload all content from the website
    _loadContent(forceRefresh: true);
  }

  /// Scrolls the page smoothly to the top
  /// Used when user switches to Home tab or refreshes
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Position 0 is the top of the page
        duration: const Duration(milliseconds: 300), // Takes 300ms to scroll
        curve: Curves.easeOut, // Smooth animation that slows down at the end
      );
    }
  }

  /// Loads content from the Vidyapith website
  /// Fetches events, quotes, and other information
  /// 
  /// Parameters:
  /// - forceRefresh: If true, ignores cached data and fetches fresh content
  Future<void> _loadContent({bool forceRefresh = false}) async {
    // Safety check: Don't update if screen is no longer visible
    if (!mounted) return;

    // Show loading indicator if we're forcing refresh or don't have content yet
    if (forceRefresh || _websiteContent == null) {
      setState(() {
        _isLoading = true; // Show loading spinner
        if (forceRefresh) {
          _errorMessage = null; // Clear any previous errors
        }
      });
    }

    try {
      // Fetch content from the website (may use cached version if available)
      final content = await _scraper.getWebsiteContent(
        forceRefresh: forceRefresh,
      );
      // Safety check again before updating
      if (!mounted) return;
      // Update the screen with the fetched content
      setState(() {
        _websiteContent = content; // Store the fetched content
        _isLoading = false; // Hide loading spinner
        _errorMessage = null; // Clear any errors
      });
    } catch (_) {
      // If something goes wrong (network error, parsing error, etc.)
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Hide loading spinner
        _errorMessage = 'Unable to load latest updates.'; // Show error message
      });
    }
  }

  /// Builds the entire Home screen layout
  /// This is the main method that creates all the visual elements
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Check if device is using dark mode or light mode
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Background color changes based on theme (dark or light)
      backgroundColor: isDark
          ? const Color(0xFF101922) // Dark blue-gray
          : const Color(0xFFF5F7F8), // Light gray
      body: SafeArea(
        // SafeArea ensures content isn't hidden by device notches or status bars
        child: RefreshIndicator(
          // Pull-to-refresh: User can pull down to reload content
          onRefresh: () => _loadContent(forceRefresh: true),
          color: const Color(0xFF0B73DA), // Blue refresh indicator
          child: SingleChildScrollView(
            controller: _scrollController, // Allows programmatic scrolling
            physics: const AlwaysScrollableScrollPhysics(), // Always allows scrolling
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align items to the left
              children: [
                // Header with letterhead image and notification button
                _buildHeader(context, isDark),
                // "Quote of the day" section
                _buildWelcomeSection(context, isDark),
                // Photo carousel showing school images
                _buildPhotoCarouselSection(context, isDark),
                // Upcoming events list
                _buildEventsSection(context, isDark),
                // Quick links grid (Snack Signup, Classes, etc.)
                _buildResourcesSection(context, isDark),
                // Bottom spacing
                const SizedBox(height: ShadCNTheme.space12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section at the top of the Home screen
  /// Displays the Vidyapith letterhead image centered, with a notification button on the right
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ShadCNTheme.space4, // Left and right padding
        vertical: ShadCNTheme.space2, // Top and bottom padding
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : const Color(0xFFF5F7F8),
      ),
      child: Row(
        children: [
          // Left spacer - Creates space to balance the notification button on the right
          // This keeps the letterhead perfectly centered
          const SizedBox(width: 40, height: 40),
          const SizedBox(width: ShadCNTheme.space2),
          // Expanded widget takes up all available space
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 90, // Maximum height of the header bar
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Wide container
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                    child: Container(
                      height: 90,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        // White background for dark theme, light gray for light theme
                        color: isDark
                            ? Colors.white
                            : const Color(0xFFF5F7F8),
                      ),
                      child: Padding(
                        // Padding inside the container creates white space around the image
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Transform.scale(
                          scale: 1.2, // Makes the image 20% larger
                          alignment: Alignment.center,
                          child: Container(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFFF5F7F8),
                            child: Image.asset(
                              'assets/images/letterhead.png', // The letterhead image
                              fit: BoxFit.fitWidth, // Fits width, crops top/bottom if needed
                              alignment: Alignment.center, // Centers the image
                              filterQuality: FilterQuality.high, // High quality rendering
                              width: double.infinity, // Full width available
                              // If image fails to load, show a broken image icon
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
          // Notification button on the right side
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20), // Circular button
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Handle notification tap - functionality to be added later
              },
              icon: Icon(
                Icons.notifications_outlined, // Bell icon
                color: isDark ? Colors.white : const Color(0xFF424242),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the "Quote of the day" section
  /// Displays an inspirational quote or thought from the website
  /// Shows loading message while fetching, or error message if fetch fails
  Widget _buildWelcomeSection(BuildContext context, bool isDark) {
    // Get the quote/thought from the website content
    final thought = _websiteContent?.thoughtOfTheDay;
    
    // Determine what text to display:
    // - If we have a quote, show it
    // - If loading, show "Loading..."
    // - If no quote available, show "unavailable" message
    final displayQuote =
        thought?.text ??
        (_isLoading
            ? 'Loading thought of the day...'
            : 'Thought of the day unavailable right now.');
    
    // Get the author name if available
    final author = thought?.author;
    
    // Show error message only if there's an error AND we're not loading AND no quote
    final bool showError =
        _errorMessage != null && thought == null && !_isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShadCNTheme.space4,
        0, // No top margin
        ShadCNTheme.space4,
        ShadCNTheme.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
        children: [
          // Section title
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
          // The actual quote text
          Text(
            displayQuote,
            style: TextStyle(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
              fontSize: 16,
              // Show in italic if it's an actual quote (not a loading/error message)
              fontStyle: thought != null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          // Show author name if available (e.g., "- Swami Vivekananda")
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
          // Show error message if something went wrong
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: ShadCNTheme.space1),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFEF9A9A) // Light red
                      : const Color(0xFFB91C1C), // Dark red
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the photo carousel section
  /// Displays a scrolling gallery of school images that users can swipe through
  Widget _buildPhotoCarouselSection(BuildContext context, bool isDark) {
    // List of image URLs from the Vidyapith website
    // These are photos of the school that rotate automatically
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
            ? _buildCarouselLoadingPlaceholder(isDark) // Show loading if no images
            : PhotoCarousel(imageUrls: carouselImages, isDark: isDark), // Show carousel
      ),
    );
  }

  /// Shows a loading placeholder while carousel images are being loaded
  /// Displays a spinner inside a rounded container
  Widget _buildCarouselLoadingPlaceholder(bool isDark) {
    return AspectRatio(
      aspectRatio: 16 / 9, // Standard widescreen ratio (like a TV or monitor)
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // Rounded corners
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE3F2FD),
        ),
        child: const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3), // Loading spinner
          ),
        ),
      ),
    );
  }

  /// Builds the "Upcoming Events" section
  /// Displays a list of upcoming events fetched from the Vidyapith website
  /// Shows loading state, empty state, or error state as appropriate
  Widget _buildEventsSection(BuildContext context, bool isDark) {
    // Get events from website content, or empty list if not loaded yet
    final events = _websiteContent?.upcomingEvents ?? [];
    
    // Determine what state to show:
    // - Loading: Show spinner while fetching events
    // - Empty: Show "No events" message if no events found
    // - Error: Show error message if fetch failed
    final bool isLoadingEvents = _isLoading && events.isEmpty;
    final bool showEmptyState =
        !_isLoading && events.isEmpty && _errorMessage == null;
    final bool showErrorState =
        !_isLoading && events.isEmpty && _errorMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
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
              // Show loading spinner while fetching events
              if (isLoadingEvents) _buildLoadingEventPlaceholder(isDark),
              
              // Show list of events if we have them
              if (!isLoadingEvents && events.isNotEmpty)
                ...List.generate(events.length, (index) {
                  final event = events[index];
                  return Padding(
                    // Add spacing between events, except after the last one
                    padding: EdgeInsets.only(
                      bottom: index == events.length - 1
                          ? 0 // No spacing after last event
                          : ShadCNTheme.space3, // Spacing between events
                    ),
                    child: _buildEventCard(context, isDark, event),
                  );
                }),
              
              // Show "No events" message if list is empty
              if (!isLoadingEvents && showEmptyState)
                _buildStatusMessage('No upcoming events posted yet.', isDark),
              
              // Show error message if fetch failed
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

  /// Builds a single event card
  /// Displays an event with a date badge on the left and event details on the right
  Widget _buildEventCard(
    BuildContext context,
    bool isDark,
    UpcomingEvent event,
  ) {
    // Extract month and day from the event text (e.g., "January 15" -> "JAN" and "15")
    final (String?, String?) dateParts = _extractDateParts(event);
    final String? month = dateParts.$1;
    final String? day = dateParts.$2;
    
    // Get event details (additional info like time or location)
    final String detailText = event.details ?? '';
    
    // Get the main event title/description
    final String description = event.title.trim();

    return ShadCard(
      child: Container(
        padding: const EdgeInsets.all(ShadCNTheme.space4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(20), // Rounded corners
          border: Border.all(
            color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE0E7FF),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Date badge on the left (shows month and day, or event icon)
            _buildEventLeadingBadge(isDark, month: month, day: day),
            const SizedBox(width: ShadCNTheme.space4),
            // Event details on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show details (time, location, etc.) if available
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
                  // Show main event title/description
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

  /// Builds the date badge shown on the left side of event cards
  /// If date is available, shows month abbreviation (e.g., "JAN") and day number (e.g., "15")
  /// If date is not available, shows a generic event icon instead
  Widget _buildEventLeadingBadge(bool isDark, {String? month, String? day}) {
    // If we have both month and day, show them in a date badge format
    if (month != null && day != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space3,
          vertical: ShadCNTheme.space2,
        ),
        decoration: BoxDecoration(
          // Blue background with transparency
          color: isDark
              ? const Color(0xFF0B73DA).withOpacity(0.2)
              : const Color(0xFF0B73DA).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Month abbreviation (e.g., "JAN", "FEB")
            Text(
              month,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF60A5FA) // Light blue
                    : const Color(0xFF0B73DA), // Dark blue
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            // Day number (e.g., "15", "03")
            Text(
              day,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF0B73DA),
                fontSize: 24, // Larger font for day
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // If no date available, show a generic event icon
    return Container(
      padding: const EdgeInsets.all(ShadCNTheme.space3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0B73DA).withOpacity(0.2)
            : const Color(0xFF0B73DA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.event_available_outlined, // Calendar/event icon
        size: 28,
        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA),
      ),
    );
  }

  /// Shows a loading placeholder while events are being fetched
  /// Displays a spinner inside a card-shaped container
  Widget _buildLoadingEventPlaceholder(bool isDark) {
    return ShadCard(
      child: Container(
        height: 96, // Same height as an event card
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3), // Loading spinner
        ),
      ),
    );
  }

  /// Shows a status message (either "No events" or error message)
  /// Used when there are no events to display or when loading fails
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

  /// Extracts month and day from event text
  /// Looks for patterns like "January 15" or "March 3" in the event title/details
  /// Returns month abbreviation (e.g., "JAN") and day (e.g., "15" or "03")
  /// Returns null values if no date is found
  (String?, String?) _extractDateParts(UpcomingEvent event) {
    // Combine event details and title to search for date
    final source = '${event.details ?? ''} ${event.title}'.trim();
    
    // Use regular expression to find month name followed by day number
    // Pattern matches: "January 15", "March 3", etc.
    final match = RegExp(
      r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2})',
    ).firstMatch(source);

    // If no date found, return null
    if (match == null) return (null, null);
    
    // Extract the month name and day number
    final monthName = match.group(1) ?? '';
    final day = match.group(2) ?? '';
    
    // Convert full month name to 3-letter abbreviation (e.g., "January" -> "JAN")
    final monthAbbrev = monthName.length >= 3
        ? monthName.substring(0, 3) // Take first 3 letters
        : monthName;

    // Return uppercase month abbreviation and day with leading zero if needed
    return (monthAbbrev.toUpperCase(), day.padLeft(2, '0')); // "3" becomes "03"
  }

  /// Builds the "Quick Links" section
  /// Displays a grid of clickable tiles that navigate to different features
  /// Each tile shows an icon and label
  Widget _buildResourcesSection(BuildContext context, bool isDark) {
    // List of all quick links with their icons, labels, and destinations
    // URLs starting with "internal://" open in-app screens
    // URLs starting with "https://" open external websites
    final quickLinks = [
      {
        'icon': Icons.restaurant_menu,
        'label': 'SNACK SIGNUP',
        'url': 'internal://snack-signup', // Opens Snack Signup screen
      },
      {
        'icon': Icons.school,
        'label': 'CURRICULAR CLASSES',
        'url': 'internal://class/Curricular Classes', // Opens class detail screen
      },
      {
        'icon': Icons.music_note,
        'label': 'MUSIC CLASSES',
        'url': 'internal://class/Music Classes', // Opens class detail screen
      },
      {
        'icon': Icons.assignment,
        'label': '2025 DIWALI TOPICS',
        'url':
            'https://www.vidyapith.org/uploads/5/2/1/3/52135817/2025-diwali_projects_suggestions.pdf', // Opens PDF in browser
      },
      {
        'icon': Icons.local_fire_department,
        'label': 'SUMMER CAMP CLASSES',
        'url': 'internal://class/Summer Camp', // Opens class detail screen
      },
      {
        'icon': Icons.volunteer_activism,
        'label': 'ACT FOOD DRIVE',
        'url': 'https://vidyapith-act.netlify.app/', // Opens external website
      },
      {
        'icon': Icons.storefront,
        'label': 'BOOKSTORE',
        'url': 'internal://bookstore', // Opens Bookstore screen
      },
      {
        'icon': Icons.app_registration,
        'label': 'ADMISSIONS',
        'url': 'internal://admissions', // Opens Admissions screen
      },
      {
        'icon': Icons.favorite_border,
        'label': 'DONATE',
        'url': 'internal://donate', // Opens Donate screen
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
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
        // Grid of quick link tiles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ShadCNTheme.space4),
          child: GridView.builder(
            shrinkWrap: true, // Don't take up infinite space
            physics: const NeverScrollableScrollPhysics(), // Grid itself doesn't scroll
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: ShadCNTheme.space3, // Space between columns
              mainAxisSpacing: ShadCNTheme.space3, // Space between rows
              childAspectRatio: 1.2, // Width to height ratio
            ),
            itemCount: quickLinks.length, // Total number of tiles
            itemBuilder: (context, index) {
              final link = quickLinks[index];
              // Build each tile with icon, label, and URL
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

  /// Builds a single quick link tile
  /// Displays an icon and label in a clickable card
  /// When tapped, navigates to the appropriate screen or opens a URL
  Widget _buildResourceTile(
    BuildContext context,
    bool isDark, {
    required IconData icon, // The icon to display (e.g., restaurant icon for Snack Signup)
    required String label, // The text label (e.g., "SNACK SIGNUP")
    required String url, // Where to navigate when tapped
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20), // Ripple effect matches container shape
        onTap: () {
          // Handle tap - navigate to screen or open URL
          _handleQuickLinkTap(context, url);
        },
        child: Container(
          decoration: BoxDecoration(
            // Blue-tinted background
            color: isDark
                ? const Color(0xFF0B73DA).withOpacity(0.22) // Semi-transparent blue
                : const Color(0xFFE8F1FF), // Light blue
            borderRadius: BorderRadius.circular(20), // Rounded corners
            border: Border.all(
              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE0E7FF),
            ),
          ),
          padding: const EdgeInsets.all(ShadCNTheme.space3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
            children: [
              // Icon at the top
              Icon(
                icon,
                color: isDark
                    ? const Color(0xFF60A5FA) // Light blue
                    : const Color(0xFF0B73DA), // Dark blue
                size: 28,
              ),
              const SizedBox(height: ShadCNTheme.space1),
              // Label text below icon
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFE5E7EB) // Light gray
                        : const Color(0xFF424242), // Dark gray
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // Center the text
                  maxLines: 2, // Allow up to 2 lines
                  overflow: TextOverflow.ellipsis, // Show "..." if text is too long
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles when a user taps a quick link tile
  /// If URL starts with "internal://", opens an in-app screen
  /// Otherwise, opens the URL in an external browser
  Future<void> _handleQuickLinkTap(BuildContext context, String url) async {
    // Check if this is an internal link (opens in-app screen)
    if (url.startsWith('internal://')) {
      // Handle different internal link types
      if (url == 'internal://classes') {
        // Open the main classes screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ClassesScreen()));
        return;
      }
      if (url == 'internal://donate') {
        // Open the donate screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DonateScreen()));
        return;
      }
      if (url.startsWith('internal://class/')) {
        // Extract class name from URL (e.g., "Curricular Classes", "Music Classes")
        final className = url.replaceFirst('internal://class/', '');
        // Open class detail screen with the specific class name
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassDetailScreen(title: className),
          ),
        );
        return;
      }
      if (url == 'internal://bookstore') {
        // Open the bookstore screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BookstoreScreen()));
        return;
      }
      if (url == 'internal://admissions') {
        // Open the admissions screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdmissionsScreen()));
        return;
      }
      if (url == 'internal://snack-signup') {
        // Open the snack signup screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SnackSignupScreen()));
        return;
      }
      return;
    }

    // If not an internal link, it's an external URL (website or PDF)
    // Parse the URL to make sure it's valid
    final uri = Uri.tryParse(url);

    if (uri == null) {
      // URL is invalid, show error message
      if (mounted) {
        _showLaunchError(context);
      }
      return;
    }

    try {
      // Open the URL in an external browser (not inside the app)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      // If opening failed, show error message
      if (!launched && mounted) {
        _showLaunchError(context);
      }
    } catch (_) {
      // If something went wrong, show error message
      if (mounted) {
        _showLaunchError(context);
      }
    }
  }

  /// Shows an error message if a link fails to open
  /// Displays a temporary message at the bottom of the screen
  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open link. Please try again later.'),
        behavior: SnackBarBehavior.floating, // Floating above the bottom navigation
      ),
    );
  }
}
