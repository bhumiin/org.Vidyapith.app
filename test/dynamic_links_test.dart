import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;

import 'package:vidyapith_hybrid_app/models/website_content.dart';
import 'package:vidyapith_hybrid_app/services/website_scraper.dart';

void main() {
  group('WebsiteContent dynamicLinks JSON', () {
    test('round-trips a list of dynamic links', () {
      final content = WebsiteContent(
        dynamicLinks: const [
          DynamicLink(
            title: 'Letters from Swamis',
            url: 'https://docs.google.com/presentation/d/abc',
          ),
          DynamicLink(
            title: 'Messages for Vandana Aunty',
            url: 'https://docs.google.com/document/d/xyz',
          ),
        ],
        fetchedAt: DateTime.utc(2026, 1, 15),
      );

      final restored = WebsiteContent.fromJson(content.toJson());

      expect(restored.dynamicLinks, hasLength(2));
      expect(restored.dynamicLinks[0].title, 'Letters from Swamis');
      expect(
        restored.dynamicLinks[0].url,
        'https://docs.google.com/presentation/d/abc',
      );
      expect(restored.dynamicLinks[1].title, 'Messages for Vandana Aunty');
    });

    test('migrates legacy dynamicLink object into a one-element list', () {
      final restored = WebsiteContent.fromJson({
        'dynamicLink': {
          'title': 'Legacy Announcement',
          'url': 'https://docs.google.com/document/d/legacy',
        },
        'fetchedAt': '2026-01-15T00:00:00.000Z',
      });

      expect(restored.dynamicLinks, hasLength(1));
      expect(restored.dynamicLinks.single.title, 'Legacy Announcement');
      expect(
        restored.dynamicLinks.single.url,
        'https://docs.google.com/document/d/legacy',
      );
    });

    test('defaults to empty list when neither field is present', () {
      final restored = WebsiteContent.fromJson({
        'fetchedAt': '2026-01-15T00:00:00.000Z',
      });

      expect(restored.dynamicLinks, isEmpty);
    });
  });

  group('WebsiteScraper consecutive dynamic links', () {
    late WebsiteScraper scraper;

    setUp(() {
      scraper = WebsiteScraper();
    });

    tearDown(() {
      scraper.dispose();
    });

    test('parses two consecutive sibling announcement anchors', () {
      const html = '''
<html><body>
  <div class="column">
    <div class="paragraph">
      <strong><a href="https://docs.google.com/presentation/d/letters">
        LETTERS FROM SWAMIS
      </a></strong>
    </div>
    <div class="paragraph">
      <strong><a href="https://docs.google.com/document/d/messages" target="_blank">
        MESSAGES FOR VANDANA AUNTY
      </a></strong>
    </div>
  </div>
</body></html>
''';

      final content = scraper.parseHomepageDocument(html_parser.parse(html));

      expect(content.dynamicLinks, hasLength(2));
      expect(content.dynamicLinks[0].title, contains('LETTERS FROM SWAMIS'));
      expect(
        content.dynamicLinks[0].url,
        'https://docs.google.com/presentation/d/letters',
      );
      expect(
        content.dynamicLinks[1].title,
        contains('MESSAGES FOR VANDANA AUNTY'),
      );
      expect(
        content.dynamicLinks[1].url,
        'https://docs.google.com/document/d/messages',
      );
    });

    test('stops before excluded calendar and ACT links in the run', () {
      const html = '''
<html><body>
  <div class="column">
    <div class="paragraph">
      <a href="https://docs.google.com/presentation/d/letters">LETTERS FROM SWAMIS</a>
    </div>
    <div class="paragraph">
      <a href="https://docs.google.com/document/d/messages">MESSAGES FOR VANDANA AUNTY</a>
    </div>
    <div class="paragraph">
      <a href="https://www.vidyapith.org/2026-calendar.html">CALENDAR</a>
    </div>
    <div class="paragraph">
      <a href="https://vidyapith-act.netlify.app/">ACT FOOD DRIVE</a>
    </div>
    <div class="paragraph">
      <a href="https://www.vidyapith.org/about.html">Video: Vidyapith, Our Story</a>
    </div>
  </div>
</body></html>
''';

      final content = scraper.parseHomepageDocument(html_parser.parse(html));

      expect(content.dynamicLinks, hasLength(2));
      expect(content.dynamicLinks[0].title, contains('LETTERS'));
      expect(content.dynamicLinks[1].title, contains('MESSAGES'));
      expect(
        content.dynamicLinks.any((l) => l.title.contains('CALENDAR')),
        isFalse,
      );
      expect(
        content.dynamicLinks.any((l) => l.title.contains('ACT')),
        isFalse,
      );
    });

    test('returns a single link when only one announcement exists', () {
      const html = '''
<html><body>
  <div class="paragraph">
    <a href="https://docs.google.com/document/d/only">ONLY ANNOUNCEMENT</a>
  </div>
  <hr>
  <div class="paragraph">
    <a href="https://docs.google.com/document/d/after">AFTER THE BREAK</a>
  </div>
</body></html>
''';

      final content = scraper.parseHomepageDocument(html_parser.parse(html));

      expect(content.dynamicLinks, hasLength(1));
      expect(content.dynamicLinks.single.title, contains('ONLY ANNOUNCEMENT'));
    });

    test('returns empty list when there are no announcements', () {
      const html = '''
<html><body>
  <nav><a href="/about.html">About</a></nav>
  <p>Welcome to Vidyapith</p>
</body></html>
''';

      final content = scraper.parseHomepageDocument(html_parser.parse(html));

      expect(content.dynamicLinks, isEmpty);
    });
  });
}
