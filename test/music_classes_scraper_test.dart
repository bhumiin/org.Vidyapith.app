import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vidyapith_hybrid_app/services/website_scraper.dart';

/// Minimal Weebly-style fixture mirroring music-classes.html structure.
const _musicClassesFixtureHtml = '''
<!DOCTYPE html>
<html>
<body>
  <h2 class="wsite-content-title">
    <strong><font>Vidyapith Offers the Following Music Classes:</font></strong>
  </h2>
  <div class="wsite-multicol">
    <table class="wsite-multicol-table">
      <tbody>
        <tr>
          <td class="wsite-multicol-col">
            <h2 class="wsite-content-title">
              <u><strong>Hindustani Classical&nbsp;Vocal Music Classes</strong></u>
            </h2>
            <div class="paragraph">
              Taught by Sri Mohan Deshpande and Smt. Trupti Parikh&nbsp;<br />
              &#8203;<strong>Saturdays &nbsp; 1:30pm</strong><br />
              To inquire further, please submit this
              <strong><u>
                <a href="https://docs.google.com/forms/d/e/1FAIpQLSfevivtHOBTy63RpzULik0fZQeBHzSElUcKYsSZjntbxFdkOg/viewform"
                   target="_blank">VOCAL CLASS INQUIRY FORM</a>
              </u>.</strong>
            </div>
          </td>
          <td class="wsite-multicol-col">
            <h2 class="wsite-content-title">
              <u><strong>Tabla Classes</strong></u>
            </h2>
            <div class="paragraph">
              Taught by Shri Dibyarka Chatterjee &amp;&nbsp;Shri Samir Chatterjee<br />
              <strong>Sundays &nbsp; 2:00pm</strong><br />
              To inquire further, please submit this&nbsp;
              <u><strong>
                <a href="https://docs.google.com/forms/d/e/1FAIpQLSe70jjmNoyYN4K3l4uNeK_j5FTeuu2styr7Xxpw399DUxC9Ug/viewform?usp=sf_link"
                   target="_blank">TABLA CLASS FORM</a>
              </strong></u>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</body>
</html>
''';

void main() {
  group('fetchMusicClassesContent', () {
    late WebsiteScraper scraper;

    setUp(() {
      final client = MockClient((request) async {
        expect(request.url.path, contains('music-classes'));
        return http.Response(
          _musicClassesFixtureHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      scraper = WebsiteScraper(client: client);
    });

    test('parses short bold titles with separate teachers and schedule', () async {
      final content = await scraper.fetchMusicClassesContent();

      expect(
        content.vocalSection.title,
        'Hindustani Classical Vocal Music Classes',
      );
      expect(
        content.vocalSection.teachers,
        'Sri Mohan Deshpande and Smt. Trupti Parikh',
      );
      expect(content.vocalSection.schedule, 'Saturdays 1:30pm');
      expect(content.vocalSection.description, isEmpty);

      expect(content.tablaSection.title, 'Tabla Classes');
      expect(
        content.tablaSection.teachers,
        'Shri Dibyarka Chatterjee & Shri Samir Chatterjee',
      );
      expect(content.tablaSection.schedule, 'Sundays 2:00pm');
      expect(content.tablaSection.description, isEmpty);
    });

    test('keeps form URLs and strips inquiry CTA from text fields', () async {
      final content = await scraper.fetchMusicClassesContent();

      expect(
        content.vocalSection.formUrl,
        contains('docs.google.com/forms'),
      );
      expect(
        content.tablaSection.formUrl,
        contains('docs.google.com/forms'),
      );

      for (final section in [content.vocalSection, content.tablaSection]) {
        final blob =
            '${section.title} ${section.teachers} ${section.schedule} ${section.description}'
                .toLowerCase();
        expect(blob, isNot(contains('inquire')));
        expect(blob, isNot(contains('inquiry')));
        expect(blob, isNot(contains('submit this')));
      }
    });

    test('does not duplicate the full paragraph across fields', () async {
      final content = await scraper.fetchMusicClassesContent();

      expect(
        content.vocalSection.title.toLowerCase(),
        isNot(contains('taught by')),
      );
      expect(
        content.vocalSection.title.toLowerCase(),
        isNot(contains('saturday')),
      );
      expect(
        content.vocalSection.teachers.toLowerCase(),
        isNot(contains('saturday')),
      );
      expect(
        content.vocalSection.schedule.toLowerCase(),
        isNot(contains('taught by')),
      );

      expect(
        content.tablaSection.title.toLowerCase(),
        isNot(contains('taught by')),
      );
      expect(
        content.tablaSection.teachers.toLowerCase(),
        isNot(contains('sunday')),
      );
      expect(
        content.tablaSection.schedule.toLowerCase(),
        isNot(contains('taught by')),
      );
    });
  });
}
