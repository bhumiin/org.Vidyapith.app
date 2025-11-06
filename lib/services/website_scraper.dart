import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/website_content.dart';

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

  // ============================================================================
  // CONSTANTS - Cache Keys
  // ============================================================================
  // These keys identify where we store cached data in local storage (SharedPreferences).
  // Each content type has its own cache key so they can be stored separately.
  
  /// Cache key for homepage content (thought of the day, events, images)
  static const String _cacheKey = 'website_content_cache_v1';
  
  /// Cache key for events page content
  static const String _eventsCacheKey = 'events_content_cache_v1';
  
  /// Cache key for bookstore content
  static const String _bookstoreCacheKey = 'bookstore_content_cache_v1';
  
  /// Cache key for donation content
  static const String _donateCacheKey = 'donate_content_cache_v1';
  
  /// Cache key for admissions content (v2 indicates this is version 2)
  static const String _admissionsCacheKey = 'admissions_content_cache_v2';
  
  /// Cache key for contact content
  static const String _contactCacheKey = 'contact_content_cache_v1';

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

    // Extract different parts of the content using helper methods
    final thought = _parseThoughtOfTheDay(document);
    final events = _parseUpcomingEvents(document);
    final carouselImages = _parseCarouselImages(document);

    // Combine everything into a WebsiteContent object
    return WebsiteContent(
      thoughtOfTheDay: thought,
      upcomingEvents: events,
      carouselImages: carouselImages,
      fetchedAt: DateTime.now(), // Record when we fetched this data
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
    final (
      String? email,
      String? instruction,
      String? qrImageUrl
    ) zelleInfo = _extractZelleInfo(document, baseUri);
    final (
      String? checkInstruction,
      List<String> addressLines,
      String? paypalInstruction,
      String? paypalUrl,
      String? paypalNote,
      String? creditCardInstruction,
      String? creditCardUrl,
      String? creditCardNote,
      String? matchingInstruction,
      String? matchingUrl
    ) methodsInfo = _extractOtherDonateInfo(document, baseUri);

    final List<String> mailingAddress = methodsInfo.$2.isNotEmpty
        ? methodsInfo.$2
        : _fallbackDonateAddress;

    return DonateContent(
      introParagraphs: introParagraphs,
      zelleEmail: zelleInfo.$1,
      zelleInstruction: zelleInfo.$2,
      zelleQrImageUrl: zelleInfo.$3,
      checkInstruction: methodsInfo.$1,
      checkMailingAddress: mailingAddress,
      paypalGivingInstruction: methodsInfo.$3,
      paypalGivingUrl: methodsInfo.$4,
      paypalGivingNote: methodsInfo.$5,
      creditCardInstruction: methodsInfo.$6,
      creditCardUrl: methodsInfo.$7,
      creditCardNote: methodsInfo.$8,
      matchingGrantInstruction: methodsInfo.$9,
      matchingFormUrl: methodsInfo.$10,
      fetchedAt: DateTime.now(),
    );
  }

  List<String> _extractDonateIntro(Document document) {
    for (final element in document.querySelectorAll('div.paragraph, p')) {
      final text = _cleanHtml(element.innerHtml);
      final lowered = text.toLowerCase();
      if (lowered.contains('vivekananda vidyapith relies') ||
          lowered.contains('donations') && text.trim().isNotEmpty) {
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

  (
    String?,
    String?,
    String?,
  ) _extractZelleInfo(Document document, Uri baseUri) {
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
    String?,
    String?,
    String?,
  ) _extractOtherDonateInfo(Document document, Uri baseUri) {
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
      return (null, const [], null, null, null, null, null, null, null, null);
    }

    String? checkInstruction;
    final List<String> addressLines = [];
    String? paypalInstruction;
    String? paypalUrl;
    String? paypalNote;
    String? creditCardInstruction;
    String? creditCardUrl;
    String? creditCardNote;
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
            lowered.startsWith('please note');
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
      } else if (lowered.contains('credit card')) {
        if (lowered.startsWith('please note')) {
          creditCardNote ??= line;
        } else {
          creditCardInstruction ??= line;
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
      } else if (loweredHref.contains('paypal.com') &&
          loweredHref.contains('donate')) {
        creditCardUrl ??= resolved;
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
      creditCardInstruction,
      creditCardUrl,
      creditCardNote,
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

  Future<CurricularClassesContent> fetchCurricularClassesContent({
    String? thumbnailOverride,
  }) async {
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
        );

    final CurricularClassesSection? adultsSection = _extractCurricularSection(
      document,
      match: (text) => text.contains('adults'),
    );

    if (youngstersSection == null || adultsSection == null) {
      throw StateError('Unable to parse curricular classes sections.');
    }

    final String thumbnailUrl =
        thumbnailOverride ?? _extractCurricularThumbnail(document) ?? '';

    return CurricularClassesContent(
      youngstersSection: youngstersSection,
      adultsSection: adultsSection,
      thumbnailUrl: thumbnailUrl,
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

  MusicClassSection? _extractMusicSection(
    Document document, {
    required bool Function(String loweredText) match,
  }) {
    Element? targetTd;

    // First try to find by strong tag
    for (final strong in document.querySelectorAll('strong')) {
      final text = _cleanHtml(strong.innerHtml).toLowerCase();
      if (match(text)) {
        targetTd = _findParentTd(strong);
        break;
      }
    }

    // If not found, search all table cells
    if (targetTd == null) {
      for (final td in document.querySelectorAll('table tr td')) {
        final text = _cleanHtml(td.innerHtml).toLowerCase();
        if (match(text)) {
          targetTd = td;
          break;
        }
      }
    }

    if (targetTd == null || targetTd.localName != 'td') {
      return null;
    }

    // Extract form URL from anchor tag if present
    String? formUrl;
    final anchor =
        targetTd.querySelector('a[href*="docs.google.com"]') ??
        targetTd.querySelector('a');
    if (anchor != null) {
      formUrl = anchor.attributes['href'];
      if (formUrl != null && !formUrl.startsWith('http')) {
        formUrl = 'https://www.vidyapith.org$formUrl';
      }
    }

    final cleaned = _cleanHtml(targetTd.innerHtml);
    final lines = cleaned
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return null;
    }

    String title = '';
    String teachers = '';
    String schedule = '';
    String description = '';

    // Find title - usually the first line or contains the class type
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (match(lower) && title.isEmpty) {
        title = line;
        break;
      }
    }

    // If title not found, use first line
    if (title.isEmpty) {
      title = lines.first;
    }

    // Extract teachers (usually contains "Taught by")
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('taught by')) {
        teachers = line
            .replaceAll(RegExp(r'^.*?taught by', caseSensitive: false), '')
            .trim();
        break;
      }
    }

    // Extract schedule (usually contains day and time)
    for (final line in lines) {
      final lower = line.toLowerCase();
      if ((lower.contains('saturday') ||
              lower.contains('sunday') ||
              lower.contains('monday') ||
              lower.contains('tuesday') ||
              lower.contains('wednesday') ||
              lower.contains('thursday') ||
              lower.contains('friday')) &&
          (lower.contains('pm') ||
              lower.contains('am') ||
              lower.contains(':') ||
              lower.contains('time'))) {
        schedule = line;
        break;
      }
    }

    // Remaining text goes to description
    final descriptionLines = <String>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (line != title &&
          !lower.contains('taught by') &&
          !lower.contains('inquiry form') &&
          !lower.contains('submit') &&
          schedule != line) {
        descriptionLines.add(line);
      }
    }
    description = descriptionLines.join(' ').trim();

    return MusicClassSection(
      title: title,
      teachers: teachers.isEmpty ? '' : teachers,
      schedule: schedule.isEmpty ? '' : schedule,
      description: description.isEmpty ? '' : description,
      formUrl: formUrl,
    );
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

  String _extractSummerCampDescription(Document document) {
    // Look for table cells containing "summer camp" text
    for (final td in document.querySelectorAll('table tr td')) {
      final text = _cleanHtml(td.innerHtml).toLowerCase();
      if (text.contains('summer camp') && text.contains('invigorating')) {
        final cleaned = _cleanHtml(td.innerHtml);
        final lines = cleaned
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

        // Find the description text (after "Summer Camp" title)
        String description = '';
        bool foundTitle = false;

        for (final line in lines) {
          final lower = line.toLowerCase();
          if (lower.contains('summer camp') && !foundTitle) {
            foundTitle = true;
            // Skip the title line, get the description
            continue;
          }
          if (foundTitle && line.isNotEmpty) {
            if (description.isNotEmpty) {
              description += ' $line';
            } else {
              description = line;
            }
          }
        }

        if (description.isNotEmpty) {
          return description;
        }
      }
    }

    // Fallback: try to find any table cell with substantial text
    for (final td in document.querySelectorAll('table tr td')) {
      final cleaned = _cleanHtml(td.innerHtml);
      final lines = cleaned
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      if (lines.length > 1) {
        final text = cleaned.toLowerCase();
        if (text.contains('summer camp') && text.contains('vidyapith')) {
          // Extract description part (skip title)
          final descriptionLines = lines.skip(1).where((line) {
            final lower = line.toLowerCase();
            return !lower.contains('summer camp') ||
                !lower.contains('vidyapith');
          }).toList();

          if (descriptionLines.isEmpty) {
            // If no separate description, use all lines after first
            return lines.skip(1).join(' ').trim();
          }

          return descriptionLines.join(' ').trim();
        }
      }
    }

    return 'Summer Camp information unavailable.';
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

  CurricularClassesSection? _extractCurricularSection(
    Document document, {
    required bool Function(String loweredText) match,
  }) {
    Element? targetTd;

    for (final strong in document.querySelectorAll('strong')) {
      final text = _cleanHtml(strong.innerHtml).toLowerCase();
      if (match(text)) {
        targetTd = _findParentTd(strong);
        break;
      }
    }

    if (targetTd == null) {
      for (final td in document.querySelectorAll('table tr td')) {
        final text = _cleanHtml(td.innerHtml).toLowerCase();
        if (match(text)) {
          targetTd = td;
          break;
        }
      }
    }

    if (targetTd == null || targetTd.localName != 'td') {
      return null;
    }

    final lines = _cleanHtml(targetTd.innerHtml)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return null;
    }

    final title = lines.first;
    String schedule = '';
    final List<String> descriptionLines = [];

    for (final line in lines.skip(1)) {
      final lower = line.toLowerCase();
      if (schedule.isEmpty &&
          (lower.startsWith('classes are held') ||
              lower.startsWith('scriptural study classes are held'))) {
        schedule = line;
      } else {
        descriptionLines.add(line);
      }
    }

    final description = descriptionLines.join(' ');

    return CurricularClassesSection(
      title: title,
      schedule: schedule,
      description: description,
    );
  }

  Element? _findParentTd(Element element) {
    Element? current = element;
    while (current != null && current.localName != 'td') {
      current = current.parent;
    }
    return current;
  }

  String? _extractCurricularThumbnail(Document document) {
    for (final image in document.querySelectorAll('img')) {
      final url = _resolveImageUrl(image);
      if (url == null || url.isEmpty) {
        continue;
      }
      if (url.contains('6185815')) {
        return url;
      }
    }

    final firstImage = document.querySelector('img');
    if (firstImage != null) {
      return _resolveImageUrl(firstImage);
    }

    return null;
  }

  List<UpcomingEvent> _parseUpcomingEvents(Document document) {
    final heading = _findHeading(document, 'upcoming events');
    if (heading == null) return const [];

    final paragraph =
        heading.nextElementSibling ?? heading.parent?.nextElementSibling;
    if (paragraph == null) return const [];

    final cleaned = _cleanHtml(paragraph.innerHtml);
    if (cleaned.isEmpty) return const [];

    final entries = cleaned
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return entries.map((entry) {
      final segments = entry.split(' - ');
      final title = segments.isNotEmpty ? segments.last.trim() : entry.trim();
      final details = segments.length > 1
          ? segments.sublist(0, segments.length - 1).join(' - ').trim()
          : null;
      return UpcomingEvent(
        title: title,
        details: (details != null && details.isNotEmpty) ? details : null,
      );
    }).toList();
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
  /// 1. Converts HTML line breaks (`<br>` tags) to newlines
  /// 2. Parses the HTML to extract text content (removes all HTML tags)
  /// 3. Replaces special characters (non-breaking spaces, zero-width spaces) with normal spaces
  /// 4. Normalizes line endings (converts \r to \n)
  /// 5. Removes empty lines and trims whitespace from each line
  /// 
  /// This is useful because HTML contains tags like `<p>`, `<div>`, `<strong>`, etc.
  /// We only want the actual text content, not the formatting tags.
  /// 
  /// Example:
  /// Input: `<p>Hello <strong>world</strong>!</p><br>Next line`
  /// Output: `Hello world!\nNext line`
  String _cleanHtml(String html) {
    // Convert HTML line breaks to newline characters
    // This regex matches `<br>`, `<br/>`, `<br />`, etc. (case-insensitive)
    final withBreaks = html.replaceAll(
      RegExp(r'(<br\s*/?>)+', caseSensitive: false),
      '\n',
    );
    
    // Parse the HTML fragment to extract just the text content
    // This removes all HTML tags and gives us plain text
    final fragment = html_parser.parseFragment(withBreaks);
    
    // Get the text content and clean up special characters
    final text = (fragment.text ?? '')
        .replaceAll('\u00A0', ' ')  // Replace non-breaking space with regular space
        .replaceAll('\u200B', '')   // Remove zero-width space characters
        .replaceAll('\r', '\n');    // Normalize line endings (Windows uses \r\n)

    // Split into lines, trim each line, remove empty lines, then join back
    return text
        .split(RegExp(r'\n+'))           // Split on one or more newlines
        .map((line) => line.trim())       // Remove leading/trailing whitespace from each line
        .where((line) => line.isNotEmpty) // Remove empty lines
        .join('\n');                      // Join back with single newlines
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

    final List<String> lines = infoElement != null
        ? _cleanHtml(infoElement.innerHtml)
              .split('\n')
              .map(_normalizeBookstoreLine)
              .where((line) => line.isNotEmpty)
              .toList()
        : const [];

    final List<String> aboutLines = [];
    final List<String> locationLines = [];
    final List<String> hours = [];
    String? contactEmail;

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

      final Match? emailMatch = emailRegex.firstMatch(line);
      if (emailMatch != null) {
        contactEmail ??= emailMatch.group(0);
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

    String about = aboutLines.join(' ');
    if (about.isEmpty && infoElement != null) {
      about = _cleanHtml(
        infoElement.innerHtml,
      ).replaceAll(RegExp(r'About Us\s*:?', caseSensitive: false), '').trim();
    }

    about = about.replaceAll(RegExp(r'\s+'), ' ').trim();

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
    String? sectionI;
    String? sectionII;
    String? sectionIII;
    String? sectionIV;
    String? kgFormUrl;
    String? alternateRouteFormUrl;
    final List<String> addressLines = [];

    // Find the main content area - typically within a div or table
    Element? mainContent;
    
    // Try to find content by looking for "ADMISSIONS" heading
    final heading = _findHeading(document, 'admissions');
    if (heading != null) {
      // Find the parent container that holds all sections
      Element? current = heading.parent;
      while (current != null && current.localName != 'body') {
        final text = _cleanHtml(current.innerHtml).toLowerCase();
        if (text.contains('new admissions') || text.contains('kindergarten')) {
          mainContent = current;
          break;
        }
        current = current.parent;
      }
    }

    // If not found by heading, try to find by table or div structure
    if (mainContent == null) {
      for (final element in document.querySelectorAll('div.paragraph, div.wsite-text, table')) {
        final text = _cleanHtml(element.innerHtml).toLowerCase();
        if (text.contains('admissions') && 
            (text.contains('new admissions') || text.contains('kindergarten'))) {
          mainContent = element;
          break;
        }
      }
    }

    // If still not found, use body as fallback
    mainContent ??= document.body;

    if (mainContent != null) {
      final cleaned = _cleanHtml(mainContent.innerHtml);
      final lines = cleaned
          .split(RegExp(r'\n+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final List<String> sectionILines = [];
      final List<String> sectionIILines = [];
      final List<String> sectionIIILines = [];
      final List<String> sectionIVLines = [];
      String? currentSection;

      for (final line in lines) {
        final lower = line.toLowerCase();
        
        // Detect section markers
        if (lower.contains('i. new admissions') || 
            (lower.contains('new admissions') && lower.contains('closed'))) {
          currentSection = 'I';
          // Include the section header line
          sectionILines.add(line);
        } else if (lower.contains('ii.') && lower.contains('kindergarten')) {
          currentSection = 'II';
          // Include the section header line
          sectionIILines.add(line);
        } else if (lower.contains('iii.') && (lower.contains('grades') || lower.contains('1-5'))) {
          currentSection = 'III';
          // Include the section header line
          sectionIIILines.add(line);
        } else if (lower.contains('iv.') || 
                   (lower.contains('beyond') && lower.contains('5th grade'))) {
          currentSection = 'IV';
          // Include the section header line
          sectionIVLines.add(line);
        } else if (lower.contains('vivekananda vidyapith') && 
                   lower.contains('hinchman')) {
          // Address section
          addressLines.add(line);
          continue;
        } else {
          // Add line to appropriate section
          switch (currentSection) {
            case 'I':
              sectionILines.add(line);
              break;
            case 'II':
              sectionIILines.add(line);
              break;
            case 'III':
              sectionIIILines.add(line);
              break;
            case 'IV':
              sectionIVLines.add(line);
              break;
          }
        }
      }

      // Remove section headers (I., II., III., IV.) from content
      sectionI = sectionILines.isNotEmpty 
          ? sectionILines
              .join('\n\n')
              .replaceAll(RegExp(r'^I\.?\s*', caseSensitive: false), '')
              .trim() 
          : null;
      sectionII = sectionIILines.isNotEmpty 
          ? sectionIILines
              .join('\n\n')
              .replaceAll(RegExp(r'^II\.?\s*', caseSensitive: false), '')
              .trim() 
          : null;
      sectionIII = sectionIIILines.isNotEmpty 
          ? sectionIIILines
              .join('\n\n')
              .replaceAll(RegExp(r'^III\.?\s*', caseSensitive: false), '')
              .trim() 
          : null;
      sectionIV = sectionIVLines.isNotEmpty 
          ? sectionIVLines
              .join('\n\n')
              .replaceAll(RegExp(r'^IV\.?\s*', caseSensitive: false), '')
              .trim() 
          : null;

      // Extract form URLs from anchor tags - search entire document
      final baseUri = Uri.parse(_admissionsUrl);
      for (final anchor in document.querySelectorAll('a')) {
        final href = anchor.attributes['href'];
        if (href == null || href.isEmpty) continue;
        
        final anchorText = _cleanHtml(anchor.innerHtml).toLowerCase();
        final resolvedUrl = _resolveHref(href, baseUri);
        if (resolvedUrl == null) continue;
        
        // Look for KG Inquiry Form - more flexible matching
        if (kgFormUrl == null && 
            (anchorText.contains('kg inquiry form') || 
             anchorText.contains('kindergarten inquiry') ||
             anchorText.contains('2026-27 kg') ||
             anchorText.contains('kg inquiry'))) {
          kgFormUrl = resolvedUrl;
        }
        
        // Look for Alternate Route Inquiry Form - more flexible matching
        if (alternateRouteFormUrl == null && 
            (anchorText.contains('alternate route inquiry') ||
             anchorText.contains('grades 1-5 inquiry') ||
             anchorText.contains('alternate route inquiry form') ||
             anchorText.contains('2026-27 alternate'))) {
          alternateRouteFormUrl = resolvedUrl;
        }
      }

      // If sections weren't found by markers, try to parse by content patterns
      if (sectionI == null && sectionII == null && sectionIII == null && sectionIV == null) {
        // Fallback: parse entire content and split by logical breaks
        final allText = cleaned;
        
        // Try to extract sections using regex patterns
        final sectionIPattern = RegExp(
          r'(I\.?\s*New\s+Admissions[^\n]*(?:\n(?!I{1,3}\.)[^\n]*)*)',
          caseSensitive: false,
          dotAll: true,
        );
        final sectionIIPattern = RegExp(
          r'(II\.?\s*For\s+Admission[^\n]*(?:\n(?!I{1,3}\.)[^\n]*)*)',
          caseSensitive: false,
          dotAll: true,
        );
        final sectionIIIPattern = RegExp(
          r'(III\.?\s*For\s+Admission[^\n]*(?:\n(?!I{1,3}\.)[^\n]*)*)',
          caseSensitive: false,
          dotAll: true,
        );
        final sectionIVPattern = RegExp(
          r'(IV\.?\s*Because[^\n]*(?:\n(?!I{1,3}\.)[^\n]*)*)',
          caseSensitive: false,
          dotAll: true,
        );

        final sectionIMatch = sectionIPattern.firstMatch(allText);
        final sectionIIMatch = sectionIIPattern.firstMatch(allText);
        final sectionIIIMatch = sectionIIIPattern.firstMatch(allText);
        final sectionIVMatch = sectionIVPattern.firstMatch(allText);

        sectionI = sectionIMatch?.group(1)?.trim()
            ?.replaceAll(RegExp(r'^I\.?\s*', caseSensitive: false), '')
            ?.trim();
        sectionII = sectionIIMatch?.group(1)?.trim()
            ?.replaceAll(RegExp(r'^II\.?\s*', caseSensitive: false), '')
            ?.trim();
        sectionIII = sectionIIIMatch?.group(1)?.trim()
            ?.replaceAll(RegExp(r'^III\.?\s*', caseSensitive: false), '')
            ?.trim();
        sectionIV = sectionIVMatch?.group(1)?.trim()
            ?.replaceAll(RegExp(r'^IV\.?\s*', caseSensitive: false), '')
            ?.trim();
      }

      // Extract address if not already found
      if (addressLines.isEmpty) {
        final addressPattern = RegExp(
          r'(Vivekananda\s+Vidyapith\s+(?:\d+\s+)?[^\n]+\n[^\n]+\n[^\n]+)',
          caseSensitive: false,
        );
        final addressMatch = addressPattern.firstMatch(cleaned);
        if (addressMatch != null) {
          final addressText = addressMatch.group(1);
          if (addressText != null) {
            addressLines.addAll(
              addressText
                  .split('\n')
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty),
            );
          }
        }
      }
    }

    // Fallback address if not found
    if (addressLines.isEmpty) {
      addressLines.addAll([
        'Vivekananda Vidyapith',
        '20 Hinchman Avenue',
        'Wayne NJ 07470',
      ]);
    }

    return AdmissionsContent(
      sectionI: sectionI,
      sectionII: sectionII,
      sectionIII: sectionIII,
      sectionIV: sectionIV,
      kgFormUrl: kgFormUrl,
      alternateRouteFormUrl: alternateRouteFormUrl,
      addressLines: addressLines,
      fetchedAt: DateTime.now(),
    );
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
