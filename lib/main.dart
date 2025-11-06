// Import statements - These bring in all the tools and components we need
// to build the app, like buttons, screens, web views, and theme styling
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/foundation.dart';
import 'ui/theme/shadcn_theme.dart';
import 'ui/components/button.dart';
import 'ui/components/card.dart';
import 'ui/components/input.dart';
import 'ui/components/badge.dart';
import 'ui/components/alert.dart';
import 'ui/components/checkbox.dart';
import 'ui/components/radio.dart';
import 'ui/components/select.dart';
import 'ui/components/container.dart';
import 'ui/components/dialog.dart';
import 'ui/screens/about_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/events_screen.dart';
import 'ui/screens/calendar_screen.dart';
import 'ui/screens/contact_screen.dart';
import 'services/daily_refresh.dart';

/// Main entry point of the application
/// This is the first function that runs when the app starts
/// It tells Flutter to start running the VidyapithApp
void main() {
  runApp(const VidyapithApp());
}

/// Root application widget
/// This sets up the entire app with its theme (light/dark mode) and
/// determines which screen to show first (MainScreen)
/// 
/// Features:
/// - App name: "Vidyapith"
/// - Automatic theme switching based on device settings (light/dark mode)
/// - Custom theme colors for both light and dark modes
class VidyapithApp extends StatelessWidget {
  const VidyapithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vidyapith', // This is the app name shown in the app switcher
      theme: ShadCNTheme.lightTheme, // Light mode colors and styling
      darkTheme: ShadCNTheme.darkTheme, // Dark mode colors and styling
      themeMode: ThemeMode.system, // Automatically follows device theme setting
      home: const MainScreen(), // The first screen users see when app opens
    );
  }
}

/// Main navigation screen with bottom tab bar
/// This is the central hub of the app that manages all 5 tabs:
/// Home, About, Events, Calendar, and Contact
/// 
/// Key Features:
/// - Bottom navigation bar with 5 tabs
/// - Each tab remembers its scroll position
/// - Automatic scroll-to-top when switching tabs
/// - Home tab refresh when tapping Home while already on Home
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Tracks which tab is currently selected (0 = Home, 1 = About, etc.)
  int _currentIndex = 0;
  
  // This notifier tells the Home screen to refresh its content
  // We use an integer that increments each time, so the Home screen
  // always knows when to reload even if tapped multiple times
  final ValueNotifier<int> _homeRefreshNotifier = ValueNotifier<int>(0);
  
  // These notifiers tell each screen to scroll back to the top
  // When a user taps a tab, we toggle the value (true/false) to trigger
  // the scroll-to-top action on that specific screen
  final ValueNotifier<bool> _homeScrollNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _aboutScrollNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _eventsScrollNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _calendarScrollNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _contactScrollNotifier = ValueNotifier<bool>(false);

  // List of all tabs in the app with their names and website URLs
  // This configuration makes it easy to add or modify tabs in the future
  final List<Map<String, String>> _tabs = [
    {'title': 'Home', 'url': 'https://www.vidyapith.org'},
    {'title': 'About', 'url': 'https://www.vidyapith.org/about'},
    {'title': 'Events', 'url': 'https://www.vidyapith.org/events'},
    {
      'title': 'Calendar',
      'url':
          'https://www.vidyapith.org/uploads/5/2/1/3/52135817/v9_final_dates_vp_calendar_2025_n_2024.11.12.pdf',
    },
    {'title': 'Contact', 'url': 'https://www.vidyapith.org/contact'},
  ];

  /// This runs once when the screen is first created
  /// It checks if the contact information needs to be refreshed
  /// (for example, if it's been more than 24 hours since last update)
  @override
  void initState() {
    super.initState();
    // Check if contact data needs refreshing in the background
    // This doesn't block the app from loading - it happens quietly
    DailyRefreshService.refreshContactIfNeeded();
  }

  /// Cleanup function - runs when the screen is removed from memory
  /// This prevents memory leaks by properly disposing of all notifiers
  /// Think of it like turning off all the lights before leaving a room
  @override
  void dispose() {
    _homeRefreshNotifier.dispose();
    _homeScrollNotifier.dispose();
    _aboutScrollNotifier.dispose();
    _eventsScrollNotifier.dispose();
    _calendarScrollNotifier.dispose();
    _contactScrollNotifier.dispose();
    super.dispose();
  }

  /// Builds the main screen layout with navigation
  /// This creates the visual structure: bottom navigation bar and content area
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all 5 tab screens in memory at once
      // This means when you switch tabs, the content is already loaded
      // and scroll position is preserved. Only the visible tab is shown.
      body: IndexedStack(
        index: _currentIndex, // Shows the tab at this index (0-4)
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key; // Which tab number (0, 1, 2, 3, or 4)
          final tab = entry.value; // The tab's title and URL

          // Each tab gets its own custom screen widget
          // We pass the scroll notifier so the screen can listen for scroll-to-top commands
          
          // Tab 0: Home - Special because it has refresh capability
          if (index == 0) {
            return HomeScreen(
              refreshNotifier: _homeRefreshNotifier, // Allows refreshing Home tab
              scrollNotifier: _homeScrollNotifier, // Allows scrolling Home to top
            );
          }

          // Tab 1: About - Shows information about Vidyapith
          if (index == 1) {
            return AboutScreen(scrollNotifier: _aboutScrollNotifier);
          }

          // Tab 2: Events - Shows upcoming events
          if (index == 2) {
            return EventsScreen(scrollNotifier: _eventsScrollNotifier);
          }

          // Tab 3: Calendar - Shows the calendar PDF
          if (index == 3) {
            return CalendarScreen(scrollNotifier: _calendarScrollNotifier);
          }

          // Tab 4: Contact - Shows contact information
          if (index == 4) {
            return ContactScreen(scrollNotifier: _contactScrollNotifier);
          }

          // Fallback: If somehow we have more tabs, use a generic WebView
          return WebViewTab(url: tab['url']!, title: tab['title']!);
        }).toList(),
      ),
      // Bottom navigation bar - The 5 tabs users can tap at the bottom of the screen
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex, // Highlights which tab is currently active
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'About'),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.contact_page_outlined),
            label: 'Contact',
          ),
        ],
        // This function runs every time a user taps a tab
        onDestinationSelected: (index) {
          // Special behavior: If user taps Home while already on Home, refresh the content
          // This is useful for checking if there are new updates
          if (index == 0 && _currentIndex == 0) {
            // Increment the refresh counter to trigger a refresh
            _homeRefreshNotifier.value = _homeRefreshNotifier.value + 1;
          }
          
          // Switch to the selected tab by updating the current index
          setState(() => _currentIndex = index);
          
          // Scroll to top for whichever tab was selected
          // We toggle the value (true becomes false, false becomes true) to trigger
          // the scroll action, even if the user is already at the top
          switch (index) {
            case 0:
              _homeScrollNotifier.value = !_homeScrollNotifier.value;
              break;
            case 1:
              _aboutScrollNotifier.value = !_aboutScrollNotifier.value;
              break;
            case 2:
              _eventsScrollNotifier.value = !_eventsScrollNotifier.value;
              break;
            case 3:
              _calendarScrollNotifier.value = !_calendarScrollNotifier.value;
              break;
            case 4:
              _contactScrollNotifier.value = !_contactScrollNotifier.value;
              break;
          }
        },
      ),
    );
  }
}

