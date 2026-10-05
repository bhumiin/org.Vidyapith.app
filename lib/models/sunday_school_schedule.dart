/// Structured Sunday School class schedule for the 2026-2027 year.
///
/// The schedule is a fixed dataset that ships with the app as a JSON asset
/// (`assets/data/sunday-school-schedule-2026-2027.json`). The field contract
/// is documented in `docs/sunday-school-schedule-schema.md`.
///
/// Parsing is defensive: a missing or unexpected value falls back to a safe
/// default instead of throwing, so a data problem degrades into an incomplete
/// screen rather than a crash.
class SundaySchoolSchedule {
  /// Version of the JSON schema (currently "1.0").
  final String schemaVersion;

  /// Maps each printed symbol (`*`, `(-)`, `((--))`) to its meaning.
  ///
  /// These symbols really do appear inside `teachers_raw`, so the grade
  /// schedule screen shows this legend alongside the teacher lists.
  final Map<String, String> legend;

  /// The four clusters in the order they are printed: I, II, III, IV.
  ///
  /// Never sorted or reordered - the printed order is the display order.
  final List<ScheduleCluster> clusters;

  /// Where the schedule came from (email, attachments, extraction method).
  /// Developer-facing provenance - read it, never render it in the UI.
  final Map<String, dynamic> source;

  /// Every reading that is not fully confirmed. Developer-facing provenance -
  /// read it, never render it in the UI.
  final List<Map<String, dynamic>> uncertainties;

  const SundaySchoolSchedule({
    required this.schemaVersion,
    required this.legend,
    required this.clusters,
    required this.source,
    required this.uncertainties,
  });

