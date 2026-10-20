import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vidyapith_hybrid_app/models/website_content.dart';
import 'package:vidyapith_hybrid_app/ui/components/announcements_carousel.dart';

void main() {
  const links = [
    DynamicLink(
      title: 'REGISTER FOR 50TH ANNIVERSARY ALUMNI REUNION HERE',
      url: 'https://www.vidyapith.org/50th-anniversary-alumni-reunion.html',
    ),
    DynamicLink(
      title: 'LETTERS FROM SWAMIS & PRAVRAJIKAS',
      url: 'https://docs.google.com/presentation/d/letters/pub',
    ),
    DynamicLink(
      title: 'MESSAGES FOR AND MEMORIES OF VANDANA AUNTY',
      url: 'https://docs.google.com/presentation/d/messages/pub',
    ),
  ];

  testWidgets('shows first announcement and advances on swipe', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnnouncementsCarousel(
            links: links,
            interval: const Duration(seconds: 30),
          ),
        ),
      ),
    );

    expect(find.text(links[0].title), findsOneWidget);
    expect(find.text(links[1].title), findsNothing);

    await tester.fling(
      find.byType(AnnouncementCard),
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text(links[1].title), findsOneWidget);
    expect(find.text(links[0].title), findsNothing);
  });

  testWidgets('shows one indicator per announcement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnnouncementsCarousel(
            links: links,
            interval: const Duration(seconds: 30),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedContainer), findsNWidgets(links.length));
  });

  testWidgets('tapping the slide reports the visible link', (tester) async {
    DynamicLink? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnnouncementsCarousel(
            links: links,
            interval: const Duration(seconds: 30),
            onLinkTap: (link) => tapped = link,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AnnouncementCard));
    await tester.pump();

    expect(tapped?.url, links[0].url);
  });

  testWidgets('renders nothing when there are no announcements',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnnouncementsCarousel(links: []),
        ),
      ),
    );

    expect(find.byType(AnnouncementCard), findsNothing);
    expect(find.byType(AnimatedContainer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a single announcement without indicators or errors',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnnouncementsCarousel(
            links: [links.first],
            interval: const Duration(seconds: 30),
          ),
        ),
      ),
    );

    expect(find.text(links[0].title), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
