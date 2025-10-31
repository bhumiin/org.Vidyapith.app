import 'package:shared_preferences/shared_preferences.dart';

import '../services/website_scraper.dart';

class DailyRefreshService {
  static const String _lastContactRefreshKey = 'last_contact_refresh_timestamp';
  static const Duration _refreshInterval = Duration(hours: 24);

  /// Check if contact content needs refresh and refresh if needed.
  /// Returns true if refresh was triggered, false if cached content is still fresh.
  static Future<bool> refreshContactIfNeeded({
    WebsiteScraper? scraper,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRefreshTimestamp = prefs.getInt(_lastContactRefreshKey);

    final now = DateTime.now();
    bool needsRefresh = false;

    if (lastRefreshTimestamp == null) {
      // First time, refresh now
      needsRefresh = true;
    } else {
      final lastRefresh = DateTime.fromMillisecondsSinceEpoch(lastRefreshTimestamp);
      final age = now.difference(lastRefresh);
      if (age >= _refreshInterval) {
        needsRefresh = true;
      }
    }

    if (needsRefresh) {
      try {
        final scraperInstance = scraper ?? WebsiteScraper();
        await scraperInstance.getContactContent(forceRefresh: true);
        await prefs.setInt(
          _lastContactRefreshKey,
          now.millisecondsSinceEpoch,
        );
        scraperInstance.dispose();
        return true;
      } catch (_) {
        // Silent failure - don't block app startup
        return false;
      }
    }

    return false;
  }

  /// Manually reset the last refresh timestamp (useful for testing)
  static Future<void> resetLastRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastContactRefreshKey);
  }
}

