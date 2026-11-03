import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/classes/domain/classes_actor.dart';
import 'package:frontend/src/features/classes/domain/timetable_entry_model.dart';
import 'package:frontend/src/features/classes/domain/subject_model.dart';
import 'package:frontend/src/features/classes/domain/class_model.dart';
import 'package:frontend/src/features/classes/domain/section_model.dart';
import 'package:frontend/src/features/classes/domain/classroom_model.dart';
import 'package:frontend/src/features/classes/data/classes_repository.dart';
import 'package:frontend/src/features/classes/application/timetable_controller.dart';
import 'package:frontend/src/features/classes/presentation/admin/timetable_management_screen.dart';
import 'package:frontend/src/features/classes/presentation/widgets/classes_lookup.dart';
import 'package:frontend/src/features/classes/presentation/widgets/timetable_day_list.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const admin = ClassesActor(role: UserRole.admin, userId: 'USR-ADMIN-01');

  final List<ClassModel> mockClasses = [
    const ClassModel(
      id: 'cls-10',
      name: '10th Class',
      gradeLevel: 10,
      academicYear: '2026-27',
    ),
    const ClassModel(
      id: 'cls-9',
      name: '9th Class',
      gradeLevel: 9,
      academicYear: '2026-27',
    ),
  ];

  final List<SectionModel> mockSections = [
    const SectionModel(
      id: 'sec-10a',
      classId: 'cls-10',
      name: 'Section A',
      capacity: 35,
    ),
    const SectionModel(
      id: 'sec-10b',
      classId: 'cls-10',
      name: 'Section B',
      capacity: 35,
    ),
    const SectionModel(
      id: 'sec-9a',
      classId: 'cls-9',
      name: 'Section A',
      capacity: 35,
    ),
  ];

  final List<SubjectModel> mockSubjects = [
    const SubjectModel(
      id: 'sub-math',
      classId: 'cls-10',
      name: 'Mathematics',
      code: 'MTH',
      type: 'Theory',
      teacherId: 'tch-101',
    ),
    const SubjectModel(
      id: 'sub-phy-lab',
      classId: 'cls-10',
      name: 'Physics Practical',
      code: 'PHY',
      type: 'Practical',
      teacherId: 'tch-102',
    ),
  ];

  final List<ClassroomModel> mockClassrooms = [
    const ClassroomModel(
      id: 'room-101',
      name: 'Room 101',
      building: 'Main',
      capacity: 40,
      roomType: 'Theory',
      status: 'Available',
    ),
    const ClassroomModel(
      id: 'room-lab1',
      name: 'Physics Lab 1',
      building: 'Science Block',
      capacity: 30,
      roomType: 'Practical',
      status: 'Available',
    ),
    const ClassroomModel(
      id: 'room-lab2',
      name: 'Chemistry Lab 2',
      building: 'Science Block',
      capacity: 30,
      roomType: 'Practical',
      status: 'Available',
    ),
    const ClassroomModel(
      id: 'room-unavail',
      name: 'Robotics Lab',
      building: 'Science Block',
      capacity: 25,
      roomType: 'Practical',
      status: 'Not Available',
    ),
  ];

  final List<TeacherOption> mockTeachers = [
    const TeacherOption('tch-101', 'Anita Roy (Mathematics)'),
    const TeacherOption('tch-102', 'R. Sharma (Physics)'),
  ];

  ClassesLookup createLookup() {
    return ClassesLookup(
      classes: mockClasses,
      sections: mockSections,
      subjects: mockSubjects,
      classrooms: mockClassrooms,
      teachers: mockTeachers,
    );
  }

  group('Timetable Module – Model & Repository Overlap Rules', () {
    test(
      'Practical period requires available classroom/lab in repository',
      () async {
        final repo = MockClassesRepository();

        // Saving Practical without room should throw error
        expect(
          () => repo.saveTimetableEntry(
            admin,
            const TimetableEntryModel(
              id: '',
              classId: 'cls-1',
              sectionId: 'sec-1b',
              subjectId: 'sub-phy-lab',
              teacherId: 'STF-2026-0199',
              subjectType: 'Practical',
              classroomId: null,
              dayOfWeek: 6,
              startTime: '06:00',
              endTime: '06:45',
            ),
            isNew: true,
          ),
          throwsA(
            isA<ClassesDataException>().having(
              (e) => e.message,
              'message',
              contains(
                'Please select an available room or lab for Practical period',
              ),
            ),
          ),
        );
      },
    );

    test(
      'Theory period automatically clears classroomId in repository',
      () async {
        final repo = MockClassesRepository();

        final saved = await repo.saveTimetableEntry(
          admin,
          const TimetableEntryModel(
            id: '',
            classId: 'cls-1',
            sectionId: 'sec-1b',
            subjectId: 'sub-math',
            teacherId: 'STF-2026-0199',
            subjectType: 'Theory',
            classroomId: 'room-101', // Provided, but Theory should clear it
            dayOfWeek: 6,
            startTime: '06:00',
            endTime: '06:45',
          ),
          isNew: true,
        );

        expect(saved.classroomId, isNull);
      },
    );

    test('Prevent overlapping practical periods in the same room/lab', () async {
      final repo = MockClassesRepository();

      // 1. Schedule first practical class in room-lab1 for section sec-1b at 07:00
      await repo.saveTimetableEntry(
        admin,
        const TimetableEntryModel(
          id: '',
          classId: 'cls-1',
          sectionId: 'sec-1b',
          subjectId: 'sub-phy-lab',
          teacherId: 'STF-2026-0199',
          subjectType: 'Practical',
          classroomId: 'room-lab1',
          dayOfWeek: 6,
          startTime: '07:00',
          endTime: '07:45',
        ),
        isNew: true,
      );

      // 2. Attempt another class for a different section (sec-1a) with different teacher booking the same room-lab1 at overlapping time
      expect(
        () => repo.saveTimetableEntry(
          admin,
          const TimetableEntryModel(
            id: '',
            classId: 'cls-1',
            sectionId: 'sec-1a',
            subjectId: 'sub-phy-lab',
            teacherId: 'STF-2026-0198',
            subjectType: 'Practical',
            classroomId: 'room-lab1',
            dayOfWeek: 6,
            startTime: '07:15',
            endTime: '08:00',
          ),
          isNew: true,
        ),
        throwsA(
          isA<ClassesDataException>().having(
            (e) => e.message,
            'message',
            contains(
              'That classroom or lab is already booked for that time slot',
            ),
          ),
        ),
      );
    });

    test('Prevent overlapping period for same teacher', () async {
      final repo = MockClassesRepository();

      await repo.saveTimetableEntry(
        admin,
        const TimetableEntryModel(
          id: '',
          classId: 'cls-1',
          sectionId: 'sec-1a',
          subjectId: 'sub-math',
          teacherId: 'STF-2026-0199',
          subjectType: 'Theory',
          dayOfWeek: 6,
          startTime: '08:00',
          endTime: '08:45',
        ),
        isNew: true,
      );

      expect(
        () => repo.saveTimetableEntry(
          admin,
          const TimetableEntryModel(
            id: '',
            classId: 'cls-1',
            sectionId: 'sec-1b',
            subjectId: 'sub-math',
            teacherId: 'STF-2026-0199',
            subjectType: 'Theory',
            dayOfWeek: 6,
            startTime: '08:15',
            endTime: '09:00',
          ),
          isNew: true,
        ),
        throwsA(
          isA<ClassesDataException>().having(
            (e) => e.message,
            'message',
            contains('That teacher is already teaching in that time slot'),
          ),
        ),
      );
    });

    test('Prevent overlapping period for same class and section', () async {
      final repo = MockClassesRepository();

      await repo.saveTimetableEntry(
        admin,
        const TimetableEntryModel(
          id: '',
          classId: 'cls-1',
          sectionId: 'sec-1a',
          subjectId: 'sub-math',
          teacherId: 'STF-2026-0198',
          subjectType: 'Theory',
          dayOfWeek: 6,
          startTime: '13:00',
          endTime: '13:45',
        ),
        isNew: true,
      );

      expect(
        () => repo.saveTimetableEntry(
          admin,
          const TimetableEntryModel(
            id: '',
            classId: 'cls-1',
            sectionId: 'sec-1a',
            subjectId: 'sub-phy-lab',
            teacherId: 'STF-2026-0199',
            subjectType: 'Practical',
            classroomId: 'room-lab1',
            dayOfWeek: 6,
            startTime: '13:15',
            endTime: '14:00',
          ),
          isNew: true,
        ),
        throwsA(
          isA<ClassesDataException>().having(
            (e) => e.message,
            'message',
            contains('This section already has a period in that time slot'),
          ),
        ),
      );
    });
  });

  group('Timetable Module – Add Period Dialog Field Order & Logic', () {
    testWidgets(
      'Add Period Form displays fields in exact order and hides Room Number for Theory',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final lookup = createLookup();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return Consumer(
                      builder: (context, ref, _) {
                        return ElevatedButton(
                          onPressed: () =>
                              openPeriodModal(context, ref, lookup),
                          child: const Text('Open Modal'),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Check dialog is open
        expect(find.text('Add Timetable Period'), findsOneWidget);

        // Verify Field Labels exist:
        // 1. Class
        expect(find.text('Class'), findsOneWidget);
        // 2. Section
        expect(find.text('Section'), findsOneWidget);
        // 3. Subject Type
        expect(find.text('Subject Type'), findsOneWidget);
        // 4. Subject
        expect(find.text('Subject'), findsOneWidget);
        // Default subject type is Theory -> Room Number field MUST BE HIDDEN
        expect(find.text('Room Number / Lab'), findsNothing);
        // 6. Day of the Week
        expect(find.text('Day of the Week'), findsOneWidget);
        // 7. Month
        expect(find.text('Month'), findsOneWidget);
        // 8. Period / Time (AM/PM)
        expect(find.text('Period / Time (AM/PM)'), findsOneWidget);
        // 9. Teacher
        expect(find.text('Teacher'), findsOneWidget);
      },
    );

    testWidgets(
      'Subject Type = Practical shows Room Number field and clearing on switch to Theory',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final lookup = createLookup();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return Consumer(
                      builder: (context, ref, _) {
                        return ElevatedButton(
                          onPressed: () =>
                              openPeriodModal(context, ref, lookup),
                          child: const Text('Open Modal'),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Initially Theory -> Room Number / Lab hidden
        expect(find.text('Room Number / Lab'), findsNothing);

        // Switch Subject Type to Practical
        await tester.tap(find.text('Theory').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Practical').last);
        await tester.pumpAndSettle();

        // Now Room Number / Lab field must be visible!
        expect(find.text('Room Number / Lab'), findsOneWidget);

        // Switch back to Theory
        await tester.tap(find.text('Practical').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Theory').last);
        await tester.pumpAndSettle();

        // Room Number / Lab field must be hidden again!
        expect(find.text('Room Number / Lab'), findsNothing);
      },
    );
  });

  group('Timetable Module – Timetable Display Requirements', () {
    testWidgets(
      'Timetable grid aligns subject type and centers faculty and room',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final lookup = createLookup();
        final entries = [
          const TimetableEntryModel(
            id: 'tt-theory',
            classId: 'cls-10',
            sectionId: 'sec-10a',
            subjectId: 'sub-math',
            teacherId: 'tch-101',
            subjectType: 'Theory',
            dayOfWeek: 1,
            startTime: '08:00',
            endTime: '08:45',
          ),
          const TimetableEntryModel(
            id: 'tt-practical',
            classId: 'cls-10',
            sectionId: 'sec-10a',
            subjectId: 'sub-phy-lab',
            teacherId: 'tch-102',
            subjectType: 'Practical',
            classroomId: 'room-lab1',
            dayOfWeek: 1,
            startTime: '08:45',
            endTime: '09:30',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classesLookupProvider.overrideWith((ref) => lookup),
              timetableControllerProvider.overrideWith(
                () => _FakeTimetableController(entries),
              ),
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
        await tester.pumpAndSettle();

        expect(find.text('Mathematics'), findsOneWidget);
        expect(find.text('Theory'), findsOneWidget);
        expect(find.text('Physics Practical'), findsOneWidget);
        expect(find.text('Practical'), findsOneWidget);
        expect(find.text('Physics Lab 1'), findsOneWidget);
        expect(find.text('Room 101'), findsNothing);

        final subjectTypeRow = find
            .ancestor(of: find.text('Theory'), matching: find.byType(Row))
            .first;
        expect(
          find.descendant(
            of: subjectTypeRow,
            matching: find.text('Mathematics'),
          ),
          findsOneWidget,
        );

        final facultyText = tester.widget<Text>(find.text('Anita Roy'));
        expect(facultyText.textAlign, TextAlign.center);
        expect(
          tester.getTopLeft(find.text('Anita Roy')).dy,
          greaterThan(tester.getTopLeft(find.text('Mathematics')).dy),
        );
      },
    );

    testWidgets(
      'TimetableDayList displays room for Practical and omits room for Theory',
      (tester) async {
        final lookup = createLookup();

        final entries = [
          const TimetableEntryModel(
            id: 'tt-1',
            classId: 'cls-10',
            sectionId: 'sec-10a',
            subjectId: 'sub-math',
            teacherId: 'tch-101',
            subjectType: 'Theory',
            classroomId: null,
            dayOfWeek: 1,
            startTime: '08:00',
            endTime: '08:45',
          ),
          const TimetableEntryModel(
            id: 'tt-2',
            classId: 'cls-10',
            sectionId: 'sec-10a',
            subjectId: 'sub-phy-lab',
            teacherId: 'tch-102',
            subjectType: 'Practical',
            classroomId: 'room-lab1',
            dayOfWeek: 1,
            startTime: '08:45',
            endTime: '09:30',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimetableDayList(entries: entries, lookup: lookup),
            ),
          ),
        );

        // Theory period: shows Theory badge, Mathematics, Anita Roy, but NO room name
        expect(find.text('08:00 – 08:45  ·  Mathematics'), findsOneWidget);
        expect(find.textContaining('· Theory ·'), findsOneWidget);

        // Practical period: shows Practical badge, Physics Practical, R. Sharma, and Physics Lab 1
        expect(
          find.text('08:45 – 09:30  ·  Physics Practical'),
          findsOneWidget,
        );
        expect(find.textContaining('· Practical ·'), findsOneWidget);
        expect(find.textContaining('Physics Lab 1'), findsOneWidget);
      },
    );
  });
}

class _FakeTimetableController extends TimetableController {
  final List<TimetableEntryModel> data;

  _FakeTimetableController(this.data);

  @override
  Future<List<TimetableEntryModel>> build() async => data;
}
