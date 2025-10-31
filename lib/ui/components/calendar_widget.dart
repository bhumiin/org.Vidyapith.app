import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/shadcn_theme.dart';
import '../../models/calendar_event.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime displayedMonth;
  final List<CalendarEvent> events;
  final Function(DateTime) onDateTapped;
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
    
    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);
    // weekday returns 1 (Monday) to 7 (Sunday), convert to 0 (Sunday) to 6 (Saturday)
    final firstDayOfWeek = (firstDayOfMonth.weekday % 7);
    
    // Calculate days to show (including previous month's trailing days)
    final daysToShow = <DateTime>[];
    
    // Add previous month's trailing days
    for (int i = firstDayOfWeek - 1; i >= 0; i--) {
      daysToShow.add(firstDayOfMonth.subtract(Duration(days: i + 1)));
    }
    
    // Add current month's days
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      daysToShow.add(DateTime(displayedMonth.year, displayedMonth.month, day));
    }
    
    // Add next month's leading days to fill the grid
    final remainingDays = 42 - daysToShow.length; // 6 weeks * 7 days
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

  Widget _buildSyncLink(BuildContext context, bool isDark) {
    return Center(
      child: InkWell(
        onTap: () => _syncWithGoogleCalendar(context),
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

  Future<void> _syncWithGoogleCalendar(BuildContext context) async {
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

  Widget _buildMonthHeader(
    BuildContext context,
    bool isDark,
    String monthName,
    int year,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            final prevMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
            onMonthChanged(prevMonth);
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
        IconButton(
          onPressed: () {
            final nextMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
            onMonthChanged(nextMonth);
          },
          icon: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white : const Color(0xFF424242),
          ),
        ),
      ],
    );
  }

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

  Widget _buildCalendarGrid(
    BuildContext context,
    bool isDark,
    List<DateTime> days,
    DateTime displayedMonth,
    DateTime today,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: ShadCNTheme.space1,
        crossAxisSpacing: ShadCNTheme.space1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        final isCurrentMonth = date.month == displayedMonth.month;
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
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
      onTap: hasEvents ? () => onDateTapped(date) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? (isDark
                  ? const Color(0xFF0B73DA).withOpacity(0.3)
                  : const Color(0xFF0B73DA).withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ShadCNTheme.radius),
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
            if (hasEvents)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: dayEvents.any((e) => e.isVidyapithEvent)
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0B73DA),
                  shape: BoxShape.circle,
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

