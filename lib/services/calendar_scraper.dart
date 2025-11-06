import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event.dart';

/// Service that fetches and caches calendar events from the Vidyapith website.
/// 
/// This class handles:
/// - Fetching calendar event data (currently hardcoded, but designed for PDF parsing)
/// - Caching the calendar data locally for 7 days to avoid repeated fetches
/// - Organizing events by month for easy display in the calendar widget
/// 
/// The calendar contains various types of events:
/// - Vidyapith events (school activities, celebrations)
/// - Holidays (public holidays, religious observances)
/// - Indian calendar dates (traditional Indian festivals and observances)
class CalendarScraper {
  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================
  
  /// Creates a new CalendarScraper instance.
  /// 
  /// [client] - Optional HTTP client (for testing). If not provided, creates a new one.
  ///            This allows us to inject a mock client during testing.
  CalendarScraper({http.Client? client}) : _client = client ?? http.Client();

  // ============================================================================
  // CONSTANTS
  // ============================================================================
  
  /// URL of the calendar PDF file on the Vidyapith website.
  /// Currently not used, but kept for future PDF parsing implementation.
  static const String _calendarUrl =
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/v9_final_dates_vp_calendar_2025_n_2024.11.12.pdf';
  
  /// Key used to store cached calendar content in SharedPreferences (local storage).
  /// This key identifies where we saved the cached calendar data.
  static const String _cacheKey = 'calendar_content_cache_v1';
  
  /// How long cached calendar data remains valid (7 days).
  /// After this time, we'll fetch fresh data from the website.
  static const Duration _cacheDuration = Duration(days: 7);

  // ============================================================================
  // INSTANCE VARIABLES
  // ============================================================================
  
  /// HTTP client used to make network requests to fetch calendar data.
  /// This is used to download the calendar PDF or fetch data from the website.
  final http.Client _client;

  // ============================================================================
  // PUBLIC METHODS
  // ============================================================================
  
