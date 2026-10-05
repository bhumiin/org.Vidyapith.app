import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:vidyapith_hybrid_app/models/sunday_school_schedule.dart';
import 'package:vidyapith_hybrid_app/services/sunday_school_schedule_service.dart';
import 'package:vidyapith_hybrid_app/ui/screens/class_schedule_screen.dart';
import 'package:vidyapith_hybrid_app/ui/screens/grade_schedule_screen.dart';

/// Path of the bundled schedule, relative to the project root.
const String scheduleAssetPath =
    'assets/data/sunday-school-schedule-2026-2027.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SundaySchoolSchedule schedule;

  setUpAll(() async {
    final raw = await rootBundle.loadString(scheduleAssetPath);
    schedule = SundaySchoolSchedule.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  });

  /// Looks up a grade group by its display label (e.g. "6B").
  ScheduleGroup groupFor(String gradeLabel) {
    for (final cluster in schedule.clusters) {
      for (final group in cluster.groups) {
        if (group.gradeLabel == gradeLabel) return group;
      }
    }
    throw StateError('No grade group "$gradeLabel" in the schedule');
  }

  /// Pumps a [GradeScheduleScreen] for one grade group.
  Future<void> pumpGradeScreen(WidgetTester tester, String gradeLabel) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GradeScheduleScreen(
          group: groupFor(gradeLabel),
          legend: schedule.legend,
        ),
      ),
    );
  }

  group('SundaySchoolSchedule bundled asset', () {
    test('parses the four clusters in printed order with their grades', () {
      expect(
        schedule.clusters.map((cluster) => cluster.id),
        ['I', 'II', 'III', 'IV'],
      );
      expect(
        schedule.clusters[0].groups.map((group) => group.gradeLabel),
        ['KG', '1B', '2B'],
      );
      expect(
        schedule.clusters[1].groups.map((group) => group.gradeLabel),
        ['3B', '4B', '5B'],
      );
      expect(
        schedule.clusters[2].groups.map((group) => group.gradeLabel),
        ['6B', '7B', '8B'],
      );
      // Cluster IV has four grades; the other three have three.
      expect(
        schedule.clusters[3].groups.map((group) => group.gradeLabel),
        ['9B', '10B', '11B', '12B'],
      );
      expect(
        schedule.legend.keys,
        containsAll(<String>['*', '(-)', '((--))']),
      );
    });

    test('gives every group exactly four periods numbered 1 to 4', () {
      for (final cluster in schedule.clusters) {
        for (final group in cluster.groups) {
          expect(
            group.periods.map((period) => period.period),
            [1, 2, 3, 4],
            reason: 'Cluster ${cluster.id} / ${group.gradeLabel}',
          );
        }
      }
    });

    test('keeps source and uncertainties as developer provenance', () {
      expect(schedule.source, isNotEmpty);
      expect(schedule.uncertainties, isNotEmpty);
      // The printed placeholders that carry no personal name stay as printed.
      expect(
        groupFor('12B').periods.first.cells.first.teachersRaw,
        contains('(Uncle)'),
      );
    });

    test('SundaySchoolScheduleService loads the bundled schedule', () async {
      final loaded = await SundaySchoolScheduleService().loadSchedule();

      expect(loaded, isNotNull);
      expect(loaded!.clusters, hasLength(4));
      expect(loaded.clusters.last.groups, hasLength(4));
    });
  });

  group('GradeScheduleScreen rendering rules', () {
    testWidgets(
      'section-scoped period renders each section\'s own subject',
      (tester) async {
        await pumpGradeScreen(tester, '6B');

        // Period 1 of 6B is section-scoped: 6B1 and 6B2 print different
        // subjects, and both must appear.
        expect(find.text('Music VI'), findsOneWidget);
        expect(find.text('10 Stories of Ramayana'), findsOneWidget);
      },
    );

    testWidgets(
      'grade-scoped merged period renders its teacher list exactly once',
      (tester) async {
        await pumpGradeScreen(tester, '4B');

        // Period 1 of 4B is grade-scoped and merged: the subject and the
        // teacher list are printed once for the whole grade group, even
        // though the JSON carries the list in both section cells.
        expect(find.text('Biographies IV'), findsOneWidget);
        expect(
          find.text('Apexa Aunty*, Sumathi Aunty*, Lakshmi Aunty'),
          findsOneWidget,
        );
        // The same holds for the other merged period of 4B.
        expect(find.text('Music IV'), findsOneWidget);
        expect(
          find.text('Nilesh Bhaiya*, Chandrashekhar Uncle'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'grade-scoped unmerged period renders one teacher list per section',
      (tester) async {
        await pumpGradeScreen(tester, '6B');

        // Period 3 of 6B is grade-scoped but not merged: the subject is
        // printed once, while each section's teacher list is printed
        // independently and must be rendered once per section.
        expect(find.text('Sanskrit VI'), findsOneWidget);
        expect(find.text('Jayesh Uncle'), findsOneWidget);
        expect(
          find.text('Pratibha Aunty*, Khyati Aunty*'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows the symbol legend alongside the schedule',
        (tester) async {
      await pumpGradeScreen(tester, '6B');

      expect(find.text('Legend'), findsOneWidget);
      expect(
        find.text('* — Teacher teaches in more than one Cluster'),
        findsOneWidget,
      );
      expect(
        find.text('(-) — teacher will attend class'),
        findsOneWidget,
      );
      expect(
        find.text('((--)) — teacher will attend occasionally'),
        findsOneWidget,
      );
    });
  });

  group('ClassScheduleScreen cluster list', () {
    testWidgets('loads the bundled schedule when none is injected',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ClassScheduleScreen()));

      // The asset read completes off the fake test clock.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cluster I'), findsOneWidget);
      expect(find.text('Cluster IV'), findsOneWidget);
    });

    testWidgets(
      'lists the four clusters in order and expands one at a time',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ClassScheduleScreen(schedule: schedule)),
        );

        expect(find.text('Cluster I'), findsOneWidget);
        expect(find.text('Cluster II'), findsOneWidget);
        expect(find.text('Cluster III'), findsOneWidget);
        expect(find.text('Cluster IV'), findsOneWidget);
        // Grades are hidden while every cluster is collapsed.
        expect(find.text('9B'), findsNothing);

        await tester.tap(find.text('Cluster IV'));
        await tester.pumpAndSettle();

        // Cluster IV shows all four of its grades.
        expect(find.text('9B'), findsOneWidget);
        expect(find.text('10B'), findsOneWidget);
        expect(find.text('11B'), findsOneWidget);
        expect(find.text('12B'), findsOneWidget);
        // Only one cluster is open at a time, so Cluster I stays closed.
        expect(find.text('KG'), findsNothing);

        await tester.ensureVisible(find.text('12B'));
        await tester.tap(find.text('12B'));
        await tester.pumpAndSettle();

        expect(find.byType(GradeScheduleScreen), findsOneWidget);
        expect(find.text('Period 1'), findsOneWidget);
        expect(find.text('Class size: 20'), findsOneWidget);
      },
    );
  });
}
