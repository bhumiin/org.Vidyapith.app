import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/shadcn_theme.dart';
import '../../models/calendar_event.dart';

/// A customizable calendar widget that displays events and supports month navigation.
/// 
/// This widget shows a full month view with:
/// - Google Calendar sync link
/// - Month/year navigation buttons
/// - Day labels (S, M, T, W, T, F, S)
/// - Visual indicators for days with events
/// - Highlighting for today's date
/// 
/// Example usage:
/// ```dart
/// CalendarWidget(
///   displayedMonth: DateTime(2024, 1),
///   events: myEventsList,
///   onDateTapped: (date) => showEventDetails(date),
///   onMonthChanged: (newMonth) => updateMonth(newMonth),
/// )
/// ```
class CalendarWidget extends StatelessWidget {
  /// The month and year currently being displayed
  final DateTime displayedMonth;
  /// List of events to show on the calendar
  final List<CalendarEvent> events;
  /// Callback when a date with events is tapped
  final Function(DateTime) onDateTapped;
  /// Callback when user navigates to a different month (prev/next buttons)
  final Function(DateTime) onMonthChanged;

  const CalendarWidget({
    super.key,
    required this.displayedMonth,
    required this.events,
    required this.onDateTapped,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate the first and last day of the displayed month
    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    // Day 0 of next month = last day of current month
    final lastDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);
    
    // Convert weekday from 1-7 (Mon-Sun) to 0-6 (Sun-Sat) for easier grid positioning
    // weekday returns 1 (Monday) to 7 (Sunday), convert to 0 (Sunday) to 6 (Saturday)
    final firstDayOfWeek = (firstDayOfMonth.weekday % 7);
    
    // Build the list of days to display in the calendar grid
    // This includes days from previous month (to fill the first week) and
    // days from next month (to fill the last week)
    final daysToShow = <DateTime>[];
    
    // Add previous month's trailing days (to fill the first week)
    // For example, if month starts on Wednesday, add Sun, Mon, Tue from previous month
    for (int i = firstDayOfWeek - 1; i >= 0; i--) {
      daysToShow.add(firstDayOfMonth.subtract(Duration(days: i + 1)));
    }
    
    // Add all days of the current month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      daysToShow.add(DateTime(displayedMonth.year, displayedMonth.month, day));
    }
    
    // Add next month's leading days to fill the remaining grid slots
    // Calendar grid is 6 weeks × 7 days = 42 days total
    final remainingDays = 42 - daysToShow.length;
    for (int day = 1; day <= remainingDays; day++) {
      daysToShow.add(DateTime(displayedMonth.year, displayedMonth.month + 1, day));
    }

    final today = DateTime.now();
    final monthName = _getMonthName(displayedMonth.month);
    final year = displayedMonth.year;

