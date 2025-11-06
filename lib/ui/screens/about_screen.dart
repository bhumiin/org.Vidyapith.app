import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../components/photo_carousel.dart';
import '../theme/shadcn_theme.dart';
import '../components/logo_leading.dart';

/// About Screen - This is the main screen that displays information about Vidyapith.
/// It shows users:
/// - A header with the app logo and title
/// - A photo carousel with rotating images
/// - The mission statement text
/// - A clickable video preview that opens a video player
/// Users can also pull down to refresh the page, and the screen automatically
/// scrolls to the top when requested from other parts of the app.
class AboutScreen extends StatefulWidget {
  /// This allows other parts of the app to request scrolling to the top of this screen.
  /// When set to true, the screen will smoothly scroll back to the beginning.
  final ValueNotifier<bool>? scrollNotifier;

  const AboutScreen({super.key, this.scrollNotifier});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

/// The internal state class that manages all the interactive features of the About screen.
class _AboutScreenState extends State<AboutScreen> {
  /// This controller manages the scrolling behavior of the page.
  /// It allows us to programmatically scroll to the top when needed.
  final ScrollController _scrollController = ScrollController();

  /// List of image URLs that will be displayed in the photo carousel.
  /// These are the pictures that users can swipe through at the top of the screen.
  static const _carouselImages = [
    'https://www.vidyapith.org/uploads/5/2/1/3/52135817/_685374493.jpg',
    'https://www.vidyapith.org/uploads/5/2/1/3/52135817/_7709050.jpg',
    'https://www.vidyapith.org/uploads/5/2/1/3/52135817/_5081962.jpg',
  ];

  /// The mission statement text that appears in the "Our Mission" section.
  /// This explains what Vidyapith is and what it stands for.
  static const _aboutText =
      'Vivekananda Vidyapith is an Academy of Indian Philosophy and Culture '
      'dedicated to the development of the life and character of youngsters. '
      'Vidyapith\'s all-round educative process is based on ancient Eastern '
      'spiritual wisdom and modern Western teaching methods.  Believing that '
      'each individual is potentially divine, Vidyapith provides a conducive '
      'environment for everyone to unfold their energy and talents, and to '
      'channel these towards the noble path of character-building.';

  /// The URL of the thumbnail image (preview picture) shown before the video is played.
  /// This is the static image users see with a play button overlay.
  static const _thumbnailUrl =
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/published/screen-shot-2024-08-02-at-1-12-46-pm.png?1722619290';

  /// The URL of the actual video that will be displayed when the user taps the video thumbnail.
  /// This video is hosted on Google Drive and opens in a web viewer.
  static const _videoPreviewUrl =
      'https://drive.google.com/file/d/0B6DIjih-Bpcrc2stbi1DN1YzUmc/preview';

  /// Tracks whether the page is currently refreshing (when user pulls down).
  /// This prevents multiple refresh operations from happening at the same time.
  bool _isRefreshing = false;

  /// Called when this screen is first created and displayed.
  /// Sets up a listener so that when other parts of the app request scrolling,
  /// this screen will automatically scroll to the top.
  @override
  void initState() {
    super.initState();
    widget.scrollNotifier?.addListener(_onScrollRequested);
  }

  /// Called when this screen is removed or closed.
  /// Cleans up resources like the scroll controller and listeners to prevent memory leaks.
  @override
  void dispose() {
    widget.scrollNotifier?.removeListener(_onScrollRequested);
    _scrollController.dispose();
    super.dispose();
  }

  /// This method is called when another part of the app requests that this screen scroll to the top.
  /// It simply triggers the scrollToTop() method.
  void _onScrollRequested() {
    scrollToTop();
  }