  /// Parses a decoded `sunday-school-schedule-2026-2027.json` document.
  ///
  /// Malformed entries are skipped or defaulted rather than thrown, so the
  /// screens always have something to show.
  factory SundaySchoolSchedule.fromJson(Map<String, dynamic> json) {
    final clusters = <ScheduleCluster>[];
    final rawClusters = json['clusters'];
    if (rawClusters is List) {
      for (final entry in rawClusters) {
        if (entry is Map) {
          clusters.add(
            ScheduleCluster.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    return SundaySchoolSchedule(
      schemaVersion: _stringOr(json['schema_version'], ''),
      legend: _stringMap(json['legend']),
      clusters: clusters,
      source: _mapOrEmpty(json['source']),
      uncertainties: _mapList(json['uncertainties']),
    );
  }
}

/// One printed cluster sheet (I-IV) and the grades it holds.
class ScheduleCluster {
  /// Cluster id as printed: "I", "II", "III" or "IV".
  final String id;

  /// Which photographed sheet holds this cluster (1 or 2).
  final int sheet;

  /// Page number printed on the sheet: I=1, II=2, III=3, IV=4.
  final int pageNumber;

  /// Where the cluster sits on its sheet: "top" or "bottom".
  final String pageInSheet;

  /// Grade labels in this cluster, as printed.
  final List<String> grades;

  /// The celebration line exactly as printed.
  final String celebrationsRaw;

  /// The celebration line split into individual items.
  final List<String> celebrations;

  /// Prayer / assembly / snack-break row text, keyed by section code or "all".
  final Map<String, String> prayerAssembly;

  /// One entry per grade in this cluster, in printed order.
  final List<ScheduleGroup> groups;

  const ScheduleCluster({
    required this.id,
    required this.sheet,
    required this.pageNumber,
    required this.pageInSheet,
    required this.grades,
    required this.celebrationsRaw,
    required this.celebrations,
    required this.prayerAssembly,
    required this.groups,
  });

  factory ScheduleCluster.fromJson(Map<String, dynamic> json) {
    final groups = <ScheduleGroup>[];
    final rawGroups = json['groups'];
    if (rawGroups is List) {
      for (final entry in rawGroups) {
        if (entry is Map) {
          groups.add(ScheduleGroup.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }

    return ScheduleCluster(
      id: _stringOr(json['id'], ''),
      sheet: _intOr(json['sheet'], 0),
      pageNumber: _intOr(json['page_number'], 0),
      pageInSheet: _stringOr(json['page_in_sheet'], ''),
      grades: _stringList(json['grades']),
      celebrationsRaw: _stringOr(json['celebrations_raw'], ''),
      celebrations: _stringList(json['celebrations']),
      prayerAssembly: _stringMap(json['prayer_assembly']),
      groups: groups,
    );
  }
}

/// One grade group (e.g. "4B") with its sections, rooms and four periods.
class ScheduleGroup {
  /// Grade as printed ("KG", "1" ... "12").
  final String grade;

  /// Grade with its section letter ("3B", "KG", "9B") - the display name.
  final String gradeLabel;

  /// The grade header exactly as printed, e.g. "(17+1) Grade 5B".
  final String headerRaw;

  /// The number in the first set of parentheses in the header.
  final int classSize;

  /// The `+N` part of the header and the header as printed, when present.
  final String? classSizeNote;

  /// Section codes and the room printed for each.
  final List<ScheduleSection> sections;

  /// Extra room text printed in the header (breakout rooms, library periods).
  final String? roomNote;

  /// True where the header row prints *Snack Break*.
  final bool snackBreak;

  /// The four periods of the session, in order.
  final List<SchedulePeriod> periods;

  const ScheduleGroup({
    required this.grade,
    required this.gradeLabel,
    required this.headerRaw,
    required this.classSize,
    this.classSizeNote,
    required this.sections,
    this.roomNote,
    this.snackBreak = false,
    required this.periods,
  });

  factory ScheduleGroup.fromJson(Map<String, dynamic> json) {
    final sections = <ScheduleSection>[];
    final rawSections = json['sections'];
    if (rawSections is List) {
      for (final entry in rawSections) {
        if (entry is Map) {
          sections.add(
            ScheduleSection.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    final periods = <SchedulePeriod>[];
    final rawPeriods = json['periods'];
    if (rawPeriods is List) {
      for (final entry in rawPeriods) {
        if (entry is Map) {
          periods.add(SchedulePeriod.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }
    periods.sort((a, b) => a.period.compareTo(b.period));

    return ScheduleGroup(
      grade: _stringOr(json['grade'], ''),
      gradeLabel: _stringOr(json['grade_label'], ''),
      headerRaw: _stringOr(json['header_raw'], ''),
      classSize: _intOr(json['class_size'], 0),
      classSizeNote: _nullableString(json['class_size_note']),
      sections: sections,
      roomNote: _nullableString(json['room_note']),
      snackBreak: _boolOr(json['snack_break']),
      periods: periods,
    );
  }
}

/// A section code and the room printed for it.
///
/// [room] is kept exactly as printed and may be compound, e.g. grades 9B and
/// 10B use "Room 109 - Periods 1,2,3; Library - Period 4".
class ScheduleSection {
  /// Section code as printed ("3B1", "9B").
  final String code;

  /// The room exactly as printed - never split or abbreviated.
  final String room;

  const ScheduleSection({required this.code, required this.room});

  factory ScheduleSection.fromJson(Map<String, dynamic> json) =>
      ScheduleSection(
        code: _stringOr(json['code'], ''),
        room: _stringOr(json['room'], ''),
      );
}

/// One of the four periods of a session for one grade group.
class SchedulePeriod {
  /// Period number, 1-4.
  final int period;

  /// "section" when each cell prints its own subject; "grade" when the
  /// subject is printed once for the whole grade group.
  final String subjectScope;

  /// The shared subject, present when [subjectScope] is "grade".
  final String? subject;

  /// Description of the shared subject, present for some "grade" periods.
  final String? subjectDetail;

  /// True when one printed cell spans every section, so a single teacher list
  /// covers the whole grade group.
  final bool merged;

  /// One cell per section, in printed left-to-right order.
  final List<ScheduleCell> cells;

  const SchedulePeriod({
    required this.period,
    required this.subjectScope,
    this.subject,
    this.subjectDetail,
    this.merged = false,
    required this.cells,
  });

  /// True when every cell carries its own subject.
  bool get isSectionScoped => subjectScope == 'section';

  factory SchedulePeriod.fromJson(Map<String, dynamic> json) {
    final cells = <ScheduleCell>[];
    final rawCells = json['cells'];
    if (rawCells is List) {
      for (final entry in rawCells) {
        if (entry is Map) {
          cells.add(ScheduleCell.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }

    return SchedulePeriod(
      period: _intOr(json['period'], 0),
      subjectScope: _stringOr(json['subject_scope'], 'section'),
      subject: _nullableString(json['subject']),
      subjectDetail: _nullableString(json['subject_detail']),
      merged: _boolOr(json['merged']),
      cells: cells,
    );
  }
}

/// One printed cell: a section's subject (when per-section) and teachers.
class ScheduleCell {
  /// Section code this cell belongs to.
  final String section;

  /// The subject for this cell, present when the period is section-scoped.
  final String? subject;

  /// Description following the subject in the same printed line.
  final String? subjectDetail;

  /// The subject line exactly as printed (subject + description, unsplit).
  final String? activityRaw;

  /// **Authoritative.** The teacher list exactly as printed - symbols,
  /// parentheses and all. Never tidy it up.
  final String teachersRaw;

  /// Best-effort split of [teachersRaw]. Use it only for searching or
  /// indexing; [teachersRaw] is what the sheet says.
  final List<ScheduleTeacher> teachers;

  /// Set on cells whose text was read from an adjacent merged cell.
  final String? mergedWith;

  /// Free-text notes about this specific cell.
  final List<String> flags;

  const ScheduleCell({
    required this.section,
    this.subject,
    this.subjectDetail,
    this.activityRaw,
    required this.teachersRaw,
    this.teachers = const [],
    this.mergedWith,
    this.flags = const [],
  });

  factory ScheduleCell.fromJson(Map<String, dynamic> json) {
    final teachers = <ScheduleTeacher>[];
    final rawTeachers = json['teachers'];
    if (rawTeachers is List) {
      for (final entry in rawTeachers) {
        if (entry is Map) {
          teachers.add(
            ScheduleTeacher.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    return ScheduleCell(
      section: _stringOr(json['section'], ''),
      subject: _nullableString(json['subject']),
      subjectDetail: _nullableString(json['subject_detail']),
      activityRaw: _nullableString(json['activity_raw']),
      teachersRaw: _stringOr(json['teachers_raw'], ''),
      teachers: teachers,
      mergedWith: _nullableString(json['merged_with']),
      flags: _stringList(json['flags']),
    );
  }
}

/// One entry of the convenience `teachers[]` split.
class ScheduleTeacher {
  /// Name with the symbols stripped. Null is valid - some printed entries
  /// carry a placeholder such as "(Uncle)" with no personal name.
  final String? name;

  /// The printed token, symbols included.
  final String raw;

  /// True when printed with `*` - teaches in more than one cluster.
  final bool multiCluster;

  /// "attend" for single parentheses, "occasional" for double parentheses.
  /// Derive any icon or shade from this field, never by parsing [raw].
  final String? attendance;

  /// True when the token names more than one teacher.
  final bool compound;

  /// Anything else worth keeping (trailing punctuation as printed, etc.).
  final String? note;

  const ScheduleTeacher({
    this.name,
    required this.raw,
    this.multiCluster = false,
    this.attendance,
    this.compound = false,
    this.note,
  });

  factory ScheduleTeacher.fromJson(Map<String, dynamic> json) => ScheduleTeacher(
        name: _nullableString(json['name']),
        raw: _stringOr(json['raw'], ''),
        multiCluster: _boolOr(json['multi_cluster']),
        attendance: _nullableString(json['attendance']),
        compound: _boolOr(json['compound']),
        note: _nullableString(json['note']),
      );
}

/// Reads a non-empty string, falling back to [fallback] otherwise.
String _stringOr(dynamic value, String fallback) =>
    value is String && value.isNotEmpty ? value : fallback;

/// Reads a string that may be absent or null.
String? _nullableString(dynamic value) => value is String ? value : null;

/// Reads an integer, falling back to [fallback] otherwise.
int _intOr(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

/// Reads a boolean that may be absent; anything but true becomes false.
bool _boolOr(dynamic value) => value is bool ? value : false;

/// Reads a list of strings, skipping anything that is not a string.
List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

/// Reads an object of string values, ignoring non-string entries.
Map<String, String> _stringMap(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, String>{};
  value.forEach((key, entry) {
    if (key is String && entry is String) {
      result[key] = entry;
    }
  });
  return result;
}

/// Reads an object as a mutable JSON map.
Map<String, dynamic> _mapOrEmpty(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

/// Reads a list of objects as JSON maps, skipping anything malformed.
List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
}
