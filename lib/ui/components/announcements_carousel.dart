import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/website_content.dart';
import '../theme/shadcn_theme.dart';
import 'card.dart';

/// Swipeable, auto-advancing carousel of homepage announcement links.
///
/// Mirrors [EventsCarousel]: one announcement per slide, page indicators when
/// there is more than one, and the card grows with the full title so long
/// campaign headlines are never truncated. Tapping a slide invokes
/// [onLinkTap]; the parent decides how to open the URL.
class AnnouncementsCarousel extends StatefulWidget {
  /// Creates an announcements carousel for [links].
  const AnnouncementsCarousel({
    super.key,
    required this.links,
    this.interval = const Duration(seconds: 5),
    this.isDark = false,
    this.onLinkTap,
  });

  /// Announcement links to show, in homepage order.
  final List<DynamicLink> links;

  /// Time each slide stays visible before auto-advancing.
  final Duration interval;

  /// Whether to use dark theme colors.
  final bool isDark;

  /// Called when the user taps the visible announcement.
  final ValueChanged<DynamicLink>? onLinkTap;

  @override
  State<AnnouncementsCarousel> createState() => _AnnouncementsCarouselState();
}

class _AnnouncementsCarouselState extends State<AnnouncementsCarousel> {
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  List<DynamicLink> get _links => widget.links;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant AnnouncementsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final linksChanged = !listEquals(oldWidget.links, widget.links);
    if (widget.interval != oldWidget.interval || linksChanged) {
      _restartAutoPlay();
    }

    if (_links.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= _links.length) {
      _currentIndex = _links.length - 1;
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    if (_links.length <= 1) return;

    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer(widget.interval, () {
      if (!mounted) return;
      _goToNext();
      _startAutoPlay();
    });
  }

  void _restartAutoPlay() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  void _goToNext() {
    if (_links.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _links.length;
    });
  }

  void _goToPrevious() {
    if (_links.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _links.length) % _links.length;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -200) {
      _goToNext();
      _restartAutoPlay();
    } else if (velocity > 200) {
      _goToPrevious();
      _restartAutoPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_links.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentLink = _links[_currentIndex];

    return Column(
      children: [
        GestureDetector(
          onHorizontalDragEnd: _links.length > 1 ? _onHorizontalDragEnd : null,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: AnnouncementCard(
                key: ValueKey<int>(_currentIndex),
                link: currentLink,
                isDark: widget.isDark,
                onTap: widget.onLinkTap == null
                    ? null
                    : () => widget.onLinkTap!(currentLink),
              ),
            ),
          ),
        ),
        if (_links.length > 1) ...[
          const SizedBox(height: ShadCNTheme.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_links.length, (index) {
              final isActive = index == _currentIndex;
              final activeColor = widget.isDark
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF0B73DA);
              final inactiveColor = widget.isDark
                  ? const Color(0xFF4B5563)
                  : const Color(0xFFD1D5DB);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: isActive ? 16 : 6,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Card showing a single announcement link with title and chevron.
///
/// Text is never truncated — the card grows with the full homepage headline.
class AnnouncementCard extends StatelessWidget {
  /// Creates an announcement card for [link].
  const AnnouncementCard({
    super.key,
    required this.link,
    this.isDark = false,
    this.onTap,
  });

  /// Announcement to display.
  final DynamicLink link;

  /// Whether to use dark theme colors.
  final bool isDark;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA);
    final foreground = isDark ? Colors.white : const Color(0xFF424242);

    return ShadCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ShadCNTheme.space4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFF5F7F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2D3748)
                    : const Color(0xFFE0E7FF),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(ShadCNTheme.space3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.campaign_outlined, size: 28, color: accent),
                ),
                const SizedBox(width: ShadCNTheme.space4),
                Expanded(
                  child: Text(
                    link.title,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: ShadCNTheme.space2),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: accent,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
