import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({
    super.key,
    required this.imageUrls,
    this.interval = const Duration(seconds: 3),
    this.aspectRatio = 16 / 9,
    this.borderRadius = 16,
    this.isDark = false,
  });

  final List<String> imageUrls;
  final Duration interval;
  final double aspectRatio;
  final double borderRadius;
  final bool isDark;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;
  late List<double?> _imageAspectRatios;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imageAspectRatios = List<double?>.filled(widget.imageUrls.length, null);
    _resolveAllAspectRatios();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant PhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interval != oldWidget.interval ||
        widget.imageUrls.length != oldWidget.imageUrls.length ||
        !listEquals(widget.imageUrls, oldWidget.imageUrls)) {
      if (widget.imageUrls.length != oldWidget.imageUrls.length ||
          !listEquals(widget.imageUrls, oldWidget.imageUrls)) {
        _imageAspectRatios =
            List<double?>.filled(widget.imageUrls.length, null);
        _resolveAllAspectRatios();
        if (_currentIndex >= widget.imageUrls.length) {
          _currentIndex = widget.imageUrls.isEmpty
              ? 0
              : widget.imageUrls.length - 1;
        }
      }
      _restartAutoPlay();
    }

    if (widget.imageUrls.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= widget.imageUrls.length) {
      _currentIndex = widget.imageUrls.length - 1;
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (widget.imageUrls.length <= 1) {
      return;
    }

    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(widget.interval, (_) => _goToNextPage());
  }

  void _restartAutoPlay() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  void _goToNextPage() {
    if (!mounted || widget.imageUrls.length <= 1) {
      return;
    }

    final nextPage = (_currentIndex + 1) % widget.imageUrls.length;

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resolveAllAspectRatios() {
    for (final entry in widget.imageUrls.asMap().entries) {
      _resolveAspectRatio(entry.key, entry.value);
    }
  }

  void _resolveAspectRatio(int index, String url) {
    final ImageProvider provider = url.startsWith('assets/')
        ? AssetImage(url)
        : NetworkImage(url);

    final ImageStream stream =
        provider.resolve(const ImageConfiguration());
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
    if (widget.imageUrls.isEmpty) {
      return _buildEmptyState(context);
    }

    final double containerAspectRatio = _containerAspectRatio();

    return AspectRatio(
      aspectRatio: containerAspectRatio,
      child: Container(
        color: widget.isDark
            ? const Color(0xFF101922)
            : const Color(0xFFF5F7F8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _FadingImage(
                  controller: _pageController,
                  index: index,
                  imageUrl: widget.imageUrls[index],
                  isDark: widget.isDark,
                );
              },
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (index) {
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

class _NetworkImageWithPlaceholder extends StatelessWidget {
  const _NetworkImageWithPlaceholder({required this.url, required this.isDark});

  final String url;
  final bool isDark;

  bool get _isAssetImage => url.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? const Color(0xFF101922)
        : const Color(0xFFF5F7F8);

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
