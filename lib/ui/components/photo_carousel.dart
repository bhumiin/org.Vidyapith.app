import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Extra time the featured quote slide stays visible beyond [PhotoCarousel.interval].
const Duration kQuoteSlideExtraDwell = Duration(seconds: 2);

/// A single slide in [PhotoCarousel] — either an image or a quote.
sealed class CarouselSlide {
  const CarouselSlide();
}

/// Image slide backed by a network URL or asset path.
class CarouselImageSlide extends CarouselSlide {
  /// Creates an image slide for [url].
  const CarouselImageSlide(this.url);

  /// Network URL or asset path starting with `assets/`.
  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarouselImageSlide && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// Text slide showing a featured quote and optional author.
class CarouselQuoteSlide extends CarouselSlide {
  /// Creates a quote slide.
  const CarouselQuoteSlide({required this.text, this.author});

  /// Quote body text.
  final String text;

  /// Optional attribution (e.g. author name).
  final String? author;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarouselQuoteSlide &&
          other.text == text &&
          other.author == author;

  @override
  int get hashCode => Object.hash(text, author);
}

/// Returns how long [slide] should remain visible given the base [interval].
///
/// Quote slides dwell [kQuoteSlideExtraDwell] longer than image slides.
Duration carouselDwellForSlide(CarouselSlide slide, Duration interval) {
  if (slide is CarouselQuoteSlide) {
    return interval + kQuoteSlideExtraDwell;
  }
  return interval;
}

/// Builds image [CarouselSlide]s from a list of URLs.
List<CarouselSlide> carouselSlidesFromUrls(List<String> imageUrls) {
  return imageUrls.map(CarouselImageSlide.new).toList(growable: false);
}

/// An image/quote carousel that automatically cycles through slides.
///
/// Supports:
/// - Image and quote slides
/// - Automatic rotation with longer dwell on quote slides
/// - Fade transitions and page indicators
/// - Network and asset images
class PhotoCarousel extends StatefulWidget {
  /// Creates a carousel from [slides].
  const PhotoCarousel({
    super.key,
    required this.slides,
    this.interval = const Duration(seconds: 3),
    this.aspectRatio = 16 / 9,
    this.borderRadius = 16,
    this.isDark = false,
  });

  /// Convenience constructor for image-only carousels.
  PhotoCarousel.images({
    super.key,
    required List<String> imageUrls,
    this.interval = const Duration(seconds: 3),
    this.aspectRatio = 16 / 9,
    this.borderRadius = 16,
    this.isDark = false,
  }) : slides = carouselSlidesFromUrls(imageUrls);

  /// Slides to display (images and/or quotes).
  final List<CarouselSlide> slides;

  /// Base dwell time between automatic transitions (default: 3 seconds).
  final Duration interval;

  /// Aspect ratio of the carousel container (default: 16/9).
  final double aspectRatio;

  /// Border radius for rounded corners (default: 16).
  final double borderRadius;

  /// Whether to use dark theme colors.
  final bool isDark;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;
  late List<double?> _imageAspectRatios;

  List<CarouselSlide> get _slides => widget.slides;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imageAspectRatios = List<double?>.filled(_slides.length, null);
    _resolveAllAspectRatios();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant PhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final slidesChanged = !listEquals(oldWidget.slides, widget.slides);
    if (widget.interval != oldWidget.interval || slidesChanged) {
      if (slidesChanged) {
        _imageAspectRatios = List<double?>.filled(_slides.length, null);
        _resolveAllAspectRatios();
        if (_currentIndex >= _slides.length) {
          _currentIndex = _slides.isEmpty ? 0 : _slides.length - 1;
        }
      }
      _restartAutoPlay();
    }

    if (_slides.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= _slides.length) {
      _currentIndex = _slides.length - 1;
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Starts a one-shot autoplay timer using the current slide's dwell.
  void _startAutoPlay() {
    if (_slides.length <= 1) {
      return;
    }

    _autoPlayTimer?.cancel();
    final dwell = carouselDwellForSlide(_slides[_currentIndex], widget.interval);
    _autoPlayTimer = Timer(dwell, () {
      _goToNextPage();
      if (mounted) {
        _startAutoPlay();
      }
    });
  }

  void _restartAutoPlay() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  void _goToNextPage() {
    if (!mounted || _slides.length <= 1) {
      return;
    }

    final nextPage = (_currentIndex + 1) % _slides.length;

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resolveAllAspectRatios() {
    for (final entry in _slides.asMap().entries) {
      final slide = entry.value;
      if (slide is CarouselImageSlide) {
        _resolveAspectRatio(entry.key, slide.url);
      }
    }
  }

  void _resolveAspectRatio(int index, String url) {
    final ImageProvider provider = url.startsWith('assets/')
        ? AssetImage(url)
        : NetworkImage(url);

    final ImageStream stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      final ratio = info.image.width / info.image.height;
      if (mounted) {
        setState(() {
          if (index < _imageAspectRatios.length) {
            _imageAspectRatios[index] = ratio;
          }
        });
      }
      stream.removeListener(listener);
    }, onError: (Object _, StackTrace? __) {
      stream.removeListener(listener);
    });

    stream.addListener(listener);
  }

