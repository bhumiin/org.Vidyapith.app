import 'package:flutter/material.dart';

import '../../models/sunday_school_schedule.dart';
import '../components/badge.dart';
import '../components/branded_app_bar.dart';
import '../components/card.dart';
import '../components/copyright_widget.dart';
import '../theme/shadcn_theme.dart';

/// Grade Schedule Screen - the four periods of one grade group.
///
/// Reached by tapping a grade inside the Class Schedule screen. It shows:
/// - the grade header as printed, its section codes, rooms, class size and
///   any header note,
/// - the four periods in order. Where the subject is printed per section it
///   appears in each section's block; where it is printed once for the grade
///   it appears once, followed by the teacher list(s),
/// - the symbol legend, because symbols such as `*` and `((--))` appear
///   inside the printed teacher lists.
///
/// Teacher lists are rendered from `teachers_raw` exactly as printed - never
/// tidied, expanded or stripped of symbols.
class GradeScheduleScreen extends StatelessWidget {
  /// The grade group to display.
  final ScheduleGroup group;

  /// The symbol legend from the schedule JSON, keyed by printed symbol.
  final Map<String, String> legend;

  const GradeScheduleScreen({
    super.key,
    required this.group,
    required this.legend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: buildBrandedAppBar(
        title: Text('Grade ${group.gradeLabel}'),
        backgroundColor: isDark ? theme.colorScheme.surface : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ShadCNTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(theme, isDark),
            for (final period in group.periods) ...[
              const SizedBox(height: ShadCNTheme.space3),
              _buildPeriodCard(theme, isDark, period),
            ],
            if (legend.isNotEmpty) ...[
              const SizedBox(height: ShadCNTheme.space4),
              _buildLegendCard(theme, isDark),
            ],
            const SizedBox(height: ShadCNTheme.space4),
            CopyrightWidget(),
          ],
        ),
      ),
    );
  }

  /// Header card: grade label, printed header, section codes with rooms,
  /// class size and the nullable header notes.
  Widget _buildHeaderCard(ThemeData theme, bool isDark) {
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: ShadCNTheme.fontBold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: ShadCNTheme.fontSemibold,
      color: isDark
          ? ShadCNTheme.darkMutedForeground
          : ShadCNTheme.mutedForeground,
    );
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark
          ? ShadCNTheme.darkMutedForeground
          : ShadCNTheme.mutedForeground,
    );

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.gradeLabel, style: titleStyle),
          if (group.headerRaw.isNotEmpty) ...[
            const SizedBox(height: ShadCNTheme.space1),
            // The header exactly as printed, kept for reference.
            Text(group.headerRaw, style: mutedStyle),
          ],
          if (group.sections.isNotEmpty) ...[
            const SizedBox(height: ShadCNTheme.space3),
            Text('Rooms', style: labelStyle),
            const SizedBox(height: ShadCNTheme.space1),
            for (final section in group.sections)
              Padding(
                padding: const EdgeInsets.only(bottom: ShadCNTheme.space1),
                // The room is printed as-is: grades 9B and 10B carry a
                // compound room that changes by period, so it is never split.
                child: Text('${section.code} — ${section.room}', style: bodyStyle),
              ),
          ],
          const SizedBox(height: ShadCNTheme.space1),
          Text('Class size: ${group.classSize}', style: bodyStyle),
          if (group.classSizeNote != null)
            Padding(
              padding: const EdgeInsets.only(top: ShadCNTheme.space1),
              child: Text(group.classSizeNote!, style: mutedStyle),
            ),
          if (group.roomNote != null)
            Padding(
              padding: const EdgeInsets.only(top: ShadCNTheme.space1),
              child: Text(group.roomNote!, style: mutedStyle),
            ),
          if (group.snackBreak) ...[
            const SizedBox(height: ShadCNTheme.space2),
            const ShadBadge(
              text: 'Snack Break',
              variant: ShadBadgeVariant.outline,
              size: ShadBadgeSize.sm,
            ),
          ],
        ],
      ),
    );
  }

  /// One card per period, in printed order.
  Widget _buildPeriodCard(ThemeData theme, bool isDark, SchedulePeriod period) {
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: ShadCNTheme.fontSemibold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Period ${period.period}', style: titleStyle),
          const SizedBox(height: ShadCNTheme.space2),
          if (period.isSectionScoped)
            // Each section prints its own subject, so each cell is rendered
            // with its own subject and its own teacher list.
            for (var i = 0; i < period.cells.length; i++) ...[
              if (i > 0) const SizedBox(height: ShadCNTheme.space3),
              _buildSectionEntry(
                theme,
                isDark,
                period.cells[i],
                showSectionLabel: period.cells.length > 1,
              ),
            ]
          else ...[
            // The subject is printed once for the whole grade group.
            _buildSubject(
              theme,
              isDark,
              period.subject,
              period.subjectDetail,
            ),
            const SizedBox(height: ShadCNTheme.space2),
            if (period.merged)
              // One printed cell spans every section: render the single
              // teacher list once, not once per section.
              _buildTeacherBlock(
                theme,
                isDark,
                label: period.cells.map((cell) => cell.section).join(', '),
                teachersRaw: period.cells.isEmpty
                    ? ''
                    : period.cells.first.teachersRaw,
              )
            else
              // Shared subject, but each section's teacher list was printed
              // independently - render one block per section.
              for (var i = 0; i < period.cells.length; i++) ...[
                if (i > 0) const SizedBox(height: ShadCNTheme.space3),
                _buildTeacherBlock(
                  theme,
                  isDark,
                  label: period.cells[i].section,
                  teachersRaw: period.cells[i].teachersRaw,
                ),
              ],
          ],
        ],
      ),
    );
  }

  /// One section-scoped cell: its own subject plus its own teacher list.
  Widget _buildSectionEntry(
    ThemeData theme,
    bool isDark,
    ScheduleCell cell, {
    required bool showSectionLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSectionLabel) ...[
          _sectionLabel(theme, isDark, cell.section),
          const SizedBox(height: ShadCNTheme.space1),
        ],
        _buildSubject(theme, isDark, cell.subject ?? cell.activityRaw, cell.subjectDetail),
        const SizedBox(height: ShadCNTheme.space1),
        _teacherList(theme, isDark, cell.teachersRaw),
      ],
    );
  }

  /// Subject line (and its detail) for a period or a cell.
  Widget _buildSubject(
    ThemeData theme,
    bool isDark,
    String? subject,
    String? subjectDetail,
  ) {
    if (subject == null || subject.isEmpty) {
      return const SizedBox.shrink();
    }

    final subjectStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: ShadCNTheme.fontSemibold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final detailStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark
          ? ShadCNTheme.darkMutedForeground
          : ShadCNTheme.mutedForeground,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subject, style: subjectStyle),
        if (subjectDetail != null && subjectDetail.isNotEmpty) ...[
          const SizedBox(height: ShadCNTheme.space1),
          Text(subjectDetail, style: detailStyle),
        ],
      ],
    );
  }

  /// A labelled teacher list - label is the section code(s) or empty.
  Widget _buildTeacherBlock(
    ThemeData theme,
    bool isDark, {
    required String label,
    required String teachersRaw,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          _sectionLabel(theme, isDark, label),
          const SizedBox(height: ShadCNTheme.space1),
        ],
        _teacherList(theme, isDark, teachersRaw),
      ],
    );
  }

  /// The printed teacher list, symbols and parentheses untouched.
  Widget _teacherList(ThemeData theme, bool isDark, String teachersRaw) {
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
      height: 1.4,
    );

    return Text(teachersRaw, style: style);
  }

  /// Section code label used above subjects and teacher lists.
  Widget _sectionLabel(ThemeData theme, bool isDark, String label) {
    final style = theme.textTheme.labelMedium?.copyWith(
      fontWeight: ShadCNTheme.fontSemibold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );

    return Text(label, style: style);
  }

  /// The symbol legend, shown unobtrusively below the schedule.
  Widget _buildLegendCard(ThemeData theme, bool isDark) {
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: ShadCNTheme.fontSemibold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final entryStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark
          ? ShadCNTheme.darkMutedForeground
          : ShadCNTheme.mutedForeground,
    );

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legend', style: labelStyle),
          const SizedBox(height: ShadCNTheme.space1),
          for (final entry in legend.entries)
            Text('${entry.key} — ${entry.value}', style: entryStyle),
        ],
      ),
    );
  }
}
