import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vidyapith_hybrid_app/services/website_scraper.dart';

/// Minimal Weebly-style fixture mirroring admissions1.html structure.
///
/// Body uses `<br /><br />` between I. / II. / III., with `<strong>` and `<u>`
/// emphasis (maroon color omitted from assertions — scraper ignores color).
const _admissionsFixtureHtml = '''
<!DOCTYPE html>
<html>
<head>
  <title>Admissions</title>
</head>
<body>
  <div id="wsite-content">
    <h2 class="wsite-content-title" style="text-align:center;">
      <u><strong><font color="#8d2424">ADMISSIONS<br /></font></strong></u>
    </h2>
    <div class="paragraph" style="text-align:left;">
      <br />
      <strong><font size="4">&#8203;I.&nbsp;</font></strong>
      <strong style="color:rgb(141, 36, 36)"><font size="4">Admission into Vidyapith's&nbsp;</font></strong>
      <strong style="color:rgb(141, 36, 36)"><font size="4"><u>2026-27 GRADES 1-5</u>&nbsp;is&nbsp;<u>CLOSED</u>.&nbsp;</font></strong>
      <br /><br />
      <strong><font size="4">II. </font></strong>
      <strong style="color:rgb(141, 36, 36)"><font size="4">Admissions and the waitlist for the <u>2026-27 Kindergarten</u> is now <u>CLOSED</u>. &nbsp;Those currently on the waitlist must attend the makeup Orientation and Registration session on September 9, 2026 at 7:00pm in order to register. An email will be sent to those who are on the waitlist with &nbsp;more details.</font></strong>
      <br />&#8203;<br />
      <strong><font size="4">&#8203;III.&nbsp;Because Vidyapith's curriculum is taught as a yearly progression to the same cohort of students,&nbsp;Vidyapith generally does not admit new students beyond 5th grade.&nbsp;</font></strong>
      <br /><br />
      <strong><font size="4">Thank you for your interest in Vidyapith's character-building program.</font></strong>
      <br /><br /><br /><br />
    </div>
    <h2 class="wsite-content-title" style="text-align:center;">
      <font size="3">
        <span>Vivekananda Vidyapith<br />20 Hinchman Avenue<br />Wayne NJ &nbsp;07470</span>
      </font>
    </h2>
    <div class="paragraph">
      <a href="https://example.com/kg-form">2026-27 KG Inquiry Form</a>
      <a href="https://example.com/alt-form">2026-27 Alternate Route Inquiry Form</a>
    </div>
  </div>
</body>
</html>
''';

void main() {
  group('fetchAdmissionsContent', () {
    test('splits I/II/III onto separate paragraphs with bold and underline',
        () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('admissions'));
        return http.Response(
          _admissionsFixtureHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final scraper = WebsiteScraper(client: client);

      final content = await scraper.fetchAdmissionsContent();

      expect(content.paragraphs.length, greaterThanOrEqualTo(3));

      String plainOf(int index) =>
          content.paragraphs[index].spans.map((s) => s.text).join();

      expect(plainOf(0), startsWith('I.'));
      expect(plainOf(0), contains('Admission into Vidyapith'));
      expect(plainOf(1), startsWith('II.'));
      expect(plainOf(1), contains('Kindergarten'));
      expect(plainOf(2), startsWith('III.'));
      expect(plainOf(2), contains('beyond 5th grade'));

      // Paragraphs are separate — I. and II. are not collapsed onto one line.
      expect(plainOf(0), isNot(contains('II.')));
      expect(plainOf(1), isNot(contains('III.')));

      final underlined = content.paragraphs
          .expand((p) => p.spans)
          .where((s) => s.isUnderlined)
          .map((s) => s.text.trim())
          .toList();
      expect(underlined, contains('2026-27 GRADES 1-5'));
      expect(underlined.where((t) => t == 'CLOSED').length, greaterThanOrEqualTo(2));
      expect(underlined, contains('2026-27 Kindergarten'));

      final boldSpans = content.paragraphs
          .expand((p) => p.spans)
          .where((s) => s.isBold && s.text.trim().isNotEmpty);
      expect(boldSpans, isNotEmpty);
      expect(
        boldSpans.any((s) => s.text.contains('Admission into')),
        isTrue,
      );

      expect(content.addressLines, contains('Vivekananda Vidyapith'));
      expect(content.addressLines, contains('20 Hinchman Avenue'));
      expect(
        content.addressLines.any((l) => l.contains('07470')),
        isTrue,
      );

      expect(content.kgFormUrl, contains('kg-form'));
      expect(content.alternateRouteFormUrl, contains('alt-form'));
    });

    test('throws when the page returns a non-200 status', () async {
      final client = MockClient((request) async {
        return http.Response('Nope', 500);
      });
      final scraper = WebsiteScraper(client: client);

      expect(
        () => scraper.fetchAdmissionsContent(),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