  double _containerAspectRatio() {
    final resolved = _imageAspectRatios.whereType<double>().toList();
    if (resolved.isEmpty) {
      return widget.aspectRatio;
    }
    final double minRatio = resolved.reduce(math.min);
    return minRatio;
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) {
      return _buildEmptyState(context);
    }

    final double containerAspectRatio = _containerAspectRatio();

    return AspectRatio(
      aspectRatio: containerAspectRatio,
      child: Container(
        color: widget.isDark
            ? const Color(0xFF101922)
            : const Color(0xFFF5F7F8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _restartAutoPlay();
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return switch (slide) {
                    CarouselImageSlide(:final url) => _FadingImage(
                        controller: _pageController,
                        index: index,
                        imageUrl: url,
                        isDark: widget.isDark,
                      ),
                    CarouselQuoteSlide(:final text, :final author) =>
                      _QuoteSlidePage(
                        controller: _pageController,
                        index: index,
                        text: text,
                        author: author,
                        isDark: widget.isDark,
                      ),
                  };
                },
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final isActive = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: isActive ? 16 : 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE3F2FD),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFBBDEFB),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 36,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0B73DA),
          ),
          const SizedBox(height: 12),
          Text(
            'Photos coming soon',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white : const Color(0xFF424242),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We are fetching the latest photos from Vidyapith.org.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quote panel with the same fade behavior as image slides.
class _QuoteSlidePage extends StatelessWidget {
  const _QuoteSlidePage({
    required this.controller,
    required this.index,
    required this.text,
    required this.author,
    required this.isDark,
  });

  final PageController controller;
  final int index;
  final String text;
  final String? author;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double opacity = 1.0;
        if (controller.hasClients && controller.position.hasContentDimensions) {
          final double? page = controller.page;
          if (page != null) {
            opacity = (1.0 - (page - index).abs()).clamp(0.0, 1.0);
          } else {
            opacity = index == controller.initialPage ? 1.0 : 0.0;
          }
        } else {
          opacity = index == 0 ? 1.0 : 0.0;
        }

        return Opacity(
          opacity: Curves.easeInOut.transform(opacity),
          child: child,
        );
      },
      child: ColoredBox(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE8EEF5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFF4B5563),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                ),
              ),
              if (author != null && author!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '- $author',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades images in/out as the carousel transitions.
class _FadingImage extends StatelessWidget {
  const _FadingImage({
    required this.controller,
    required this.index,
    required this.imageUrl,
    required this.isDark,
  });

  final PageController controller;
  final int index;
  final String imageUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double opacity = 1.0;
        if (controller.hasClients && controller.position.hasContentDimensions) {
          final double? page = controller.page;
          if (page != null) {
            opacity = (1.0 - (page - index).abs()).clamp(0.0, 1.0);
          } else {
            opacity = index == controller.initialPage ? 1.0 : 0.0;
          }
        } else {
          opacity = index == 0 ? 1.0 : 0.0;
        }

        return Opacity(
          opacity: Curves.easeInOut.transform(opacity),
          child: child,
        );
      },
      child: _NetworkImageWithPlaceholder(url: imageUrl, isDark: isDark),
    );
  }
}

/// Displays network or asset images with loading and error states.
class _NetworkImageWithPlaceholder extends StatelessWidget {
  const _NetworkImageWithPlaceholder({required this.url, required this.isDark});

  final String url;
  final bool isDark;

  bool get _isAssetImage => url.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? const Color(0xFF101922) : const Color(0xFFF5F7F8);

    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: _isAssetImage
          ? Image.asset(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 36,
                    color: Colors.grey.shade500,
                  ),
                );
              },
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 36,
                    color: Colors.grey.shade500,
                  ),
                );
              },
            ),
    );
  }
}
