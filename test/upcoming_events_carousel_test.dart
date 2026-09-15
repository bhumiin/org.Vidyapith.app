import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;

import 'package:vidyapith_hybrid_app/models/website_content.dart';
import 'package:vidyapith_hybrid_app/services/website_scraper.dart';
import 'package:vidyapith_hybrid_app/ui/components/events_carousel.dart';

void main() {
  group('splitUpcomingEventBlob', () {
    test('splits a multi-event homepage paragraph into separate entries', () {
      const blob =
          'Saturday & Sunday, September 19 & 20, 9:00am-1:00pm - First Day of Fall Semester Classes for Students '
          'Saturday, September 19, 5:00pm - Janmashtami Celebration '
          'Saturday, September 26, 9:30am-1:00pm - 50th Anniversary Events - No class for KG-5th Grade; Attendance will be taken for Saturday 6th-12th Grade Students '
          'Sunday, September 27, 9:00am-12:00pm - Shortened Day for all Sunday students KG-12th Grade due to 50th Anniversary Events '
          'Sunday, September 27, 5:00pm - 50th Anniversary Symposium at St. Timothy Lutheran Church, 395 Valley Road, Wayne NJ';

      final parts = splitUpcomingEventBlob(blob);

      expect(parts, hasLength(5));
      expect(parts[0], contains('First Day of Fall Semester'));
      expect(parts[1], contains('Janmashtami Celebration'));
      expect(parts[2], contains('50th Anniversary Events'));
      expect(parts[2], contains('Saturday 6th-12th Grade'));
      expect(parts[3], contains('Shortened Day'));
      expect(parts[4], contains('50th Anniversary Symposium'));
    });

    test('leaves a single event unchanged', () {
      const single =
          'Saturday, September 19, 5:00pm - Janmashtami Celebration';
      expect(splitUpcomingEventBlob(single), [single]);
    });

    test('does not split on weekday mentions without a following month', () {
      const entry =
          'Saturday, September 26, 9:30am-1:00pm - 50th Anniversary Events - No class for KG-5th Grade; Attendance will be taken for Saturday 6th-12th Grade Students';

      expect(splitUpcomingEventBlob(entry), hasLength(1));
      expect(splitUpcomingEventBlob(entry).single, entry);
    });
  });

  group('filterAndSortUpcomingEvents', () {
    test('returns events soonest-first and drops past dates', () {
      final now = DateTime(2026, 9, 15);
      final events = [
        const UpcomingEvent(
          title: 'Later event',
          details: 'Saturday, September 27, 5:00pm',
        ),
        const UpcomingEvent(
          title: 'Sooner event',
          details: 'Saturday, September 19, 5:00pm',
        ),
        const UpcomingEvent(
          title: 'Past event',
          details: 'Monday, September 1, 2020, 5:00pm',
        ),
        const UpcomingEvent(
          title: 'Same day later',
          details: 'Saturday, September 19, 9:00pm',
        ),
      ];

      final sorted = filterAndSortUpcomingEvents(events, now: now);

      expect(sorted.map((e) => e.title).toList(), [
        'Sooner event',
        'Same day later',
        'Later event',
      ]);
    });
  });

  group('WebsiteScraper upcoming events', () {
    test('parses, splits, and sorts homepage upcoming events', () {
      const html = '''
<html><body>
  <h2 class="wsite-content-title">Upcoming Events</h2>
  <div class="paragraph"><strong>Sunday, September 27, 2099, 5:00pm - Symposium<br /><br />Saturday, September 19, 2099, 5:00pm - Janmashtami Celebration<br /><br />Saturday, September 26, 2099, 9:30am-1:00pm - 50th Anniversary Events - Attendance for Saturday 6th-12th Grade</strong><br /></div>
  <h2>Thought of The Day</h2>
  <p>"A thought." - Author</p>
</body></html>
''';

      final scraper = WebsiteScraper();
      addTearDown(scraper.dispose);

      final content = scraper.parseHomepageDocument(html_parser.parse(html));
      final events = content.upcomingEvents;

      expect(events, hasLength(3));
      expect(events.map((e) => e.title).toList(), [
        'Janmashtami Celebration',
        '50th Anniversary Events - Attendance for Saturday 6th-12th Grade',
        'Symposium',
      ]);
      expect(events[1].details, 'Saturday, September 26, 2099, 9:30am-1:00pm');
    });

    test('splits all five live-style br-separated events', () {
      const html = '''
<html><body>
  <h2 class="wsite-content-title"><font>Upcoming Events</font></h2>
  <div class="paragraph" style="text-align:center;"><strong>Saturday &amp; Sunday, September 19 &amp; 20, 9:00am-1:00pm - First Day of Fall Semester Classes for Students<br /><br />Saturday, September 19, 5:00pm - Janmashtami Celebration<br /><br />Saturday, September 26, 9:30am-1:00pm - 50th Anniversary Events - No class for KG-5th Grade; Attendance will be taken for Saturday 6th-12th Grade Students<br /><br />Sunday, September 27, 9:00am-12:00pm - Shortened Day for all Sunday students KG-12th Grade due to 50th Anniversary Events<br /><br />Sunday, September 27, 5:00pm - 50th Anniversary Symposium at St. Timothy Lutheran Church, 395 Valley Road, Wayne NJ</strong><br /></div>
</body></html>
''';

      final scraper = WebsiteScraper();
      addTearDown(scraper.dispose);

      final content = scraper.parseHomepageDocument(html_parser.parse(html));
      final events = filterAndSortUpcomingEvents(
        content.upcomingEvents,
        now: DateTime(2026, 9, 15),
      );

      expect(events, hasLength(5));
      expect(events[0].title, 'First Day of Fall Semester Classes for Students');
      expect(events[0].details,
          'Saturday & Sunday, September 19 & 20, 9:00am-1:00pm');
      expect(events[1].title, 'Janmashtami Celebration');
      expect(
        events[2].title,
        '50th Anniversary Events - No class for KG-5th Grade; Attendance will be taken for Saturday 6th-12th Grade Students',
      );
      expect(events[3].title, contains('Shortened Day'));
      expect(events[4].title, contains('50th Anniversary Symposium'));
    });
  });

  group('EventsCarousel', () {
    testWidgets('shows first event and advances on swipe', (tester) async {
      final events = [
        const UpcomingEvent(
          title: 'First Event',
          details: 'Saturday, September 19, 5:00pm',
        ),
        const UpcomingEvent(
          title: 'Second Event',
          details: 'Sunday, September 20, 5:00pm',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventsCarousel(
              events: events,
              interval: const Duration(seconds: 30),
            ),
          ),
        ),
      );

      expect(find.text('First Event'), findsOneWidget);
      expect(find.text('Second Event'), findsNothing);

      await tester.fling(
        find.byType(UpcomingEventCard),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Second Event'), findsOneWidget);
    });

    testWidgets('shows full long event text without truncation', (tester) async {
      const longTitle =
          '50th Anniversary Events - No class for KG-5th Grade; Attendance will be taken for Saturday 6th-12th Grade Students';
      const longDetails = 'Saturday, September 26, 9:30am-1:00pm';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: EventsCarousel(
                events: const [
                  UpcomingEvent(title: longTitle, details: longDetails),
                ],
                interval: const Duration(seconds: 30),
              ),
            ),
          ),
        ),
      );

      expect(find.text(longTitle), findsOneWidget);
      expect(find.text(longDetails), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows page indicators when there are multiple events',
        (tester) async {
      final events = [
        const UpcomingEvent(
          title: 'First Event',
          details: 'Saturday, September 19, 5:00pm',
        ),
        const UpcomingEvent(
          title: 'Second Event',
          details: 'Sunday, September 20, 5:00pm',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventsCarousel(
              events: events,
              interval: const Duration(seconds: 30),
            ),
          ),
        ),
      );

      expect(find.text('First Event'), findsOneWidget);
      // Two indicator dots (active + inactive AnimatedContainers).
      expect(find.byType(AnimatedContainer), findsNWidgets(2));
    });
  });
}
