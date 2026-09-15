import 'package:flutter_test/flutter_test.dart';

import 'package:vidyapith_hybrid_app/core/vidyapith_urls.dart';

void main() {
  group('vidyapithCalendarPageUrl', () {
    test('builds 2026 calendar page from a 2026 date', () {
      expect(
        vidyapithCalendarPageUrl(now: DateTime(2026, 3, 1)),
        'https://www.vidyapith.org/2026-calendar.html',
      );
    });

    test('builds 2027 calendar page from a 2027 date', () {
      expect(
        vidyapithCalendarPageUrl(now: DateTime(2027, 1, 1)),
        'https://www.vidyapith.org/2027-calendar.html',
      );
    });

    test('uses the current year when now is omitted', () {
      final year = DateTime.now().year;
      expect(
        vidyapithCalendarPageUrl(),
        'https://www.vidyapith.org/$year-calendar.html',
      );
    });
  });
}
