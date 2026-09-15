import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/website_content.dart';
import '../theme/shadcn_theme.dart';
import 'card.dart';

/// Swipeable, auto-advancing carousel of upcoming event cards.
///
/// Shows one [UpcomingEvent] at a time with page indicators. The card sizes
/// itself to the full title and details so text is never truncated. Auto-play
/// runs only when there is more than one event.
class EventsCarousel extends StatefulWidget {
  /// Creates an events carousel for [events].
  const EventsCarousel({
    super.key,
    required this.events,
    this.interval = const Duration(seconds: 5),
    this.isDark = false,
  });

  /// Events to show (already sorted soonest-first by the scraper).
  final List<UpcomingEvent> events;

  /// Time each slide stays visible before auto-advancing.
  final Duration interval;

  /// Whether to use dark theme colors.
  final bool isDark;

  @override
  State<EventsCarousel> createState() => _EventsCarouselState();
}

class _EventsCarouselState extends State<EventsCarousel> {
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  List<UpcomingEvent> get _events => widget.events;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant EventsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final eventsChanged = !listEquals(oldWidget.events, widget.events);
    if (widget.interval != oldWidget.interval || eventsChanged) {
      if (eventsChanged) {
        if (_currentIndex >= _events.length) {
          _currentIndex = _events.isEmpty ? 0 : _events.length - 1;
        }
      }
      _restartAutoPlay();
    }

    if (_events.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= _events.length) {
      _currentIndex = _events.length - 1;
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    if (_events.length <= 1) {
      return;
    }

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
    if (_events.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _events.length;
    });
  }

  void _goToPrevious() {
    if (_events.isEmpty) return;
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + _events.length) % _events.length;
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
    if (_events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        GestureDetector(
          onHorizontalDragEnd: _events.length > 1 ? _onHorizontalDragEnd : null,
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
              child: UpcomingEventCard(
                key: ValueKey<int>(_currentIndex),
                event: _events[_currentIndex],
                isDark: widget.isDark,
              ),
            ),
          ),
        ),
        if (_events.length > 1) ...[
          const SizedBox(height: ShadCNTheme.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_events.length, (index) {
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

/// Card showing a single upcoming event with an optional date badge.
///
/// Text is never truncated — the card grows with the full title and details.
class UpcomingEventCard extends StatelessWidget {
  /// Creates an event card for [event].
  const UpcomingEventCard({
    super.key,
    required this.event,
    this.isDark = false,
  });

  /// Event to display.
  final UpcomingEvent event;

  /// Whether to use dark theme colors.
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dateParts = extractUpcomingEventDateParts(event);
    final month = dateParts.$1;
    final day = dateParts.$2;
    final detailText = event.details ?? '';
    final description = event.title.trim();

    return ShadCard(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ShadCNTheme.space4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE0E7FF),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventLeadingBadge(isDark: isDark, month: month, day: day),
            const SizedBox(width: ShadCNTheme.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (detailText.isNotEmpty)
                    Text(
                      detailText,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  if (detailText.isNotEmpty)
                    const SizedBox(height: ShadCNTheme.space1),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF424242),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracts month abbreviation and day from event text.
///
/// Returns `(monthAbbrev, day)` such as `("SEP", "19")`, or nulls if missing.
(String?, String?) extractUpcomingEventDateParts(UpcomingEvent event) {
  final source = '${event.details ?? ''} ${event.title}'.trim();
  final match = RegExp(
    r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2})',
  ).firstMatch(source);

  if (match == null) return (null, null);

  final monthName = match.group(1) ?? '';
  final day = match.group(2) ?? '';
  final monthAbbrev = monthName.length >= 3
      ? monthName.substring(0, 3)
      : monthName;

  return (monthAbbrev.toUpperCase(), day.padLeft(2, '0'));
}

class _EventLeadingBadge extends StatelessWidget {
  const _EventLeadingBadge({
    required this.isDark,
    this.month,
    this.day,
  });

  final bool isDark;
  final String? month;
  final String? day;

  @override
  Widget build(BuildContext context) {
    if (month != null && day != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space3,
          vertical: ShadCNTheme.space2,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0B73DA).withValues(alpha: 0.2)
              : const Color(0xFF0B73DA).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              month!,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF0B73DA),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              day!,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF0B73DA),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(ShadCNTheme.space3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0B73DA).withValues(alpha: 0.2)
            : const Color(0xFF0B73DA).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.event_available_outlined,
        size: 28,
        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA),
      ),
    );
  }
}