    return Column(
      children: [
        // Google Calendar sync link
        _buildSyncLink(context, isDark),
        const SizedBox(height: ShadCNTheme.space3),
        // Month navigation header
        _buildMonthHeader(context, isDark, monthName, year),
        const SizedBox(height: ShadCNTheme.space4),
        // Day labels
        _buildDayLabels(context, isDark),
        const SizedBox(height: ShadCNTheme.space2),
        // Calendar grid
        _buildCalendarGrid(
          context,
          isDark,
          daysToShow,
          displayedMonth,
          today,
        ),
      ],
    );
  }

  /// Builds the "Sync with Google Calendar" link button at the top of the calendar
  Widget _buildSyncLink(BuildContext context, bool isDark) {
    return Center(
      child: InkWell(
        onTap: () => _syncWithGoogleCalendar(context), // Open Google Calendar when tapped
        borderRadius: BorderRadius.circular(ShadCNTheme.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ShadCNTheme.space3,
            vertical: ShadCNTheme.space2,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0B73DA).withOpacity(0.1)
                : const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(ShadCNTheme.radius),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF0B73DA).withOpacity(0.3)
                  : const Color(0xFF0B73DA).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sync,
                size: 16,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA),
              ),
              const SizedBox(width: ShadCNTheme.space2),
              Text(
                'Sync with Google Calendar',
                style: TextStyle(
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA),
                  fontSize: ShadCNTheme.textSm,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the Vidyapith Google Calendar in an external browser
  /// Shows an error message if the calendar cannot be opened
  Future<void> _syncWithGoogleCalendar(BuildContext context) async {
    // Google Calendar public URL for Vidyapith events
    const googleCalendarUrl =
        'https://calendar.google.com/calendar/u/1?cid=Y185NjlmODM4YzQ3YTFhNDA1YmIxOWU0Yzg1MTIyOWQyZDMyOGUwMzQxYzgzMjExNGIwMDUwNjM2MjE0OTM4MDRlQGdyb3VwLmNhbGVuZGFyLmdvb2dsZS5jb20';

    final uri = Uri.parse(googleCalendarUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open Google Calendar. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Google Calendar. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Builds the month navigation header with previous/next buttons and month/year display
  Widget _buildMonthHeader(
    BuildContext context,
    bool isDark,
    String monthName,
    int year,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous month button
        IconButton(
          onPressed: () {
            final prevMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
            onMonthChanged(prevMonth); // Notify parent to update the month
          },
          icon: Icon(
            Icons.chevron_left,
            color: isDark ? Colors.white : const Color(0xFF424242),
          ),
        ),
        Text(
          '$monthName $year',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF424242),
            fontSize: ShadCNTheme.textXl,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Next month button
        IconButton(
          onPressed: () {
            final nextMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
            onMonthChanged(nextMonth); // Notify parent to update the month
          },
          icon: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white : const Color(0xFF424242),
          ),
        ),
      ],
    );
  }

  /// Builds the day labels row (Sunday through Saturday)
  Widget _buildDayLabels(BuildContext context, bool isDark) {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    return Row(
      children: dayLabels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                fontSize: ShadCNTheme.textSm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the calendar grid with all days of the month
  Widget _buildCalendarGrid(
    BuildContext context,
    bool isDark,
    List<DateTime> days,
    DateTime displayedMonth,
    DateTime today,
  ) {
    return GridView.builder(
      shrinkWrap: true, // Only take up needed space
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling (parent handles it)
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 7 columns for 7 days of the week
        mainAxisSpacing: ShadCNTheme.space1,
        crossAxisSpacing: ShadCNTheme.space1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        // Check if this date is in the currently displayed month
        final isCurrentMonth = date.month == displayedMonth.month;
        // Check if this date is today
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        // Find all events for this specific day
        final dayEvents = events.where((e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day).toList();

        return _buildDayCell(
          context,
          isDark,
          date,
          isCurrentMonth,
          isToday,
          dayEvents,
        );
      },
    );
  }

  /// Builds a single day cell in the calendar grid
  /// Shows the day number, highlights today, and shows event indicators
  Widget _buildDayCell(
    BuildContext context,
    bool isDark,
    DateTime date,
    bool isCurrentMonth,
    bool isToday,
    List<CalendarEvent> dayEvents,
  ) {
    final hasEvents = dayEvents.isNotEmpty;
    
    return GestureDetector(
      // Only allow tapping if there are events on this day
      onTap: hasEvents ? () => onDateTapped(date) : null,
      child: Container(
        decoration: BoxDecoration(
          // Highlight today's date with a blue background
          color: isToday
              ? (isDark
                  ? const Color(0xFF0B73DA).withOpacity(0.3)
                  : const Color(0xFF0B73DA).withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ShadCNTheme.radius),
          // Add a border around today's date
          border: isToday
              ? Border.all(
                  color: const Color(0xFF0B73DA),
                  width: 2,
                )
              : null,
        ),
        padding: const EdgeInsets.all(ShadCNTheme.space1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isCurrentMonth
                    ? (isToday
                        ? const Color(0xFF0B73DA)
                        : (isDark ? Colors.white : const Color(0xFF424242)))
                    : (isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF)),
                fontSize: ShadCNTheme.textSm,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // Show a small dot indicator if there are events on this day
            // Red dot for Vidyapith events, blue dot for other events
            if (hasEvents)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: dayEvents.any((e) => e.isVidyapithEvent)
                      ? const Color(0xFFEF4444) // Red for Vidyapith events
                      : const Color(0xFF0B73DA), // Blue for other events
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Converts a month number (1-12) to its full name
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

