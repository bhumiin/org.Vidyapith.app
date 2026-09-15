import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/vidyapith_urls.dart';
import '../models/calendar_event.dart';

/// Service that fetches and caches calendar events from the Vidyapith
/// Google Calendar public ICS feed.
///
/// Events are cached locally for 7 days. On network failure, a stale cache
/// is returned when available.
class CalendarScraper {
  /// Creates a new [CalendarScraper].
  ///
  /// [client] may be injected for tests; otherwise a new [http.Client] is used.
  CalendarScraper({http.Client? client}) : _client = client ?? http.Client();

  /// Yearly calendar HTML page URL (bookstore / printed calendar info).
  static String get calendarUrl => vidyapithCalendarPageUrl();

  /// Public ICS feed used to load in-app events.
  static String get icsUrl => vidyapithGoogleCalendarIcsUrl;

  /// Bumped when the data source or event shape changes so stale caches
  /// are not reused after upgrades.
  static const String _cacheKey = 'calendar_content_cache_v2';

  static const Duration _cacheDuration = Duration(days: 7);

  final http.Client _client;

  /// Returns calendar content from cache when fresh, otherwise fetches ICS.
  ///
  /// When [forceRefresh] is true, cache age is ignored.
  Future<CalendarContent> getCalendarContent({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    CalendarContent? cachedContent;

    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(cachedJson) as Map,
        );
        cachedContent = CalendarContent.fromJson(json);
      } catch (_) {
        cachedContent = null;
      }
    }

    if (!forceRefresh && cachedContent != null) {
      final age = DateTime.now().difference(cachedContent.fetchedAt);
      if (age <= _cacheDuration) {
        return cachedContent;
      }
    }

    try {
      final freshContent = await fetchCalendarContent();
      try {
        await prefs.setString(_cacheKey, jsonEncode(freshContent.toJson()));
      } catch (_) {
        // Cache write failures should not block returning fresh data.
      }
      return freshContent;
    } catch (_) {
      if (cachedContent != null) {
        return cachedContent;
      }
      rethrow;
    }
  }

  /// Downloads the public ICS feed and parses it into [CalendarContent].
  Future<CalendarContent> fetchCalendarContent() async {
    final uri = Uri.parse(icsUrl);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load calendar ICS (status: ${response.statusCode})',
        uri,
      );
    }

    final body = utf8.decode(response.bodyBytes);
    return parseIcsToCalendarContent(body);
  }

  /// Closes the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}

/// Parses an ICS document string into [CalendarContent].
///
/// Exposed for unit tests. [fetchedAt] defaults to now.
CalendarContent parseIcsToCalendarContent(
  String ics, {
  DateTime? fetchedAt,
}) {
  final calendar = ICalendar.fromString(ics);
  final eventsByMonth = <int, List<CalendarEvent>>{};

  for (final item in calendar.data) {
    if (item['type'] != 'VEVENT') continue;

    final title = (item['summary'] as String?)?.trim();
    if (title == null || title.isEmpty) continue;

    final startRaw = item['dtstart'];
    final DateTime? startUtcOrLocal = startRaw is IcsDateTime
        ? startRaw.toDateTime()
        : (startRaw is String ? DateTime.tryParse(startRaw) : null);
    if (startUtcOrLocal == null) continue;

    // Timed UTC events → local calendar day; all-day dates stay as calendar dates.
    final local = startUtcOrLocal.isUtc ? startUtcOrLocal.toLocal() : startUtcOrLocal;
    final date = DateTime(local.year, local.month, local.day);

    final description = _firstNonEmpty([
      item['description'] as String?,
      item['location'] as String?,
    ]);

    final lowerTitle = title.toLowerCase();
    final isHoliday = lowerTitle.contains('holiday') ||
        lowerTitle.contains('no classes') ||
        lowerTitle.contains('closed');

    final key = date.year * 100 + date.month;
    eventsByMonth.putIfAbsent(key, () => []);
    eventsByMonth[key]!.add(
      CalendarEvent(
        date: date,
        title: title,
        description: description,
        isVidyapithEvent: true,
        isHoliday: isHoliday,
      ),
    );
  }

  for (final events in eventsByMonth.values) {
    events.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.title.compareTo(b.title);
    });
  }

  return CalendarContent(
    eventsByMonth: eventsByMonth,
    fetchedAt: fetchedAt ?? DateTime.now(),
  );
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