  /// Smoothly scrolls the page back to the very top (position 0).
  /// This creates a nice animation effect that takes 300 milliseconds (0.3 seconds).
  /// Only works if the scroll controller is ready (hasClients).
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Handles the pull-to-refresh gesture when the user drags down from the top of the screen.
  /// Currently simulates a refresh by showing a loading indicator for 750 milliseconds.
  /// In the future, this could be updated to actually reload content from the internet.
  Future<void> _onRefresh() async {
    // Prevent multiple refresh operations from running at the same time
    if (_isRefreshing) return;

    // Show the refresh indicator (spinning circle)
    setState(() => _isRefreshing = true);
    // Wait for 0.75 seconds to simulate refreshing
    await Future<void>.delayed(const Duration(milliseconds: 750));
    // Hide the refresh indicator
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  /// This is the main method that builds the entire screen's user interface.
  /// It checks if the user has dark mode enabled and adjusts colors accordingly.
  /// The screen is made up of several sections stacked vertically:
  /// 1. Header (logo and title)
  /// 2. Photo carousel (swipeable images)
  /// 3. About section (mission statement)
  /// 4. Video section (clickable video preview)
  @override
  Widget build(BuildContext context) {
    // Get the current theme settings (light or dark mode)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Background color changes based on light/dark mode
      backgroundColor: isDark
          ? const Color(0xFF101922)  // Dark blue-gray for dark mode
          : const Color(0xFFF5F7F8), // Light gray for light mode
      body: SafeArea(
        // SafeArea ensures content doesn't overlap with phone notches or status bars
        child: RefreshIndicator(
          // This enables pull-to-refresh functionality (drag down to refresh)
          onRefresh: _onRefresh,
          color: const Color(0xFF0B73DA), // Blue color for the refresh spinner
          child: SingleChildScrollView(
            // Allows the entire page to scroll vertically
            controller: _scrollController, // Connects to our scroll controller
            physics: const AlwaysScrollableScrollPhysics(), // Always allows scrolling
            child: Column(
              // Stacks all sections vertically
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isDark),        // Top bar with logo and title
                _buildCarouselSection(isDark),        // Image carousel
                _buildAboutSection(isDark),           // Mission statement text
                _buildVideoSection(context, isDark),   // Video preview section
                const SizedBox(height: ShadCNTheme.space12), // Bottom spacing
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section at the top of the screen.
  /// This displays:
  /// - The app logo on the left
  /// - The "About Vidyapith" title in the center
  /// - A notification icon button on the right (currently not functional)
  /// The header has a subtle shadow to make it stand out from the content below.
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      // Adds padding (spacing) around the header content
      padding: const EdgeInsets.symmetric(
        horizontal: ShadCNTheme.space4, // Left and right spacing
        vertical: ShadCNTheme.space2,   // Top and bottom spacing
      ),
      decoration: BoxDecoration(
        // Background color matches the screen background
        color: isDark ? const Color(0xFF101922) : const Color(0xFFF5F7F8),
        // Adds a subtle shadow below the header for visual depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Very light shadow
            blurRadius: 4,     // How blurry the shadow is
            offset: const Offset(0, 2), // Shadow position (2 pixels down)
          ),
        ],
      ),
      child: Row(
        // Arranges items horizontally (left to right)
        children: [
          // App logo component (no back button shown on this screen)
          const LogoLeading(showBackButton: false),
          const SizedBox(width: ShadCNTheme.space2), // Small gap after logo
          Expanded(
            // This makes the title take up remaining space and stay centered
            child: Center(
              child: Text(
                'About Vidyapith', // The screen title
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Text color changes based on light/dark mode
                  color: isDark ? Colors.white : const Color(0xFF424242),
                  fontSize: 20,
                  fontWeight: FontWeight.bold, // Makes the text bold
                  letterSpacing: -0.015,       // Slightly tighter letter spacing
                ),
              ),
            ),
          ),
          // Notification icon button (placeholder for future functionality)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20), // Makes it circular
            ),
            child: IconButton(
              onPressed: () {}, // Currently does nothing (empty function)
              icon: Icon(
                Icons.notifications_outlined, // Bell icon
                color: isDark ? Colors.white : const Color(0xFF424242),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the photo carousel section.
  /// This displays a horizontal scrolling gallery of images that users can swipe through.
  /// The images are loaded from the internet URLs stored in _carouselImages.
  Widget _buildCarouselSection(bool isDark) {
    return Container(
      // Background color matches the screen
      color: isDark ? const Color(0xFF101922) : const Color(0xFFF5F7F8),
      child: Padding(
        // Adds horizontal padding (left and right spacing)
        padding: const EdgeInsets.symmetric(horizontal: ShadCNTheme.space4),
        // Uses the PhotoCarousel component to display swipeable images
        child: PhotoCarousel(imageUrls: _carouselImages, isDark: isDark),
      ),
    );
  }

  /// Builds the "Our Mission" text section.
  /// This displays the mission statement heading and the descriptive text about Vidyapith.
  /// The text explains what the organization is and what it stands for.
  Widget _buildAboutSection(bool isDark) {
    return Padding(
      // Adds padding on all sides (left, top, right, bottom)
      padding: const EdgeInsets.fromLTRB(
        ShadCNTheme.space4, // Left padding
        ShadCNTheme.space5, // Top padding (more space above)
        ShadCNTheme.space4, // Right padding
        ShadCNTheme.space3, // Bottom padding
      ),
      child: Column(
        // Stacks the heading and text vertically
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns text to the left
        children: [
          // Section heading
          Text(
            'Our Mission',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF424242),
              fontSize: 24,
              fontWeight: FontWeight.bold, // Makes it stand out as a heading
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space2), // Space between heading and text
          // Mission statement text
          Text(
            _aboutText, // The long descriptive text about Vidyapith
            style: TextStyle(
              // Slightly muted color for the body text
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
              fontSize: 16,
              height: 1.5, // Line height for better readability
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the video section with a clickable video preview.
  /// This section shows:
  /// - A "Watch Our Story" heading
  /// - A thumbnail image (preview picture) of the video
  /// - A play button overlay on top of the thumbnail
  /// When users tap anywhere on the video thumbnail, it opens a video player dialog.
  /// The image loads from the internet and shows a loading spinner while downloading.
  Widget _buildVideoSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section heading
          Text(
            'Watch Our Story',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF424242),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: ShadCNTheme.space3), // Space between heading and video
          // The entire video thumbnail is clickable
          GestureDetector(
            // When tapped, opens the video player
            onTap: () => _openVideo(context),
            child: ClipRRect(
              // Rounds the corners of the video thumbnail (16 pixel radius)
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                // Stack allows us to layer the play button on top of the thumbnail image
                alignment: Alignment.center,
                children: [
                  // The video thumbnail image (preview picture)
                  AspectRatio(
                    // Maintains 16:9 aspect ratio (standard widescreen video format)
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      _thumbnailUrl, // The URL of the preview image
                      fit: BoxFit.cover, // Fills the space while maintaining aspect ratio
                      // Shows a loading spinner while the image is downloading
                      loadingBuilder: (context, child, loadingProgress) {
                        // If image is fully loaded, show it
                        if (loadingProgress == null) {
                          return child;
                        }
                        // Otherwise, show a loading spinner
                        return Container(
                          color: isDark
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFE3F2FD),
                          child: const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),
                        );
                      },
                      // If the image fails to load, show a broken image icon
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFE3F2FD),
                          child: Icon(
                            Icons.broken_image_outlined, // Broken image icon
                            size: 48,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF90CAF9),
                          ),
                        );
                      },
                    ),
                  ),
                  // Play button overlay (the circular play button on top of the thumbnail)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      // Semi-transparent black background (45% opacity)
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle, // Makes it perfectly circular
                      border: Border.all(
                        // White border around the circle (80% opacity)
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded, // The play arrow icon
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the video when the user taps the video thumbnail.
  /// This method handles two different scenarios:
  /// 1. If running on web: Opens the video in a new browser tab/window
  /// 2. If running on mobile (iOS/Android): Opens a video player dialog overlay
  /// The dialog shows the video in a web view that the user can close by tapping the X button.
  Future<void> _openVideo(BuildContext context) async {
    // Convert the video URL string into a proper URI object
    final previewUri = Uri.parse(_videoPreviewUrl);

    // Check if the app is running in a web browser
    if (kIsWeb) {
      // On web, open the video in a new browser tab/window
      final launched = await launchUrl(
        previewUri,
        mode: LaunchMode.externalApplication, // Opens in external browser
      );
      // If the video failed to open, show an error message
      if (!launched && context.mounted) {
        _showLaunchError(context);
      }
      return;
    }

    // On mobile devices, show the video in a dialog overlay
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // User can tap outside to close
      barrierColor: Colors.black.withValues(alpha: 0.85), // Dark semi-transparent background
      builder: (dialogContext) {
        // Creates and shows the video dialog component
        return _VideoDialog(url: previewUri.toString());
      },
    );
  }

  /// Shows an error message if the video fails to open (web only).
  /// This displays a small notification at the bottom of the screen telling the user
  /// that the video couldn't be opened.
  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open the video. Please try again later.'),
        behavior: SnackBarBehavior.floating, // Floating style (not anchored to bottom)
      ),
    );
  }
}

/// Video Dialog - A popup overlay that displays the video player.
/// This dialog appears when users tap the video thumbnail on mobile devices.
/// It shows the video in a web view (like a mini browser) and allows users to
/// watch the video without leaving the app. Users can close it by tapping the X button.
class _VideoDialog extends StatefulWidget {
  const _VideoDialog({required this.url});

  /// The URL of the video to display (hosted on Google Drive)
  final String url;

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

/// The internal state that manages the video dialog's loading and display.
class _VideoDialogState extends State<_VideoDialog> {
  /// Controller that manages the web view (mini browser) that displays the video
  late final WebViewController _controller;
  /// Tracks whether the video is still loading (shows a spinner while loading)
  bool _isLoading = true;

  /// Called when the dialog is first created.
  /// Sets up the web view controller to load and display the video.
  @override
  void initState() {
    super.initState();
    // Create and configure the web view controller
    _controller = WebViewController()
      // Enable JavaScript so the video player can work properly
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Set background to black (looks better while loading)
      ..setBackgroundColor(Colors.black)
      // Set up a listener to know when the video page finishes loading
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // When the page finishes loading, hide the loading spinner
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      // Start loading the video URL
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Builds the video dialog's user interface.
  /// This creates a full-screen overlay with:
  /// - A black background
  /// - The video player (web view) in the center
  /// - A loading spinner while the video loads
  /// - A close button (X) in the top-right corner
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero, // No padding - dialog takes full screen
      backgroundColor: Colors.transparent, // Transparent so we can see the black background
      child: Stack(
        // Stack allows us to layer the close button on top of the video
        children: [
          Positioned.fill(
            // Makes the container fill the entire dialog
            child: Container(
              color: Colors.black, // Black background for the video
              child: SafeArea(
                // Ensures content doesn't overlap with phone notches or status bars
                child: Stack(
                  children: [
                    // The video player (web view) - fills most of the screen
                    Positioned.fill(
                      child: ClipRRect(
                        // Rounds the corners of the video (12 pixel radius)
                        borderRadius: BorderRadius.circular(12),
                        child: WebViewWidget(controller: _controller), // The actual video player
                      ),
                    ),
                    // Loading spinner - shown while video is loading
                    if (_isLoading)
                      const Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white, // White spinner on black background
                            ),
                          ),
                        ),
                      ),
                    // Close button - positioned in the top-right corner
                    Positioned(
                      top: 16,  // 16 pixels from the top
                      right: 16, // 16 pixels from the right
                      child: Material(
                        // Semi-transparent black background (60% opacity)
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: const CircleBorder(), // Makes it circular
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded, // X icon to close the dialog
                            color: Colors.white,
                          ),
                          // When tapped, closes the video dialog and returns to the About screen
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
