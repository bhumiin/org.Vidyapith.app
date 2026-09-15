import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/website_content.dart';

/// Weekday + optional second weekday + comma + month + day.
///
/// Used to find where each upcoming event starts inside a single text blob.
final RegExp upcomingEventStartPattern = RegExp(
  r'(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)'
  r'(?:\s*&\s*(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday))?,'
  r'\s*(?:January|February|March|April|May|June|July|August|September|October|November|December)'
  r'\s+\d{1,2}',
  caseSensitive: false,
);

const Map<String, int> _monthNameToNumber = {
  'january': 1,
  'february': 2,
  'march': 3,
  'april': 4,
  'may': 5,
  'june': 6,
  'july': 7,
  'august': 8,
  'september': 9,
  'october': 10,
  'november': 11,
  'december': 12,
};

/// Splits a single line/blob that may contain multiple events into entries.
///
/// Looks for boundaries matching [upcomingEventStartPattern] so titles that
/// mention weekdays without a following month (e.g. "Saturday 6th") stay intact.
List<String> splitUpcomingEventBlob(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];

  final matches = upcomingEventStartPattern.allMatches(trimmed).toList();
  if (matches.isEmpty) {
    return [trimmed];
  }
  if (matches.length == 1 && matches.first.start == 0) {
    return [trimmed];
  }

  final parts = <String>[];
  for (var i = 0; i < matches.length; i++) {
    final start = matches[i].start;
    final end = i + 1 < matches.length ? matches[i + 1].start : trimmed.length;
    final part = trimmed.substring(start, end).trim();
    if (part.isNotEmpty) {
      parts.add(part);
    }
  }
  return parts.isEmpty ? [trimmed] : parts;
}

/// Expands collected lines so multi-event paragraphs become separate entries.
List<String> expandUpcomingEventLines(List<String> lines) {
  final expanded = <String>[];
  for (final line in lines) {
    expanded.addAll(splitUpcomingEventBlob(line));
  }
  return expanded;
}

/// Parses an event entry string into [UpcomingEvent].
///
/// Uses the first ` - ` as the details/title separator so titles may still
/// contain additional dashes (e.g. anniversary notes).
UpcomingEvent upcomingEventFromEntry(String entry) {
  final separator = entry.indexOf(' - ');
  if (separator < 0) {
    return UpcomingEvent(title: entry.trim());
  }
  final details = entry.substring(0, separator).trim();
  final title = entry.substring(separator + 3).trim();
  return UpcomingEvent(
    title: title,
    details: details.isNotEmpty ? details : null,
  );
}

/// Parses the calendar date (and optional start time) for sorting/filtering.
///
/// Returns null when no valid month/day can be found.
DateTime? parseUpcomingEventSortDate(
  UpcomingEvent event, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final currentYear = reference.year;
  final currentMonth = reference.month;
  final currentDay = reference.day;
  final eventText = '${event.details ?? ''} ${event.title}'.toLowerCase();

  final dateMatch = RegExp(
    r'(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:\s*,\s*(\d{4}))?',
    caseSensitive: false,
  ).firstMatch(eventText);

  if (dateMatch == null) return null;

  final monthName = dateMatch.group(1)!.toLowerCase();
  final day = int.tryParse(dateMatch.group(2) ?? '');
  if (day == null || day < 1 || day > 31) return null;

  final month = _monthNameToNumber[monthName];
  if (month == null) return null;

  final yearStr = dateMatch.group(3);
  int year;
  if (yearStr != null && yearStr.isNotEmpty) {
    year = int.tryParse(yearStr) ?? currentYear;
  } else {
    year = currentYear;
    if (month < currentMonth ||
        (month == currentMonth && day < currentDay)) {
      year = currentYear + 1;
    }
  }

  var hour = 0;
  var minute = 0;
  final timeMatch = RegExp(
    r'(\d{1,2}):(\d{2})\s*(am|pm)',
    caseSensitive: false,
  ).firstMatch(eventText);
  if (timeMatch != null) {
    var h = int.tryParse(timeMatch.group(1)!) ?? 0;
    final m = int.tryParse(timeMatch.group(2)!) ?? 0;
    final period = timeMatch.group(3)!.toLowerCase();
    if (period == 'pm' && h < 12) h += 12;
    if (period == 'am' && h == 12) h = 0;
    hour = h;
    minute = m;
  }

  try {
    return DateTime(year, month, day, hour, minute);
  } catch (_) {
    return null;
  }
}

/// Filters past events and sorts remaining ones soonest-first.
List<UpcomingEvent> filterAndSortUpcomingEvents(
  Iterable<UpcomingEvent> events, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);

  final dated = <({UpcomingEvent event, DateTime sortDate})>[];
  for (final event in events) {
    final sortDate = parseUpcomingEventSortDate(event, now: reference);
    if (sortDate == null) continue;
    final eventDay = DateTime(sortDate.year, sortDate.month, sortDate.day);
    if (eventDay.isBefore(today)) continue;
    dated.add((event: event, sortDate: sortDate));
  }

  dated.sort((a, b) => a.sortDate.compareTo(b.sortDate));
  return dated.map((e) => e.event).toList(growable: false);
}

/// Service that scrapes (extracts) content from the Vidyapith website.
/// 
/// Web scraping means downloading HTML pages and extracting specific information
/// from them (like text, images, links, etc.). This class:
/// 
/// - Downloads HTML pages from various Vidyapith website URLs
/// - Parses the HTML to extract specific content (events, classes, contact info, etc.)
/// - Caches the extracted data locally to avoid repeated network requests
/// - Handles errors gracefully by falling back to cached data when available
/// 
/// The scraper supports multiple content types:
/// - Homepage content (thought of the day, upcoming events, carousel images)
/// - Events page content
/// - Bookstore information
/// - Donation information
/// - Admissions information
/// - Contact information
/// - Class information (curricular, music, summer camp)
class WebsiteScraper {
  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================
  
  /// Creates a new WebsiteScraper instance.
  /// 
  /// [client] - Optional HTTP client (for testing). If not provided, creates a new one.
  ///            This allows us to inject a mock client during testing.
  WebsiteScraper({http.Client? client}) : _client = client ?? http.Client();

  // ============================================================================
  // CONSTANTS - Website URLs
  // ============================================================================
  // These are the URLs of different pages on the Vidyapith website that we scrape.
  
  /// Main homepage URL
  static const String _homepageUrl = 'https://www.vidyapith.org/';
  
  /// URL for the curricular classes page
  static const String _curricularClassesUrl =
      'https://www.vidyapith.org/curricular-classes.html';
  
  /// URL for the music classes page
  static const String _musicClassesUrl =
      'https://www.vidyapith.org/music-classes.html';
  
  /// URL for the summer camp page
  static const String _summerCampUrl =
      'https://www.vidyapith.org/summer-camp.html';
  
  /// URL for the events page
  static const String _eventsUrl = 'https://www.vidyapith.org/events.html';
  
  /// URL for the bookstore page
  static const String _bookstoreUrl =
      'https://www.vidyapith.org/bookstore.html';
  
  /// URL for the donation page
  static const String _donateUrl = 'https://www.vidyapith.org/donate.html';
  
  /// URL for the admissions page
  static const String _admissionsUrl =
      'https://www.vidyapith.org/admissions1.html';
  
  /// URL for the contact page
  static const String _contactUrl =
      'https://www.vidyapith.org/contact-us1.html';

  /// URL for the archives page
  static const String _archivesUrl =
      'https://www.vidyapith.org/archives.html';

  // ============================================================================
  // CONSTANTS - Cache Keys
  // ============================================================================
  // These keys identify where we store cached data in local storage (SharedPreferences).
  // Each content type has its own cache key so they can be stored separately.
  
  /// Cache key for homepage content (thought of the day, events, images).
  /// v5 invalidates caches that stored upcoming events as a single merged entry.
  static const String _cacheKey = 'website_content_cache_v5';
  
  /// Cache key for events page content
  static const String _eventsCacheKey = 'events_content_cache_v1';
  
  /// Cache key for bookstore content.
  /// v2 invalidates caches that flattened `<br>` breaks and missed Cloudflare emails.
  static const String _bookstoreCacheKey = 'bookstore_content_cache_v2';
  
  /// Cache key for donation content.
  /// v2: full method list (securities, recurring) and list-based scrape.
  static const String _donateCacheKey = 'donate_content_cache_v2';
  
  /// Cache key for admissions content (v3: rich paragraphs with bold/underline)
  static const String _admissionsCacheKey = 'admissions_content_cache_v3';
  
  /// Cache key for contact content
  static const String _contactCacheKey = 'contact_content_cache_v1';

  /// Cache key for archives content
  static const String _archivesCacheKey = 'archives_content_cache_v1';

  // ============================================================================
  // CONSTANTS - Cache Durations
  // ============================================================================
  // How long cached data remains valid before we fetch fresh data.
  // 24 hours means data is refreshed once per day.
  
  /// How long homepage content cache is valid (24 hours)
  static const Duration _cacheDuration = Duration(hours: 24);
  
  /// How long events content cache is valid (24 hours)
  static const Duration _eventsCacheDuration = Duration(hours: 24);
  
  /// How long bookstore content cache is valid (24 hours)
  static const Duration _bookstoreCacheDuration = Duration(hours: 24);
  
  /// How long donation content cache is valid (24 hours)
  static const Duration _donateCacheDuration = Duration(hours: 24);
  
  /// How long admissions content cache is valid (24 hours)
  static const Duration _admissionsCacheDuration = Duration(hours: 24);
  
  /// How long contact content cache is valid (24 hours)
  static const Duration _contactCacheDuration = Duration(hours: 24);

  /// How long archives content cache is valid (24 hours)
  static const Duration _archivesCacheDuration = Duration(hours: 24);

  // ============================================================================
  // CONSTANTS - Other
  // ============================================================================
  
  /// Parsed URI object for the homepage (used for resolving relative URLs)
  static final Uri _homepageUri = Uri.parse(_homepageUrl);
  
  /// Parsed URI object for the donate page
  static final Uri _donateUri = Uri.parse(_donateUrl);
  
  /// Fallback mailing address if we can't extract it from the website
  /// Used as a backup when parsing fails
  static const List<String> _fallbackDonateAddress = [
    'Vivekananda Vidyapith',
    '20 Hinchman Avenue',
    'Wayne, NJ 07470',
  ];

  // ============================================================================
  // INSTANCE VARIABLES
  // ============================================================================
  
  /// HTTP client used to make network requests to download web pages
  final http.Client _client;

  // ============================================================================
  // HOMEPAGE CONTENT METHODS
  // ============================================================================
  
