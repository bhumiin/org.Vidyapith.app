import 'package:flutter/material.dart';

import '../../models/sunday_school_schedule.dart';
import '../../services/sunday_school_schedule_service.dart';
import '../components/branded_app_bar.dart';
import '../components/card.dart';
import '../components/copyright_widget.dart';
import '../theme/shadcn_theme.dart';
import 'grade_schedule_screen.dart';

/// Class Schedule Screen - cluster to grade to schedule drill-down.
///
/// Lists the four clusters in the order they are printed (I, II, III, IV).
/// Tapping a cluster expands it in place - an accordion, one open at a time -
/// to reveal the grades inside it. Tapping a grade pushes
/// [GradeScheduleScreen] for that grade group.
///
/// The schedule is a bundled JSON asset, so this screen loads it once and
/// falls back to a message if the asset is missing or unreadable.
class ClassScheduleScreen extends StatefulWidget {
  /// Pre-loaded schedule. When null the screen loads the bundled asset itself
  /// (tests pass a schedule directly).
  final SundaySchoolSchedule? schedule;

  const ClassScheduleScreen({super.key, this.schedule});

  @override
  State<ClassScheduleScreen> createState() => _ClassScheduleScreenState();
}

class _ClassScheduleScreenState extends State<ClassScheduleScreen> {
  /// The parsed bundled schedule, once it has loaded.
  SundaySchoolSchedule? _schedule;

  /// True while the bundled asset is being read.
  bool _isLoading = true;

  /// Set when the asset could not be loaded.
  String? _errorMessage;

  /// Index of the one open cluster, or null when all are collapsed.
  int? _openClusterIndex;

  @override
  void initState() {
    super.initState();
    final injected = widget.schedule;
    if (injected != null) {
      _schedule = injected;
      _isLoading = false;
    } else {
      _loadSchedule();
    }
  }

  /// Loads the bundled schedule, degrading to an error message on failure.
  Future<void> _loadSchedule() async {
    final schedule = await SundaySchoolScheduleService().loadSchedule();
    if (!mounted) return;
    setState(() {
      _schedule = schedule;
      _isLoading = false;
      _errorMessage =
          schedule == null ? 'Unable to load the class schedule.' : null;
    });
  }

  /// Opens a cluster, closing whichever one was open before it.
  void _toggleCluster(int index) {
    setState(() {
      _openClusterIndex = _openClusterIndex == index ? null : index;
    });
  }

  /// Pushes the grade schedule screen for one grade group.
  void _openGradeSchedule(
    SundaySchoolSchedule schedule,
    ScheduleGroup group,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GradeScheduleScreen(
          group: group,
          legend: schedule.legend,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final schedule = _schedule;

    return Scaffold(
      appBar: buildBrandedAppBar(
        title: const Text('Class Schedule'),
        backgroundColor: isDark ? theme.colorScheme.surface : null,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : schedule == null
              ? _buildErrorState(theme, isDark)
              : _buildClusterList(theme, isDark, schedule),
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

  /// The four cluster cards, in printed order, with the copyright footer.
  Widget _buildClusterList(
    ThemeData theme,
    bool isDark,
    SundaySchoolSchedule schedule,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < schedule.clusters.length; i++) ...[
            if (i > 0) const SizedBox(height: ShadCNTheme.space3),
            _buildClusterCard(theme, isDark, schedule, i),
          ],
          const SizedBox(height: ShadCNTheme.space4),
          CopyrightWidget(),
        ],
      ),
    );
  }

  /// One cluster: a tappable header that toggles the accordion, plus the
  /// grade rows shown while the cluster is open.
  Widget _buildClusterCard(
    ThemeData theme,
    bool isDark,
    SundaySchoolSchedule schedule,
    int index,
  ) {
    final cluster = schedule.clusters[index];
    final isOpen = _openClusterIndex == index;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
              onTap: () => _toggleCluster(index),
              child: Padding(
                padding: const EdgeInsets.all(ShadCNTheme.space4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cluster ${cluster.id}', style: titleStyle),
                          if (cluster.grades.isNotEmpty) ...[
                            const SizedBox(height: ShadCNTheme.space1),
                            Text('Grades: ${cluster.grades.join(', ')}',
                                style: subtitleStyle),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: ShadCNTheme.space2),
                    Icon(
                      isOpen ? Icons.expand_less : Icons.expand_more,
                      color: iconColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOpen)
            for (var i = 0; i < cluster.groups.length; i++) ...[
              const Divider(height: 1),
              _buildGradeRow(theme, isDark, schedule, cluster.groups[i]),
            ],
        ],
      ),
    );
  }

  /// One grade row inside an open cluster. Tapping it pushes the grade
  /// schedule screen. Only the grade is listed - bold, with no header text.
  Widget _buildGradeRow(
    ThemeData theme,
    bool isDark,
    SundaySchoolSchedule schedule,
    ScheduleGroup group,
  ) {
    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: ShadCNTheme.fontBold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openGradeSchedule(schedule, group),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ShadCNTheme.space4,
            vertical: ShadCNTheme.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(group.gradeLabel, style: labelStyle),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark
                    ? ShadCNTheme.darkMutedForeground
                    : ShadCNTheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
