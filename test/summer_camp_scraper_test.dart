import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vidyapith_hybrid_app/services/website_scraper.dart';

/// Minimal Weebly-style fixture mirroring summer-camp.html structure.
///
/// Title and body share one paragraph with a `<br>` between them; `_cleanHtml`
/// collapses that into a single line, which previously broke extraction.
const _summerCampFixtureHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta property="og:description"
        content="Summer Camp Vidyapith Summer Camps are invigorating..." />
</head>
<body>
  <div id="wsite-content">
    <div class="wsite-multicol">
      <table class="wsite-multicol-table">
        <tbody>
          <tr>
            <td class="wsite-multicol-col">
              <div class="paragraph">
                <u><font size="5">Summer Camp</font></u><br />
                <span><font size="4">&#8203;</font>
                <font size="4">Vidyapith Summer Camps are invigorating,
                character-building, and fun for all. &nbsp;In an atmosphere
                similar to the traditional Gurukul, students follow a
                comprehensive program &nbsp;for one week that includes studies,
                service, and recreational activities. These camps stimulate
                enthusiasm and interest and are open only to currently
                registered Vidyapith students.</font></span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="paragraph">Copyright @ Vivekananda Vidyapith 2024</div>
  </div>
</body>
</html>
''';

const _expectedDescription =
    'Vidyapith Summer Camps are invigorating, character-building, and fun for '
    'all. In an atmosphere similar to the traditional Gurukul, students follow '
    'a comprehensive program for one week that includes studies, service, and '
    'recreational activities. These camps stimulate enthusiasm and interest '
    'and are open only to currently registered Vidyapith students.';

void main() {
  group('fetchSummerCampContent', () {
    test('parses description from paragraph with title and br', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('summer-camp'));
        return http.Response(
          _summerCampFixtureHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final scraper = WebsiteScraper(client: client);

      final content = await scraper.fetchSummerCampContent();

      expect(content.title, 'Summer Camp');
      expect(content.description, _expectedDescription);
      expect(content.description, isNot(contains('information unavailable')));
      expect(
        content.description.toLowerCase().startsWith('summer camp'),
        isFalse,
      );
      expect(content.thumbnailUrl, isNotEmpty);
    });

    test('throws when the page returns a non-200 status', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final scraper = WebsiteScraper(client: client);

      expect(
        () => scraper.fetchSummerCampContent(),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
