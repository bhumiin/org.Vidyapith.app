import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;

import 'package:vidyapith_hybrid_app/models/website_content.dart';
import 'package:vidyapith_hybrid_app/services/website_scraper.dart';
import 'package:vidyapith_hybrid_app/ui/components/photo_carousel.dart';

void main() {
  group('FeaturedQuote model', () {
    test('JSON round-trip preserves text and author', () {
      const quote = FeaturedQuote(
        text: 'Each soul is potentially divine.',
        author: 'Swami Vivekananda',
      );

      final restored = FeaturedQuote.fromJson(quote.toJson());

      expect(restored.text, quote.text);
      expect(restored.author, quote.author);
    });
  });

  group('WebsiteScraper featured quote', () {
    test('parses featured quote above Thought of the Day without confusing them',
        () {
      const html = '''
<html><body>
  <div>
    <p>"Each soul is potentially divine. The goal is to manifest this divinity within by controlling nature, external and internal. Do this either by work, or worship, or psychic control, or philosophy – by one or more or all of these - and be free." - Swami Vivekananda</p>
    <h2>Thought of The Day</h2>
    <p>"The purer the mind, the easier it is to control." -Swami Vivekananda</p>
  </div>
</body></html>
''';

      final scraper = WebsiteScraper();
      addTearDown(scraper.dispose);

      final content = scraper.parseHomepageDocument(html_parser.parse(html));

      expect(content.featuredQuote, isNotNull);
      expect(
        content.featuredQuote!.text,
        'Each soul is potentially divine. The goal is to manifest this divinity within by controlling nature, external and internal. Do this either by work, or worship, or psychic control, or philosophy – by one or more or all of these - and be free.',
      );
      expect(content.featuredQuote!.author, 'Swami Vivekananda');
      expect(
        content.featuredQuote!.text,
        isNot(contains('Swami Vivekananda')),
      );

      expect(content.thoughtOfTheDay, isNotNull);
      expect(
        content.thoughtOfTheDay!.text,
        contains('The purer the mind'),
      );
      expect(
        content.featuredQuote!.text,
        isNot(equals(content.thoughtOfTheDay!.text)),
      );
    });

    test('keeps in-quote dashes out of the author field', () {
      final scraper = WebsiteScraper();
      addTearDown(scraper.dispose);

      const html = '''
<html><body>
  <p>"Do this either by work, or worship, or psychic control, or philosophy – by one or more or all of these - and be free." - Swami Vivekananda</p>
  <h2>Thought of The Day</h2>
  <p>"Short thought." - Author</p>
</body></html>
''';

      final content = scraper.parseHomepageDocument(html_parser.parse(html));

      expect(content.featuredQuote, isNotNull);
      expect(
        content.featuredQuote!.text,
        contains('by one or more or all of these - and be free'),
      );
      expect(content.featuredQuote!.author, 'Swami Vivekananda');
    });
  });

  group('carouselDwellForSlide', () {
    test('quote slides dwell 2 seconds longer than the base interval', () {
      const interval = Duration(seconds: 3);
      const quote = CarouselQuoteSlide(
        text: 'Be free.',
        author: 'Swami Vivekananda',
      );
      const image = CarouselImageSlide('https://example.com/photo.jpg');

      expect(
        carouselDwellForSlide(quote, interval),
        interval + kQuoteSlideExtraDwell,
      );
      expect(carouselDwellForSlide(image, interval), interval);
    });
  });

  group('PhotoCarousel quote slide', () {
    testWidgets('shows featured quote as the first slide', (tester) async {
      const quoteText =
          'Each soul is potentially divine. The goal is to manifest this divinity within.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoCarousel(
              slides: const [
                CarouselQuoteSlide(
                  text: quoteText,
                  author: 'Swami Vivekananda',
                ),
                CarouselQuoteSlide(
                  text: 'Second slide placeholder.',
                  author: 'Test',
                ),
              ],
              interval: const Duration(seconds: 30),
            ),
          ),
        ),
      );

      expect(find.text(quoteText), findsOneWidget);
      expect(find.text('- Swami Vivekananda'), findsOneWidget);
    });
  });
}
