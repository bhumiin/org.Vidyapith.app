import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/sunday_school_schedule.dart';

/// Loads the Sunday School class schedule that ships with the app.
///
/// There is deliberately no scraper here: the 2026-2027 schedule is a fixed,
/// already-extracted dataset bundled as a JSON asset, so it is read from the
/// asset bundle and never fetched at runtime.
class SundaySchoolScheduleService {
  /// Where the bundled schedule lives, relative to the project root.
  static const String assetPath =
      'assets/data/sunday-school-schedule-2026-2027.json';

  /// Reads and parses the bundled schedule.
  ///
  /// Returns null when the asset is missing or cannot be parsed, so callers
  /// can fall back to an error state instead of crashing.
  Future<SundaySchoolSchedule?> loadSchedule() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        debugPrint('SundaySchoolScheduleService: schedule asset is not an object');
        return null;
      }
      return SundaySchoolSchedule.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (error) {
      // Degrade gracefully: a missing or corrupt asset becomes an empty
      // screen with a message, not a crash.
      debugPrint('SundaySchoolScheduleService: unable to load schedule: $error');
      return null;
    }
  }
}