  /// Gets homepage content (thought of the day, events, carousel images).
  /// 
  /// Uses smart caching: checks for cached data first, and only fetches fresh data
  /// if cache is expired or forceRefresh is true.
  /// 
  /// [forceRefresh] - If true, ignores cache and always fetches fresh data.
  /// 
  /// Returns: WebsiteContent with thought of the day, events, and carousel images.
  Future<WebsiteContent> getWebsiteContent({bool forceRefresh = false}) async {
    // Get access to local storage
    final prefs = await SharedPreferences.getInstance();
    WebsiteContent? cachedContent;

    // Try to load cached content from local storage
    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson != null) {
      try {
        // Convert stored JSON string back to WebsiteContent object
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(cachedJson) as Map,
        );
        cachedContent = WebsiteContent.fromJson(json);
      } catch (_) {
        // If JSON parsing fails, ignore corrupted cache and fetch fresh
        cachedContent = null;
      }
    }

    // Check if we should use cached data
    if (!forceRefresh && cachedContent != null) {
      // Calculate age of cached data
      final age = DateTime.now().difference(cachedContent.fetchedAt);
      // If cache is still fresh (less than 24 hours old), return it
      if (age <= _cacheDuration) {
        return cachedContent;
      }
    }

    // Cache expired or forceRefresh is true - fetch fresh data
    try {
      final freshContent = await fetchWebsiteContent();
      // Save fresh data to cache
      try {
        await prefs.setString(_cacheKey, jsonEncode(freshContent.toJson()));
      } catch (_) {
        // If cache save fails, don't worry - we still return fresh data
        // Cache write failures should not block returning fresh data.
      }
      return freshContent;
    } catch (_) {
      // If fetch fails but we have cached data, return it as fallback
      if (cachedContent != null) {
        return cachedContent;
      }
      // No cache available - rethrow the error so caller can handle it
      rethrow;
    }
  }

  /// Fetches fresh homepage content from the website.
  /// 
  /// Downloads the homepage HTML, parses it, and extracts:
  /// - Thought of the day
  /// - Featured quote (above Thought of the Day)
  /// - Upcoming events
  /// - Carousel images
  /// 
  /// Returns: Fresh WebsiteContent object.
  /// Throws: http.ClientException if the HTTP request fails.
  Future<WebsiteContent> fetchWebsiteContent() async {
    // Download the homepage HTML
    final response = await _client.get(Uri.parse(_homepageUrl));

    // Check if the request was successful (status code 200 = OK)
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load website content (status: ${response.statusCode})',
        Uri.parse(_homepageUrl),
      );
    }

    // Parse the HTML into a document object we can search through
    // utf8.decode converts the raw bytes to text, handling special characters
    final document = html_parser.parse(utf8.decode(response.bodyBytes));

    return parseHomepageDocument(document);
  }

  /// Parses a homepage HTML [document] into [WebsiteContent].
  ///
  /// Exposed for unit tests so fixture HTML can be verified without HTTP.
  WebsiteContent parseHomepageDocument(Document document) {
    final thought = _parseThoughtOfTheDay(document);
    final featuredQuote = _parseFeaturedQuote(document);
    final events = _parseUpcomingEvents(document);
    final carouselImages = _parseCarouselImages(document);
    final dynamicLinks = _parseDynamicLinks(document);

    return WebsiteContent(
      thoughtOfTheDay: thought,
      featuredQuote: featuredQuote,
      upcomingEvents: events,
      carouselImages: carouselImages,
      dynamicLinks: dynamicLinks,
      fetchedAt: DateTime.now(),
    );
  }

  Future<DonateContent> getDonateContent({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    DonateContent? cachedContent;

    final cachedJson = prefs.getString(_donateCacheKey);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(cachedJson) as Map,
        );
        cachedContent = DonateContent.fromJson(json);
      } catch (_) {
        cachedContent = null;
      }
    }

    if (!forceRefresh && cachedContent != null) {
      final age = DateTime.now().difference(cachedContent.fetchedAt);
      if (age <= _donateCacheDuration) {
        return cachedContent;
      }
    }

    try {
      final freshContent = await fetchDonateContent();
      try {
        await prefs.setString(_donateCacheKey, jsonEncode(freshContent.toJson()));
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

  Future<DonateContent> fetchDonateContent() async {
    final response = await _client.get(_donateUri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load donate content (status: ${response.statusCode})',
        _donateUri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
    return _parseDonateContent(document, _donateUri);
  }

  DonateContent _parseDonateContent(Document document, Uri baseUri) {
    final List<String> introParagraphs = _extractDonateIntro(document);

    String? zelleEmail;
    String? zelleInstruction;
    String? zelleQrImageUrl;
    String? securitiesInstruction;
    String? securitiesEmail;
    String? checkInstruction;
    List<String> checkMailingAddress = [];
    String? paypalGivingInstruction;
    String? paypalGivingUrl;
    String? paypalGivingNote;
    String? recurringInstruction;
    String? recurringUrl;
    String? matchingGrantInstruction;
    String? matchingFormUrl;

    Element? zelleListItem;
    Element? checkListItem;

    for (final Element li in document.querySelectorAll('li')) {
      final String text = _cleanHtml(li.innerHtml).trim();
      if (text.isEmpty) {
        continue;
      }
      final String lowered = text.toLowerCase();

      if (lowered.contains('zelle')) {
        zelleListItem = li;
        zelleInstruction ??= text;
        zelleEmail ??= _firstEmailIn(li);
        continue;
      }

      if (lowered.contains('securities') ||
          lowered.contains('appreciated financial')) {
        securitiesInstruction ??= text;
        securitiesEmail ??= _firstEmailIn(li);
        continue;
      }

      if (lowered.contains('matching') && lowered.contains('grant')) {
        matchingGrantInstruction ??= text;
        matchingFormUrl ??= _firstHrefMatching(
          li,
          baseUri,
          (href) => href.toLowerCase().contains('docs.google.com/forms'),
        );
        continue;
      }

      if (lowered.contains('recurring') ||
          (lowered.contains('monthly donation') &&
              !lowered.contains('paypal giving'))) {
        recurringInstruction ??= text;
        recurringUrl ??= _firstHrefMatching(
          li,
          baseUri,
          (href) {
            final lower = href.toLowerCase();
            return lower.contains('paypal.com') &&
                (lower.contains('donate') || lower.contains('hosted_button'));
          },
        );
        continue;
      }

      if (lowered.contains('paypal giving fund')) {
        if (lowered.startsWith('please note')) {
          paypalGivingNote ??= text;
        } else {
          paypalGivingInstruction ??= text;
        }
        paypalGivingUrl ??= _firstHrefMatching(
          li,
          baseUri,
          (href) {
            final lower = href.toLowerCase();
            return lower.contains('paypal.com') &&
                (lower.contains('fundraiser') || lower.contains('giving'));
          },
        );
        continue;
      }

      if (lowered.contains('donate by') && lowered.contains('check')) {
        checkListItem = li;
        checkInstruction ??= text;
        continue;
      }
    }

    // Legacy table-cell fallback when list items are absent.
    if (zelleInstruction == null &&
        securitiesInstruction == null &&
        matchingGrantInstruction == null &&
        recurringInstruction == null &&
        paypalGivingInstruction == null &&
        checkInstruction == null) {
      return _parseDonateContentLegacy(document, baseUri, introParagraphs);
    }

    zelleQrImageUrl = _extractZelleQrImageUrl(document, baseUri, zelleListItem);

    if (checkListItem != null) {
      checkMailingAddress = _extractCheckAddressNear(checkListItem);
    }

    // Prefer same org email for securities when decode fails on one anchor.
    securitiesEmail ??= zelleEmail;
    zelleEmail ??= securitiesEmail;

    final List<String> mailingAddress = checkMailingAddress.isNotEmpty
        ? checkMailingAddress
        : _fallbackDonateAddress;

    return DonateContent(
      introParagraphs: introParagraphs,
      zelleEmail: zelleEmail,
      zelleInstruction: zelleInstruction,
      zelleQrImageUrl: zelleQrImageUrl,
      securitiesInstruction: securitiesInstruction,
      securitiesEmail: securitiesEmail,
      checkInstruction: checkInstruction,
      checkMailingAddress: mailingAddress,
      paypalGivingInstruction: paypalGivingInstruction,
      paypalGivingUrl: paypalGivingUrl,
      paypalGivingNote: paypalGivingNote,
      recurringInstruction: recurringInstruction,
      recurringUrl: recurringUrl,
      matchingGrantInstruction: matchingGrantInstruction,
      matchingFormUrl: matchingFormUrl,
      fetchedAt: DateTime.now(),
    );
  }

  /// Legacy table-based donate parse used when the page has no method list items.
  DonateContent _parseDonateContentLegacy(
    Document document,
    Uri baseUri,
    List<String> introParagraphs,
  ) {
    final (
      String? email,
      String? instruction,
      String? qrImageUrl
    ) zelleInfo = _extractZelleInfoLegacy(document, baseUri);
    final (
      String? checkInstruction,
      List<String> addressLines,
      String? paypalInstruction,
      String? paypalUrl,
      String? paypalNote,
      String? matchingInstruction,
      String? matchingUrl,
    ) = _extractOtherDonateInfoLegacy(document, baseUri);

    final List<String> mailingAddress = addressLines.isNotEmpty
        ? addressLines
        : _fallbackDonateAddress;

    return DonateContent(
      introParagraphs: introParagraphs,
      zelleEmail: zelleInfo.$1,
      zelleInstruction: zelleInfo.$2,
      zelleQrImageUrl: zelleInfo.$3,
      checkInstruction: checkInstruction,
      checkMailingAddress: mailingAddress,
      paypalGivingInstruction: paypalInstruction,
      paypalGivingUrl: paypalUrl,
      paypalGivingNote: paypalNote,
      matchingGrantInstruction: matchingInstruction,
      matchingFormUrl: matchingUrl,
      fetchedAt: DateTime.now(),
    );
  }

  List<String> _extractDonateIntro(Document document) {
    for (final element in document.querySelectorAll('div.paragraph, p')) {
      final text = _cleanHtml(element.innerHtml);
      final lowered = text.toLowerCase();
      if (lowered.contains('vivekananda vidyapith relies') ||
          (lowered.contains('donations') &&
              lowered.contains('501') &&
              text.trim().isNotEmpty)) {
        final lines = text
            .split(RegExp(r'\n+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        if (lines.isNotEmpty) {
          return lines;
        }
      }
    }
    return const [];
  }

  String? _firstEmailIn(Element root) {
    for (final anchor in root.querySelectorAll('a')) {
      final String? email = _extractEmailFromAnchor(anchor);
      if (email != null && email.isNotEmpty) {
        return email;
      }
    }
    return null;
  }

  String? _firstHrefMatching(
    Element root,
    Uri baseUri,
    bool Function(String href) predicate,
  ) {
    for (final anchor in root.querySelectorAll('a')) {
      final String? href = anchor.attributes['href'];
      if (href == null || href.isEmpty) {
        continue;
      }
      final String? resolved = _resolveHref(href, baseUri);
      if (resolved == null || resolved.isEmpty) {
        continue;
      }
      if (predicate(resolved)) {
        return resolved;
      }
    }
    return null;
  }

  String? _extractZelleQrImageUrl(
    Document document,
    Uri baseUri,
    Element? zelleListItem,
  ) {
    Element? searchRoot = zelleListItem;
    while (searchRoot != null &&
        searchRoot.localName != 'td' &&
        searchRoot.localName != 'body') {
      searchRoot = searchRoot.parent;
    }
    searchRoot ??= document.body;

    if (searchRoot != null) {
      for (final Element image in searchRoot.querySelectorAll('img')) {
        final String? url = _resolveImageUrlWithBase(image, baseUri);
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }

    // Fallback: first content image after the donate heading.
    for (final Element image in document.querySelectorAll(
      '.wsite-image img, #wsite-content img',
    )) {
      final String? url = _resolveImageUrlWithBase(image, baseUri);
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  List<String> _extractCheckAddressNear(Element checkListItem) {
    Element? container = checkListItem.parent;
    while (container != null) {
      final bool isParagraph = container.localName == 'div' &&
          container.classes.contains('paragraph');
      if (isParagraph || container.localName == 'td') {
        break;
      }
      container = container.parent;
    }
    container ??= checkListItem.parent;

    if (container == null) {
      return const [];
    }

    final List<String> lines = [];
    for (final Element span in container.querySelectorAll('span')) {
      final String text =
          _cleanHtml(span.innerHtml).replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty || text.length > 80) {
        continue;
      }
      final String lowered = text.toLowerCase();
      if (lowered.contains('donate by') ||
          lowered.contains('please mail') ||
          lowered.contains('please note') ||
          lowered.contains('click')) {
        continue;
      }
      if (lowered.contains('vivekananda vidyapith') ||
          RegExp(r'\d').hasMatch(text) ||
          lowered.contains('avenue') ||
          lowered.contains('street') ||
          lowered.contains('wayne') ||
          lowered.contains('nj')) {
        lines.add(text);
      }
    }

    if (lines.length >= 2) {
      return lines;
    }

    // Fallback: split cleaned container text after the org name when it
    // looks like a mailing address (street / city / ZIP).
    final String cleaned = _cleanHtml(container.innerHtml);
    final Match? match = RegExp(
      r'vivekananda\s+vidyapith\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (match != null) {
      final String rest = (match.group(1) ?? '').trim();
      final String restLower = rest.toLowerCase();
      final bool looksLikeAddress = RegExp(r'\d').hasMatch(rest) &&
          (restLower.contains('avenue') ||
              restLower.contains('street') ||
              restLower.contains('wayne') ||
              restLower.contains('nj') ||
              RegExp(r'\b\d{5}\b').hasMatch(rest));
      if (looksLikeAddress) {
        return [
          'Vivekananda Vidyapith',
          ...rest
              .split(RegExp(r'\s{2,}|\n+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty && e.length < 80),
        ];
      }
    }
    return const [];
  }

  (
    String?,
    String?,
    String?,
  ) _extractZelleInfoLegacy(Document document, Uri baseUri) {
    Element? zelleCell;
    for (final td in document.querySelectorAll('table tr td')) {
      final text = _cleanHtml(td.innerHtml).toLowerCase();
      if (text.contains('zelle')) {
        zelleCell = td;
        break;
      }
    }

    if (zelleCell == null) {
      return (null, null, null);
    }

    final List<String> lines = _cleanHtml(zelleCell.innerHtml)
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String? instruction;
    for (final line in lines) {
      final lowered = line.toLowerCase();
      if (lowered.contains('zelle')) {
        instruction = line;
        break;
      }
    }
    instruction ??= lines.isNotEmpty ? lines.first : null;

    String? email;
    for (final anchor in zelleCell.querySelectorAll('a')) {
      email = _extractEmailFromAnchor(anchor);
      if (email != null && email.isNotEmpty) {
        break;
      }
    }

    final Element? image = zelleCell.querySelector('img');
    final String? qrImageUrl = image != null
        ? _resolveImageUrlWithBase(image, baseUri)
        : null;

    return (email, instruction, qrImageUrl);
  }

  (
    String?,
    List<String>,
    String?,
    String?,
    String?,
    String?,
    String?,
  ) _extractOtherDonateInfoLegacy(Document document, Uri baseUri) {
    Element? donationCell;
    for (final td in document.querySelectorAll('table tr td')) {
      final text = _cleanHtml(td.innerHtml).toLowerCase();
      if (text.contains('paypal') ||
          text.contains('credit card') ||
          text.contains('matching grant') ||
          text.contains('please mail your donation')) {
        donationCell = td;
        break;
      }
    }

    if (donationCell == null) {
      return (null, const [], null, null, null, null, null);
    }

    String? checkInstruction;
    final List<String> addressLines = [];
    String? paypalInstruction;
    String? paypalUrl;
    String? paypalNote;
    String? matchingInstruction;
    String? matchingUrl;

    final List<String> lines = _cleanHtml(donationCell.innerHtml)
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    bool captureAddress = false;

    for (final line in lines) {
      final String lowered = line.toLowerCase();

      if (lowered.contains('to donate by check')) {
        checkInstruction ??= line;
        captureAddress = true;
        continue;
      }

      if (captureAddress) {
        final bool isNextSection = lowered.startsWith('to donate online') ||
            lowered.startsWith('to donate by credit card') ||
            lowered.startsWith('if your company') ||
            lowered.startsWith('please note') ||
            lowered.startsWith('to make a');
        if (isNextSection) {
          captureAddress = false;
        } else {
          addressLines.add(line);
          continue;
        }
      }

      if (lowered.contains('paypal giving fund')) {
        if (lowered.startsWith('please note')) {
          paypalNote ??= line;
        } else {
          paypalInstruction ??= line;
        }
      } else if (lowered.contains('matching') && lowered.contains('grant')) {
        matchingInstruction ??= line;
      }
    }

    for (final anchor in donationCell.querySelectorAll('a')) {
      final String? href = anchor.attributes['href'];
      if (href == null || href.isEmpty) {
        continue;
      }

      final String? resolved = _resolveHref(href, baseUri);
      if (resolved == null || resolved.isEmpty) {
        continue;
      }

      final String loweredHref = resolved.toLowerCase();
      if (loweredHref.contains('paypal.com') &&
          loweredHref.contains('fundraiser')) {
        paypalUrl ??= resolved;
      } else if (loweredHref.contains('docs.google.com/forms')) {
        matchingUrl ??= resolved;
      }
    }

    final List<String> sanitizedAddress = addressLines
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return (
      checkInstruction,
      sanitizedAddress,
      paypalInstruction,
      paypalUrl,
      paypalNote,
      matchingInstruction,
      matchingUrl,
    );
  }

  String? _extractEmailFromAnchor(Element anchor) {
    final String text = _cleanHtml(anchor.innerHtml).trim();
    if (_looksLikeEmail(text)) {
      return text;
    }

    final String? href = anchor.attributes['href'];
    if (href != null && href.isNotEmpty) {
      if (href.startsWith('mailto:')) {
        final String email = href.replaceFirst('mailto:', '').trim();
        if (_looksLikeEmail(email)) {
          return email;
        }
      }

      final int hashIndex = href.lastIndexOf('#');
      if (hashIndex != -1 && hashIndex + 1 < href.length) {
        final String encoded = href.substring(hashIndex + 1);
        final String? decoded = _decodeCloudflareEmail(encoded);
        if (_looksLikeEmail(decoded)) {
          return decoded;
        }
      }
    }

    final String? cfEmail = anchor.attributes['data-cfemail'];
    if (cfEmail != null && cfEmail.isNotEmpty) {
      final String? decoded = _decodeCloudflareEmail(cfEmail);
      if (_looksLikeEmail(decoded)) {
        return decoded;
      }
    }

    return null;
  }

  String? _decodeCloudflareEmail(String? encoded) {
    if (encoded == null || encoded.length < 2 || encoded.length.isOdd) {
      return null;
    }

    try {
      final int key = int.parse(encoded.substring(0, 2), radix: 16);
      final StringBuffer buffer = StringBuffer();
      for (int i = 2; i < encoded.length; i += 2) {
        final int charCode =
            int.parse(encoded.substring(i, i + 2), radix: 16) ^ key;
        buffer.writeCharCode(charCode);
      }
      return buffer.toString();
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeEmail(String? value) {
    if (value == null) {
      return false;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim());
  }

  String? _resolveHref(String href, Uri baseUri) {
    final String trimmed = href.trim();
    if (trimmed.isEmpty || trimmed.startsWith('javascript:')) {
      return null;
    }

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return null;
    }

    final Uri resolved = uri.hasScheme ? uri : baseUri.resolveUri(uri);
    return resolved.toString();
  }

  /// Fallback image for youngsters curricular section when scrape fails.
  static const String _curricularYoungstersFallbackImageUrl =
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/published/1254951.jpg?1766496217';

  /// Fallback image for adults curricular section when scrape fails.
  static const String _curricularAdultsFallbackImageUrl =
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/6185815.jpeg';

  /// Fetches curricular classes content (youngsters + adults) from the website.
  ///
  /// Each section includes the exact heading title, the full paragraph body as
  /// [CurricularClassesSection.description], and the paired multicol image.
  Future<CurricularClassesContent> fetchCurricularClassesContent() async {
    final uri = Uri.parse(_curricularClassesUrl);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load curricular classes content (status: ${response.statusCode})',
        uri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));

    final CurricularClassesSection? youngstersSection =
        _extractCurricularSection(
          document,
          match: (text) => text.contains('youngsters'),
          fallbackImageUrl: _curricularYoungstersFallbackImageUrl,
        );

    final CurricularClassesSection? adultsSection = _extractCurricularSection(
      document,
      match: (text) => text.contains('adults'),
      fallbackImageUrl: _curricularAdultsFallbackImageUrl,
    );

    if (youngstersSection == null || adultsSection == null) {
      throw StateError('Unable to parse curricular classes sections.');
    }

    return CurricularClassesContent(
      youngstersSection: youngstersSection,
      adultsSection: adultsSection,
    );
  }

  Future<MusicClassesContent> fetchMusicClassesContent() async {
    final uri = Uri.parse(_musicClassesUrl);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load music classes content (status: ${response.statusCode})',
        uri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));

    final MusicClassSection? vocalSection = _extractMusicSection(
      document,
      match: (text) => text.contains('hindustani') || text.contains('vocal'),
    );

    final MusicClassSection? tablaSection = _extractMusicSection(
      document,
      match: (text) => text.contains('tabla'),
    );

    if (vocalSection == null || tablaSection == null) {
      throw StateError('Unable to parse music classes sections.');
    }

    const String vocalThumbnailUrl =
        'https://www.vidyapith.org/uploads/5/2/1/3/52135817/editor/screen-shot-2024-08-02-at-1-25-10-pm.png?1722619683';
    const String tablaThumbnailUrl =
        'https://www.vidyapith.org/uploads/5/2/1/3/52135817/published/6518226.jpg?1723039710';

    return MusicClassesContent(
      vocalSection: vocalSection,
      tablaSection: tablaSection,
      vocalThumbnailUrl: vocalThumbnailUrl,
      tablaThumbnailUrl: tablaThumbnailUrl,
    );
  }

  /// Extracts one music class section (vocal or tabla) from the page.
  ///
  /// Titles come from the matching heading/`<strong>` only. Teachers, schedule,
  /// and description are parsed from the following paragraph with `<br>` treated
  /// as line breaks so fields do not collapse into duplicated blobs. Inquiry
  /// CTA wording is omitted from text fields; use [MusicClassSection.formUrl].
  MusicClassSection? _extractMusicSection(
    Document document, {
    required bool Function(String loweredText) match,
  }) {
    final Element? titleElement = _findMusicClassTitleElement(document, match);
    if (titleElement == null) {
      return null;
    }

    final String title = _cleanHtml(titleElement.innerHtml);
    if (title.isEmpty) {
      return null;
    }

    Element heading = titleElement;
    while (heading.parent != null && heading.localName != 'h2') {
      heading = heading.parent!;
    }

    final Element? bodyElement = _findMusicSectionBody(heading);
    final String? formUrl = _extractMusicFormUrl(bodyElement);
    final List<String> bodyLines = bodyElement != null
        ? _musicSectionLines(bodyElement.innerHtml)
        : const <String>[];

    String teachers = '';
    String schedule = '';
    final List<String> descriptionLines = <String>[];

    for (final String line in bodyLines) {
      final String lower = line.toLowerCase();

      if (_isMusicInquiryCtaLine(lower)) {
        continue;
      }

      if (teachers.isEmpty && lower.contains('taught by')) {
        teachers = _extractTeachersFromLine(line);
        // Same line may also carry the schedule after the teachers clause.
        final String? inlineSchedule = _extractScheduleFromLine(line);
        if (inlineSchedule != null && schedule.isEmpty) {
          schedule = inlineSchedule;
        }
        continue;
      }

      if (schedule.isEmpty) {
        final String? scheduleOnly = _extractScheduleFromLine(line);
        if (scheduleOnly != null && !_looksLikeTaughtByLine(lower)) {
          schedule = scheduleOnly;
          continue;
        }
      }

      if (line != title &&
          !_looksLikeTaughtByLine(lower) &&
          !_isMusicScheduleLine(lower)) {
        descriptionLines.add(line);
      }
    }

    final String description = descriptionLines.join(' ').trim();

    return MusicClassSection(
      title: title,
      teachers: teachers,
      schedule: schedule,
      description: description,
      formUrl: formUrl,
    );
  }

  /// Finds the heading/`<strong>` whose text matches the vocal or tabla section.
  Element? _findMusicClassTitleElement(
    Document document,
    bool Function(String loweredText) match,
  ) {
    for (final Element strong in document.querySelectorAll('strong')) {
      final String text = _cleanHtml(strong.innerHtml).toLowerCase();
      if (match(text) && _isMusicClassTitleCandidate(text)) {
        return strong;
      }
    }

    for (final Element heading in document.querySelectorAll('h2')) {
      final String text = _cleanHtml(heading.innerHtml).toLowerCase();
      if (match(text) && _isMusicClassTitleCandidate(text)) {
        return heading;
      }
    }

    return null;
  }

  /// True when [lowered] looks like a class title rather than schedule or form CTA.
  bool _isMusicClassTitleCandidate(String lowered) {
    if (_isMusicInquiryCtaLine(lowered)) {
      return false;
    }
    if (_isMusicScheduleLine(lowered) && !lowered.contains('class')) {
      return false;
    }
    return true;
  }

  /// Returns the paragraph (or first content sibling) after [heading].
  Element? _findMusicSectionBody(Element heading) {
    Element? current = heading.nextElementSibling;
    while (current != null) {
      final String tag = current.localName?.toLowerCase() ?? '';
      if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(tag)) {
        break;
      }

      final String className = current.className.toLowerCase();
      if (tag == 'div' && className.contains('paragraph')) {
        return current;
      }
      if (tag == 'p') {
        return current;
      }

      final String text = _cleanHtml(current.innerHtml).toLowerCase();
      if (text.contains('taught by') || _isMusicScheduleLine(text)) {
        return current;
      }

      current = current.nextElementSibling;
    }
    return null;
  }

  /// Resolves the Google Form (or first anchor) URL inside [bodyElement].
  String? _extractMusicFormUrl(Element? bodyElement) {
    if (bodyElement == null) {
      return null;
    }

    final Element? anchor =
        bodyElement.querySelector('a[href*="docs.google.com"]') ??
        bodyElement.querySelector('a');
    if (anchor == null) {
      return null;
    }

    String? formUrl = anchor.attributes['href'];
    if (formUrl != null && !formUrl.startsWith('http')) {
      formUrl = 'https://www.vidyapith.org$formUrl';
    }
    return formUrl;
  }

  /// Splits music section HTML into non-empty lines, preserving `<br>` breaks.
  ///
  /// Source whitespace/newlines between tags are collapsed so inquiry CTA markup
  /// does not produce stray punctuation-only lines.
  List<String> _musicSectionLines(String html) {
    const String breakSentinel = '\uE000';
    final String withSentinel = html.replaceAll(
      RegExp(r'(<br\s*/?>)+', caseSensitive: false),
      breakSentinel,
    );
    final fragment = html_parser.parseFragment(withSentinel);
    final String text = (fragment.text ?? '')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(breakSentinel, '\n');

    return text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !RegExp(r'^[\.,;:!?\-–—]+$').hasMatch(line))
        .toList();
  }

  /// Names only from a "Taught by …" line (schedule/inquiry fragments stripped).
  String _extractTeachersFromLine(String line) {
    String teachers = line
        .replaceFirst(RegExp(r'^.*?taught by\s*', caseSensitive: false), '')
        .trim();

    teachers = teachers
        .replaceFirst(
          RegExp(
            r'\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday).*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    teachers = teachers
        .replaceFirst(
          RegExp(r'\s*to inquire further.*$', caseSensitive: false),
          '',
        )
        .trim();

    return teachers;
  }

  /// Day/time segment from [line], or null if none.
  String? _extractScheduleFromLine(String line) {
    final Match? match = RegExp(
      r'((?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)s?\b.*?(?:\d{1,2}:\d{2}\s*(?:am|pm)|\d{1,2}\s*(?:am|pm)))',
      caseSensitive: false,
    ).firstMatch(line);
    if (match == null) {
      return null;
    }
    return match.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _looksLikeTaughtByLine(String lowered) => lowered.contains('taught by');

  bool _isMusicScheduleLine(String lowered) {
    final bool hasDay =
        lowered.contains('saturday') ||
        lowered.contains('sunday') ||
        lowered.contains('monday') ||
        lowered.contains('tuesday') ||
        lowered.contains('wednesday') ||
        lowered.contains('thursday') ||
        lowered.contains('friday');
    final bool hasTime =
        lowered.contains('am') ||
        lowered.contains('pm') ||
        RegExp(r'\d{1,2}:\d{2}').hasMatch(lowered);
    return hasDay && hasTime;
  }

  bool _isMusicInquiryCtaLine(String lowered) {
    return lowered.contains('inquire') ||
        lowered.contains('inquiry') ||
        lowered.contains('submit this') ||
        (lowered.contains('form') &&
            (lowered.contains('vocal') ||
                lowered.contains('tabla') ||
                lowered.contains('class')));
  }

  Future<SummerCampContent> fetchSummerCampContent() async {
    final uri = Uri.parse(_summerCampUrl);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load summer camp content (status: ${response.statusCode})',
        uri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));

    final String description = _extractSummerCampDescription(document);
    const String thumbnailUrl =
        'https://www.vidyapith.org/uploads/5/2/1/3/52135817/1511582.jpg?1453641308';

    return SummerCampContent(
      title: 'Summer Camp',
      description: description,
      thumbnailUrl: thumbnailUrl,
    );
  }

  /// Extracts the summer camp description from the Weebly page.
  ///
  /// Prefers `#wsite-content .paragraph` / `.paragraph` text, then table cells.
  /// Strips a leading "Summer Camp" heading from the cleaned single-line string
  /// (since [_cleanHtml] collapses `<br>` / newlines into spaces).
  String _extractSummerCampDescription(Document document) {
    for (final selector in ['#wsite-content .paragraph', '.paragraph']) {
      for (final element in document.querySelectorAll(selector)) {
        final body = _summerCampBodyFromCleanedText(
          _cleanHtml(element.innerHtml),
        );
        if (body != null) {
          return body;
        }
      }
    }

    for (final td in document.querySelectorAll('table tr td')) {
      final body = _summerCampBodyFromCleanedText(_cleanHtml(td.innerHtml));
      if (body != null) {
        return body;
      }
    }

    return 'Summer Camp information unavailable.';
  }

  /// Returns the summer camp body text from a cleaned blob, or null if unmatched.
  ///
  /// Accepts text that mentions summer camp and looks like the program blurb
  /// (e.g. contains "invigorating" or "vidyapith" + substantial length).
  String? _summerCampBodyFromCleanedText(String cleaned) {
    final trimmed = cleaned.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final lower = trimmed.toLowerCase();
    final looksLikeBlurb =
        lower.contains('summer camp') &&
        (lower.contains('invigorating') ||
            (lower.contains('vidyapith') && trimmed.length > 40));
    if (!looksLikeBlurb) {
      return null;
    }

    // Strip a leading page heading such as "Summer Camp" before the body.
    final stripped = trimmed.replaceFirst(
      RegExp(r'^summer\s+camp\s*', caseSensitive: false),
      '',
    );
    final body = stripped.trim();
    if (body.isEmpty || body.toLowerCase() == 'summer camp') {
      return null;
    }

    return body;
  }

  ThoughtOfTheDay? _parseThoughtOfTheDay(Document document) {
    final heading = _findHeading(document, 'thought of the day');
    if (heading == null) return null;

    final paragraph =
        heading.nextElementSibling ?? heading.parent?.nextElementSibling;
    if (paragraph == null) return null;

    final cleaned = _cleanHtml(paragraph.innerHtml);
    if (cleaned.isEmpty) return null;

    final lines = cleaned
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    String text = lines.first;
    String? author;

    if (lines.length > 1) {
      author = lines.sublist(1).join(' ').trim();
    } else {
      final regex = RegExp(r'-\s*(.+)$');
      final match = regex.firstMatch(text);
      if (match != null) {
        author = match.group(1)?.trim();
        text = text.substring(0, match.start).trim();
      }
    }

    return ThoughtOfTheDay(
      text: text,
      author: author?.isEmpty == true ? null : author,
    );
  }

  /// Parses the featured quote that appears above Thought of the Day.
  ///
  /// Walks previous siblings of the Thought of the Day heading looking for
  /// quote-like text that is distinct from the thought itself.
  FeaturedQuote? _parseFeaturedQuote(Document document) {
    final heading = _findHeading(document, 'thought of the day');
    if (heading == null) return null;

    final thought = _parseThoughtOfTheDay(document);
    final thoughtText = thought?.text.trim().toLowerCase() ?? '';

    // Prefer immediate previous siblings of the heading (and its parent).
    for (final start in <Element?>[heading, heading.parent]) {
      if (start == null) continue;
      Element? current = start.previousElementSibling;
      while (current != null) {
        final quote = _extractFeaturedQuoteFromElement(
          current,
          thoughtText: thoughtText,
        );
        if (quote != null) return quote;
        current = current.previousElementSibling;
      }
    }

    // Fallback: first substantial quote-like block before the heading.
    final markers = document.querySelectorAll(
      'p, font, span, div, h1, h2, h3, h4, h5, h6',
    );
    final headingIndex = markers.indexOf(heading);
    final limit = headingIndex >= 0 ? headingIndex : markers.length;

    for (var i = 0; i < limit; i++) {
      final element = markers[i];
      if (_isAncestorOf(element, heading)) continue;
      final quote = _extractFeaturedQuoteFromElement(
        element,
        thoughtText: thoughtText,
        requireSubstantial: true,
      );
      if (quote != null) return quote;
    }

    return null;
  }

  /// Returns true when [ancestor] contains [descendant] in the DOM tree.
  bool _isAncestorOf(Element ancestor, Element descendant) {
    Element? current = descendant.parent;
    while (current != null) {
      if (identical(current, ancestor)) return true;
      current = current.parent;
    }
    return false;
  }

  FeaturedQuote? _extractFeaturedQuoteFromElement(
    Element element, {
    required String thoughtText,
    bool requireSubstantial = false,
  }) {
    final cleaned = _cleanHtml(element.innerHtml).trim();
    final quote = _quoteFromCleanedText(cleaned);
    if (quote == null) return null;

    final quoteText = quote.text.trim().toLowerCase();
    if (quoteText.isEmpty || quoteText == thoughtText) return null;
    if (_looksLikeNavigationOrEvents(quoteText)) return null;
    if (requireSubstantial && quote.text.length < 40) return null;
    return quote;
  }

  /// Splits cleaned HTML text into quote body + optional author.
  ///
  /// Prefers text inside quotation marks so internal dashes (e.g. "philosophy –
  /// by one or more…") are not mistaken for the author attribution that follows
  /// the closing quote.
  FeaturedQuote? _quoteFromCleanedText(String cleaned) {
    if (cleaned.isEmpty) return null;

    var text = cleaned.trim();
    String? author;

    final quoted = RegExp(
      r'^[\"\u201C](.+)[\"\u201D]\s*(?:[-–—]\s*)?(.*)$',
      dotAll: true,
    ).firstMatch(text);

    if (quoted != null) {
      text = (quoted.group(1) ?? '').trim();
      final trailing = (quoted.group(2) ?? '').trim();
      if (trailing.isNotEmpty) {
        author = trailing;
      }
    } else {
      // No wrapping quotes: use the last dash-attribution only.
      final allDashes = RegExp(r'[-–—]\s*').allMatches(text).toList();
      if (allDashes.isNotEmpty) {
        final last = allDashes.last;
        final maybeAuthor = text.substring(last.end).trim();
        // Treat as author only when the trailing fragment looks like a name,
        // not a continuation of the sentence (short, no sentence punctuation).
        if (maybeAuthor.isNotEmpty &&
            maybeAuthor.length <= 80 &&
            !maybeAuthor.contains('.') &&
            !RegExp(r'\band\b', caseSensitive: false).hasMatch(maybeAuthor)) {
          author = maybeAuthor;
          text = text.substring(0, last.start).trim();
        }
      }

      text = _stripWrappingQuotes(text);
    }

    if (text.isEmpty) return null;

    final hasAuthor = author != null && author.isNotEmpty;
    if (!hasAuthor && text.length < 60) return null;

    return FeaturedQuote(
      text: text,
      author: author?.isEmpty == true ? null : author,
    );
  }

  /// Removes a single pair of leading/trailing straight or curly quotes.
  String _stripWrappingQuotes(String value) {
    var text = value.trim();
    while (text.startsWith('"') ||
        text.startsWith('\u201C') ||
        text.startsWith("'")) {
      text = text.substring(1).trimLeft();
    }
    while (text.endsWith('"') ||
        text.endsWith('\u201D') ||
        text.endsWith("'")) {
      text = text.substring(0, text.length - 1).trimRight();
    }
    return text;
  }

  bool _looksLikeNavigationOrEvents(String lower) {
    return lower.contains('upcoming events') ||
        lower.contains('calendar') ||
        lower.contains('food drive') ||
        lower.contains('letters from') ||
        lower.contains('admissions') ||
        lower.contains('bookstore');
  }

  List<String> _parseCarouselImages(Document document) {
    final candidates = document.querySelectorAll('img');
    if (candidates.isEmpty) return const [];

    final Set<String> seen = <String>{};
    final List<String> results = [];

    for (final image in candidates) {
      final url = _resolveImageUrl(image);
      if (url == null || url.isEmpty) {
        continue;
      }

      final normalizedUrl = _stripTrackingParameters(url);
      if (!_isLikelyCarouselImage(image, normalizedUrl)) {
        continue;
      }

      if (seen.add(normalizedUrl)) {
        results.add(normalizedUrl);
      }

      if (results.length >= 8) {
        break;
      }
    }

    return results;
  }

  /// Parses the homepage for consecutive announcement links not in Quick Links.
  ///
  /// Collects a consecutive run of sibling announcement blocks (e.g. stacked
  /// homepage campaign links). Returns an empty list if none are found.
  List<DynamicLink> _parseDynamicLinks(Document document) {
    const maxLinks = 5;
    final baseUri = _homepageUri;
    final anchors = document.querySelectorAll('a');
    final detectedAt = DateTime.now();

    Element? firstAnchor;
    DynamicLink? firstLink;
    for (final anchor in anchors) {
      final link = _dynamicLinkFromAnchor(anchor, baseUri, detectedAt);
      if (link == null) continue;
      firstAnchor = anchor;
      firstLink = link;
      break;
    }

    if (firstAnchor == null || firstLink == null) {
      return const [];
    }

    final results = <DynamicLink>[firstLink];
    final seenUrls = <String>{firstLink.url.toLowerCase()};
    final firstBlock = _announcementBlockFor(firstAnchor);

    Element? sibling = firstBlock.nextElementSibling;
    while (sibling != null && results.length < maxLinks) {
      if (_isAnnouncementRunTerminator(sibling)) {
        break;
      }

      if (_isEmptyOrSpacerBlock(sibling)) {
        sibling = sibling.nextElementSibling;
        continue;
      }

      final siblingAnchors = sibling.querySelectorAll('a');
      if (siblingAnchors.isEmpty) {
        // Non-empty block without links ends the announcement run.
        break;
      }

      DynamicLink? qualified;
      var hasContentLink = false;
      for (final anchor in siblingAnchors) {
        final href = anchor.attributes['href'];
        if (href == null || href.isEmpty) continue;
        if (href.startsWith('mailto:') ||
            href.startsWith('javascript:') ||
            href.startsWith('#')) {
          continue;
        }
        hasContentLink = true;
        qualified ??= _dynamicLinkFromAnchor(anchor, baseUri, detectedAt);
      }

      if (qualified != null) {
        final key = qualified.url.toLowerCase();
        if (!seenUrls.contains(key)) {
          seenUrls.add(key);
          results.add(qualified);
        }
        sibling = sibling.nextElementSibling;
        continue;
      }

      // Excluded or non-qualifying content link ends the consecutive run.
      if (hasContentLink) {
        break;
      }

      sibling = sibling.nextElementSibling;
    }

    return results;
  }

  /// Builds a [DynamicLink] from [anchor] when it passes homepage filters.
  DynamicLink? _dynamicLinkFromAnchor(
    Element anchor,
    Uri baseUri,
    DateTime detectedAt,
  ) {
    final href = anchor.attributes['href'];
    if (href == null || href.isEmpty) return null;
    if (href.startsWith('mailto:') ||
        href.startsWith('javascript:') ||
        href.startsWith('#')) {
      return null;
    }

    final resolvedUrl = _resolveHref(href, baseUri);
    if (resolvedUrl == null || resolvedUrl.isEmpty) return null;
    if (_isExcludedDynamicLinkUrl(resolvedUrl)) return null;
    if (_isNavigationDynamicLink(anchor)) return null;

    final linkText = _cleanHtml(anchor.innerHtml).trim();
    if (linkText.isEmpty || linkText.length < 3) return null;

    final lowerText = linkText.toLowerCase();
    if (lowerText.startsWith('http://') ||
        lowerText.startsWith('https://') ||
        lowerText.endsWith('.pdf') ||
        lowerText.endsWith('.jpg') ||
        lowerText.endsWith('.png')) {
      return null;
    }

    return DynamicLink(
      title: linkText,
      url: resolvedUrl,
      detectedAt: detectedAt,
    );
  }

  /// Whether [url] is already covered by Quick Links or site navigation.
  bool _isExcludedDynamicLinkUrl(String url) {
    const excludedUrls = {
      'internal://snack-signup',
      'internal://class/curricular classes',
      'internal://class/music classes',
      'internal://class/summer camp',
      'https://vidyapith-act.netlify.app/',
      'internal://bookstore',
      'internal://admissions',
      'internal://donate',
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/2025-diwali_projects_suggestions.pdf',
    };
    const excludedPatterns = [
      '/about',
      '/events',
      '/contact',
      'calendar',
      'mailto:',
      'javascript:',
      '#',
    ];

    final lowerUrl = url.toLowerCase();
    for (final excluded in excludedUrls) {
      if (lowerUrl.contains(excluded.toLowerCase())) return true;
    }
    for (final pattern in excludedPatterns) {
      if (lowerUrl.contains(pattern.toLowerCase())) return true;
    }
    return false;
  }

  /// Whether [anchor] sits inside clear site navigation chrome.
  bool _isNavigationDynamicLink(Element anchor) {
    Element? parent = anchor.parent;
    var depth = 0;
    while (parent != null && depth < 5) {
      final classes = parent.classes.join(' ').toLowerCase();
      final id = parent.id.toLowerCase();
      final tagName = parent.localName?.toLowerCase() ?? '';

      if ((classes.contains('nav') && !classes.contains('content')) ||
          (classes.contains('menu') && !classes.contains('content')) ||
          (tagName == 'nav') ||
          (tagName == 'header' &&
              id.contains('header') &&
              !classes.contains('content')) ||
          (tagName == 'footer' && id.contains('footer'))) {
        return true;
      }
      parent = parent.parent;
      depth++;
    }
    return false;
  }

  /// Nearest Weebly-style paragraph/block wrapper for an announcement anchor.
  Element _announcementBlockFor(Element anchor) {
    Element? current = anchor.parent;
    while (current != null) {
      final classes = current.classes.join(' ').toLowerCase();
      final tag = current.localName?.toLowerCase() ?? '';
      if (classes.contains('paragraph') ||
          tag == 'p' ||
          tag == 'li' ||
          tag == 'div') {
        // Prefer Weebly paragraph blocks; otherwise use the nearest block.
        if (classes.contains('paragraph') || tag == 'p' || tag == 'li') {
          return current;
        }
        // Use a div only if it is a direct content sibling container.
        if (tag == 'div' && current.parent != null) {
          final parentHasMultipleBlocks =
              current.parent!.children.where((c) {
                final t = c.localName?.toLowerCase();
                return t == 'div' || t == 'p';
              }).length >
              1;
          if (parentHasMultipleBlocks) {
            return current;
          }
        }
      }
      current = current.parent;
    }
    return anchor.parent ?? anchor;
  }

  /// Horizontal rules and similar markers end the announcement sibling run.
  bool _isAnnouncementRunTerminator(Element element) {
    final tag = element.localName?.toLowerCase() ?? '';
    if (tag == 'hr') return true;
    if (element.querySelector('hr') != null) return true;
    final text = _cleanHtml(element.innerHtml).trim().toLowerCase();
    if (text.contains('thought of the day')) {
      return true;
    }
    return false;
  }

  /// True when a sibling block is visually empty / spacer-only.
  bool _isEmptyOrSpacerBlock(Element element) {
    final text = _cleanHtml(element.innerHtml).trim();
    if (text.isNotEmpty) return false;
    // Allow spacer images / empty wrappers without ending the run.
    return element.querySelectorAll('a').isEmpty;
  }

  /// Fetches all clickable links from a given page, excluding navigation links.
  /// 
  /// Downloads the page HTML, parses all anchor tags, and extracts
  /// link text and URLs. Filters out common navigation links (Home, About, etc.)
  /// and links that are in navigation elements. Returns only links that are
  /// part of the main content.
  /// 
  /// [url] - The URL of the page to fetch links from.
  /// 
  /// Returns: List of maps with 'text' (String) and 'url' (String) keys.
  /// Throws: http.ClientException if the HTTP request fails.
  Future<List<Map<String, String>>> fetchPageLinks(String url) async {
    final uri = Uri.parse(url);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load page links (status: ${response.statusCode})',
        uri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
    final baseUri = uri;
    final List<Map<String, String>> links = [];

    // Common navigation link texts to exclude
    final excludedNavTexts = {
      'home',
      'about',
      'classes',
      'events',
      'calendar',
      'contact',
      'contact us',
      'bookstore',
      'admissions',
      'donate',
      'donation',
      'gallery',
      'photos',
      'news',
      'blog',
    };

    // Common navigation URL patterns to exclude
    final excludedNavPatterns = [
      '/about',
      '/events',
      '/contact',
      '/calendar',
      '/classes',
      '/bookstore',
      '/admissions',
      '/donate',
      '/gallery',
      '/photos',
      '/news',
      '/blog',
      '#top',
      '#main',
      '#content',
    ];

    for (final anchor in document.querySelectorAll('a')) {
      final href = anchor.attributes['href'];
      if (href == null || href.isEmpty) continue;

      // Skip email links
      if (href.startsWith('mailto:')) continue;

      // Skip JavaScript links
      if (href.startsWith('javascript:')) continue;

      // Skip anchor links (same page navigation)
      if (href.startsWith('#')) continue;

      // Resolve relative URLs
      final resolvedUrl = _resolveHref(href, baseUri);
      if (resolvedUrl == null || resolvedUrl.isEmpty) continue;

      // Extract link text
      final linkText = _cleanHtml(anchor.innerHtml).trim();
      if (linkText.isEmpty) continue;

      final lowerLinkText = linkText.toLowerCase();
      final lowerUrl = resolvedUrl.toLowerCase();

      // Check if this is a navigation link by text
      bool isNavLink = excludedNavTexts.contains(lowerLinkText);

      // Check if this is a navigation link by URL pattern
      if (!isNavLink) {
        for (final pattern in excludedNavPatterns) {
          if (lowerUrl.contains(pattern.toLowerCase())) {
            isNavLink = true;
            break;
          }
        }
      }

      // Check if link is in navigation elements (nav, header, footer)
      if (!isNavLink) {
        Element? parent = anchor.parent;
        int depth = 0;
        while (parent != null && depth < 6) {
          final classes = parent.classes.join(' ').toLowerCase();
          final id = parent.id.toLowerCase();
          final tagName = parent.localName?.toLowerCase() ?? '';
          
          // Check if it's in a navigation element
          if (classes.contains('nav') ||
              classes.contains('menu') ||
              classes.contains('navigation') ||
              classes.contains('header') ||
              classes.contains('footer') ||
              tagName == 'nav' ||
              tagName == 'header' ||
              tagName == 'footer' ||
              id.contains('nav') ||
              id.contains('menu') ||
              id.contains('header') ||
              id.contains('footer')) {
            isNavLink = true;
            break;
          }
          parent = parent.parent;
          depth++;
        }
      }

      // Skip navigation links
      if (isNavLink) continue;

      // Skip very short link text (likely not meaningful)
      if (linkText.length < 3) continue;

      // Skip links that are just URLs or file names
      if (linkText.toLowerCase().startsWith('http://') ||
          linkText.toLowerCase().startsWith('https://') ||
          linkText.toLowerCase().endsWith('.pdf') ||
          linkText.toLowerCase().endsWith('.jpg') ||
          linkText.toLowerCase().endsWith('.png')) {
        continue;
      }

      // Found a content link - add it
      links.add({'text': linkText, 'url': resolvedUrl});
    }

    return links;
  }

  /// Fetches page content and extracts title and main content text.
  /// 
  /// Downloads the page HTML and attempts to extract:
  /// - Page title (from h1, h2, or title tag)
  /// - Main content text (from main, .content, article, paragraphs, or body)
  /// - Structured content with better formatting preservation
  /// 
  /// [url] - The URL of the page to fetch content from.
  /// 
  /// Returns: Map with 'title' (String?) and 'content' (String?) keys.
  /// Throws: http.ClientException if the HTTP request fails.
  Future<Map<String, String?>> fetchPageContent(String url) async {
    final uri = Uri.parse(url);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load page content (status: ${response.statusCode})',
        uri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
    String? pageTitle;
    String? pageContent;

    // Try to extract page title - prioritize h1, then h2, then title tag
    final titleElement = document.querySelector('h1') ??
        document.querySelector('h2') ??
        document.querySelector('title');
    if (titleElement != null) {
      pageTitle = _cleanHtml(titleElement.innerHtml).trim();
    }

    // Try to extract main content with better structure
    Element? mainContentElement = document.querySelector('main') ??
        document.querySelector('.content') ??
        document.querySelector('.wsite-content') ??
        document.querySelector('article') ??
        document.querySelector('.paragraph') ??
        document.querySelector('body');

    if (mainContentElement != null) {
      // Extract structured content - headings, paragraphs, lists, etc.
      final List<String> contentParts = [];
      
      // First, extract headings and their following content
      final headings = mainContentElement.querySelectorAll('h1, h2, h3, h4, h5, h6, strong');
      final processedElements = <Element>{};
      
      // Process headings and their following content
      for (final heading in headings) {
        if (processedElements.contains(heading)) continue;
        
        final headingText = heading.text?.trim() ?? '';
        if (headingText.isEmpty) continue;
        
        // Check if this heading is significant (not too short, not just formatting)
        if (headingText.length < 3) continue;
        
        // Find the content that follows this heading
        Element? nextSibling = heading.nextElementSibling;
        String? followingContent;
        
        // Look for content in the next sibling (usually a paragraph or div)
        if (nextSibling != null && 
            (nextSibling.localName == 'p' || 
             nextSibling.localName == 'div' ||
             nextSibling.localName == 'span')) {
          final contentText = nextSibling.text?.trim() ?? '';
          if (contentText.isNotEmpty && contentText.length > 3) {
            followingContent = contentText
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            processedElements.add(nextSibling);
          }
        }
        
        // Combine heading and content with line break
        if (followingContent != null && followingContent.isNotEmpty) {
          contentParts.add('$headingText\n\n$followingContent');
        } else {
          // Just the heading if no following content found
          contentParts.add(headingText);
        }
        
        processedElements.add(heading);
      }
      
      // Extract paragraphs that weren't already processed
      final paragraphs = mainContentElement.querySelectorAll('p');
      for (final p in paragraphs) {
        if (processedElements.contains(p)) continue;
        
        // Check if this paragraph contains a heading
        final hasHeading = p.querySelector('h1, h2, h3, h4, h5, h6, strong') != null;
        
        if (hasHeading) {
          // Extract heading and content separately
          final heading = p.querySelector('h1, h2, h3, h4, h5, h6, strong');
          if (heading != null) {
            final headingText = heading.text?.trim() ?? '';
            // Get text after the heading
            final allText = p.text?.trim() ?? '';
            final afterHeading = allText.replaceFirst(headingText, '').trim();
            
            if (headingText.isNotEmpty && afterHeading.isNotEmpty) {
              final cleanedHeading = headingText.replaceAll(RegExp(r'\s+'), ' ').trim();
              final cleanedContent = afterHeading.replaceAll(RegExp(r'\s+'), ' ').trim();
              contentParts.add('$cleanedHeading\n\n$cleanedContent');
            } else if (headingText.isNotEmpty) {
              contentParts.add(headingText.replaceAll(RegExp(r'\s+'), ' ').trim());
            }
          }
        } else {
          // Regular paragraph without heading
          final rawText = p.text ?? '';
          final cleaned = rawText
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (cleaned.isNotEmpty && cleaned.length > 3) {
            contentParts.add(cleaned);
          }
        }
        
        processedElements.add(p);
      }
      
      // Extract list items
      final listItems = mainContentElement.querySelectorAll('li');
      for (final li in listItems) {
        if (processedElements.contains(li)) continue;
        
        final rawText = li.text ?? '';
        final cleaned = rawText
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleaned.isNotEmpty && cleaned.length > 3) {
          contentParts.add('• $cleaned');
        }
        processedElements.add(li);
      }
      
      // Extract div content if no paragraphs found
      if (contentParts.isEmpty) {
        final divs = mainContentElement.querySelectorAll('div.paragraph, div.wsite-text');
        for (final div in divs) {
          // Check for headings within div
          final heading = div.querySelector('h1, h2, h3, h4, h5, h6, strong');
          if (heading != null) {
            final headingText = heading.text?.trim() ?? '';
            final allText = div.text?.trim() ?? '';
            final afterHeading = allText.replaceFirst(headingText, '').trim();
            
            if (headingText.isNotEmpty && afterHeading.isNotEmpty) {
              final cleanedHeading = headingText.replaceAll(RegExp(r'\s+'), ' ').trim();
              final cleanedContent = afterHeading.replaceAll(RegExp(r'\s+'), ' ').trim();
              contentParts.add('$cleanedHeading\n\n$cleanedContent');
            } else if (headingText.isNotEmpty) {
              contentParts.add(headingText.replaceAll(RegExp(r'\s+'), ' ').trim());
            }
          } else {
            final rawText = div.text ?? '';
            final cleaned = rawText
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            if (cleaned.isNotEmpty && cleaned.length > 10) {
              contentParts.add(cleaned);
            }
          }
        }
      }
      
      // If still no structured content, fall back to cleaned HTML
      if (contentParts.isEmpty) {
        final rawText = mainContentElement.text ?? '';
        final cleaned = rawText
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleaned.isNotEmpty) {
          contentParts.add(cleaned);
        }
      }
      
      // Join content parts with double newlines for paragraph breaks
      pageContent = contentParts.join('\n\n');
      
      // Final cleanup: normalize line breaks
      pageContent = pageContent
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')  // Max 2 newlines
          .replaceAll(RegExp(r'[ \t]+\n'), '\n')  // Remove spaces before newlines
          .replaceAll(RegExp(r'\n[ \t]+'), '\n')  // Remove spaces after newlines
          .trim();
      
      // Limit content length but be more generous
      if (pageContent.length > 5000) {
        pageContent = '${pageContent.substring(0, 5000)}...';
      }
    }

    return {'title': pageTitle, 'content': pageContent};
  }

  Future<BookstoreContent> getBookstoreContent({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    BookstoreContent? cachedContent;

    final cachedJson = prefs.getString(_bookstoreCacheKey);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(cachedJson) as Map,
        );
        cachedContent = BookstoreContent.fromJson(json);
      } catch (_) {
        cachedContent = null;
      }
    }

    if (!forceRefresh && cachedContent != null) {
      final age = DateTime.now().difference(cachedContent.fetchedAt);
      if (age <= _bookstoreCacheDuration) {
        return cachedContent;
      }
    }

    try {
      final freshContent = await fetchBookstoreContent();
      try {
        await prefs.setString(
          _bookstoreCacheKey,
          jsonEncode(freshContent.toJson()),
        );
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

  Future<BookstoreContent> fetchBookstoreContent() async {
    final uri = Uri.parse(_bookstoreUrl);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load bookstore content (status: ${response.statusCode})',
        uri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
    return _parseBookstoreContent(document);
  }

  String? _resolveImageUrl(Element image) {
    String? src = image.attributes['data-src']?.trim();
    src ??= image.attributes['data-original']?.trim();

    final String? srcSet =
        image.attributes['data-srcset']?.trim() ??
        image.attributes['srcset']?.trim();

    if ((src == null || src.isEmpty) && srcSet != null && srcSet.isNotEmpty) {
      src = srcSet
          .split(',')
          .map((entry) => entry.trim())
          .firstWhere((entry) => entry.isNotEmpty, orElse: () => '');
      final int spaceIndex = src.indexOf(' ');
      if (spaceIndex != -1) {
        src = src.substring(0, spaceIndex);
      }
    }

    src ??= image.attributes['src']?.trim();

    if (src == null || src.isEmpty) {
      return null;
    }

    if (src.startsWith('data:')) {
      return null;
    }

    final Uri uri = Uri.parse(src);
    final Uri resolved = uri.hasScheme ? uri : _homepageUri.resolveUri(uri);
    return resolved.toString();
  }

  String _stripTrackingParameters(String url) {
    final Uri uri = Uri.parse(url);
    if (!uri.hasQuery) {
      return url;
    }

    final Uri cleaned = uri.replace(query: '');
    return cleaned.toString();
  }

  bool _isLikelyCarouselImage(Element image, String url) {
    final lowerUrl = url.toLowerCase();
    const disallowedTokens = [
      'logo',
      'icon',
      'favicon',
      'badge',
      'sprite',
      'avatar',
      'social',
      'footer',
      'banner-ad',
    ];

    if (disallowedTokens.any((token) => lowerUrl.contains(token))) {
      return false;
    }

    final parent = image.parent;
    final grandParent = parent?.parent;

    String _collectClasses(Node? node) {
      if (node is! Element) {
        return '';
      }
      final element = node;
      final elementClasses = <String>[];
      final classAttr = element.attributes['class'];
      if (classAttr != null && classAttr.isNotEmpty) {
        elementClasses.add(classAttr);
      }
      if (element.classes.isNotEmpty) {
        elementClasses.add(element.classes.join(' '));
      }
      return elementClasses.join(' ');
    }

    final String combinedClasses = ([
      _collectClasses(image),
      _collectClasses(parent),
      _collectClasses(grandParent),
    ].where((value) => value.isNotEmpty).join(' ')).toLowerCase();

    if (combinedClasses.contains('logo') || combinedClasses.contains('icon')) {
      return false;
    }

    final widthAttr = image.attributes['width'];
    if (widthAttr != null) {
      final width = int.tryParse(widthAttr);
      if (width != null && width <= 120) {
        return false;
      }
    }

    final heightAttr = image.attributes['height'];
    if (heightAttr != null) {
      final height = int.tryParse(heightAttr);
      if (height != null && height <= 120) {
        return false;
      }
    }

    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowedExtensions.any((ext) => lowerUrl.contains(ext))) {
      return false;
    }

    return true;
  }

  /// Extracts one curricular section (youngsters or adults) from the page.
  ///
  /// Titles come from the matching `h2` / `<strong>` heading. The full sibling
  /// `div.paragraph` text becomes [CurricularClassesSection.description]
  /// (schedule is left empty). The image is taken from the sibling multicol
  /// column in the same row, falling back to [fallbackImageUrl].
  CurricularClassesSection? _extractCurricularSection(
    Document document, {
    required bool Function(String loweredText) match,
    required String fallbackImageUrl,
  }) {
    final Element? titleElement = _findCurricularTitleElement(document, match);
    if (titleElement == null) {
      return null;
    }

    Element heading = titleElement;
    while (heading.parent != null && heading.localName != 'h2') {
      heading = heading.parent!;
    }

    final String title = _cleanHtml(heading.innerHtml);
    if (title.isEmpty) {
      return null;
    }

    final String description = _extractCurricularDescription(heading);
    if (description.isEmpty) {
      return null;
    }

    final String imageUrl =
        _extractCurricularSectionImage(heading) ?? fallbackImageUrl;

    return CurricularClassesSection(
      title: title,
      schedule: '',
      description: description,
      imageUrl: imageUrl,
    );
  }

  /// Finds a curricular heading element whose cleaned text matches [match].
  Element? _findCurricularTitleElement(
    Document document,
    bool Function(String loweredText) match,
  ) {
    for (final Element heading in document.querySelectorAll('h2')) {
      final String text = _cleanHtml(heading.innerHtml).toLowerCase();
      if (match(text)) {
        return heading;
      }
    }

    for (final Element strong in document.querySelectorAll('strong')) {
      final String text = _cleanHtml(strong.innerHtml).toLowerCase();
      if (match(text)) {
        return strong;
      }
    }

    return null;
  }

  /// Returns the full paragraph text following [heading] in its column.
  String _extractCurricularDescription(Element heading) {
    Element? sibling = heading.nextElementSibling;
    while (sibling != null) {
      final String? tag = sibling.localName?.toLowerCase();
      if (tag == 'h1' || tag == 'h2' || tag == 'h3') {
        break;
      }

      final bool isParagraph =
          tag == 'div' &&
          (sibling.classes.contains('paragraph') ||
              sibling.querySelector('.paragraph') != null);
      if (isParagraph || tag == 'p') {
        final Element paragraph =
            sibling.classes.contains('paragraph') || tag == 'p'
            ? sibling
            : sibling.querySelector('.paragraph')!;
        final String text = _cleanHtml(paragraph.innerHtml);
        if (text.isNotEmpty) {
          return text;
        }
      }

      sibling = sibling.nextElementSibling;
    }

    // Fallback: paragraph elsewhere in the same multicol cell.
    final Element? cell = _findParentTd(heading);
    if (cell != null) {
      final Element? paragraph = cell.querySelector('.paragraph') ?? cell.querySelector('p');
      if (paragraph != null) {
        return _cleanHtml(paragraph.innerHtml);
      }
    }

    return '';
  }

  /// Resolves the image URL from the sibling multicol column of [heading].
  String? _extractCurricularSectionImage(Element heading) {
    final Element? cell = _findParentTd(heading);
    final Element? row = cell?.parent;
    if (cell == null || row == null) {
      return null;
    }

    for (final Element siblingCell in row.children) {
      if (identical(siblingCell, cell)) {
        continue;
      }
      if (siblingCell.localName != 'td') {
        continue;
      }

      for (final Element image in siblingCell.querySelectorAll('img')) {
        final String? url = _resolveImageUrl(image);
        if (url == null || url.isEmpty) {
          continue;
        }
        final String lower = url.toLowerCase();
        if (lower.contains('letterhead') ||
            lower.contains('logo') ||
            lower.contains('favicon')) {
          continue;
        }
        return url;
      }
    }

    return null;
  }

  Element? _findParentTd(Element element) {
    Element? current = element;
    while (current != null && current.localName != 'td') {
      current = current.parent;
    }
    return current;
  }

  List<UpcomingEvent> _parseUpcomingEvents(Document document) {
    final heading = _findHeading(document, 'upcoming events');
    if (heading == null) return const [];

    // Find the parent container that holds the events section
    Element? container = heading.parent;
    if (container == null) return const [];

    // Collect content from siblings following the heading, stopping at next section
    final List<String> eventLines = [];
    Element? current = heading.nextElementSibling;
    int depth = 0;
    const maxDepth = 10; // Prevent infinite loops

    while (current != null && depth < maxDepth) {
      // Stop if we encounter another heading (indicates next section)
      final tagName = current.localName?.toLowerCase() ?? '';
      if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(tagName)) {
        final headingText = _cleanHtml(current.innerHtml).toLowerCase();
        // Stop if this is a different section heading (not "upcoming events")
        if (!headingText.contains('upcoming events')) {
          break;
        }
      }

      // Preserve <br> as line breaks so each posted event becomes its own line
      final cleaned = _cleanUpcomingEventsHtml(current.innerHtml);
      if (cleaned.isNotEmpty) {
        final lines = cleaned
            .split(RegExp(r'\n+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        eventLines.addAll(lines);
      }

      // Move to next sibling
      current = current.nextElementSibling;
      depth++;
    }

    // If we didn't find content in siblings, try the parent's next sibling
    if (eventLines.isEmpty) {
      final parentNext = heading.parent?.nextElementSibling;
      if (parentNext != null) {
        final cleaned = _cleanUpcomingEventsHtml(parentNext.innerHtml);
        if (cleaned.isNotEmpty) {
          eventLines.addAll(
            cleaned
                .split(RegExp(r'\n+'))
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList(),
          );
        }
      }
    }

    if (eventLines.isEmpty) return const [];

    final entries = expandUpcomingEventLines(eventLines);
    final events = entries.map(upcomingEventFromEntry);
    return filterAndSortUpcomingEvents(events);
  }

  /// Cleans upcoming-events HTML while keeping `<br>` as newlines.
  ///
  /// The homepage posts multiple events in one paragraph separated by
  /// `<br /><br />`. Preserving those breaks makes each event its own line
  /// before weekday-boundary splitting runs as a fallback.
  String _cleanUpcomingEventsHtml(String html) {
    final withBreaks = html.replaceAll(
      RegExp(r'(<br\s*/?>)+', caseSensitive: false),
      '\n',
    );
    final fragment = html_parser.parseFragment(withBreaks);
    return (fragment.text ?? '')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  Element? _findHeading(Document document, String containsText) {
    final lowered = containsText.toLowerCase();
    for (final selector in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']) {
      for (final element in document.querySelectorAll(selector)) {
        final text = element.text.toLowerCase();
        if (text.contains(lowered)) {
          return element;
        }
      }
    }
    return null;
  }

  /// Helper method to clean HTML and extract plain text.
  /// 
  /// This method:
  /// 1. Converts HTML line breaks (`<br>` tags) to spaces (not newlines) for better text flow
  /// 2. Parses the HTML to extract text content (removes all HTML tags)
  /// 3. Replaces special characters (non-breaking spaces, zero-width spaces) with normal spaces
  /// 4. Normalizes line endings (converts \r to \n)
  /// 5. Removes excessive whitespace and normalizes spacing
  /// 
  /// This is useful because HTML contains tags like `<p>`, `<div>`, `<strong>`, etc.
  /// We only want the actual text content, not the formatting tags.
  /// 
  /// Example:
  /// Input: `<p>Hello <strong>world</strong>!</p><br>Next line`
  /// Output: `Hello world! Next line`
  String _cleanHtml(String html) {
    // Convert HTML line breaks to spaces (not newlines) to avoid weird line breaks
    // This regex matches `<br>`, `<br/>`, `<br />`, etc. (case-insensitive)
    final withBreaks = html.replaceAll(
      RegExp(r'(<br\s*/?>)+', caseSensitive: false),
      ' ',
    );
    
    // Parse the HTML fragment to extract just the text content
    // This removes all HTML tags and gives us plain text
    final fragment = html_parser.parseFragment(withBreaks);
    
    // Get the text content and clean up special characters
    final text = (fragment.text ?? '')
        .replaceAll('\u00A0', ' ')  // Replace non-breaking space with regular space
        .replaceAll('\u200B', '')   // Remove zero-width space characters
        .replaceAll('\r', ' ')      // Convert carriage returns to spaces
        .replaceAll('\n', ' ')      // Convert newlines to spaces
        .replaceAll(RegExp(r'\s+'), ' ')  // Replace multiple spaces with single space
        .trim();                    // Remove leading/trailing whitespace

    return text;
  }

  Future<EventsContent> getEventsContent({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    EventsContent? cachedContent;

    final cachedJson = prefs.getString(_eventsCacheKey);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(cachedJson) as Map,
        );
        cachedContent = EventsContent.fromJson(json);
      } catch (_) {
        cachedContent = null;
      }
    }

    if (!forceRefresh && cachedContent != null) {
      final age = DateTime.now().difference(cachedContent.fetchedAt);
      if (age <= _eventsCacheDuration) {
        return cachedContent;
      }
    }

    try {
      final freshContent = await fetchEventsContent();
      try {
        await prefs.setString(
          _eventsCacheKey,
          jsonEncode(freshContent.toJson()),
        );
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

  Future<EventsContent> fetchEventsContent() async {
    final response = await _client.get(Uri.parse(_eventsUrl));

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load events content (status: ${response.statusCode})',
        Uri.parse(_eventsUrl),
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
    final eventsUri = Uri.parse(_eventsUrl);
    final events = _parseEvents(document, eventsUri);

    return EventsContent(events: events, fetchedAt: DateTime.now());
  }

  BookstoreContent _parseBookstoreContent(Document document) {
    final DateTime now = DateTime.now();

    String title = 'Bookstore';
    final Element? titleElement = document.querySelector(
      'h2.wsite-content-title',
    );
    if (titleElement != null) {
      final cleanedTitle = _cleanHtml(titleElement.innerHtml);
      if (cleanedTitle.isNotEmpty) {
        title = cleanedTitle;
      }
    }

    Element? infoElement;
    for (final element in document.querySelectorAll('div.paragraph')) {
      final text = _cleanHtml(element.innerHtml).toLowerCase();
      if (text.contains('about us') && text.contains('bookstore')) {
        infoElement = element;
        break;
      }
    }

    // Preserve website <br> page breaks as newlines (do not use _cleanHtml here).
    final List<String> lines = infoElement != null
        ? _bookstoreLinesFromHtml(infoElement.innerHtml)
        : const [];

    final List<String> aboutLines = [];
    final List<String> locationLines = [];
    final List<String> hours = [];
    String? contactEmail;

    // Decode Cloudflare-protected emails from anchors before reading body text.
    if (infoElement != null) {
      for (final Element anchor in infoElement.querySelectorAll('a')) {
        final String? email = _extractEmailFromAnchor(anchor);
        if (email != null && email.isNotEmpty) {
          contactEmail = email;
          break;
        }
      }
    }

    String? currentSection;
    final RegExp emailRegex = RegExp(
      r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
    );

    for (final line in lines) {
      final String lowered = line.toLowerCase();
      if (lowered.startsWith('about us')) {
        currentSection = 'about';
        continue;
      }
      if (lowered.startsWith('location')) {
        currentSection = 'location';
        continue;
      }
      if (lowered.startsWith('hours')) {
        currentSection = 'hours';
        continue;
      }
      if (lowered.startsWith('questions')) {
        currentSection = 'questions';
        continue;
      }

      // Skip Cloudflare placeholder text such as "[email protected]".
      if (lowered.contains('[email') ||
          lowered.contains('email protected') ||
          lowered.contains('email\u00a0protected')) {
        continue;
      }

      final Match? emailMatch = emailRegex.firstMatch(line);
      if (emailMatch != null) {
        contactEmail ??= emailMatch.group(0);
        continue;
      }

      // Contact copy belongs in the Questions card (email only), not body text.
      if (currentSection == 'questions') {
        continue;
      }

      switch (currentSection) {
        case 'about':
          aboutLines.add(line);
          break;
        case 'location':
          locationLines.add(line);
          break;
        case 'hours':
          hours.add(line);
          break;
        default:
          break;
      }
    }

    final String about = aboutLines
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final List<String> sanitizedLocationLines = locationLines
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final List<String> sanitizedHours = hours
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return BookstoreContent(
      title: title.isNotEmpty ? title : 'Bookstore',
      about: about,
      locationLines: sanitizedLocationLines,
      hours: sanitizedHours,
      contactEmail: contactEmail,
      fetchedAt: now,
    );
  }

  /// Converts bookstore HTML into plain text lines, preserving `<br>` breaks.
  ///
  /// Unlike [_cleanHtml], this keeps website page breaks so About / Location /
  /// Hours / Questions can be split the same way as on bookstore.html.
  List<String> _bookstoreLinesFromHtml(String html) {
    final withBreaks = html.replaceAll(
      RegExp(r'(<br\s*/?>)+', caseSensitive: false),
      '\n',
    );
    final fragment = html_parser.parseFragment(withBreaks);
    final text = (fragment.text ?? '')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    return text
        .split('\n')
        .map(_normalizeBookstoreLine)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _normalizeBookstoreLine(String line) {
    final String normalizedWhitespace = line
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalizedWhitespace
        .replaceFirst(RegExp(r'^(?:[-•]+\s*)'), '')
        .trim();
  }

  List<Event> _parseEvents(Document document, Uri baseUri) {
    final List<Event> events = [];
    final Set<String> processedImages = <String>{};

    // Strategy 1: Parse table rows (events page uses table structure)
    final tableRows = document.querySelectorAll('table tr');
    for (final row in tableRows) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 2) continue;

      String? imageUrl;
      String? title;
      String? description;

      // Look for image in any cell
      for (final cell in cells) {
        final image = cell.querySelector('img');
        if (image != null) {
          final url = _resolveImageUrlWithBase(image, baseUri);
          if (url != null &&
              url.isNotEmpty &&
              _isLikelyEventImage(image, url)) {
            imageUrl = _stripTrackingParameters(url);
            break;
          }
        }
      }

      if (imageUrl == null || processedImages.contains(imageUrl)) {
        continue;
      }
      processedImages.add(imageUrl);

      // Look for text content in cells (usually in the cell without image)
      for (final cell in cells) {
        final hasImage = cell.querySelector('img') != null;
        if (hasImage) continue;

        final text = _cleanHtml(cell.innerHtml).trim();
        if (text.isEmpty || text.length < 10) continue;

        final lines = text
            .split(RegExp(r'\n+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

        if (lines.isEmpty) continue;

        // First line is usually title (may be bold or strong)
        String? cellTitle;
        final strong = cell.querySelector('strong');
        if (strong != null) {
          cellTitle = _cleanHtml(strong.innerHtml).trim();
        }
        if (cellTitle == null || cellTitle.isEmpty) {
          cellTitle = lines.first;
        }

        // Remove common prefixes and clean up
        cellTitle = cellTitle.replaceAll(RegExp(r'^[:\-\s]+'), '');

        // Check if it looks like a title (not too long, not generic)
        if (cellTitle.length < 3 ||
            cellTitle.length > 100 ||
            cellTitle.toLowerCase().contains('picture') ||
            cellTitle.toLowerCase().contains('image')) {
          continue;
        }

        title = cellTitle;

        // Rest of the lines are description
        // Skip the title line and collect the rest
        final descLines = <String>[];
        bool isFirstLine = true;
        for (final line in lines) {
          // Skip the first line if it matches the title
          if (isFirstLine && line.trim() == cellTitle.trim()) {
            isFirstLine = false;
            continue;
          }
          isFirstLine = false;

          final cleanLine = line.trim();
          if (cleanLine.isNotEmpty &&
              cleanLine != cellTitle &&
              !cleanLine.toLowerCase().contains('picture') &&
              !cleanLine.toLowerCase().contains('image')) {
            descLines.add(cleanLine);
          }
        }

        description = descLines.isNotEmpty ? descLines.join(' ').trim() : '';

        break;
      }

      if (title != null && title.isNotEmpty && imageUrl != null) {
        events.add(
          Event(
            title: title,
            imageUrl: imageUrl,
            description: description != null && description.isNotEmpty
                ? description
                : title,
          ),
        );
      }
    }

    // Strategy 2: If no events found from tables, try general image + text approach
    if (events.isEmpty) {
      final images = document.querySelectorAll('img');

      for (final image in images) {
        final imageUrl = _resolveImageUrlWithBase(image, baseUri);
        if (imageUrl == null || imageUrl.isEmpty) {
          continue;
        }

        if (!_isLikelyEventImage(image, imageUrl)) {
          continue;
        }

        final normalizedUrl = _stripTrackingParameters(imageUrl);
        if (processedImages.contains(normalizedUrl)) {
          continue;
        }
        processedImages.add(normalizedUrl);

        // Find associated text content near this image
        Element? container = image.parent;
        int depth = 0;
        while (container != null && depth < 5) {
          if (container.localName == 'div' ||
              container.localName == 'td' ||
              container.localName == 'section') {
            final text = _cleanHtml(container.innerHtml);
            if (text.isNotEmpty && text.length > 20) {
              final lines = text
                  .split(RegExp(r'\n+'))
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty)
                  .toList();

              if (lines.isNotEmpty) {
                String title = lines.first;
                String description = lines.length > 1
                    ? lines.sublist(1).join(' ').trim()
                    : '';

                if (title.length >= 3 &&
                    !title.toLowerCase().contains('image') &&
                    !title.toLowerCase().contains('photo') &&
                    !title.toLowerCase().contains('picture')) {
                  title = title.replaceAll(RegExp(r'^[:\-\s]+'), '');

                  if (title.isNotEmpty) {
                    events.add(
                      Event(
                        title: title,
                        imageUrl: normalizedUrl,
                        description: description.isNotEmpty
                            ? description
                            : title,
                      ),
                    );
                    break;
                  }
                }
              }
            }
          }
          container = container.parent;
          depth++;
        }
      }
    }

    return events;
  }

  String? _resolveImageUrlWithBase(Element image, Uri baseUri) {
    String? src = image.attributes['data-src']?.trim();
    src ??= image.attributes['data-original']?.trim();

    final String? srcSet =
        image.attributes['data-srcset']?.trim() ??
        image.attributes['srcset']?.trim();

    if ((src == null || src.isEmpty) && srcSet != null && srcSet.isNotEmpty) {
      src = srcSet
          .split(',')
          .map((entry) => entry.trim())
          .firstWhere((entry) => entry.isNotEmpty, orElse: () => '');
      final int spaceIndex = src.indexOf(' ');
      if (spaceIndex != -1) {
        src = src.substring(0, spaceIndex);
      }
    }

    src ??= image.attributes['src']?.trim();

    if (src == null || src.isEmpty) {
      return null;
    }

    if (src.startsWith('data:')) {
      return null;
    }

    final Uri uri = Uri.parse(src);
    final Uri resolved = uri.hasScheme ? uri : baseUri.resolveUri(uri);
    return resolved.toString();
  }

  bool _isLikelyEventImage(Element image, String url) {
    final lowerUrl = url.toLowerCase();
    const disallowedTokens = [
      'logo',
      'icon',
      'favicon',
      'badge',
      'sprite',
      'avatar',
      'social',
      'footer',
      'banner-ad',
      'header',
    ];

    if (disallowedTokens.any((token) => lowerUrl.contains(token))) {
      return false;
    }

    final parent = image.parent;
    final grandParent = parent?.parent;

    String _collectClasses(Node? node) {
      if (node is! Element) {
        return '';
      }
      final element = node;
      final elementClasses = <String>[];
      final classAttr = element.attributes['class'];
      if (classAttr != null && classAttr.isNotEmpty) {
        elementClasses.add(classAttr);
      }
      if (element.classes.isNotEmpty) {
        elementClasses.add(element.classes.join(' '));
      }
      return elementClasses.join(' ');
    }

    final String combinedClasses = ([
      _collectClasses(image),
      _collectClasses(parent),
      _collectClasses(grandParent),
    ].where((value) => value.isNotEmpty).join(' ')).toLowerCase();

    if (combinedClasses.contains('logo') || combinedClasses.contains('icon')) {
      return false;
    }

    final widthAttr = image.attributes['width'];
    if (widthAttr != null) {
      final width = int.tryParse(widthAttr);
      if (width != null && width <= 120) {
        return false;
      }
    }

    final heightAttr = image.attributes['height'];
    if (heightAttr != null) {
      final height = int.tryParse(heightAttr);
      if (height != null && height <= 120) {
        return false;
      }
    }

    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowedExtensions.any((ext) => lowerUrl.contains(ext))) {
      return false;
    }

    return true;
  }

  Future<AdmissionsContent> getAdmissionsContent({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    AdmissionsContent? cachedContent;

    final cachedJson = prefs.getString(_admissionsCacheKey);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(cachedJson) as Map,
        );
        cachedContent = AdmissionsContent.fromJson(json);
      } catch (_) {
        cachedContent = null;
      }
    }

    if (!forceRefresh && cachedContent != null) {
      final age = DateTime.now().difference(cachedContent.fetchedAt);
      if (age <= _admissionsCacheDuration) {
        return cachedContent;
      }
    }

    try {
      final freshContent = await fetchAdmissionsContent();
      try {
        await prefs.setString(
          _admissionsCacheKey,
          jsonEncode(freshContent.toJson()),
        );
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

  Future<AdmissionsContent> fetchAdmissionsContent() async {
    final uri = Uri.parse(_admissionsUrl);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load admissions content (status: ${response.statusCode})',
        uri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
    return _parseAdmissionsContent(document);
  }

  AdmissionsContent _parseAdmissionsContent(Document document) {
    String? kgFormUrl;
    String? alternateRouteFormUrl;
    final List<String> addressLines = [];
    List<AdmissionsParagraph> paragraphs = [];

    // Prefer the Weebly paragraph that contains the I. / II. / III. notice.
    Element? bodyElement;
    for (final element in document.querySelectorAll(
      'div.paragraph, div.wsite-text, div.wsite-content-title, p',
    )) {
      final plain = _cleanHtml(element.innerHtml).toLowerCase();
      if (plain.contains('i.') &&
          (plain.contains('admission') || plain.contains('kindergarten'))) {
        bodyElement = element;
        break;
      }
    }

    // Fallback: walk up from an ADMISSIONS heading.
    if (bodyElement == null) {
      final heading = _findHeading(document, 'admissions');
      if (heading != null) {
        Element? current = heading.parent;
        while (current != null && current.localName != 'body') {
          final text = _cleanHtml(current.innerHtml).toLowerCase();
          if (text.contains('i.') &&
              (text.contains('admission') || text.contains('kindergarten'))) {
            bodyElement = current;
            break;
          }
          current = current.parent;
        }
      }
    }

    bodyElement ??= document.body;

    if (bodyElement != null) {
      paragraphs = _parseAdmissionsRichParagraphs(bodyElement);
    }

    // Extract form URLs from anchor tags - search entire document
    final baseUri = Uri.parse(_admissionsUrl);
    for (final anchor in document.querySelectorAll('a')) {
      final href = anchor.attributes['href'];
      if (href == null || href.isEmpty) continue;

      final anchorText = _cleanHtml(anchor.innerHtml).toLowerCase();
      final resolvedUrl = _resolveHref(href, baseUri);
      if (resolvedUrl == null) continue;

      if (kgFormUrl == null &&
          (anchorText.contains('kg inquiry form') ||
              anchorText.contains('kindergarten inquiry') ||
              anchorText.contains('2026-27 kg') ||
              anchorText.contains('kg inquiry'))) {
        kgFormUrl = resolvedUrl;
      }

      if (alternateRouteFormUrl == null &&
          (anchorText.contains('alternate route inquiry') ||
              anchorText.contains('grades 1-5 inquiry') ||
              anchorText.contains('alternate route inquiry form') ||
              anchorText.contains('2026-27 alternate'))) {
        alternateRouteFormUrl = resolvedUrl;
      }
    }

    // Address: prefer a compact heading/span that lists Vivekananda + Hinchman.
    for (final element in document.querySelectorAll('h2, h3, span, div, p')) {
      final html = element.innerHtml;
      final plain = _cleanHtml(html);
      final lower = plain.toLowerCase();
      if (!lower.contains('vivekananda vidyapith') ||
          !lower.contains('hinchman')) {
        continue;
      }
      // Skip large containers that also include the I./II./III. body.
      if (lower.contains('i.') &&
          (lower.contains('closed') || lower.contains('kindergarten'))) {
        continue;
      }
      final lines = html
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('\u00A0', ' ')
          .replaceAll('\u200B', '')
          .replaceAll('&nbsp;', ' ')
          .split('\n')
          .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.length >= 2 &&
          lines.first.toLowerCase().contains('vivekananda vidyapith')) {
        addressLines
          ..clear()
          ..addAll(lines.take(3));
        break;
      }
    }

    if (addressLines.isEmpty) {
      addressLines.addAll([
        'Vivekananda Vidyapith',
        '20 Hinchman Avenue',
        'Wayne NJ 07470',
      ]);
    }

    return AdmissionsContent(
      paragraphs: paragraphs,
      kgFormUrl: kgFormUrl,
      alternateRouteFormUrl: alternateRouteFormUrl,
      addressLines: addressLines,
      fetchedAt: DateTime.now(),
    );
  }

  /// Parses admissions body HTML into paragraphs, preserving bold and underline.
  ///
  /// `<br>` tags become paragraph breaks (consecutive breaks collapse).
  /// `<strong>`/`<b>` set bold; `<u>` sets underline. Maroon color is ignored.
  List<AdmissionsParagraph> _parseAdmissionsRichParagraphs(Element root) {
    final List<List<AdmissionsTextSpan>> paragraphBuffers = [[]];

    void flushEmptyTrailing() {
      while (paragraphBuffers.length > 1 &&
          paragraphBuffers.last.every((s) => s.text.trim().isEmpty)) {
        paragraphBuffers.removeLast();
      }
    }

    void startNewParagraph() {
      final current = paragraphBuffers.last;
      final hasText = current.any((s) => s.text.trim().isNotEmpty);
      if (hasText) {
        paragraphBuffers.add([]);
      }
    }

    void appendSpan(String raw, {required bool bold, required bool underline}) {
      // Normalize whitespace but keep single spaces between words.
      var text = raw
          .replaceAll('\u00A0', ' ')
          .replaceAll('\u200B', '')
          .replaceAll(RegExp(r'[\n\r\t]+'), ' ');
      if (text.isEmpty) return;

      final buffer = paragraphBuffers.last;
      if (buffer.isNotEmpty) {
        final last = buffer.last;
        if (last.isBold == bold && last.isUnderlined == underline) {
          buffer[buffer.length - 1] = AdmissionsTextSpan(
            text: last.text + text,
            isBold: bold,
            isUnderlined: underline,
          );
          return;
        }
      }
      buffer.add(
        AdmissionsTextSpan(
          text: text,
          isBold: bold,
          isUnderlined: underline,
        ),
      );
    }

    void walk(Node node, {required bool bold, required bool underline}) {
      if (node.nodeType == Node.TEXT_NODE) {
        final value = node.text ?? '';
        if (value.isEmpty) return;
        appendSpan(value, bold: bold, underline: underline);
        return;
      }

      if (node is! Element) return;
      final tag = node.localName?.toLowerCase() ?? '';

      if (tag == 'br') {
        startNewParagraph();
        return;
      }

      // Skip scripts/styles and the ADMISSIONS page title if nested.
      if (tag == 'script' || tag == 'style') return;

      final nextBold = bold || tag == 'strong' || tag == 'b';
      final nextUnderline = underline || tag == 'u';

      for (final child in node.nodes) {
        walk(child, bold: nextBold, underline: nextUnderline);
      }
    }

    for (final child in root.nodes) {
      walk(child, bold: false, underline: false);
    }

    flushEmptyTrailing();

    return paragraphBuffers
        .map((spans) {
          // Collapse internal runs of spaces per span and trim paragraph edges.
          final cleaned = <AdmissionsTextSpan>[];
          for (final span in spans) {
            final text = span.text.replaceAll(RegExp(r' +'), ' ');
            if (text.isEmpty) continue;
            if (cleaned.isNotEmpty &&
                cleaned.last.isBold == span.isBold &&
                cleaned.last.isUnderlined == span.isUnderlined) {
              cleaned[cleaned.length - 1] = AdmissionsTextSpan(
                text: cleaned.last.text + text,
                isBold: span.isBold,
                isUnderlined: span.isUnderlined,
              );
            } else {
              cleaned.add(
                AdmissionsTextSpan(
                  text: text,
                  isBold: span.isBold,
                  isUnderlined: span.isUnderlined,
                ),
              );
            }
          }
          if (cleaned.isEmpty) {
            return const AdmissionsParagraph(spans: []);
          }
          // Trim leading/trailing whitespace on the paragraph.
          cleaned[0] = AdmissionsTextSpan(
            text: cleaned.first.text.replaceFirst(RegExp(r'^\s+'), ''),
            isBold: cleaned.first.isBold,
            isUnderlined: cleaned.first.isUnderlined,
          );
          cleaned[cleaned.length - 1] = AdmissionsTextSpan(
            text: cleaned.last.text.replaceFirst(RegExp(r'\s+$'), ''),
            isBold: cleaned.last.isBold,
            isUnderlined: cleaned.last.isUnderlined,
          );
          return AdmissionsParagraph(
            spans: cleaned.where((s) => s.text.isNotEmpty).toList(),
          );
        })
        .where((p) => p.spans.isNotEmpty)
        .toList();
  }

  Future<ContactContent> getContactContent({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    ContactContent? cachedContent;

    final cachedJson = prefs.getString(_contactCacheKey);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(cachedJson) as Map,
        );
        cachedContent = ContactContent.fromJson(json);
      } catch (_) {
        cachedContent = null;
      }
    }

    if (!forceRefresh && cachedContent != null) {
      final age = DateTime.now().difference(cachedContent.fetchedAt);
      if (age <= _contactCacheDuration) {
        return cachedContent;
      }
    }

    try {
      final freshContent = await fetchContactContent();
      try {
        await prefs.setString(
          _contactCacheKey,
          jsonEncode(freshContent.toJson()),
        );
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

  Future<ContactContent> fetchContactContent() async {
    final uri = Uri.parse(_contactUrl);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load contact content (status: ${response.statusCode})',
        uri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
    return _parseContactContent(document, uri);
  }

  ContactContent _parseContactContent(Document document, Uri baseUri) {
    String? phone;
    final List<String> addressLines = [];
    String? absenceTardyInstructions;
    String? admissionsUrl;
    String? mondayScripturalClassFormUrl;
    String? tablaClassFormUrl;
    String? registrationEmail;
    String? alumniEmail;
    String? heroImageUrl;
    String? generalNotice;

    // Extract phone number - look for "973-628-1877"
    final phonePattern = RegExp(r'973-628-1877');
    final allText = document.body?.text ?? '';
    if (phonePattern.hasMatch(allText)) {
      phone = '973-628-1877';
    }

    // Extract address - look for "Vivekananda Vidyapith" and "Hinchman Avenue"
    final addressPattern = RegExp(
      r'Vivekananda Vidyapith.*?20 Hinchman Avenue.*?Wayne.*?NJ.*?07470',
      caseSensitive: false,
      dotAll: true,
    );
    final addressMatch = addressPattern.firstMatch(allText);
    if (addressMatch != null) {
      final addressText = addressMatch.group(0);
      if (addressText != null) {
        final lines = addressText
            .split(RegExp(r'\s+'))
            .where((line) => line.trim().isNotEmpty)
            .toList();
        // Try to extract meaningful address lines
        if (lines.isNotEmpty) {
          addressLines.addAll([
            'Vivekananda Vidyapith',
            '20 Hinchman Avenue',
            'Wayne, NJ 07470',
          ]);
        }
      }
    }

    // Fallback: try to find address in table cells
    if (addressLines.isEmpty) {
      for (final td in document.querySelectorAll('table tr td')) {
        final text = _cleanHtml(td.innerHtml).toLowerCase();
        if (text.contains('hinchman') && text.contains('wayne')) {
          final cleaned = _cleanHtml(td.innerHtml);
          final lines = cleaned
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();
          if (lines.isNotEmpty) {
            // Look for address-like lines
            for (final line in lines) {
              if (line.toLowerCase().contains('vivekananda') ||
                  line.toLowerCase().contains('hinchman') ||
                  line.toLowerCase().contains('wayne')) {
                if (!addressLines.contains(line)) {
                  addressLines.add(line);
                }
              }
            }
          }
          break;
        }
      }
    }

    // Fallback to default address if still empty
    if (addressLines.isEmpty) {
      addressLines.addAll([
        'Vivekananda Vidyapith',
        '20 Hinchman Avenue',
        'Wayne, NJ 07470',
      ]);
    }

    // Extract Absence/Tardy instructions
    final absencePattern = RegExp(
      r'To report an.*?Absence.*?Tardy.*?8:30am',
      caseSensitive: false,
      dotAll: true,
    );
    final absenceMatch = absencePattern.firstMatch(allText);
    if (absenceMatch != null) {
      absenceTardyInstructions = absenceMatch.group(0)?.trim();
    } else {
      // Try to find it in list items
      for (final li in document.querySelectorAll('li')) {
        final text = _cleanHtml(li.innerHtml).toLowerCase();
        if (text.contains('absence') || text.contains('tardy')) {
          absenceTardyInstructions = _cleanHtml(li.innerHtml).trim();
          break;
        }
      }
    }

    // Extract image URL (hero image)
    for (final img in document.querySelectorAll('img')) {
      final url = _resolveImageUrlWithBase(img, baseUri);
      if (url != null &&
          url.isNotEmpty &&
          !url.toLowerCase().contains('logo') &&
          !url.toLowerCase().contains('icon') &&
          !url.toLowerCase().contains('favicon')) {
        heroImageUrl = url;
        break;
      }
    }

    // Extract form URLs and emails from anchor tags
    final baseUriParsed = Uri.parse(_contactUrl);
    for (final anchor in document.querySelectorAll('a')) {
      final href = anchor.attributes['href'];
      if (href == null || href.isEmpty) continue;

      final anchorText = _cleanHtml(anchor.innerHtml).toLowerCase();
      final resolvedUrl = _resolveHref(href, baseUriParsed);

      // Check for Admissions page link
      if (admissionsUrl == null &&
          (anchorText.contains('admissions') ||
              resolvedUrl?.toLowerCase().contains('admissions') == true)) {
        if (resolvedUrl != null &&
            resolvedUrl.contains('admissions') &&
            !resolvedUrl.contains('contact')) {
          admissionsUrl = resolvedUrl;
        }
      }

      // Check for Monday Scriptural Class Form
      if (mondayScripturalClassFormUrl == null &&
          (anchorText.contains('monday scriptural') ||
              anchorText.contains('scriptural class'))) {
        if (resolvedUrl != null &&
            (resolvedUrl.contains('docs.google.com') ||
                resolvedUrl.contains('form'))) {
          mondayScripturalClassFormUrl = resolvedUrl;
        }
      }

      // Check for Tabla Class Form
      if (tablaClassFormUrl == null &&
          (anchorText.contains('tabla') || anchorText.contains('tabla class'))) {
        if (resolvedUrl != null &&
            (resolvedUrl.contains('docs.google.com') ||
                resolvedUrl.contains('form'))) {
          tablaClassFormUrl = resolvedUrl;
        }
      }

      // Extract emails using existing helper
      final email = _extractEmailFromAnchor(anchor);
      if (email != null && email.isNotEmpty) {
        final lowerEmail = email.toLowerCase();
        if (lowerEmail.contains('registration') ||
            lowerEmail.contains('registrar') ||
            (registrationEmail == null && !lowerEmail.contains('alumni'))) {
          registrationEmail ??= email;
        } else if (lowerEmail.contains('alumni')) {
          alumniEmail ??= email;
        }
      }
    }

    // Extract general notice about teacher emails
    final noticePattern = RegExp(
      r'All teachers can be reached.*?email addresses.*?Thank you',
      caseSensitive: false,
      dotAll: true,
    );
    final noticeMatch = noticePattern.firstMatch(allText);
    if (noticeMatch != null) {
      generalNotice = noticeMatch.group(0)?.trim();
    } else {
      // Try to find it in paragraphs
      for (final p in document.querySelectorAll('p')) {
        final text = _cleanHtml(p.innerHtml).toLowerCase();
        if (text.contains('teachers can be reached') ||
            text.contains('should not be sent')) {
          generalNotice = _cleanHtml(p.innerHtml).trim();
          break;
        }
      }
    }

    return ContactContent(
      phone: phone,
      addressLines: addressLines,
      absenceTardyInstructions: absenceTardyInstructions,
      admissionsUrl: admissionsUrl,
      mondayScripturalClassFormUrl: mondayScripturalClassFormUrl,
      tablaClassFormUrl: tablaClassFormUrl,
      registrationEmail: registrationEmail,
      alumniEmail: alumniEmail,
      heroImageUrl: heroImageUrl,
      generalNotice: generalNotice,
      fetchedAt: DateTime.now(),
    );
  }

  /// Returns archives content from cache when fresh, otherwise fetches it.
  ///
  /// Uses a 24-hour cache. On network failure, returns stale cache when
  /// available; otherwise rethrows.
  Future<ArchivesContent> getArchivesContent({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    ArchivesContent? cachedContent;

    final cachedJson = prefs.getString(_archivesCacheKey);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(cachedJson) as Map,
        );
        cachedContent = ArchivesContent.fromJson(json);
      } catch (_) {
        cachedContent = null;
      }
    }

    if (!forceRefresh && cachedContent != null) {
      final age = DateTime.now().difference(cachedContent.fetchedAt);
      if (age <= _archivesCacheDuration) {
        return cachedContent;
      }
    }

    try {
      final freshContent = await fetchArchivesContent();
      try {
        await prefs.setString(
          _archivesCacheKey,
          jsonEncode(freshContent.toJson()),
        );
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

  /// Fetches and parses the Archives page from the live website.
  Future<ArchivesContent> fetchArchivesContent() async {
    final uri = Uri.parse(_archivesUrl);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to load archives content (status: ${response.statusCode})',
        uri,
      );
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
    return parseArchivesDocument(document);
  }

  /// Parses an Archives page [Document] into [ArchivesContent].
  ///
  /// Prefer `#wsite-content` so navigation/footer links are ignored.
  /// Titles have surrounding asterisks stripped; hrefs are resolved to
  /// absolute URLs.
  ArchivesContent parseArchivesDocument(Document document) {
    final Element? root =
        document.querySelector('#wsite-content') ??
        document.querySelector('.wsite-elements') ??
        document.body;

    final baseUri = Uri.parse(_archivesUrl);
    final List<ArchiveItem> items = [];
    final Set<String> seenUrls = <String>{};

    if (root != null) {
      for (final anchor in root.querySelectorAll('a')) {
        final href = anchor.attributes['href']?.trim();
        if (href == null || href.isEmpty) continue;
        if (href.startsWith('mailto:') ||
            href.startsWith('javascript:') ||
            href.startsWith('#')) {
          continue;
        }

        final resolvedUrl = _resolveHref(href, baseUri);
        if (resolvedUrl == null || resolvedUrl.isEmpty) continue;

        final title = _normalizeArchiveTitle(
          _cleanHtml(anchor.innerHtml),
        );
        if (title.isEmpty) continue;
        if (title.toLowerCase() == 'archives') continue;

        if (!seenUrls.add(resolvedUrl)) continue;

        items.add(ArchiveItem(title: title, url: resolvedUrl));
      }
    }

    final intro = _parseArchivesIntro(root);

    return ArchivesContent(
      intro: intro,
      items: items,
      fetchedAt: DateTime.now(),
    );
  }

  /// Builds the intro paragraph by stripping archive links from content text.
  String _parseArchivesIntro(Element? root) {
    if (root == null) return '';

    Element? paragraph;
    for (final selector in ['.paragraph', 'p', 'div.wsite-text']) {
      final candidates = root.querySelectorAll(selector);
      for (final candidate in candidates) {
        final text = _cleanHtml(candidate.innerHtml);
        if (text.length < 40) continue;
        paragraph = candidate;
        break;
      }
      if (paragraph != null) break;
    }

    final Element source = paragraph ?? root;
    final withoutLinks = source.innerHtml.replaceAll(
      RegExp(r'<a\b[^>]*>[\s\S]*?</a>', caseSensitive: false),
      ' ',
    );
    var intro = _cleanHtml(withoutLinks);
    intro = intro.replaceAll('*', '').replaceAll(RegExp(r'\s+'), ' ').trim();

    // Drop leftover empty punctuation-only fragments after link removal.
    if (intro.length < 20) return '';
    return intro;
  }

  /// Strips asterisks and collapses whitespace in archive link titles.
  String _normalizeArchiveTitle(String raw) {
    return raw
        .replaceAll('*', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================
  
  /// Cleans up resources by closing the HTTP client.
  /// 
  /// Always call this when you're done with the WebsiteScraper to free up
  /// network resources. This is especially important in long-running apps
  /// to prevent memory leaks.
  /// 
  /// Example:
  /// ```dart
  /// final scraper = WebsiteScraper();
  /// // ... use scraper ...
  /// scraper.dispose(); // Clean up when done
  /// ```
  void dispose() {
    _client.close();
  }
}
