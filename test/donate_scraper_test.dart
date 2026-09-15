import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vidyapith_hybrid_app/services/website_scraper.dart';

/// Fixture mirroring the live donate.html list layout.
const _donateFixtureHtml = '''
<!DOCTYPE html>
<html>
<head>
  <title>Donate</title>
</head>
<body>
  <div id="wsite-content">
    <h2 class="wsite-content-title">HOW TO DONATE:</h2>
    <div class="paragraph" style="text-align:center;">
      <strong>Vivekananda Vidyapith relies on the support of our families and
      well-wishers to continue its character-building educational program.
      100% of donations goes towards the running of Vidyapith's activities;
      no teacher or volunteer draws any compensation. Vidyapith is a 501(c)3
      non-profit organization.<br />WE SINCERELY THANK YOU FOR YOUR GENEROSITY
      IN AIDING VIDYAPITH'S WORK.</strong>
    </div>
    <div class="wsite-multicol">
      <table class="wsite-multicol-table">
        <tbody>
          <tr>
            <td class="wsite-multicol-col">
              <div class="paragraph">
                <ul>
                  <li>To donate by <strong>ZELLE</strong>, send your Zelle
                  payment to
                  <a href="/cdn-cgi/l/email-protection" class="__cf_email__"
                     data-cfemail="b7c1c1d6d4d4d8c2d9c3c4f7c1ded3ced6c7dec3df99d8c5d0">[email&#160;protected]</a>
                  or simply scan below. Please note that Vidyapith receives
                  the full amount of Zelle donations - no fees are deducted.</li>
                </ul>
              </div>
              <div class="wsite-image">
                <img src="/uploads/5/2/1/3/52135817/published/123-1.jpeg?1766063077"
                     alt="QR" />
              </div>
              <div class="paragraph">
                <ul>
                  <li>To donate <strong>APPRECIATED FINANCIAL SECURITIES</strong>,
                  please email
                  <a href="/cdn-cgi/l/email-protection" class="__cf_email__"
                     data-cfemail="c0b6b6a1a3a3afb5aeb4b380b6a9a4b9a1b0a9b4a8eeafb2a7">[email&#160;protected]</a>
                  to receive the necessary brokerage transfer information.</li>
                </ul>
              </div>
              <div class="paragraph">
                <ul>
                  <li>If your company provides <strong>MATCHING GRANTS</strong>
                  and you would like to secure a matching gift for Vidyapith,
                  please fill out this
                  <a href="https://docs.google.com/forms/d/e/1FAIpQLSc4hUP44RRKsZaf4c7ct7abMQn8e3GaPUwYjrRCMus7MIcPvg/viewform?usp=sf_link"
                     target="_blank">Matching Donation Form</a>.</li>
                </ul>
              </div>
            </td>
            <td class="wsite-multicol-col">
              <div class="paragraph">
                <ul>
                  <li>To make a <strong>RECURRING MONTHLY DONATION</strong>,
                  CLICK
                  <a href="https://www.paypal.com/donate/?hosted_button_id=73C6QQCH7KPHL"
                     target="_blank">HERE</a>.
                  Monthly donations provide Vidyapith with consistent support.
                  One-time donations via CREDIT CARD or VENMO can also be made
                  here.</li>
                </ul>
              </div>
              <div class="paragraph">
                <ul>
                  <li>To donate by CREDIT CARD via <strong>PAYPAL GIVING FUND</strong>,
                  CLICK
                  <a href="https://www.paypal.com/US/fundraiser/charity/1533485"
                     target="_blank">HERE</a>.
                  Please note that Vidyapith receives the full amount of PayPal
                  Giving Fund donations - no fees are deducted.</li>
                </ul>
              </div>
              <div class="paragraph">
                <ul>
                  <li>To donate by <strong>CHECK</strong>, please mail your
                  donation to:</li>
                </ul>
                <span>Vivekananda Vidyapith</span><br />
                <span>20 Hinchman Avenue</span><br />
                <span>Wayne NJ 07470</span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</body>
</html>
''';

