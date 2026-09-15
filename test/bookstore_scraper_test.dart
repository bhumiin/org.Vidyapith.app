import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vidyapith_hybrid_app/services/website_scraper.dart';

/// Fixture mirroring bookstore.html section breaks and Cloudflare email protection.
const _bookstoreFixtureHtml = '''
<!DOCTYPE html>
<html>
<body>
  <h2 class="wsite-content-title">
    <u><font color="#8d2424"><strong><font size="6">Vidyapith Bookstore</font></strong></font></u>
  </h2>
  <div class="paragraph" style="text-align:left;">
    <strong><font color="#8d2424"><font size="4"><u>About Us</u>:</font></font><br />
    <font size="4"><font color="#f37804">&nbsp; &nbsp; &nbsp;</font>
    The Vidyapith Bookstore carries a full collection of texts, CD's, clothing and more for the enjoyment of all.
    &nbsp;Students may purchase class textbooks, curricular CD's and Vidyapith uniforms here.
    &nbsp;Parents and adults of all ages are welcome to enrich their learning with the Bookstore's offerings.
    <font color="#f37804"> &nbsp;</font></font></strong><br /><br />
    <font size="4"><strong><font color="#8d2424"><u>Location</u>:</font></strong></font><br />
    <font size="4"><strong><font color="#f37804">&nbsp; &nbsp; &nbsp;</font>Vidyapith Lower Level</strong></font><br />
    <font size="4"><strong>&nbsp; &nbsp; &nbsp;20 Hinchman Avenue</strong></font><br />
    <font size="4"><strong>&nbsp; &nbsp; &nbsp;Wayne, NJ &nbsp;07470<br /><br />
    <font color="#8d2424"><font size="4"><u>Hours</u>:</font></font><br />
    <font size="4">&nbsp; &nbsp; &nbsp;Saturday School Days 10:00am - 1:00pm</font><br />
    <font><font size="4">&nbsp; &nbsp; &nbsp;Sunday School Days 10:00am - 1:00pm</font></font></strong></font><br /><br />
    <font size="4"><strong><font><font size="4"><font color="#8d2424"><u>Questions?</u>:</font><br />
    &nbsp; &nbsp; &nbsp;Contact us at
    <a href="/cdn-cgi/l/email-protection#653333270a0a0e16110a170025130c011c04150c110d4b0a1702"
       style="color: rgb(243, 120, 4);">
      <span class="__cf_email__" data-cfemail="015757436e6e6a72756e7364417768657860716875692f6e7366">[email&#160;protected]</span>
    </a>
    </font></font></strong></font>
  </div>
</body>
</html>
''';

void main() {
  group('fetchBookstoreContent', () {
    late WebsiteScraper scraper;

    setUp(() {
      final client = MockClient((request) async {
        expect(request.url.path, contains('bookstore'));
        return http.Response(
          _bookstoreFixtureHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      scraper = WebsiteScraper(client: client);
    });

    tearDown(() {
      scraper.dispose();
    });

    test('keeps website section breaks for about, location, and hours', () async {
      final content = await scraper.fetchBookstoreContent();

      expect(content.title, 'Vidyapith Bookstore');
      expect(
        content.about,
        "The Vidyapith Bookstore carries a full collection of texts, CD's, "
        "clothing and more for the enjoyment of all. Students may purchase "
        "class textbooks, curricular CD's and Vidyapith uniforms here. "
        "Parents and adults of all ages are welcome to enrich their learning "
        "with the Bookstore's offerings.",
      );
      expect(content.about.toLowerCase(), isNot(contains('location')));
      expect(content.about.toLowerCase(), isNot(contains('hours')));
      expect(content.about.toLowerCase(), isNot(contains('questions')));

      expect(content.locationLines, [
        'Vidyapith Lower Level',
        '20 Hinchman Avenue',
        'Wayne, NJ 07470',
      ]);
      expect(content.hours, [
        'Saturday School Days 10:00am - 1:00pm',
        'Sunday School Days 10:00am - 1:00pm',
      ]);
    });

    test('decodes Cloudflare-protected bookstore email', () async {
      final content = await scraper.fetchBookstoreContent();

      expect(content.contactEmail, 'VVBookstore@vidyapith.org');
      expect(content.contactEmail, isNot(contains('[email')));
    });
  });
}