/// WebView Tab - Displays web content inside the app
/// This widget shows website pages or PDFs directly in the app
/// instead of opening an external browser
/// 
/// Features:
/// - Loads web pages and PDFs
/// - Pull-to-refresh to reload content
/// - Detects when device is offline
/// - Works differently on mobile vs web platforms
class WebViewTab extends StatefulWidget {
  final String url; // The web address to load (e.g., "https://www.vidyapith.org")
  final String title; // The title of the page

  const WebViewTab({required this.url, required this.title, super.key});

  @override
  State<WebViewTab> createState() => _WebViewTabState();
}

class _WebViewTabState extends State<WebViewTab> {
  // Controller that manages the web page loading and navigation
  late final WebViewController _controller;
  
  // Controller for pull-to-refresh functionality
  // Users can pull down on the screen to reload the page
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false, // Don't refresh automatically when page loads
  );
  
  // Tracks whether the device has internet connection
  bool _isOffline = false;

  /// Initializes the WebView when the screen is first created
  /// Sets up the web page loading and connectivity monitoring
  @override
  void initState() {
    super.initState();

    // WebView only works on mobile devices (iOS/Android), not on web browsers
    // So we only set it up if we're not running on the web platform
    if (!kIsWeb) {
      // Configure the WebView to load web pages
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted) // Allow JavaScript to run
        ..setNavigationDelegate(
          NavigationDelegate(
            // Called when a page starts loading
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            // Called when a page finishes loading
            onPageFinished: (String url) {
              print('Page finished loading: $url');
            },
            // Called if there's an error loading the page
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url)); // Actually load the URL
    }

    // Listen for changes in internet connectivity
    // If the device goes offline, we'll show an offline message
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() => _isOffline = result.contains(ConnectivityResult.none));
    });
  }

  /// Called when user pulls down to refresh the page
  /// Reloads the web page content
  void _onRefresh() async {
    if (!kIsWeb) {
      await _controller.reload(); // Reload the current page
    }
    _refreshController.refreshCompleted(); // Tell the refresh indicator we're done
  }

  /// Builds the WebView display
  /// Shows different content based on connectivity and platform
  @override
  Widget build(BuildContext context) {
    // First check: If device is offline, show a message instead of trying to load
    if (_isOffline) {
      return const Center(
        child: Text(
          "You're offline. Please check your connection.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Second check: If running on web platform, show a placeholder
    // (WebView doesn't work in web browsers, so we show this instead)
    if (kIsWeb) {
      return _buildWebView();
    }

    // On mobile devices: Show the actual WebView with pull-to-refresh
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh, // What to do when user pulls down to refresh
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height, // Use full screen height
          maxWidth: MediaQuery.of(context).size.width, // Use full screen width
        ),
        child: WebViewWidget(controller: _controller), // The actual web page display
      ),
    );
  }

  /// Placeholder view for web platform
  /// Since WebView doesn't work in web browsers, this shows a simple message
  /// with the URL that would be loaded
  Widget _buildWebView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.web, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Web View',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This would load: ${widget.url}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // For web platforms, this would open in new tab
              // For mobile platforms, this is just a placeholder
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('URL: ${widget.url}')));
            },
            child: const Text('Show URL'),
          ),
        ],
      ),
    );
  }
}