/// Fixture without a check address so the fallback is used.
const _donateFallbackAddressHtml = '''
<!DOCTYPE html>
<html>
<body>
  <div id="wsite-content">
    <div class="paragraph">
      <strong>Vivekananda Vidyapith relies on donations. Vidyapith is a 501(c)3
      non-profit organization.</strong>
    </div>
    <ul>
      <li>To donate by <strong>ZELLE</strong>, send payment to
      <a href="mailto:vvaccounts@vidyapith.org">vvaccounts@vidyapith.org</a>.
      </li>
      <li>To donate by <strong>CHECK</strong>, please mail your donation to:</li>
    </ul>
  </div>
</body>
</html>
''';

void main() {
  group('fetchDonateContent', () {
    test('parses full method list: emails, QR, URLs, and check address',
        () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('donate'));
        return http.Response(
          _donateFixtureHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final scraper = WebsiteScraper(client: client);

      final content = await scraper.fetchDonateContent();

      expect(content.introParagraphs, isNotEmpty);
      expect(
        content.introParagraphs.first.toLowerCase(),
        contains('vivekananda vidyapith relies'),
      );

      expect(content.zelleEmail, 'vvaccounts@vidyapith.org');
      expect(content.zelleInstruction, isNotNull);
      expect(content.zelleInstruction!.toLowerCase(), contains('zelle'));
      expect(
        content.zelleQrImageUrl,
        contains('/uploads/5/2/1/3/52135817/published/123-1.jpeg'),
      );

      expect(content.securitiesEmail, 'vvaccounts@vidyapith.org');
      expect(content.securitiesInstruction, isNotNull);
      expect(
        content.securitiesInstruction!.toLowerCase(),
        contains('securities'),
      );

      expect(
        content.matchingFormUrl,
        startsWith('https://docs.google.com/forms/'),
      );
      expect(content.matchingGrantInstruction, isNotNull);

      expect(
        content.recurringUrl,
        'https://www.paypal.com/donate/?hosted_button_id=73C6QQCH7KPHL',
      );
      expect(content.recurringInstruction, isNotNull);
      expect(
        content.recurringInstruction!.toLowerCase(),
        contains('recurring'),
      );

      expect(
        content.paypalGivingUrl,
        'https://www.paypal.com/US/fundraiser/charity/1533485',
      );
      expect(content.paypalGivingInstruction, isNotNull);
      expect(
        content.paypalGivingInstruction!.toLowerCase(),
        contains('paypal giving fund'),
      );

      // Recurring and PayPal URLs must not be swapped.
      expect(content.recurringUrl, isNot(equals(content.paypalGivingUrl)));
      expect(content.recurringUrl!.toLowerCase(), contains('donate'));
      expect(content.paypalGivingUrl!.toLowerCase(), contains('fundraiser'));

      expect(content.checkInstruction, isNotNull);
      expect(content.checkMailingAddress, isNotEmpty);
      expect(
        content.checkMailingAddress.any(
          (line) => line.toLowerCase().contains('hinchman'),
        ),
        isTrue,
      );
      expect(
        content.checkMailingAddress.any(
          (line) => line.toLowerCase().contains('wayne'),
        ),
        isTrue,
      );
    });

    test('uses fallback mailing address when check address is missing',
        () async {
      final client = MockClient((request) async {
        return http.Response(
          _donateFallbackAddressHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final scraper = WebsiteScraper(client: client);

      final content = await scraper.fetchDonateContent();

      expect(content.zelleEmail, 'vvaccounts@vidyapith.org');
      expect(content.checkMailingAddress, [
        'Vivekananda Vidyapith',
        '20 Hinchman Avenue',
        'Wayne, NJ 07470',
      ]);
    });
  });
}
