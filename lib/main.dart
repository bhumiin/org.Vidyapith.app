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

void main() {
  runApp(const VidyapithApp());
}

class VidyapithApp extends StatelessWidget {
  const VidyapithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vidyapith',
      theme: ShadCNTheme.lightTheme,
      darkTheme: ShadCNTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

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

  @override
  void initState() {
    super.initState();
    // Trigger daily refresh check in background (non-blocking)
    DailyRefreshService.refreshContactIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;

          // Use HomeScreen for the first tab (Home)
          if (index == 0) {
            return const HomeScreen();
          }

          if (index == 1) {
            return const AboutScreen();
          }

          if (index == 2) {
            return const EventsScreen();
          }

          if (index == 3) {
            return const CalendarScreen();
          }

          if (index == 4) {
            return const ContactScreen();
          }

          return WebViewTab(url: tab['url']!, title: tab['title']!);
        }).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
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
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class WebViewTab extends StatefulWidget {
  final String url;
  final String title;

  const WebViewTab({required this.url, required this.title, super.key});

  @override
  State<WebViewTab> createState() => _WebViewTabState();
}

class _WebViewTabState extends State<WebViewTab> {
  late final WebViewController _controller;
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    // Only initialize WebView controller for non-web platforms
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Page finished loading: $url');
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    }

    Connectivity().onConnectivityChanged.listen((result) {
      setState(() => _isOffline = result.contains(ConnectivityResult.none));
    });
  }

  void _onRefresh() async {
    if (!kIsWeb) {
      await _controller.reload();
    }
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return const Center(
        child: Text(
          "You're offline. Please check your connection.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Use iframe for web platform, WebView for mobile
    if (kIsWeb) {
      return _buildWebView();
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
          maxWidth: MediaQuery.of(context).size.width,
        ),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

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

/// ShadCN UI Demo Screen
class ShadCNDemoScreen extends StatefulWidget {
  const ShadCNDemoScreen({super.key});

  @override
  State<ShadCNDemoScreen> createState() => _ShadCNDemoScreenState();
}

class _ShadCNDemoScreenState extends State<ShadCNDemoScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _textareaController = TextEditingController();
  String? _selectedValue;
  List<String> _selectedCheckboxes = [];
  String? _selectedRadio;
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _textareaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShadCN UI Components'),
        actions: [
          IconButton(
            onPressed: () {
              final brightness = Theme.of(context).brightness;
              // Toggle theme logic would go here
            },
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ShadCNTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buttons Section
            ShadSection(
              title: 'Buttons',
              description: 'Various button styles and sizes',
              child: Column(
                children: [
                  ShadFlex(
                    direction: Axis.horizontal,
                    spacing: ShadCNTheme.space2,
                    children: [
                      ShadButton(
                        text: 'Default',
                        onPressed: () => _showToast('Default button pressed!'),
                      ),
                      ShadButton(
                        text: 'Secondary',
                        variant: ShadButtonVariant.secondary,
                        onPressed: () =>
                            _showToast('Secondary button pressed!'),
                      ),
                      ShadButton(
                        text: 'Destructive',
                        variant: ShadButtonVariant.destructive,
                        onPressed: () =>
                            _showToast('Destructive button pressed!'),
                      ),
                    ],
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadFlex(
                    direction: Axis.horizontal,
                    spacing: ShadCNTheme.space2,
                    children: [
                      ShadButton(
                        text: 'Outline',
                        variant: ShadButtonVariant.outline,
                        onPressed: () => _showToast('Outline button pressed!'),
                      ),
                      ShadButton(
                        text: 'Ghost',
                        variant: ShadButtonVariant.ghost,
                        onPressed: () => _showToast('Ghost button pressed!'),
                      ),
                      ShadButton(
                        text: 'Link',
                        variant: ShadButtonVariant.link,
                        onPressed: () => _showToast('Link button pressed!'),
                      ),
                    ],
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadFlex(
                    direction: Axis.horizontal,
                    spacing: ShadCNTheme.space2,
                    children: [
                      ShadButton(
                        text: 'Small',
                        size: ShadButtonSize.sm,
                        onPressed: () => _showToast('Small button pressed!'),
                      ),
                      ShadButton(
                        text: 'Large',
                        size: ShadButtonSize.lg,
                        onPressed: () => _showToast('Large button pressed!'),
                      ),
                      ShadButton(
                        text: 'Loading',
                        isLoading: _isLoading,
                        onPressed: () {
                          setState(() => _isLoading = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            setState(() => _isLoading = false);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: ShadCNTheme.space8),

            // Cards Section
            ShadSection(
              title: 'Cards',
              description: 'Card components with different layouts',
              child: Column(
                children: [
                  ShadCardComplete(
                    title: 'Card with Title',
                    description: 'This is a card with a title and description.',
                    content: const Text('Card content goes here.'),
                    footer: ShadButton(
                      text: 'Action',
                      size: ShadButtonSize.sm,
                      onPressed: () => _showToast('Card action pressed!'),
                    ),
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadCard(
                    child: Column(
                      children: [
                        const Text('Simple Card'),
                        const SizedBox(height: ShadCNTheme.space2),
                        ShadBadge(
                          text: 'Badge',
                          variant: ShadBadgeVariant.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: ShadCNTheme.space8),

            // Form Components Section
            ShadSection(
              title: 'Form Components',
              description: 'Input fields, selects, and form controls',
              child: Column(
                children: [
                  ShadInput(
                    label: 'Email',
                    placeholder: 'Enter your email',
                    controller: _inputController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadTextarea(
                    label: 'Message',
                    placeholder: 'Enter your message',
                    controller: _textareaController,
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadSelect<String>(
                    label: 'Country',
                    placeholder: 'Select a country',
                    value: _selectedValue,
                    onChanged: (value) =>
                        setState(() => _selectedValue = value),
                    options: const [
                      ShadSelectOption(value: 'us', label: 'United States'),
                      ShadSelectOption(value: 'uk', label: 'United Kingdom'),
                      ShadSelectOption(value: 'ca', label: 'Canada'),
                      ShadSelectOption(value: 'au', label: 'Australia'),
                    ],
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadCheckboxGroup(
                    label: 'Interests',
                    selectedValues: _selectedCheckboxes,
                    onChanged: (values) =>
                        setState(() => _selectedCheckboxes = values),
                    options: const [
                      ShadCheckboxOption(value: 'sports', label: 'Sports'),
                      ShadCheckboxOption(value: 'music', label: 'Music'),
                      ShadCheckboxOption(value: 'travel', label: 'Travel'),
                    ],
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadRadioGroup<String>(
                    label: 'Gender',
                    value: _selectedRadio,
                    onChanged: (value) =>
                        setState(() => _selectedRadio = value),
                    options: const [
                      ShadRadioOption(value: 'male', label: 'Male'),
                      ShadRadioOption(value: 'female', label: 'Female'),
                      ShadRadioOption(value: 'other', label: 'Other'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: ShadCNTheme.space8),

            // Alerts Section
            ShadSection(
              title: 'Alerts',
              description: 'Alert components for notifications',
              child: Column(
                children: [
                  ShadAlert(
                    title: 'Default Alert',
                    description: 'This is a default alert message.',
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadAlert(
                    title: 'Success Alert',
                    description: 'Operation completed successfully!',
                    variant: ShadAlertVariant.success,
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadAlert(
                    title: 'Warning Alert',
                    description: 'Please check your input.',
                    variant: ShadAlertVariant.warning,
                  ),
                  const SizedBox(height: ShadCNTheme.space4),
                  ShadAlert(
                    title: 'Error Alert',
                    description: 'Something went wrong.',
                    variant: ShadAlertVariant.destructive,
                  ),
                ],
              ),
            ),

            const SizedBox(height: ShadCNTheme.space8),

            // Badges Section
            ShadSection(
              title: 'Badges',
              description: 'Badge components for labels and status',
              child: ShadFlex(
                direction: Axis.horizontal,
                spacing: ShadCNTheme.space2,
                children: const [
                  ShadBadge(text: 'Default'),
                  ShadBadge(
                    text: 'Secondary',
                    variant: ShadBadgeVariant.secondary,
                  ),
                  ShadBadge(
                    text: 'Destructive',
                    variant: ShadBadgeVariant.destructive,
                  ),
                  ShadBadge(text: 'Outline', variant: ShadBadgeVariant.outline),
                ],
              ),
            ),

            const SizedBox(height: ShadCNTheme.space8),

            // Dialog Demo
            ShadSection(
              title: 'Dialogs',
              description: 'Modal dialogs and confirmations',
              child: ShadFlex(
                direction: Axis.horizontal,
                spacing: ShadCNTheme.space2,
                children: [
                  ShadButton(
                    text: 'Show Dialog',
                    onPressed: () => _showDialog(),
                  ),
                  ShadButton(
                    text: 'Show Alert',
                    variant: ShadButtonVariant.outline,
                    onPressed: () => _showAlertDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: ShadCNTheme.space8),
          ],
        ),
      ),
    );
  }

  void _showToast(String message) {
    ShadToastService.show(
      context,
      title: message,
      variant: ShadAlertVariant.success,
    );
  }

  void _showDialog() {
    ShadDialogService.showDialog(
      context: context,
      title: 'Dialog Title',
      description: 'This is a dialog description.',
      content: const Text('Dialog content goes here.'),
      actions: [
        ShadButton(
          text: 'Cancel',
          variant: ShadButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
        ShadButton(
          text: 'Confirm',
          onPressed: () {
            Navigator.of(context).pop();
            _showToast('Dialog confirmed!');
          },
        ),
      ],
    );
  }

  void _showAlertDialog() {
    ShadDialogService.showAlertDialog(
      context: context,
      title: 'Confirm Action',
      description: 'Are you sure you want to proceed?',
      confirmText: 'Yes, proceed',
      cancelText: 'Cancel',
      onConfirm: () {
        Navigator.of(context).pop();
        _showToast('Action confirmed!');
      },
    );
  }
}
