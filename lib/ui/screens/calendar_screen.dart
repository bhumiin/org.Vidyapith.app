import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../theme/shadcn_theme.dart';
import '../components/calendar_widget.dart';
import '../components/card.dart';
import '../../models/calendar_event.dart';
import '../../services/calendar_scraper.dart';
import '../components/logo_leading.dart';

/// Calendar Screen - This screen displays a monthly calendar view with all Vidyapith events.
/// 
/// What this screen does:
/// - Shows a calendar widget where users can see all events for any month
/// - Displays a list of events below the calendar with dates, titles, and descriptions
/// - Highlights Vidyapith-specific events with special red coloring
/// - Allows users to navigate between months using arrow buttons
/// - When users tap a date on the calendar, it automatically scrolls to that event in the list
/// - Fetches event data from the Vidyapith website automatically
/// 
/// How users interact with it:
/// - Tap dates on the calendar to jump to events on that date
/// - Swipe or use arrow buttons to change months
/// - Pull down to refresh and get the latest events from the website
/// - Scroll through the events list to see all upcoming activities
/// - Tap the notification icon (currently not functional) for future notification features
class CalendarScreen extends StatefulWidget {
  /// Allows other parts of the app to request that this screen scroll to the top.
  /// Used when the user switches to the Calendar tab.
  final ValueNotifier<bool>? scrollNotifier;

  const CalendarScreen({super.key, this.scrollNotifier});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

/// Internal state class that manages the calendar screen's behavior and display.
class _CalendarScreenState extends State<CalendarScreen> {
  /// Service that fetches calendar events from the Vidyapith website.
  /// It scrapes the website to get event dates, titles, and descriptions.
  final CalendarScraper _scraper = CalendarScraper();
  
  /// Controller that manages scrolling on the page.
  /// Allows the screen to automatically scroll to specific events when dates are tapped.
  final ScrollController _scrollController = ScrollController();
  
  /// Map that stores references to each event card in the list.
  /// Used to scroll to specific events when their dates are tapped on the calendar.
  final Map<String, GlobalKey> _eventKeys = {};

  /// The calendar data that was fetched from the website (all events, dates, etc.).
  /// This is null until content is loaded.
  CalendarContent? _calendarContent;
  
  /// Tracks whether we're currently loading calendar events from the website.
  /// Shows a loading spinner while true.
  bool _isLoading = true;
  
  /// Stores any error message if loading events fails.
  /// Displayed to the user if something goes wrong (network error, etc.).
  String? _errorMessage;
  
  /// The month and year currently displayed on the calendar widget.
  /// Users can change this by navigating to different months.
  DateTime _displayedMonth = DateTime.now();

  /// Called when the screen is first created and displayed.
  /// Sets up listeners and loads initial calendar events from the website.
  @override
  void initState() {
    super.initState();
    _loadContent();
    widget.scrollNotifier?.addListener(_onScrollRequested);
  }

  /// Called when the screen is removed or closed.
  /// Cleans up resources like controllers and listeners to prevent memory leaks.
  @override
  void dispose() {
    widget.scrollNotifier?.removeListener(_onScrollRequested);
    _scrollController.dispose();
    _scraper.dispose();
    super.dispose();
  }

  /// Called when another part of the app requests that this screen scroll to the top.
  /// Triggers the scrollToTop() method.
  void _onScrollRequested() {
    scrollToTop();
  }

