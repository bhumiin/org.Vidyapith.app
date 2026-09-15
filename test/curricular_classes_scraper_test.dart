import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vidyapith_hybrid_app/services/website_scraper.dart';

/// Minimal Weebly-style fixture mirroring curricular-classes.html structure.
const _curricularClassesFixtureHtml = '''
<!DOCTYPE html>
<html>
<body>
  <div class="wsite-multicol">
    <table class="wsite-multicol-table">
      <tbody class="wsite-multicol-tbody">
        <tr class="wsite-multicol-tr">
          <td class="wsite-multicol-col">
            <div class="wsite-image">
              <img src="/uploads/5/2/1/3/52135817/published/1254951.jpg?1766496217" alt="Picture" />
            </div>
          </td>
          <td class="wsite-multicol-col">
            <h2 class="wsite-content-title">
              <font color="#8d2424">
                <u><strong><font size="5">Vidyapith Curricular Classes<br />&#8203;for Youngsters,<br />&#8203;Kindergarten through 12th Grade</font></strong></u>
              </font>
            </h2>
            <div class="paragraph">
              <font size="4">Classes are held&nbsp;Saturdays and Sundays from 9:00am- 1:00pm for youngsters from Kindergarten to 12th Grade. Inspiring thoughts, the Bhagavad Gita,&nbsp;biographies of great personalities, and stories from the Upanishads,&nbsp;Ramayana and Mahabharata are taught in an interesting way that appeals to young minds. Music, Sanskrit, shlokas, world religions, and Indian history are also integral parts of the curriculum.</font>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="wsite-multicol">
    <table class="wsite-multicol-table">
      <tbody class="wsite-multicol-tbody">
        <tr class="wsite-multicol-tr">
          <td class="wsite-multicol-col">
            <h2 class="wsite-content-title">
              <strong><u><font size="5" color="#8d2424">&#8203;Study Classes for Adults</font></u></strong>
            </h2>
            <div class="paragraph">
              <font size="4">Scriptural study classes are held&nbsp;Monday and Thursday evenings for adults. The classes include reading and group discussions on The Gospel of Sri Ramakrishna, Bhagavad Gita, Upanishads, and Vedanta as expounded by Sri Ramakrishna Paramahamsa and Swami Vivekananda. Practicing the ideals of the scriptures is emphasized in these classes.</font>
            </div>
          </td>
          <td class="wsite-multicol-col">
            <div class="wsite-image">
              <img src="/uploads/5/2/1/3/52135817/6185815.jpeg" alt="Picture" />
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
  group('fetchCurricularClassesContent', () {
    late WebsiteScraper scraper;

    setUp(() {
      final client = MockClient((request) async {
        expect(request.url.path, contains('curricular-classes'));
        return http.Response(
          _curricularClassesFixtureHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      scraper = WebsiteScraper(client: client);
    });

    test('parses exact titles and full paragraph descriptions', () async {
      final content = await scraper.fetchCurricularClassesContent();

      expect(
        content.youngstersSection.title,
        'Vidyapith Curricular Classes for Youngsters, Kindergarten through 12th Grade',
      );
      expect(content.youngstersSection.schedule, isEmpty);
      expect(
        content.youngstersSection.description,
        contains('Classes are held Saturdays and Sundays'),
      );
      expect(
        content.youngstersSection.description,
        contains('Inspiring thoughts, the Bhagavad Gita'),
      );
      expect(
        content.youngstersSection.description,
        contains('Indian history are also integral parts of the curriculum.'),
      );

      expect(content.adultsSection.title, 'Study Classes for Adults');
      expect(content.adultsSection.schedule, isEmpty);
      expect(
        content.adultsSection.description,
        contains('Scriptural study classes are held Monday and Thursday'),
      );
      expect(
        content.adultsSection.description,
        contains('Practicing the ideals of the scriptures'),
      );
    });

    test('resolves both section images from multicol siblings', () async {
      final content = await scraper.fetchCurricularClassesContent();

      expect(content.youngstersSection.imageUrl, contains('1254951.jpg'));
      expect(content.adultsSection.imageUrl, contains('6185815.jpeg'));
    });

    test('does not peel schedule out of the description paragraph', () async {
      final content = await scraper.fetchCurricularClassesContent();

      expect(content.youngstersSection.schedule, isEmpty);
      expect(content.adultsSection.schedule, isEmpty);
      expect(
        content.youngstersSection.description.toLowerCase(),
        startsWith('classes are held'),
      );
      expect(
        content.adultsSection.description.toLowerCase(),
        startsWith('scriptural study classes are held'),
      );
    });
  });
}
