import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vidyapith_hybrid_app/core/vidyapith_urls.dart';
import 'package:vidyapith_hybrid_app/services/calendar_scraper.dart';

const _sampleIcs = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//EN
BEGIN:VEVENT
DTSTART:20260919T210000Z
DTEND:20260919T233000Z
SUMMARY:Janmashtami Celebration
LOCATION:Vivekananda Vidyapith Inc\, 20 Hinchman Ave
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20270529
DTEND;VALUE=DATE:20270530
SUMMARY:No classes at Vidyapith - Memorial Day holiday
END:VEVENT
BEGIN:VEVENT
DTSTART:20261219T140000Z
SUMMARY:Youth Day I - Writing Event
DESCRIPTION:Bring notebooks
END:VEVENT
END:VCALENDAR
''';

void main() {
  group('vidyapithGoogleCalendarIcsUrl', () {
    test('points at the public basic.ics feed', () {
      expect(
        vidyapithGoogleCalendarIcsUrl,
        contains('calendar.google.com/calendar/ical/'),
      );
      expect(vidyapithGoogleCalendarIcsUrl, endsWith('/public/basic.ics'));
      expect(
        vidyapithGoogleCalendarIcsUrl,
        contains(Uri.encodeComponent(vidyapithGoogleCalendarId)),
      );
    });
  });

  group('parseIcsToCalendarContent', () {
    test('maps timed and all-day VEVENTs into months', () {
      final content = parseIcsToCalendarContent(
        _sampleIcs,
        fetchedAt: DateTime.utc(2026, 9, 15),
      );

      final sep2026 = content.getEventsForMonth(9, 2026);
      expect(sep2026, hasLength(1));
      expect(sep2026.single.title, 'Janmashtami Celebration');
      expect(sep2026.single.isVidyapithEvent, isTrue);
      expect(
        sep2026.single.description,
        'Vivekananda Vidyapith Inc, 20 Hinchman Ave',
      );

      final may2027 = content.getEventsForMonth(5, 2027);
      expect(may2027, hasLength(1));
      expect(may2027.single.title, contains('Memorial Day'));
      expect(may2027.single.isHoliday, isTrue);
      expect(may2027.single.date, DateTime(2027, 5, 29));

      final dec2026 = content.getEventsForMonth(12, 2026);
      expect(dec2026.single.description, 'Bring notebooks');
    });

    test('skips events without a summary or start', () {
      const incomplete = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//EN
BEGIN:VEVENT
DTSTART:20260101T120000Z
END:VEVENT
BEGIN:VEVENT
SUMMARY:Missing start
END:VEVENT
END:VCALENDAR
''';
      final content = parseIcsToCalendarContent(incomplete);
      expect(content.eventsByMonth, isEmpty);
    });
  });

  group('CalendarScraper.fetchCalendarContent', () {
    test('downloads ICS and returns parsed events', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), vidyapithGoogleCalendarIcsUrl);
        return http.Response(_sampleIcs, 200);
      });

      final scraper = CalendarScraper(client: client);
      final content = await scraper.fetchCalendarContent();

      expect(content.getEventsForMonth(9, 2026), hasLength(1));
      expect(content.getEventsForMonth(5, 2027), hasLength(1));
      scraper.dispose();
    });

    test('throws when ICS request fails', () async {
      final client = MockClient(
        (_) async => http.Response('nope', 500),
      );
      final scraper = CalendarScraper(client: client);

      expect(
        () => scraper.fetchCalendarContent(),
        throwsA(isA<http.ClientException>()),
      );
      scraper.dispose();
    });
  });
}
