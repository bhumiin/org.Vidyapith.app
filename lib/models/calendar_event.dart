/// Represents a single event on the calendar.
/// 
/// This class stores information about calendar events, including their date,
/// title, description, and what type of event they are (Vidyapith event,
/// holiday, or Indian calendar date).
class CalendarEvent {
  /// The date and time when this event occurs.
  final DateTime date;
  
  /// The title or name of the event (e.g., "Diwali", "Annual Day").
  final String title;
  
  /// Optional detailed description of the event.
  /// Can be null if no description is provided.
  final String? description;
  
  /// True if this is an event organized by Vidyapith.
  /// False for external events or holidays.
  final bool isVidyapithEvent;
  
  /// True if this event is a holiday (no classes or activities).
  final bool isHoliday;
  
  /// True if this date follows the Indian calendar system
  /// (e.g., Hindu lunar calendar dates).
  final bool isIndianCalendarDate;

  /// Creates a new CalendarEvent.
  /// 
  /// [date] and [title] are required - every event must have these.
  /// All other fields are optional and have default values.
  const CalendarEvent({
    required this.date,
    required this.title,
    this.description,
    this.isVidyapithEvent = false,
    this.isHoliday = false,
    this.isIndianCalendarDate = false,
  });

  /// Converts this CalendarEvent into a JSON format (Map).
  /// 
  /// This is useful for saving the event to local storage or sending it
  /// to a server. The date is converted to a string format (ISO 8601).
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'title': title,
        'description': description,
        'isVidyapithEvent': isVidyapithEvent,
        'isHoliday': isHoliday,
        'isIndianCalendarDate': isIndianCalendarDate,
      };

  /// Creates a CalendarEvent from JSON data (Map).
  /// 
  /// This is the opposite of toJson() - it takes data that was saved
  /// (like from local storage) and converts it back into a CalendarEvent object.
  /// 
  /// If the data is missing or invalid, it uses safe default values:
  /// - Missing date becomes January 1, 1970 (epoch zero)
  /// - Missing title becomes an empty string
  /// - Missing boolean flags default to false
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

/// Container class that holds all calendar events organized by month.
/// 
/// This class stores events in a map where the key is a unique month/year
/// identifier, and the value is a list of events for that month.
/// It also tracks when the calendar data was last fetched from the website.
class CalendarContent {
  /// A map that groups events by month and year.
  /// 
  /// The key is calculated as: year * 100 + month
  /// For example: March 2024 = 2024 * 100 + 3 = 202403
  /// This makes it easy to look up events for a specific month.
  final Map<int, List<CalendarEvent>> eventsByMonth;
  
  /// The timestamp when this calendar data was fetched from the website.
  /// Useful for knowing if we need to refresh the data.
  final DateTime fetchedAt;

  /// Creates a new CalendarContent object.
  const CalendarContent({
    required this.eventsByMonth,
    required this.fetchedAt,
  });

  /// Gets all events for a specific month and year.
  /// 
  /// Returns an empty list if no events exist for that month.
  /// 
  /// Example: getEventsForMonth(3, 2024) returns all events in March 2024.
  List<CalendarEvent> getEventsForMonth(int month, int year) {
    // Calculate the lookup key: 2024 * 100 + 3 = 202403
    final key = year * 100 + month;
    // Return events for that month, or empty list if none exist
    return eventsByMonth[key] ?? [];
  }

  /// Gets all events that occur on a specific date.
  /// 
  /// First gets all events for that month, then filters to only those
  /// that match the exact day. This is useful for showing events on
  /// a calendar day view.
  /// 
  /// Example: getEventsForDate(DateTime(2024, 3, 15)) returns events
  /// that occur on March 15, 2024.
  List<CalendarEvent> getEventsForDate(DateTime date) {
    // Get all events for the month
    final monthEvents = getEventsForMonth(date.month, date.year);
    // Filter to only events that match the exact day
    return monthEvents
        .where((event) =>
            event.date.year == date.year &&
            event.date.month == date.month &&
            event.date.day == date.day)
        .toList();
  }

  /// Converts this CalendarContent into JSON format for storage.
  /// 
  /// Converts the map keys (integers) to strings and converts each
  /// CalendarEvent to JSON using its toJson() method.
  Map<String, dynamic> toJson() => {
        'eventsByMonth': eventsByMonth.map(
          (key, value) => MapEntry(
            key.toString(),
            value.map((e) => e.toJson()).toList(),
          ),
        ),
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  /// Creates a CalendarContent from JSON data.
  /// 
  /// This reverses the toJson() process - it takes saved JSON data
  /// and rebuilds the CalendarContent object with all its events.
  /// 
  /// The JSON keys are strings, so we convert them back to integers
  /// to use as map keys. Each event in the list is converted back
  /// to a CalendarEvent object.
  factory CalendarContent.fromJson(Map<String, dynamic> json) {
    // Create an empty map to store the reconstructed events
    final eventsMap = <int, List<CalendarEvent>>{};
    // Get the events data from JSON, or use empty map if missing
    final eventsByMonthData = json['eventsByMonth'] as Map<String, dynamic>? ?? {};

    // Loop through each month/year in the JSON data
    eventsByMonthData.forEach((key, value) {
      // Convert the string key back to an integer (e.g., "202403" -> 202403)
      final monthKey = int.tryParse(key) ?? 0;
      // Convert each event in the list back to a CalendarEvent object
      final eventsList = (value as List<dynamic>?)
              ?.map((e) =>
                  CalendarEvent.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      // Store the events list in our map
      eventsMap[monthKey] = eventsList;
    });

    // Create and return the CalendarContent object
    return CalendarContent(
      eventsByMonth: eventsMap,
      fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Creates an empty CalendarContent with no events.
  /// 
  /// Useful when initializing the app or when there's no data available yet.
  /// The fetchedAt timestamp is set to the current time.
  static CalendarContent empty() => CalendarContent(
        eventsByMonth: {},
        fetchedAt: DateTime.now(),
      );
}

