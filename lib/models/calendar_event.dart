class CalendarEvent {
  final DateTime date;
  final String title;
  final String? description;
  final bool isVidyapithEvent;
  final bool isHoliday;
  final bool isIndianCalendarDate;

  const CalendarEvent({
    required this.date,
    required this.title,
    this.description,
    this.isVidyapithEvent = false,
    this.isHoliday = false,
    this.isIndianCalendarDate = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'title': title,
        'description': description,
        'isVidyapithEvent': isVidyapithEvent,
        'isHoliday': isHoliday,
        'isIndianCalendarDate': isIndianCalendarDate,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        isVidyapithEvent: json['isVidyapithEvent'] as bool? ?? false,
        isHoliday: json['isHoliday'] as bool? ?? false,
        isIndianCalendarDate: json['isIndianCalendarDate'] as bool? ?? false,
      );
}

class CalendarContent {
  final Map<int, List<CalendarEvent>> eventsByMonth;
  final DateTime fetchedAt;

  const CalendarContent({
    required this.eventsByMonth,
    required this.fetchedAt,
  });

  List<CalendarEvent> getEventsForMonth(int month, int year) {
    final key = year * 100 + month;
    return eventsByMonth[key] ?? [];
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    final monthEvents = getEventsForMonth(date.month, date.year);
    return monthEvents
        .where((event) =>
            event.date.year == date.year &&
            event.date.month == date.month &&
            event.date.day == date.day)
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'eventsByMonth': eventsByMonth.map(
          (key, value) => MapEntry(
            key.toString(),
            value.map((e) => e.toJson()).toList(),
          ),
        ),
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory CalendarContent.fromJson(Map<String, dynamic> json) {
    final eventsMap = <int, List<CalendarEvent>>{};
    final eventsByMonthData = json['eventsByMonth'] as Map<String, dynamic>? ?? {};

    eventsByMonthData.forEach((key, value) {
      final monthKey = int.tryParse(key) ?? 0;
      final eventsList = (value as List<dynamic>?)
              ?.map((e) =>
                  CalendarEvent.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      eventsMap[monthKey] = eventsList;
    });

    return CalendarContent(
      eventsByMonth: eventsMap,
      fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static CalendarContent empty() => CalendarContent(
        eventsByMonth: {},
        fetchedAt: DateTime.now(),
      );
}

