import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/classes/domain/class_model.dart';
import 'package:frontend/src/features/classes/domain/classes_actor.dart';
import 'package:frontend/src/features/classes/domain/classroom_model.dart';
import 'package:frontend/src/features/classes/domain/curriculum_model.dart';
import 'package:frontend/src/features/classes/domain/daily_lesson_model.dart';
import 'package:frontend/src/features/classes/domain/section_model.dart';
import 'package:frontend/src/features/classes/domain/subject_model.dart';
import 'package:frontend/src/features/classes/domain/timetable_entry_model.dart';
import 'package:frontend/src/commonwidgets/edupluse_scaffold.dart';
import 'package:frontend/src/features/classes/data/classes_local_datasource.dart';
import 'package:frontend/src/features/classes/presentation/classes_hub_screen.dart';
import 'package:frontend/src/features/classes/presentation/admin/classes_list_screen.dart';
import 'package:frontend/src/features/classes/presentation/admin/curriculum_management_screen.dart';
import 'package:frontend/src/features/classes/presentation/admin/subjects_management_screen.dart';
import 'package:frontend/src/features/classes/presentation/teacher/teacher_work_management_screen.dart';
import 'package:frontend/src/features/classes/application/classes_controller.dart';
import 'package:frontend/src/features/classes/application/classes_access.dart';
import 'package:frontend/src/features/classes/application/curriculum_controller.dart';
import 'package:frontend/src/features/classes/application/timetable_controller.dart';
import 'package:frontend/src/features/classes/application/teacher_work_controller.dart';
import 'package:frontend/src/features/classes/domain/teacher_work_model.dart';
import 'package:frontend/src/features/classes/presentation/teacher/class_details_screen.dart';
import 'package:frontend/src/features/classes/presentation/widgets/classes_lookup.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('ClassesLocalDataSource JSON Persistence & CRUD', () {
    test(
      'DataSource loads default JSON data and persists new entries',
      () async {
        final ds = ClassesLocalDataSource();
        final adminActor = const ClassesActor(
          role: UserRole.admin,
          userId: 'USR-ADMIN-01',
        );

        // 1. Initial load
        final initialClasses = await ds.getClasses(adminActor);
        expect(initialClasses.isNotEmpty, isTrue);

        // 2. Add a new class
        final newClass = await ds.saveClass(
          adminActor,
          const ClassModel(
            id: '',
            name: 'Class 7',
            gradeLevel: 7,
            academicYear: '2026-2027',
          ),
          isNew: true,
        );
        expect(newClass.id.startsWith('cls-'), isTrue);

        final updatedClasses = await ds.getClasses(adminActor);
        expect(updatedClasses.any((c) => c.name == 'Class 7'), isTrue);

        // 3. Add a new section
        final newSec = await ds.saveSection(
          adminActor,
          SectionModel(id: '', classId: newClass.id, name: 'A', capacity: 35),
          isNew: true,
        );
        expect(newSec.id.startsWith('sec-'), isTrue);

        final sections = await ds.getSections(adminActor);
        expect(
          sections.any((s) => s.classId == newClass.id && s.name == 'A'),
          isTrue,
        );

        // 4. Add a new subject
        final newSub = await ds.saveSubject(
          adminActor,
          SubjectModel(
            id: '',
            classId: newClass.id,
            name: 'Sanskrit',
            code: 'SAN-701',
            teacherId: 'tch-101',
          ),
          isNew: true,
        );
        expect(newSub.id.startsWith('sub-'), isTrue);

        final subjects = await ds.getSubjects(adminActor);
        expect(subjects.any((s) => s.code == 'SAN-701'), isTrue);

        // 5. Add a new classroom
        final newRoom = await ds.saveClassroom(
          adminActor,
          const ClassroomModel(
            id: '',
            name: 'Room 305',
            building: 'Aryabhata Academic Wing',
            capacity: 40,
          ),
          isNew: true,
        );
        expect(newRoom.id.startsWith('room-'), isTrue);

        final rooms = await ds.getClassrooms(adminActor);
        expect(rooms.any((r) => r.name == 'Room 305'), isTrue);

        // 6. Add curriculum unit
        final newCur = await ds.saveCurriculum(
          adminActor,
          CurriculumModel(
            id: '',
            classId: newClass.id,
            subjectId: newSub.id,
            title: 'Unit 1: Basic Sanskrit Grammar',
            description: 'Introduction to vowels and consonants',
            topics: ['Varnas', 'Sandhi Rules', 'Shlokas'],
          ),
          isNew: true,
        );
        expect(newCur.id.startsWith('cur-'), isTrue);

        // 7. Add timetable entry
        final newPeriod = await ds.saveTimetableEntry(
          adminActor,
          TimetableEntryModel(
            id: '',
            classId: newClass.id,
            sectionId: newSec.id,
            subjectId: newSub.id,
            teacherId: 'tch-101',
            classroomId: newRoom.id,
            dayOfWeek: 6,
            startTime: '08:00',
            endTime: '08:45',
          ),
          isNew: true,
        );
        expect(newPeriod.id.startsWith('tt-'), isTrue);

        // 8. Verify exported JSON contains the new data
        final exportedJson = ds.exportJsonString();
        expect(exportedJson.contains('Class 7'), isTrue);
        expect(exportedJson.contains('Sanskrit'), isTrue);
        expect(exportedJson.contains('Room 305'), isTrue);
      },
    );
  });

  testWidgets('Add Curriculum form presents fields in the requested order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const classModel = ClassModel(
      id: 'cls-10',
      name: '10th Class',
      code: 'CLS-10',
      gradeLevel: 10,
      academicYear: '2026-27',
    );
    const lookup = ClassesLookup(
      classes: [classModel],
      sections: [],
      subjects: [
        SubjectModel(
          id: 'sub-math',
          classId: 'cls-10',
          name: 'Mathematics',
          code: 'MTH',
        ),
      ],
      classrooms: [],
      teachers: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [classesLookupProvider.overrideWithValue(lookup)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => openCurriculumModal(
                  context,
                  ref,
                  lookup,
                ),
                child: const Text('Open Add Curriculum'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Add Curriculum'));
    await tester.pumpAndSettle();

    final orderedFields = [
      'Academic Year',
      'Class',
      'Subject',
      'Curriculum Name',
      'Initial Chapter (Subtopics not required)',
    ];
    final fieldPositions = orderedFields
        .map((label) => tester.getTopLeft(find.text(label).first).dy)
        .toList();

    for (var index = 1; index < fieldPositions.length; index++) {
      expect(fieldPositions[index - 1], lessThan(fieldPositions[index]));
    }
  });

  group('Role-Based Authentication & Permissions Matrix', () {
    test(
      'Teacher can view assigned data and add lessons, but cannot delete classes',
      () async {
        final ds = ClassesLocalDataSource();
        final adminActor = const ClassesActor(
          role: UserRole.admin,
          userId: 'USR-ADMIN-01',
        );
        final teacherActor = const ClassesActor(
          role: UserRole.teacher,
          userId: 'tch-102',
        );

        // Admin adds a class and assigns teacher
        final cls = await ds.saveClass(
          adminActor,
          const ClassModel(
            id: '',
            name: 'Class 10 Advanced',
            gradeLevel: 10,
            academicYear: '2026-2027',
            classTeacherId: 'tch-102',
          ),
          isNew: true,
        );

        final sub = await ds.saveSubject(
          adminActor,
          SubjectModel(
            id: '',
            classId: cls.id,
            name: 'Advanced Calculus',
            code: 'CAL-101',
            teacherId: 'tch-102',
          ),
          isNew: true,
        );

        // Teacher can write a lesson for their assigned subject
        final lesson = await ds.saveLesson(
          teacherActor,
          DailyLessonModel(
            id: '',
            classId: cls.id,
            subjectId: sub.id,
            teacherId: 'tch-102',
            date: DateTime.now(),
            title: 'Differentiation from first principles',
            notes: 'Covered limit definitions.',
          ),
          isNew: true,
        );
        expect(lesson.title, 'Differentiation from first principles');

        // Teacher CANNOT delete classes -> throws ClassesPermissionException
        expect(
          () async => await ds.deleteClass(teacherActor, cls.id),
          throwsA(isA<ClassesPermissionException>()),
        );

        // Teacher CANNOT manage sections -> throws ClassesPermissionException
        expect(
          () async => await ds.saveSection(
            teacherActor,
            SectionModel(id: '', classId: cls.id, name: 'B', capacity: 30),
            isNew: true,
          ),
          throwsA(isA<ClassesPermissionException>()),
        );
      },
    );

    test(
      'Student is read-only and restricted from mutating classes data',
      () async {
        final ds = ClassesLocalDataSource();
        final studentActor = const ClassesActor(
          role: UserRole.student,
          userId: 'std-1001',
          studentId: 'std-1001',
          studentUserId: 'std-1001',
          studentClassId: 'cls-10',
          studentSectionId: 'sec-10a',
          studentClassName: 'Class 10',
          studentSection: 'A',
        );

        // Student can view their class
        final classes = await ds.getClasses(studentActor);
        for (final c in classes) {
          expect(c.name.toLowerCase(), '10th class');
        }

        // Student CANNOT add a class
        expect(
          () async => await ds.saveClass(
            studentActor,
            const ClassModel(
              id: '',
              name: 'Hacked Class',
              gradeLevel: 1,
              academicYear: '2026-2027',
            ),
            isNew: true,
          ),
          throwsA(isA<ClassesPermissionException>()),
        );

        // Student CANNOT add a lesson
        expect(
          () async => await ds.saveLesson(
            studentActor,
            DailyLessonModel(
              id: '',
              classId: 'cls-10',
              subjectId: 'sub-101',
              teacherId: 'tch-102',
              date: DateTime.now(),
              title: 'Unauthorized lesson',
            ),
            isNew: true,
          ),
          throwsA(isA<ClassesPermissionException>()),
        );
      },
    );
  });

  group(
    'Dropdown Navigation & Cross-Device Responsive UI (Mobile, Tablet, Desktop)',
    () {
      testWidgets(
        'ClassesHubScreen renders on Phone (390x844) with compact dropdown and no overflow',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              ],
              child: const MaterialApp(home: ClassesHubScreen()),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Header shows breadcrumb with Classes and active section title
          expect(find.text('Classes'), findsWidgets);
          expect(find.text('Academic Classes'), findsWidgets);

          // Dropdown menu opens only when clicked
          await tester.tap(find.byType(PopupMenuButton<EdupluseNavPage>));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Dropdown items are now visible
          expect(find.text('Subjects'), findsWidgets);
          expect(find.text('Sections'), findsWidgets);
          expect(find.text('Curriculum'), findsWidgets);
          expect(find.text('Daily Lessons'), findsNothing);
          expect(find.text('Timetable'), findsWidgets);
          expect(find.text('Classrooms'), findsWidgets);
          expect(find.text('Assignments'), findsWidgets);
        },
      );

      testWidgets(
        'Classes sidebar dropdown expands on click and collapses on click on Desktop (1280x800)',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              ],
              child: const MaterialApp(home: ClassesHubScreen()),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Initially, sidebar subitems are collapsed
          expect(find.text('Teacher Work'), findsNothing);

          // Find the sidebar 'Classes' item and click to expand
          final classesSidebarFinder = find.widgetWithText(InkWell, 'Classes');
          expect(classesSidebarFinder, findsOneWidget);

          await tester.tap(classesSidebarFinder);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Submenu expanded downward!
          expect(find.text('Subjects'), findsWidgets);
          expect(find.text('Sections'), findsWidgets);
          expect(find.text('Curriculum'), findsWidgets);
          expect(find.text('Daily Lessons'), findsNothing);
          expect(find.text('Timetable'), findsWidgets);
          expect(find.text('Classrooms'), findsWidgets);
          expect(find.text('Teacher Work'), findsWidgets);

          // Click again to collapse
          await tester.tap(classesSidebarFinder);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Submenu collapsed
          expect(find.text('Teacher Work'), findsNothing);
        },
      );

      testWidgets(
        'ClassesHubScreen renders on Tablet (800x1280) in Teacher mode',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1280);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                activeUserRoleProvider.overrideWith((ref) => UserRole.teacher),
              ],
              child: const MaterialApp(home: ClassesHubScreen()),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Header shows breadcrumb
          expect(find.text('Classes'), findsWidgets);

          // Open the dropdown
          await tester.tap(find.byType(PopupMenuButton<EdupluseNavPage>));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Assignments'), findsWidgets);
          expect(find.text('Daily Lessons'), findsNothing);
        },
      );

      testWidgets(
        'ClassesHubScreen renders Assignments screen on desktop and mobile without ParentDataWidget errors',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              ],
              child: const MaterialApp(
                home: ClassesHubScreen(
                  activeNavPage: EdupluseNavPage.classesTeacherWork,
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Verifies 'Assignments' header and filters render cleanly without ParentDataWidget assertions
          expect(find.text('Assignments'), findsWidgets);
          expect(find.byType(TextField), findsOneWidget);

          // Now test on mobile size (390x844)
          tester.view.physicalSize = const Size(390, 844);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Academic Tasks'), findsOneWidget);
        },
      );

      testWidgets('clicking a class in Subjects opens that Academic Class', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        String? openedClassId;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SubjectsManagementScreen(
                  onOpenClass: (classId) => openedClassId = classId,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final className = find.text('10th Class').first;
        expect(className, findsOneWidget);
        await tester.tap(className);

        expect(openedClassId, 'cls-10');
      });

      for (final role in [
        UserRole.teacher,
        UserRole.student,
        UserRole.parent,
      ]) {
        testWidgets(
          '${role.name} opens the shared Academic Class Details page',
          (tester) async {
            tester.view.physicalSize = const Size(1280, 900);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            const classModel = ClassModel(
              id: 'cls-10',
              name: '10th Class',
              code: 'CLS-10',
              gradeLevel: 10,
              academicYear: '2026-27',
            );
            final actor = ClassesActor(
              role: role,
              userId: 'USR-${role.name.toUpperCase()}-TEST',
              studentClassId: role == UserRole.student || role == UserRole.parent
                  ? classModel.id
                  : null,
              studentId: role == UserRole.student || role == UserRole.parent
                  ? 'student-test'
                  : null,
              studentUserId: role == UserRole.student
                  ? 'USR-${role.name.toUpperCase()}-TEST'
                  : null,
              linkedParentUserId: role == UserRole.parent
                  ? 'USR-${role.name.toUpperCase()}-TEST'
                  : null,
            );
            const lookup = ClassesLookup(
              classes: [classModel],
              sections: [],
              subjects: [],
              classrooms: [],
              teachers: [],
            );

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  activeUserRoleProvider.overrideWith((ref) => role),
                  classesActorProvider.overrideWithValue(actor),
                  classesControllerProvider.overrideWith(
                    () => _FakeClassesCtrl([classModel]),
                  ),
                  classesLookupProvider.overrideWithValue(lookup),
                  curriculumControllerProvider.overrideWith(
                    () => _FakeCurriculumCtrl(const []),
                  ),
                  timetableControllerProvider.overrideWith(
                    () => _FakeTimetableCtrl(const []),
                  ),
                  teacherWorkControllerProvider.overrideWith(
                    () => _FakeTeacherWorkCtrl(const []),
                  ),
                ],
                child: const MaterialApp(home: ClassesHubScreen()),
              ),
            );
            await tester.pumpAndSettle();

            expect(find.text('Academic Classes'), findsWidgets);
            await tester.tap(find.text('10th Class').first);
            await tester.pumpAndSettle();

            expect(find.byType(ClassDetailsBody), findsOneWidget);
            expect(find.text('Class Details'), findsNothing);
            expect(find.text('Back to Academic Classes'), findsOneWidget);
          },
        );
      }

      testWidgets(
        'Clicking class in Class List opens Class Details inline on same page with Curriculum and Timetable',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final fakeClasses = [
            const ClassModel(
              id: 'cls-10',
              name: '10th Class',
              code: 'CLS-10',
              gradeLevel: 10,
              academicYear: '2026-27',
              status: 'Active',
            ),
          ];

          final fakeCurriculum = [
            const CurriculumModel(
              id: 'cur-101',
              classId: 'cls-10',
              subjectId: 'sub-101',
              title: 'Chapter 1: Real Numbers',
              description: 'Fundamental Theorem of Arithmetic',
              topics: ['Topic 1', 'Topic 2'],
              completedTopics: 1,
            ),
          ];

          final fakeTimetable = [
            const TimetableEntryModel(
              id: 'tt-101',
              classId: 'cls-10',
              sectionId: 'sec-10a',
              subjectId: 'sub-101',
              teacherId: 'tch-102',
              dayOfWeek: 1,
              startTime: '08:00',
              endTime: '08:45',
            ),
          ];

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
                classesControllerProvider.overrideWith(
                  () => _FakeClassesCtrl(fakeClasses),
                ),
                curriculumControllerProvider.overrideWith(
                  () => _FakeCurriculumCtrl(fakeCurriculum),
                ),
                timetableControllerProvider.overrideWith(
                  () => _FakeTimetableCtrl(fakeTimetable),
                ),
              ],
              child: const MaterialApp(
                home: Scaffold(body: AdminClassesListScreen()),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // 1. Initial screen displays the Academic Classes table
          expect(find.text('Academic Classes'), findsWidgets);
          // Since 10th Class has multiple sections (A and B), it appears in separate section rows
          expect(find.text('10th Class'), findsWidgets);

          // 2. Click on "10th Class" (first section row)
          await tester.tap(find.text('10th Class').first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // 3. Verifies Class Details opens on the SAME PAGE without pushing a new route
          expect(find.byType(ClassDetailsBody), findsOneWidget);
          expect(find.text('Back to Academic Classes'), findsOneWidget);

          // 4. Verifies Curriculum and Timetable are shown inside the class details
          expect(find.text('Curriculum & Syllabus'), findsOneWidget);
          expect(find.text('Class Timetable'), findsOneWidget);
          expect(find.text('Chapter 1: Real Numbers'), findsNothing);

          // 5. Click "Back to Academic Classes"
          await tester.tap(find.text('Back to Academic Classes'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // 6. Confirms user is back on the Academic Classes table on the same page
          expect(find.text('Academic Classes'), findsWidgets);
          expect(find.byType(ClassDetailsBody), findsNothing);
        },
      );

      testWidgets(
        'Class Details shows and sorts assignments for the selected class',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final classModel = const ClassModel(
            id: 'cls-10',
            name: '10th Class',
            code: 'CLS-10',
            gradeLevel: 10,
            academicYear: '2026-27',
            status: 'Active',
          );
          final workItems = [
            TeacherWorkModel(
              id: 'work-biology',
              title: 'Biology Lab',
              classId: 'cls-10',
              subjectId: 'sub-biology',
              teacherId: 'tch-101',
              dueDate: DateTime(2026, 10, 25),
              status: 'Assigned',
            ),
            TeacherWorkModel(
              id: 'work-algebra',
              title: 'Algebra Practice',
              classId: 'cls-10',
              subjectId: 'sub-math',
              teacherId: 'tch-102',
              dueDate: DateTime(2026, 11, 2),
              status: 'Reviewed',
            ),
            TeacherWorkModel(
              id: 'work-other-class',
              title: 'Other Class Assignment',
              classId: 'cls-9',
              subjectId: 'sub-math',
              teacherId: 'tch-102',
              dueDate: DateTime(2026, 10, 1),
            ),
          ];
          final lookup = ClassesLookup(
            classes: [classModel],
            sections: const [],
            subjects: const [
              SubjectModel(
                id: 'sub-biology',
                classId: 'cls-10',
                name: 'Biology',
                code: 'BIO',
              ),
              SubjectModel(
                id: 'sub-math',
                classId: 'cls-10',
                name: 'Mathematics',
                code: 'MTH',
              ),
            ],
            classrooms: const [],
            teachers: const [
              TeacherOption('tch-101', 'Anita Roy'),
              TeacherOption('tch-102', 'R. Sharma'),
            ],
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
                classesControllerProvider.overrideWith(
                  () => _FakeClassesCtrl([classModel]),
                ),
                classesLookupProvider.overrideWith((ref) => lookup),
                teacherWorkControllerProvider.overrideWith(
                  () => _FakeTeacherWorkCtrl(workItems),
                ),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: ClassDetailsBody(classId: 'cls-10'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.ensureVisible(find.text('Assignments').first);
          await tester.tap(find.text('Assignments').first);
          await tester.pumpAndSettle();

          expect(find.text('Assignments (2)'), findsOneWidget);
          expect(find.text('Biology Lab'), findsOneWidget);
          expect(find.text('Biology'), findsOneWidget);
          expect(find.text('Anita Roy'), findsOneWidget);
          expect(find.text('2026-10-25'), findsOneWidget);
          expect(find.text('Assigned'), findsOneWidget);
          expect(find.text('Algebra Practice'), findsOneWidget);
          expect(find.text('Other Class Assignment'), findsNothing);

          expect(
            tester.getTopLeft(find.text('Biology Lab')).dy,
            lessThan(tester.getTopLeft(find.text('Algebra Practice')).dy),
          );
          await tester.tap(find.text('Due Date').last);
          await tester.pumpAndSettle();
          expect(
            tester.getTopLeft(find.text('Algebra Practice')).dy,
            lessThan(tester.getTopLeft(find.text('Biology Lab')).dy),
          );
        },
      );

      testWidgets('Assignments table sorts by assignment name', (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final classModel = const ClassModel(
          id: 'cls-10',
          name: '10th Class',
          code: 'CLS-10',
          gradeLevel: 10,
          academicYear: '2026-27',
        );
        final lookup = ClassesLookup(
          classes: [classModel],
          sections: const [],
          subjects: const [
            SubjectModel(
              id: 'sub-math',
              classId: 'cls-10',
              name: 'Mathematics',
              code: 'MTH',
            ),
          ],
          classrooms: const [],
          teachers: const [TeacherOption('tch-101', 'Anita Roy')],
        );
        final workItems = [
          TeacherWorkModel(
            id: 'work-zebra',
            title: 'Zebra Assignment',
            classId: 'cls-10',
            subjectId: 'sub-math',
            teacherId: 'tch-101',
            dueDate: DateTime(2026, 10, 25),
          ),
          TeacherWorkModel(
            id: 'work-alpha',
            title: 'Alpha Assignment',
            classId: 'cls-10',
            subjectId: 'sub-math',
            teacherId: 'tch-101',
            dueDate: DateTime(2026, 11, 2),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classesLookupProvider.overrideWith((ref) => lookup),
              teacherWorkControllerProvider.overrideWith(
                () => _FakeTeacherWorkCtrl(workItems),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: TeacherWorkManagementScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Alpha Assignment'), findsOneWidget);
        expect(find.text('Zebra Assignment'), findsOneWidget);
        await tester.ensureVisible(find.text('Task Title'));
        await tester.tap(find.text('Task Title'));
        await tester.pumpAndSettle();

        expect(
          tester.getTopLeft(find.text('Alpha Assignment')).dy,
          lessThan(tester.getTopLeft(find.text('Zebra Assignment')).dy),
        );
      });
    },
  );
}

class _FakeClassesCtrl extends ClassesController {
  final List<ClassModel> data;
  _FakeClassesCtrl(this.data);
  @override
  Future<List<ClassModel>> build() async => data;
}

class _FakeCurriculumCtrl extends CurriculumController {
  final List<CurriculumModel> data;
  _FakeCurriculumCtrl(this.data);
  @override
  Future<List<CurriculumModel>> build() async => data;
}

class _FakeTimetableCtrl extends TimetableController {
  final List<TimetableEntryModel> data;
  _FakeTimetableCtrl(this.data);
  @override
  Future<List<TimetableEntryModel>> build() async => data;
}

class _FakeTeacherWorkCtrl extends TeacherWorkController {
  final List<TeacherWorkModel> data;
  _FakeTeacherWorkCtrl(this.data);
  @override
  Future<List<TeacherWorkModel>> build() async => data;
}