  /// Smoothly scrolls the page back to the very top.
  /// Used when the user switches to the Calendar tab or when requested from outside.
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Loads calendar events from the Vidyapith website.
  /// Fetches all events, their dates, titles, and descriptions.
  /// 
  /// Parameters:
  /// - forceRefresh: If true, ignores cached data and fetches fresh content from the website
  Future<void> _loadContent({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (forceRefresh || _calendarContent == null) {
      setState(() {
        _isLoading = true; // Show loading spinner
        if (forceRefresh) {
          _errorMessage = null; // Clear any previous errors
        }
      });
    }

    try {
      // Fetch calendar events from the website (may use cached version if available)
      final content = await _scraper.getCalendarContent(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _calendarContent = content; // Store the fetched events
        _isLoading = false; // Hide loading spinner
        _errorMessage = null; // Clear any errors
      });
    } catch (_) {
      // If something goes wrong (network error, parsing error, etc.)
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Hide loading spinner
        _errorMessage = 'Unable to load calendar.'; // Show error message
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
                if (_isLoading && _calendarContent == null)
                  _buildLoadingState(isDark)
                else if (_errorMessage != null && _calendarContent == null)
                  _buildErrorState(context, isDark)
                else
                  _buildCalendarContent(context, isDark),
                const SizedBox(height: ShadCNTheme.space12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section at the top of the Calendar screen.
  /// Displays the app logo, "Calendar" title, and a notification icon button.
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
                'Calendar',
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

  /// Shows a loading spinner while calendar events are being fetched from the website.
  /// This appears when the screen first loads and there's no cached data available.
  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(ShadCNTheme.space8),
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: const Color(0xFF0B73DA),
          ),
        ),
      ),
    );
  }

  /// Shows an error message if calendar events cannot be loaded.
  /// This appears when there's a network error or the website cannot be accessed.
  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Center(
        child: Text(
          _errorMessage ?? 'Unable to load calendar.',
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontSize: ShadCNTheme.textBase,
          ),
        ),
      ),
    );
  }

  /// Builds the main calendar content including the calendar widget and events list.
  /// This method:
  /// - Gets all events for the currently displayed month
  /// - Sorts them by date (earliest first)
  /// - Creates references to each event card so we can scroll to them when dates are tapped
  Widget _buildCalendarContent(BuildContext context, bool isDark) {
    // Get all events for the currently displayed month and year
    final events = _calendarContent?.getEventsForMonth(
          _displayedMonth.month,
          _displayedMonth.year,
        ) ??
        [];

    // Sort events by date (earliest first, so January 1st comes before January 15th)
    final sortedEvents = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Clear and rebuild event keys - these are references to each event card
    // Used to scroll to specific events when their dates are tapped on the calendar
    _eventKeys.clear();
    for (final event in sortedEvents) {
      final key = '${event.date.year}-${event.date.month}-${event.date.day}-${event.title}';
      _eventKeys[key] = GlobalKey();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar widget
        Padding(
          padding: const EdgeInsets.all(ShadCNTheme.space4),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(ShadCNTheme.radius2xl),
              border: Border.all(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(ShadCNTheme.space4),
            child: CalendarWidget(
              displayedMonth: _displayedMonth,
              events: events,
              onDateTapped: (date) {
                // When user taps a date on the calendar, find all events for that date
                // and scroll to the first one in the events list
                final dateEvents = sortedEvents.where((e) =>
                    e.date.year == date.year &&
                    e.date.month == date.month &&
                    e.date.day == date.day).toList();
                
                if (dateEvents.isNotEmpty) {
                  // Get the first event for this date
                  final firstEvent = dateEvents.first;
                  // Find the reference to this event's card
                  final key = '${firstEvent.date.year}-${firstEvent.date.month}-${firstEvent.date.day}-${firstEvent.title}';
                  final eventKey = _eventKeys[key];
                  
                  // Scroll to this event card with a smooth animation
                  if (eventKey?.currentContext != null) {
                    Scrollable.ensureVisible(
                      eventKey!.currentContext!,
                      duration: const Duration(milliseconds: 500), // Half-second animation
                      curve: Curves.easeInOut, // Smooth start and end
                    );
                  }
                }
              },
              onMonthChanged: (newMonth) {
                // When user changes the month (using arrow buttons or swiping),
                // update the displayed month to show events for the new month
                setState(() {
                  _displayedMonth = newMonth;
                });
              },
            ),
          ),
        ),
        // Events list
        if (sortedEvents.isNotEmpty) _buildEventsList(context, isDark, sortedEvents),
      ],
    );
  }

  /// Builds the list of events displayed below the calendar.
  /// Each event is shown as a card with the date badge on the left and event details on the right.
  /// Vidyapith-specific events are highlighted with red coloring.
  Widget _buildEventsList(
    BuildContext context,
    bool isDark,
    List<CalendarEvent> events,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShadCNTheme.space4,
        ShadCNTheme.space2,
        ShadCNTheme.space4,
        ShadCNTheme.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF424242),
              fontSize: ShadCNTheme.textXl,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space4),
          ...events.map((event) {
            final key = '${event.date.year}-${event.date.month}-${event.date.day}-${event.title}';
            final eventKey = _eventKeys[key] ?? GlobalKey();
            if (!_eventKeys.containsKey(key)) {
              _eventKeys[key] = eventKey;
            }
            
            return Padding(
              key: eventKey,
              padding: EdgeInsets.only(
                bottom: events.indexOf(event) == events.length - 1
                    ? 0
                    : ShadCNTheme.space3,
              ),
              child: _buildEventCard(context, isDark, event),
            );
          }),
        ],
      ),
    );
  }

  /// Builds a single event card showing date, title, and description.
  /// Vidyapith events are highlighted with red coloring and a special "Vidyapith" badge.
  /// Events with Indian calendar dates show an asterisk (*) badge.
  Widget _buildEventCard(
    BuildContext context,
    bool isDark,
    CalendarEvent event,
  ) {
    // Get the month name (e.g., "January", "February") from the month number
    final monthName = _getMonthName(event.date.month);
    // Get the day number (e.g., 1, 15, 31)
    final day = event.date.day;
    // Check if this is a Vidyapith-specific event (shown in red instead of blue)
    final isVidyapithEvent = event.isVidyapithEvent;

    return ShadCard(
      child: Container(
        padding: const EdgeInsets.all(ShadCNTheme.space4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(ShadCNTheme.radius2xl),
          border: Border.all(
            color: isVidyapithEvent
                ? (isDark ? const Color(0xFFEF4444).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.2))
                : (isDark ? const Color(0xFF2D3748) : const Color(0xFFE0E7FF)),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ShadCNTheme.space3,
                vertical: ShadCNTheme.space2,
              ),
              decoration: BoxDecoration(
                color: isVidyapithEvent
                    ? (isDark
                        ? const Color(0xFFEF4444).withOpacity(0.2)
                        : const Color(0xFFEF4444).withOpacity(0.1))
                    : (isDark
                        ? const Color(0xFF0B73DA).withOpacity(0.2)
                        : const Color(0xFF0B73DA).withOpacity(0.1)),
                borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Text(
                    monthName.substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      color: isVidyapithEvent
                          ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                          : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA)),
                      fontSize: ShadCNTheme.textXs,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isVidyapithEvent
                          ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                          : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA)),
                      fontSize: ShadCNTheme.text2xl,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ShadCNTheme.space4),
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isVidyapithEvent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ShadCNTheme.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFEF4444).withOpacity(0.2)
                                : const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ShadCNTheme.radiusSm),
                          ),
                          child: Text(
                            'Vidyapith',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                              fontSize: ShadCNTheme.textXs,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (isVidyapithEvent && event.isIndianCalendarDate) ...[
                        const SizedBox(width: ShadCNTheme.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ShadCNTheme.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF6B7280).withOpacity(0.2)
                                : const Color(0xFF9CA3AF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ShadCNTheme.radiusSm),
                          ),
                          child: Text(
                            '*',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              fontSize: ShadCNTheme.textXs,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isVidyapithEvent) const SizedBox(height: ShadCNTheme.space1),
                  Text(
                    event.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF424242),
                      fontSize: ShadCNTheme.textBase,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    const SizedBox(height: ShadCNTheme.space1),
                    Text(
                      event.description!,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: ShadCNTheme.textSm,
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

  /// Converts a month number (1-12) to its full name (e.g., 1 → "January", 12 → "December").
  /// Used to display the month abbreviation (e.g., "JAN", "FEB") on event date badges.
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

