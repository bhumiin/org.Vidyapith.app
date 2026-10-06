import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:vidyapith_hybrid_app/models/sunday_school_schedule.dart';
import 'package:vidyapith_hybrid_app/services/sunday_school_schedule_service.dart';
import 'package:vidyapith_hybrid_app/ui/screens/class_schedule_day_hub_screen.dart';
import 'package:vidyapith_hybrid_app/ui/screens/class_schedule_screen.dart';
import 'package:vidyapith_hybrid_app/ui/screens/grade_schedule_screen.dart';
import 'package:vidyapith_hybrid_app/ui/screens/home_screen.dart';

/// Paths of the bundled timetables, relative to the project root.
const String saturdayAssetPath =
    'assets/data/saturday-school-schedule-2026-2027.json';
const String sundayAssetPath =
    'assets/data/sunday-school-schedule-2026-2027.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SundaySchoolSchedule saturday;
  late SundaySchoolSchedule sunday;
  late Map<String, dynamic> saturdayDocument;

  setUpAll(() async {
    final saturdayRaw = await rootBundle.loadString(saturdayAssetPath);
    saturdayDocument = jsonDecode(saturdayRaw) as Map<String, dynamic>;
    saturday = SundaySchoolSchedule.fromJson(saturdayDocument);

    final sundayRaw = await rootBundle.loadString(sundayAssetPath);
    sunday = SundaySchoolSchedule.fromJson(
      jsonDecode(sundayRaw) as Map<String, dynamic>,
    );
  });

  /// Looks up a Saturday grade group by its display label (e.g. "6A").
  ScheduleGroup saturdayGroupFor(String gradeLabel) {
    for (final cluster in saturday.clusters) {
      for (final group in cluster.groups) {
        if (group.gradeLabel == gradeLabel) return group;
      }
    }
    throw StateError('No Saturday grade group "$gradeLabel" in the schedule');
  }

  /// Pumps the day hub with both bundled schedules injected.
  Future<void> pumpHub(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ClassScheduleDayHubScreen(saturday: saturday, sunday: sunday),
      ),
    );
  }

  /// Pumps a [GradeScheduleScreen] for one Saturday grade group.
  Future<void> pumpSaturdayGradeScreen(
    WidgetTester tester,
    String gradeLabel,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GradeScheduleScreen(
          group: saturdayGroupFor(gradeLabel),
          legend: saturday.legend,
        ),
      ),
    );
  }

  group('Saturday bundled asset', () {
    test('is schema 2.0 for Saturday, with the Saturday section letters', () {
      expect(saturdayDocument['day'], 'Saturday');
      expect(saturdayDocument['schema_version'], '2.0');

      expect(
        saturday.clusters.map((cluster) => cluster.id),
        ['I', 'II', 'III', 'IV'],
      );
      expect(
        saturday.clusters[0].groups.map((group) => group.gradeLabel),
        ['KG A', '1A', '2A'],
      );
      expect(
        saturday.clusters[1].groups.map((group) => group.gradeLabel),
        ['3A', '4A', '5A'],
      );
      expect(
        saturday.clusters[2].groups.map((group) => group.gradeLabel),
        ['6A', '7A', '8A'],
      );
      // Cluster IV holds four grades; the others hold three.
      expect(
        saturday.clusters[3].groups.map((group) => group.gradeLabel),
        ['9A', '10A', '11A', '12A'],
      );
    });

    test('reads class_size from the field, never from the printed header', () {
      final kg = saturdayGroupFor('KG A');
      // The header prints the size to the left of the section code.
      expect(kg.headerRaw, '17+  KG A  KG Hall');
      expect(kg.classSize, 17);
      expect(kg.classSizeNote, isNotNull);
    });

    test('every period is section-scoped with exactly one cell', () {
      for (final cluster in saturday.clusters) {
        for (final group in cluster.groups) {
          for (final period in group.periods) {
            final where = 'Cluster ${cluster.id} / ${group.gradeLabel}';
            expect(period.subjectScope, 'section', reason: where);
            expect(period.merged, isFalse, reason: where);
            expect(period.cells, hasLength(1), reason: where);
            // One section per grade, so the cell's section is null.
            expect(period.cells.single.section, isEmpty, reason: where);
          }
        }
      }
    });

    test('SundaySchoolScheduleService loads the Saturday asset', () async {
      final loaded = await SundaySchoolScheduleService().loadSchedule(
        SchoolDay.saturday,
      );

      expect(loaded, isNotNull);
      expect(loaded!.clusters, hasLength(4));
      expect(loaded.clusters.last.groups, hasLength(4));
    });
  });

  group('Class Schedule day hub', () {
    testWidgets('shows both days with their cluster and grade span',
        (tester) async {
      await pumpHub(tester);

      expect(find.text('Class Schedule'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
      // The same span fits both days: four clusters, KG through 12.
      expect(find.text('Clusters I–IV · KG–12'), findsNWidgets(2));
    });

    testWidgets('the Saturday row opens the Saturday cluster list',
        (tester) async {
      await pumpHub(tester);

      await tester.tap(find.text('Saturday'));
      await tester.pumpAndSettle();

      expect(find.byType(ClassScheduleScreen), findsOneWidget);
      expect(find.text('Cluster I'), findsOneWidget);
      expect(find.text('Cluster IV'), findsOneWidget);

      await tester.tap(find.text('Cluster I'));
      await tester.pumpAndSettle();

      // Saturday's section letters, not Sunday's.
      expect(find.text('KG A'), findsOneWidget);
      expect(find.text('1A'), findsOneWidget);
      expect(find.text('2A'), findsOneWidget);
      expect(find.text('KG'), findsNothing);
      expect(find.text('1B'), findsNothing);
    });

    testWidgets('the Sunday row opens the cluster list Sunday always had',
        (tester) async {
      await pumpHub(tester);

      await tester.tap(find.text('Sunday'));
      await tester.pumpAndSettle();

      expect(find.byType(ClassScheduleScreen), findsOneWidget);
      expect(find.text('Cluster I'), findsOneWidget);
      // Matched on the grades themselves rather than the whole line, so
      // the assertion does not depend on the line's exact prefix.
      expect(find.textContaining('KG, 1, 2'), findsOneWidget);

      await tester.tap(find.text('Cluster I'));
      await tester.pumpAndSettle();

      expect(find.text('KG'), findsOneWidget);
      expect(find.text('1B'), findsOneWidget);
      expect(find.text('2B'), findsOneWidget);

      // Drilling into a grade behaves exactly as before the day hub.
      await tester.ensureVisible(find.text('1B'));
      await tester.tap(find.text('1B'));
      await tester.pumpAndSettle();

      expect(find.byType(GradeScheduleScreen), findsOneWidget);
      expect(find.text('Grade 1B'), findsOneWidget);
      expect(find.text('Class size: 20'), findsOneWidget);
    });

    testWidgets('Cluster IV on the Saturday list renders four grade rows',
        (tester) async {
      await pumpHub(tester);

      await tester.tap(find.text('Saturday'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cluster IV'));
      await tester.pumpAndSettle();

      expect(find.text('9A'), findsOneWidget);
      expect(find.text('10A'), findsOneWidget);
      expect(find.text('11A'), findsOneWidget);
      expect(find.text('12A'), findsOneWidget);
      expect(find.text('9B'), findsNothing);
    });

    testWidgets('the Class Schedule tile lands on the day hub',
        (tester) async {
      // The home screen shows network photos; the test HTTP client answers
      // 400, so their loads fail. That is irrelevant to this navigation
      // test - swallow exactly those errors and nothing else.
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      // The website fetch fails fast in the test zone; let it settle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.ensureVisible(find.text('CLASS SCHEDULE'));
      await tester.tap(find.text('CLASS SCHEDULE'));
      await tester.pump();

      // The hub reads two assets off the bundle, off the fake clock. Do not
      // pumpAndSettle: the home screen's photo carousel keeps a live timer.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Class Schedule'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });
  });

  group('Saturday grade screen', () {
    testWidgets('a section-scoped period renders the cell\'s own subject',
        (tester) async {
      await pumpSaturdayGradeScreen(tester, '6A');

      // Period 1 of 6A is section-scoped: the subject lives on the cell.
      expect(find.text('Swami Vivekananda, Wandering Monk'), findsOneWidget);
      // ...and so does period 3's.
      expect(find.text('Sanskrit VI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cluster III period 4 renders both semester halves',
        (tester) async {
      await pumpSaturdayGradeScreen(tester, '6A');

      expect(find.text('Semester 1'), findsOneWidget);
      expect(find.text('Semester 2'), findsOneWidget);
      // Each half carries its own subject, detail and teachers.
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Mythology'), findsOneWidget);
      expect(find.text('(Ramayana)'), findsOneWidget);
      expect(
        find.text('Nina Didi, Haresh Uncle, (Medha H. Aunty*)'),
        findsOneWidget,
      );
      // The halves cell has no subject of its own - it must not crash or
      // print an empty subject line.
      expect(find.text(''), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a grade with a null class size renders without throwing',
        (tester) async {
      final group = ScheduleGroup.fromJson(const {
        'grade': '1',
        'grade_label': '1A',
        'header_raw': '1A  Room 101',
        'class_size': null,
        'sections': [
          {'code': '1A', 'room': 'Room 101'},
        ],
        'periods': [
          {
            'period': 1,
            'subject_scope': 'section',
            'merged': false,
            'cells': [
              {
                'section': null,
                'subject': 'Music',
                'teachers_raw': 'Test Aunty',
              },
            ],
          },
        ],
      });
      expect(group.classSize, isNull);

      await tester.pumpWidget(
        MaterialApp(home: GradeScheduleScreen(group: group, legend: const {})),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Grade 1A'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      // No size is printed, and certainly not a fabricated zero.
      expect(find.text('Class size: 0'), findsNothing);
      expect(find.textContaining('Class size'), findsNothing);
    });
  });
}