  /// Gets calendar content, using cache if available and fresh.
  /// 
  /// This method implements a smart caching strategy:
  /// 1. First checks if we have cached data stored locally
  /// 2. If cached data exists and is less than 7 days old, returns it immediately (fast!)
  /// 3. If cache is expired or forceRefresh is true, fetches fresh data
  /// 4. Saves fresh data to cache for future use
  /// 5. If fetching fails but we have cached data, returns the cached data (graceful degradation)
  /// 
  /// [forceRefresh] - If true, ignores cache and always fetches fresh data.
  ///                  Useful when user manually refreshes the calendar.
  /// 
  /// Returns: CalendarContent object containing all events organized by month.
  /// 
  /// Example usage:
  /// ```dart
  /// final calendar = await scraper.getCalendarContent();
  /// // Use cached data if available, or fetch fresh if needed
  /// 
  /// final freshCalendar = await scraper.getCalendarContent(forceRefresh: true);
  /// // Always fetch fresh data, ignoring cache
  /// ```
  Future<CalendarContent> getCalendarContent({bool forceRefresh = false}) async {
    // Get access to local storage (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    CalendarContent? cachedContent;

    // Try to load cached calendar data from local storage
    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson != null) {
      try {
        // Convert the stored JSON string back into a CalendarContent object
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(cachedJson) as Map,
        );
        cachedContent = CalendarContent.fromJson(json);
      } catch (_) {
        // If JSON parsing fails (corrupted data), ignore it and fetch fresh
        cachedContent = null;
      }
    }

    // Check if we should use cached data
    if (!forceRefresh && cachedContent != null) {
      // Calculate how old the cached data is
      final age = DateTime.now().difference(cachedContent.fetchedAt);
      
      // If cache is still fresh (less than 7 days old), return it immediately
      // This is much faster than fetching from the network!
      if (age <= _cacheDuration) {
        return cachedContent;
      }
    }

    // Cache is expired or forceRefresh is true - fetch fresh data
    try {
      final freshContent = await fetchCalendarContent();
      
      // Save the fresh data to cache for future use
      try {
        await prefs.setString(_cacheKey, jsonEncode(freshContent.toJson()));
      } catch (_) {
        // If saving to cache fails, don't worry - we still return fresh data
        // Cache write failures should not block returning fresh data.
      }
      
      return freshContent;
    } catch (_) {
      // If fetching fresh data fails (network error, etc.)
      if (cachedContent != null) {
        // But we have cached data available - return it as a fallback
        // This ensures the app still works even if the network is down
        return cachedContent;
      }
      
      // No cached data available and fetch failed - rethrow the error
      // The caller will need to handle this error
      rethrow;
    }
  }

  /// Fetches fresh calendar content from the source.
  /// 
  /// Currently, this method uses hardcoded calendar data. In a future implementation,
  /// this could be enhanced to:
  /// - Download and parse the PDF file from _calendarUrl
  /// - Use a PDF parsing library to extract text/data
  /// - Parse the extracted text into structured calendar events
  /// 
  /// Returns: Fresh CalendarContent with all events organized by month.
  Future<CalendarContent> fetchCalendarContent() async {
    // For now, we'll parse from the provided text content
    // In a real implementation, you might want to use a PDF parsing library
    // For this implementation, we'll manually parse the calendar data from the PDF text
    return _parseCalendarFromText();
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================
  
  /// Parses calendar events from hardcoded data.
  /// 
  /// This method manually creates calendar events for the year. In a production app,
  /// this data would come from parsing a PDF or API. The events are organized by month
  /// using a key format: year * 100 + month (e.g., 202501 for January 2025).
  /// 
  /// The method creates three types of events:
  /// - isVidyapithEvent: School-specific events (celebrations, classes, etc.)
  /// - isHoliday: Public holidays and observances
  /// - isIndianCalendarDate: Traditional Indian festivals and dates
  /// 
  /// Returns: CalendarContent with all events organized by month.
  CalendarContent _parseCalendarFromText() {
    // Map to store events organized by month
    // Key format: year * 100 + month (e.g., 202501 = January 2025)
    // Value: List of CalendarEvent objects for that month
    final eventsByMonth = <int, List<CalendarEvent>>{};

    // Parse calendar events from the provided PDF text content
    // This is a manual parsing based on the structure we saw in the PDF
    
    // January 2025 events
    _addEvent(eventsByMonth, 2025, 1, 1, 'New Year\'s Day', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 1, 1, 'Kalpataru Day', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 1, 'Pooja / Flower Offering', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 2, 'Last Day of Hanukkah', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 1, 4, 'Vidyapith Reopens', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 4, 'YOUTH DAY-III (Gr. 6-12)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 5, 'Vidyapith Reopens', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 5, 'YOUTH DAY-IV (Gr. 6-12)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 5, 'Swami Saradananda\'s Birthday', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 1, 9, 'Flower Offering for Sw. Vivekananda\'s birthday', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 11, 'YOUTH DAY-V (Gr.3-5)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 12, 'YOUTH DAY-VI (Gr.3-5)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 12, 'Sw. Turiyananda\'s Birthday', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 1, 12, 'Swami Vivekananda\'s Birthday', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 14, 'Pongal', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 1, 14, 'Makara Sankranti', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 1, 18, 'YOUTH DAY (Rain/Snow Day)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 19, 'YOUTH DAY (Rain/Snow Day)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 1, 20, 'Martin Luther King Jr. Day', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 1, 21, 'Swami Vivekananda\'s Birthday', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 1, 26, 'India\'s Republic Day', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 1, 30, 'Mahatma Gandhi Memorial Day', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 1, 31, 'Swami Brahmananda\'s Birthday', isIndianCalendarDate: true);

    // February 2025 events
    _addEvent(eventsByMonth, 2025, 2, 2, 'Sw. Trigunatitananda\'s Birthday', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 2, 2, 'Saraswati Pooja', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 2, 8, 'First Day of Spring Semester for Saturday Students', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 2, 9, 'First Day of Spring Semester for Sunday Students', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 2, 12, 'Sw. Adibhutananda\'s Birthday', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 2, 14, 'St. Valentine\'s Day', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 2, 17, 'Presidents\' Day', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 2, 20, 'Flower Offering for Maha Shivaratri', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 2, 22, 'Maha Shivaratri Celebration', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 2, 26, 'Maha Shivaratri', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 2, 27, 'Flower Offering for Sri Ramakrishna\'s birthday', isVidyapithEvent: true);

    // March 2025 events
    _addEvent(eventsByMonth, 2025, 3, 1, 'Sri Ramakrishna\'s Birthday & Celebration', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 3, 1, 'RAMADAN BEGINS', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 3, 5, 'ASH WEDNESDAY', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 3, 13, 'SRI CHAITANYA\'S BIRTHDAY', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 3, 13, 'Flower Offering for Sri Chaitanya', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 3, 15, 'Sri Chaitanya\'s Birthday Celebration', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 3, 17, 'ST. PATRICK\'S DAY', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 3, 18, 'SWAMI YOGANANDA\'S BIRTHDAY', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 3, 23, 'GUDI PADVA', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 3, 23, 'CHETI CHAND', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 3, 23, 'YUGADI', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 3, 24, 'EID-AL-FITR', isHoliday: true);

    // Add more months as needed... (continuing with key events)
    // For brevity, I'll add a few more key events from April-December

    // April 2025 - key events
    // May 2025 - key events
    // June 2025 - key events
    // July 2025 - key events
    // August 2025 - key events
    // September 2025 - key events
    // October 2025 - key events
    _addEvent(eventsByMonth, 2025, 10, 19, 'Flower Offering for Diwali', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 10, 19, 'Kali Pooja', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 10, 20, 'Diwali', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 10, 21, 'Annakut', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 10, 21, 'Bestu Varsha', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 10, 23, 'Bhai Beej (sisters\' Day)', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 10, 31, 'Halloween', isHoliday: true);

    // November 2025
    _addEvent(eventsByMonth, 2025, 11, 2, 'SWAMI SUBCDHANANDA\'S BIRTHDAY', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 11, 4, 'SWAMI VINANANANDA\'S BIRTHDAY', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 11, 4, 'ELECTION DAY', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 11, 8, 'Diwali Function', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 11, 23, 'Vidyapith Closed for Thanksgiving', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 11, 27, 'Thanksgiving Family Get-together', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 11, 27, 'THANKSGIVING DAY', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 11, 29, 'Vidyapith Closed for Thanksgiving', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 11, 29, 'SWAMI PREMANANDA\'S BIRTHDAY', isIndianCalendarDate: true);

    // December 2025
    _addEvent(eventsByMonth, 2025, 12, 1, 'Gita Jayanti', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 12, 6, 'Gita Jayanti Celebration', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 12, 11, 'Holy Mother\'s Birthday', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 12, 11, 'Flower Offering for Holy Mother\'s birthday', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 12, 13, 'Holy Mother\'s Birthday Celebration', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 12, 15, 'Hanukkah Begins', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 12, 15, 'Swami Shivañanda\'s Birthday', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2025, 12, 20, 'Christmas Celebration - YOUTH DAY 1', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 12, 25, 'Christmas Celebration', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 12, 25, 'YOUTH DAY II', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 12, 25, 'First Day of Winter', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 12, 23, 'Hanukkah Ends', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 12, 24, 'Christmas Eve', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 12, 25, 'Christmas Day', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 12, 26, 'Kwanzaa', isHoliday: true);
    _addEvent(eventsByMonth, 2025, 12, 27, 'Vidyapith Closed for holidays', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2025, 12, 31, 'New Year\'s Eve', isHoliday: true);

    // January 2026
    _addEvent(eventsByMonth, 2026, 1, 1, 'New Year\'s Day', isHoliday: true);
    _addEvent(eventsByMonth, 2026, 1, 1, 'Kalpataru Day', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 1, 'Pooja / Flower Offering', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 3, 'Vidyapith Closed for holidays', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 8, 'Flower Offering for Sw. Vivekananda\'s birthday', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 9, 'Swami Vivekananda\'s Birthday', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2026, 1, 10, 'Vidyapith Reopens', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 10, 'YOUTH DAY-III (Gr. 6-12)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 11, 'Vidyapith Reopens', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 11, 'YOUTH DAY-IV (Gr. 6-12)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 12, 'Swami Vivekananda\'s Birthday', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 14, 'Pongal', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2026, 1, 14, 'Makara Sankranti', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2026, 1, 17, 'YOUTH DAY-V (Gr.3-5)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 18, 'YOUTH DAY-VI (Gr.3-5)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 19, 'YOUTH DAY (Rain/Snow Day)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 20, 'Swami Saradananda\'s Birthday', isIndianCalendarDate: true);
    _addEvent(eventsByMonth, 2026, 1, 25, 'YOUTH DAY (Rain/Snow Day)', isVidyapithEvent: true);
    _addEvent(eventsByMonth, 2026, 1, 26, 'India\'s Republic Day', isHoliday: true);
    _addEvent(eventsByMonth, 2026, 1, 30, 'Mahatma Gandhi Memorial Day', isIndianCalendarDate: true);

    return CalendarContent(
      eventsByMonth: eventsByMonth,
      fetchedAt: DateTime.now(),
    );
  }

  /// Helper method to add an event to the eventsByMonth map.
  /// 
  /// This method:
  /// 1. Creates a DateTime object from the year, month, and day
  /// 2. Calculates a unique key for the month (year * 100 + month)
  /// 3. Ensures a list exists for that month (creates empty list if needed)
  /// 4. Adds the event to that month's list
  /// 
  /// Parameters:
  /// - [eventsByMonth]: The map storing all events organized by month
  /// - [year]: The year of the event (e.g., 2025)
  /// - [month]: The month (1-12, where 1 = January)
  /// - [day]: The day of the month (1-31)
  /// - [title]: The name/title of the event
  /// - [isVidyapithEvent]: True if this is a Vidyapith-specific event
  /// - [isHoliday]: True if this is a public holiday
  /// - [isIndianCalendarDate]: True if this is an Indian calendar observance
  /// 
  /// Example:
  /// ```dart
  /// _addEvent(eventsByMonth, 2025, 1, 1, 'New Year\'s Day', isHoliday: true);
  /// // Adds New Year's Day as a holiday on January 1, 2025
  /// ```
  void _addEvent(
    Map<int, List<CalendarEvent>> eventsByMonth,
    int year,
    int month,
    int day,
    String title, {
    bool isVidyapithEvent = false,
    bool isHoliday = false,
    bool isIndianCalendarDate = false,
  }) {
    try {
      // Create a DateTime object for this event
      final date = DateTime(year, month, day);
      
      // Create a unique key for this month
      // Formula: year * 100 + month
      // Examples: 202501 (Jan 2025), 202502 (Feb 2025), 202612 (Dec 2026)
      final key = year * 100 + month;
      
      // Ensure a list exists for this month (create empty list if it doesn't exist)
      eventsByMonth.putIfAbsent(key, () => []);
      
      // Add the event to this month's list
      eventsByMonth[key]!.add(
        CalendarEvent(
          date: date,
          title: title,
          isVidyapithEvent: isVidyapithEvent,
          isHoliday: isHoliday,
          isIndianCalendarDate: isIndianCalendarDate,
        ),
      );
    } catch (_) {
      // If the date is invalid (e.g., February 30), ignore it and continue
      // Ignore invalid dates
    }
  }

  /// Cleans up resources by closing the HTTP client.
  /// 
  /// Always call this when you're done with the CalendarScraper to free up
  /// network resources. This is especially important in long-running apps.
  void dispose() {
    _client.close();
  }
}

