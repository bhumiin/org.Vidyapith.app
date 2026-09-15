import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vidyapith_hybrid_app/services/website_scraper.dart';

/// Fixture mirroring archives.html intro paragraph and starred archive links.
const _archivesFixtureHtml = '''
<!DOCTYPE html>
<html>
<body>
  <div id="wsite-content">
    <div class="paragraph" style="text-align:center;">
      Over the course of the past 48 years, Vivekananda Vidyapith has held
      innumerable events, from Alumni Reunions to talks by distinguished monks
      of the Ramakrishna Order:<br /><br />
      <a href="/vedanta-lecture-series1.html">*Guest Speaker Talks*</a><br /><br />
      <a href="/40th-anniversary-alumni-reunion.html">*40th Anniversary Alumni Reunion*</a><br /><br />
      <a href="/2018-calendar.html">*2018 Calendar*</a><br /><br />
      <a href="/2019-calendar.html">*2019 Calendar*</a><br /><br />
      <a href="/2020-calendar.html">*2020 Calendar*</a><br /><br />
      <a href="/2021-calendar.html">*2021 Calendar*</a><br /><br />
      <a href="/2022-calendar.html">*2022 Calendar*</a><br /><br />
      <a href="/2023-calendar.html">*2023 Calendar*</a><br /><br />
      <a href="/2024-calendar.html">*2024 Calendar*</a><br /><br />
      <a href="/2025-calendar.html">*2025 Calendar*</a>
    </div>
  </div>
</body>
</html>
''';

void main() {
  group('fetchArchivesContent', () {
    late WebsiteScraper scraper;

    setUp(() {
      final client = MockClient((request) async {
        expect(request.url.path, contains('archives'));
        return http.Response(
          _archivesFixtureHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      scraper = WebsiteScraper(client: client);
    });

    tearDown(() {
      scraper.dispose();
    });

    test('parses intro and archive title cards with cleaned titles', () async {
      final content = await scraper.fetchArchivesContent();

      expect(
        content.intro,
        contains('Over the course of the past 48 years'),
      );
      expect(content.intro.toLowerCase(), isNot(contains('guest speaker')));
      expect(content.intro.toLowerCase(), isNot(contains('2018 calendar')));

      expect(content.items, hasLength(10));

      expect(content.items.first.title, 'Guest Speaker Talks');
      expect(
        content.items.first.url,
        'https://www.vidyapith.org/vedanta-lecture-series1.html',
      );

      expect(content.items[1].title, '40th Anniversary Alumni Reunion');
      expect(
        content.items[1].url,
        'https://www.vidyapith.org/40th-anniversary-alumni-reunion.html',
      );

      expect(
        content.items.map((e) => e.title).toList(),
        [
          'Guest Speaker Talks',
          '40th Anniversary Alumni Reunion',
          '2018 Calendar',
          '2019 Calendar',
          '2020 Calendar',
          '2021 Calendar',
          '2022 Calendar',
          '2023 Calendar',
          '2024 Calendar',
          '2025 Calendar',
        ],
      );

      for (final item in content.items) {
        expect(item.title, isNot(contains('*')));
        expect(item.url, startsWith('https://www.vidyapith.org/'));
      }
    });
  });
}
