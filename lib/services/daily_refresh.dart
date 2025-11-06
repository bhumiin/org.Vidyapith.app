import 'package:shared_preferences/shared_preferences.dart';

import '../services/website_scraper.dart';

/// Service that manages automatic daily refresh of contact content.
/// 
/// This service checks if contact information from the website needs to be refreshed
/// (typically once every 24 hours) and triggers a refresh if needed. This helps keep
/// the app's contact information up-to-date without requiring manual refresh.
/// 
/// Usage: Call refreshContactIfNeeded() when the app starts or at regular intervals.
class DailyRefreshService {
  // ============================================================================
  // CONSTANTS
  // ============================================================================
  
  /// Key used to store the last refresh timestamp in SharedPreferences (local storage).
  /// This key identifies where we saved the time when we last refreshed the contact info.
  static const String _lastContactRefreshKey = 'last_contact_refresh_timestamp';
  
  /// How often to refresh the contact content (24 hours = once per day).
  /// After this time has passed since the last refresh, we'll fetch fresh data.
  static const Duration _refreshInterval = Duration(hours: 24);

  // ============================================================================
  // MAIN METHODS
  // ============================================================================
  
  /// Check if contact content needs refresh and refresh if needed.
  /// 
  /// This method:
  /// 1. Checks when we last refreshed the contact content
  /// 2. If it's been more than 24 hours (or never refreshed), triggers a refresh
  /// 3. Updates the "last refreshed" timestamp after successfully refreshing
  /// 
  /// [scraper] - Optional WebsiteScraper instance (for testing). If not provided,
  ///             a new one will be created.
  /// 
  /// Returns:
  /// - `true` if a refresh was triggered and completed successfully
  /// - `false` if cached content is still fresh (less than 24 hours old) or refresh failed
  /// 
  /// Example usage:
  /// ```dart
  /// await DailyRefreshService.refreshContactIfNeeded();
  /// ```
  static Future<bool> refreshContactIfNeeded({
    WebsiteScraper? scraper,
  }) async {
    // Get access to local storage (SharedPreferences) to check last refresh time
    final prefs = await SharedPreferences.getInstance();
    
    // Read the timestamp of when we last refreshed (stored as milliseconds)
    // If null, it means we've never refreshed before
    final lastRefreshTimestamp = prefs.getInt(_lastContactRefreshKey);

    final now = DateTime.now();
    bool needsRefresh = false;

    // Check if we need to refresh
    if (lastRefreshTimestamp == null) {
      // First time running - we should refresh immediately
      needsRefresh = true;
    } else {
      // Convert the stored timestamp (milliseconds) back to a DateTime object
      final lastRefresh = DateTime.fromMillisecondsSinceEpoch(lastRefreshTimestamp);
      
      // Calculate how much time has passed since the last refresh
      final age = now.difference(lastRefresh);
      
      // If 24 hours or more have passed, we need to refresh
      if (age >= _refreshInterval) {
        needsRefresh = true;
      }
    }

    // If we need to refresh, do it now
    if (needsRefresh) {
      try {
        // Use the provided scraper (for testing) or create a new one
        final scraperInstance = scraper ?? WebsiteScraper();
        
        // Force a refresh of contact content from the website
        // This will fetch fresh data and update the cache
        await scraperInstance.getContactContent(forceRefresh: true);
        
        // Save the current time as the new "last refreshed" timestamp
        // We store it as milliseconds since epoch (a number representing the date/time)
        await prefs.setInt(
          _lastContactRefreshKey,
          now.millisecondsSinceEpoch,
        );
        
        // Clean up the HTTP client to free resources
        scraperInstance.dispose();
        
        // Return true to indicate refresh was successful
        return true;
      } catch (_) {
        // If refresh fails (network error, etc.), don't crash the app
        // Just return false - the app will use cached data if available
        // Silent failure - don't block app startup
        return false;
      }
    }

    // No refresh needed - cached content is still fresh
    return false;
  }

  /// Manually reset the last refresh timestamp (useful for testing).
  /// 
  /// This removes the stored timestamp, so the next call to refreshContactIfNeeded()
  /// will treat it as if we've never refreshed before and will refresh immediately.
  /// 
  /// Useful for:
  /// - Testing the refresh functionality
  /// - Forcing a refresh on next app launch
  /// 
  /// Example usage:
  /// ```dart
  /// await DailyRefreshService.resetLastRefresh();
  /// ```
  static Future<void> resetLastRefresh() async {
    // Get access to local storage
    final prefs = await SharedPreferences.getInstance();
    
    // Remove the stored timestamp key
    // This will cause the next refresh check to trigger immediately
    await prefs.remove(_lastContactRefreshKey);
  }
}

