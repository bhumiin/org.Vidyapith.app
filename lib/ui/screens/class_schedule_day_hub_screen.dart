import 'package:flutter/material.dart';

import '../../models/sunday_school_schedule.dart';
import '../../services/sunday_school_schedule_service.dart';
import '../components/branded_app_bar.dart';
import '../components/card.dart';
import '../components/copyright_widget.dart';
import '../theme/shadcn_theme.dart';
import 'class_schedule_screen.dart';

/// Class Schedule day hub - pick a teaching day.
///
/// The school runs two timetables (Saturday and Sunday) off one schema.
/// This screen loads both bundled assets once, shows one large card per
/// day, and pushes the shared cluster list ([ClassScheduleScreen]) for the
/// chosen day. The Quick Links "Class Schedule" tile lands here.
///
/// The two cards are siblings of the cluster cards on the screen they
/// push: a [ShadCard] with an [InkWell] row, primary label, secondary line
/// and a chevron - two destinations, not a filter, so no dropdown.
class ClassScheduleDayHubScreen extends StatefulWidget {
  /// Pre-loaded schedules. When either is null the screen loads the
  /// missing bundled asset itself (tests pass schedules directly).
  final SundaySchoolSchedule? saturday;
  final SundaySchoolSchedule? sunday;

  const ClassScheduleDayHubScreen({super.key, this.saturday, this.sunday});

  @override
  State<ClassScheduleDayHubScreen> createState() =>
      _ClassScheduleDayHubScreenState();
}

class _ClassScheduleDayHubScreenState extends State<ClassScheduleDayHubScreen> {
  /// The parsed bundled schedules, once loaded.
  SundaySchoolSchedule? _saturday;
  SundaySchoolSchedule? _sunday;

  /// True while the bundled assets are being read.
  bool _isLoading = true;

  /// Set when either asset could not be loaded.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _saturday = widget.saturday;
    _sunday = widget.sunday;
    if (_saturday != null && _sunday != null) {
      _isLoading = false;
    } else {
      _loadDays();
    }
  }

  /// Loads the bundled schedule for whichever day was not injected,
  /// degrading to an error message on failure.
  Future<void> _loadDays() async {
    final service = SundaySchoolScheduleService();
    final saturday =
        widget.saturday ?? await service.loadSchedule(SchoolDay.saturday);
    final sunday =
        widget.sunday ?? await service.loadSchedule(SchoolDay.sunday);
    if (!mounted) return;
    setState(() {
      _saturday = saturday;
      _sunday = sunday;
      _isLoading = false;
      _errorMessage = (saturday == null || sunday == null)
          ? 'Unable to load the class schedule.'
          : null;
    });
  }

  /// Pushes the cluster list for one day's schedule.
  void _openDay(SundaySchoolSchedule schedule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassScheduleScreen(schedule: schedule),
      ),
    );
  }

  /// "Clusters I–IV · KG–12", derived from the loaded schedule, as the
  /// second line of a day card.
  String _spanFor(SundaySchoolSchedule schedule) {
    final ids = schedule.clusters.map((cluster) => cluster.id).toList();
    final clusterSpan =
        ids.length > 1 ? '${ids.first}–${ids.last}' : ids.join(', ');

    // Grades run KG, 1 ... 12; KG carries no numeral, so it reads as the
    // start of the range when present.
    final gradeNumbers = <int>[];
    var hasKindergarten = false;
    for (final cluster in schedule.clusters) {
      for (final group in cluster.groups) {
        final grade = int.tryParse(group.grade);
        if (grade == null) {
          hasKindergarten = true;
        } else {
          gradeNumbers.add(grade);
        }
      }
    }
    gradeNumbers.sort();
    if (gradeNumbers.isEmpty) return 'Clusters $clusterSpan';
    final gradeSpan = hasKindergarten
        ? 'KG–${gradeNumbers.last}'
        : '${gradeNumbers.first}–${gradeNumbers.last}';
    return 'Clusters $clusterSpan · $gradeSpan';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final saturday = _saturday;
    final sunday = _sunday;

    return Scaffold(
      appBar: buildBrandedAppBar(
        title: const Text('Class Schedule'),
        backgroundColor: isDark ? theme.colorScheme.surface : null,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : saturday == null || sunday == null
              ? _buildErrorState(theme, isDark)
              : _buildDayList(theme, isDark, saturday, sunday),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ShadCNTheme.space6),
        child: Text(
          _errorMessage ?? 'Unable to load the class schedule.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? ShadCNTheme.darkMutedForeground
                : ShadCNTheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// The two day cards, Saturday then Sunday, with the copyright footer.
  Widget _buildDayList(
    ThemeData theme,
    bool isDark,
    SundaySchoolSchedule saturday,
    SundaySchoolSchedule sunday,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayCard(theme, isDark, SchoolDay.saturday, saturday),
          const SizedBox(height: ShadCNTheme.space3),
          _buildDayCard(theme, isDark, SchoolDay.sunday, sunday),
          const SizedBox(height: ShadCNTheme.space4),
          CopyrightWidget(),
        ],
      ),
    );
  }

  /// One day: a tappable card with the day name and its cluster/grade
  /// span, pushing that day's cluster list.
  Widget _buildDayCard(
    ThemeData theme,
    bool isDark,
    SchoolDay day,
    SundaySchoolSchedule schedule,
  ) {
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: ShadCNTheme.fontSemibold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark
          ? ShadCNTheme.darkMutedForeground
          : ShadCNTheme.mutedForeground,
    );
    final iconColor = isDark
        ? ShadCNTheme.darkMutedForeground
        : ShadCNTheme.mutedForeground;

    return ShadCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
          onTap: () => _openDay(schedule),
          child: Padding(
            padding: const EdgeInsets.all(ShadCNTheme.space4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.label, style: titleStyle),
                      const SizedBox(height: ShadCNTheme.space1),
                      Text(_spanFor(schedule), style: subtitleStyle),
                    ],
                  ),
                ),
                const SizedBox(width: ShadCNTheme.space2),
                Icon(Icons.chevron_right, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
