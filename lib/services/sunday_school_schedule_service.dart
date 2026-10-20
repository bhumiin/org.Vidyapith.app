import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/sunday_school_schedule.dart';

/// The two teaching days the school runs, each bound to the bundled asset
/// that holds its timetable. Both files share one schema
/// (`docs/class-schedule-schema.md`).
enum SchoolDay {
  saturday(
    'Saturday',
    'assets/data/saturday-school-schedule-2026-2027.json',
  ),
  sunday(
    'Sunday',
    'assets/data/sunday-school-schedule-2026-2027.json',
  );

  const SchoolDay(this.label, this.assetPath);

  /// Day name as the school prints it.
  final String label;

  /// Where this day's bundled schedule lives, relative to the project root.
  final String assetPath;
}

/// Loads the class schedule that ships with the app, for either teaching day.
///
/// There is deliberately no scraper here: the 2026-2027 schedules are fixed,
/// already-extracted datasets bundled as JSON assets, so they are read from
/// the asset bundle and never fetched at runtime.
class SundaySchoolScheduleService {
  /// Reads and parses the bundled schedule for [day] (Sunday by default,
  /// which is what existing callers expect).
  ///
  /// Returns null when the asset is missing or cannot be parsed, so callers
  /// can fall back to an error state instead of crashing.
  Future<SundaySchoolSchedule?> loadSchedule([
    SchoolDay day = SchoolDay.sunday,
  ]) async {
    try {
      final raw = await rootBundle.loadString(day.assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        debugPrint(
          'SundaySchoolScheduleService: ${day.label} schedule asset '
          'is not an object',
        );
        return null;
      }
      return SundaySchoolSchedule.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (error) {
      // Degrade gracefully: a missing or corrupt asset becomes an empty
      // screen with a message, not a crash.
      debugPrint(
        'SundaySchoolScheduleService: unable to load ${day.label} '
        'schedule: $error',
      );
      return null;
    }
  }
}
