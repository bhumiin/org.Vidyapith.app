import 'package:flutter/material.dart';

import '../theme/shadcn_theme.dart';
import '../components/calendar_widget.dart';
import '../components/card.dart';
import '../../models/calendar_event.dart';
import '../../services/calendar_scraper.dart';
import '../components/logo_leading.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarScraper _scraper = CalendarScraper();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _eventKeys = {};

  CalendarContent? _calendarContent;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _displayedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scraper.dispose();
    super.dispose();
  }

  Future<void> _loadContent({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (forceRefresh || _calendarContent == null) {
      setState(() {
        _isLoading = true;
        if (forceRefresh) {
          _errorMessage = null;
        }
      });
    }

    try {
      final content = await _scraper.getCalendarContent(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _calendarContent = content;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load calendar.';
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

  Widget _buildCalendarContent(BuildContext context, bool isDark) {
    final events = _calendarContent?.getEventsForMonth(
          _displayedMonth.month,
          _displayedMonth.year,
        ) ??
        [];

    // Sort events by date
    final sortedEvents = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Clear and rebuild event keys
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
                // Find first event for this date and scroll to it
                final dateEvents = sortedEvents.where((e) =>
                    e.date.year == date.year &&
                    e.date.month == date.month &&
                    e.date.day == date.day).toList();
                
                if (dateEvents.isNotEmpty) {
                  final firstEvent = dateEvents.first;
                  final key = '${firstEvent.date.year}-${firstEvent.date.month}-${firstEvent.date.day}-${firstEvent.title}';
                  final eventKey = _eventKeys[key];
                  
                  if (eventKey?.currentContext != null) {
                    Scrollable.ensureVisible(
                      eventKey!.currentContext!,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              },
              onMonthChanged: (newMonth) {
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

  Widget _buildEventCard(
    BuildContext context,
    bool isDark,
    CalendarEvent event,
  ) {
    final monthName = _getMonthName(event.date.month);
    final day = event.date.day;
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

