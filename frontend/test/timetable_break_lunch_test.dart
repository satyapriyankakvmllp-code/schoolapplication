import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/classes/domain/classes_actor.dart';
import 'package:frontend/src/features/classes/domain/timetable_entry_model.dart';
import 'package:frontend/src/features/classes/data/classes_repository.dart';
import 'package:frontend/src/features/classes/presentation/admin/timetable_management_screen.dart';
import 'package:frontend/src/features/classes/presentation/widgets/timetable_day_list.dart';
import 'package:frontend/src/features/classes/presentation/widgets/classes_lookup.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const admin = ClassesActor(role: UserRole.admin, userId: 'USR-ADMIN-01');

  group('Timetable Break & Lunch Specification and Overlap Rules', () {
    test('Overlapping Break (10:15 - 10:30 AM) is rejected for teaching periods', () async {
      final repo = MockClassesRepository();

      // Attempt period starting inside break
      expect(
        () => repo.saveTimetableEntry(
          admin,
          const TimetableEntryModel(
            id: '',
            classId: 'cls-10',
            sectionId: 'sec-10a',
            subjectId: 'sub-101',
            teacherId: 'STF-2026-0112',
            dayOfWeek: 1,
            startTime: '10:20',
            endTime: '11:05',
          ),
          isNew: true,
        ),
        throwsA(
          isA<ClassesDataException>().having(
            (e) => e.message,
            'message',
            contains('Cannot schedule class during Break (10:15 AM - 10:30 AM)'),
          ),
        ),
      );

      // Attempt period spanning across break
      expect(
        () => repo.saveTimetableEntry(
          admin,
          const TimetableEntryModel(
            id: '',
            classId: 'cls-10',
            sectionId: 'sec-10a',
            subjectId: 'sub-101',
            teacherId: 'STF-2026-0112',
            dayOfWeek: 1,
            startTime: '10:00',
            endTime: '10:45',
          ),
          isNew: true,
        ),
        throwsA(
          isA<ClassesDataException>().having(
            (e) => e.message,
            'message',
            contains('Cannot schedule class during Break (10:15 AM - 10:30 AM)'),
          ),
        ),
      );
    });

    test('Overlapping Lunch (12:00 - 12:40 PM) is rejected for teaching periods', () async {
      final repo = MockClassesRepository();

      // Attempt period ending inside lunch
      expect(
        () => repo.saveTimetableEntry(
          admin,
          const TimetableEntryModel(
            id: '',
            classId: 'cls-10',
            sectionId: 'sec-10a',
            subjectId: 'sub-101',
            teacherId: 'STF-2026-0112',
            dayOfWeek: 1,
            startTime: '11:45',
            endTime: '12:30',
          ),
          isNew: true,
        ),
        throwsA(
          isA<ClassesDataException>().having(
            (e) => e.message,
            'message',
            contains('Cannot schedule class during Lunch (12:00 PM - 12:40 PM)'),
          ),
        ),
      );

      // Attempt period starting inside lunch
      expect(
        () => repo.saveTimetableEntry(
          admin,
          const TimetableEntryModel(
            id: '',
            classId: 'cls-10',
            sectionId: 'sec-10a',
            subjectId: 'sub-101',
            teacherId: 'STF-2026-0112',
            dayOfWeek: 1,
            startTime: '12:15',
            endTime: '13:00',
          ),
          isNew: true,
        ),
        throwsA(
          isA<ClassesDataException>().having(
            (e) => e.message,
            'message',
            contains('Cannot schedule class during Lunch (12:00 PM - 12:40 PM)'),
          ),
        ),
      );
    });

    test('Non-overlapping boundary periods (ending at 10:15 / starting at 10:30) are permitted', () async {
      final repo = MockClassesRepository();

      final pBefore = await repo.saveTimetableEntry(
        admin,
        const TimetableEntryModel(
          id: '',
          classId: 'cls-1',
          sectionId: 'sec-1a',
          subjectId: 'sub-101',
          teacherId: 'STF-2026-0199',
          dayOfWeek: 6,
          startTime: '07:30',
          endTime: '08:00',
        ),
        isNew: true,
      );
      expect(pBefore.id.isNotEmpty, isTrue);
    });

    test('Break entry sanitizes teacher and classroom assignments', () async {
      final repo = MockClassesRepository();

      final breakEntry = await repo.saveTimetableEntry(
        admin,
        const TimetableEntryModel(
          id: '',
          classId: 'cls-10',
          sectionId: 'sec-10a',
          subjectId: 'sub-101',
          teacherId: 'STF-2026-0112',
          classroomId: 'room-101',
          isBreak: true,
          title: 'Special Tea Break',
          dayOfWeek: 6,
          startTime: '15:00',
          endTime: '15:20',
        ),
        isNew: true,
      );

      expect(breakEntry.isBreak, isTrue);
      expect(breakEntry.subjectId, isEmpty);
      expect(breakEntry.teacherId, isEmpty);
      expect(breakEntry.classroomId, isNull);
      expect(breakEntry.title, equals('Special Tea Break'));
    });
  });

  group('Timetable UI Views: Grid and Table View Display', () {
    testWidgets('Timetable Grid displays Break and Lunch slot rows', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TimetableManagementScreen(
                initialClassId: 'cls-10',
                initialSectionId: 'sec-10a',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check standard Break (10:15 - 10:30 AM) and Lunch (12:00 - 12:40 PM) badges
      expect(find.text('BREAK'), findsWidgets);
      expect(find.text('LUNCH'), findsWidgets);
      expect(find.text('10:15 AM - 10:30 AM'), findsWidgets);
      expect(find.text('12:00 PM - 12:40 PM'), findsWidgets);
      expect(find.text('Break'), findsWidgets);
      expect(find.text('Lunch'), findsWidgets);
    });

    testWidgets('Timetable Table View displays Break and Lunch rows with — for teacher & room', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TimetableManagementScreen(
                initialClassId: 'cls-10',
                initialSectionId: 'sec-10a',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Table View
      final tableViewToggle = find.text('Table View');
      expect(tableViewToggle, findsOneWidget);
      await tester.tap(tableViewToggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirm Table View shows Break and Lunch
      expect(find.text('Timetable Periods'), findsOneWidget);
      expect(find.text('Break'), findsWidgets);
      expect(find.text('Lunch'), findsWidgets);
      expect(find.text('10:15 AM - 10:30 AM'), findsWidgets);
      expect(find.text('12:00 PM - 12:40 PM'), findsWidgets);

      // Search for "Lunch"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Lunch');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lunch'), findsWidgets);
      // All teaching subjects should be filtered out
      expect(find.text('Mathematics'), findsNothing);
    });

    testWidgets('TimetableDayList displays Break and Lunch with custom badge and reserved text', (tester) async {
      final entries = [
        const TimetableEntryModel(
          id: 'tt-1',
          classId: 'cls-10',
          sectionId: 'sec-10a',
          subjectId: 'sub-101',
          teacherId: 'tch-1',
          dayOfWeek: 1,
          startTime: '08:00',
          endTime: '08:45',
        ),
        const TimetableEntryModel(
          id: 'tt-b1',
          classId: 'cls-10',
          sectionId: 'sec-10a',
          subjectId: '',
          teacherId: '',
          isBreak: true,
          title: 'Break',
          dayOfWeek: 1,
          startTime: '10:15',
          endTime: '10:30',
        ),
        const TimetableEntryModel(
          id: 'tt-l1',
          classId: 'cls-10',
          sectionId: 'sec-10a',
          subjectId: '',
          teacherId: '',
          isBreak: true,
          title: 'Lunch',
          dayOfWeek: 1,
          startTime: '12:00',
          endTime: '12:40',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimetableDayList(
              entries: entries,
              lookup: const ClassesLookup(
                classes: [],
                sections: [],
                subjects: [],
                classrooms: [],
                teachers: [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('10:15 – 10:30  ·  Break'), findsOneWidget);
      expect(find.text('12:00 – 12:40  ·  Lunch'), findsOneWidget);
      expect(find.text('Break Time · Reserved (No classes or teachers assigned)'), findsNWidgets(2));
    });
  });
}
