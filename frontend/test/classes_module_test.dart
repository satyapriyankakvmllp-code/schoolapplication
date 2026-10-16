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
import 'package:frontend/src/features/classes/presentation/shared/classes_hub_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('ClassesLocalDataSource JSON Persistence & CRUD', () {
    test('DataSource loads default JSON data and persists new entries', () async {
      final ds = ClassesLocalDataSource();
      final adminActor = const ClassesActor(role: UserRole.admin, userId: 'USR-ADMIN-01');

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
        SectionModel(
          id: '',
          classId: newClass.id,
          name: 'A',
          capacity: 35,
        ),
        isNew: true,
      );
      expect(newSec.id.startsWith('sec-'), isTrue);

      final sections = await ds.getSections(adminActor);
      expect(sections.any((s) => s.classId == newClass.id && s.name == 'A'), isTrue);

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
    });
  });

  group('Role-Based Authentication & Permissions Matrix', () {
    test('Teacher can view assigned data and add lessons, but cannot delete classes', () async {
      final ds = ClassesLocalDataSource();
      final adminActor = const ClassesActor(role: UserRole.admin, userId: 'USR-ADMIN-01');
      final teacherActor = const ClassesActor(role: UserRole.teacher, userId: 'tch-102');

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
    });

    test('Student is read-only and restricted from mutating classes data', () async {
      final ds = ClassesLocalDataSource();
      final studentActor = const ClassesActor(
        role: UserRole.student,
        userId: 'std-1001',
        studentClassName: 'Class 10',
        studentSection: 'A',
      );

      // Student can view their class
      final classes = await ds.getClasses(studentActor);
      for (final c in classes) {
        expect(c.name.toLowerCase(), 'class 10');
      }

      // Student CANNOT add a class
      expect(
        () async => await ds.saveClass(
          studentActor,
          const ClassModel(id: '', name: 'Hacked Class', gradeLevel: 1, academicYear: '2026-2027'),
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
    });
  });

  group('Dropdown Navigation & Cross-Device Responsive UI (Mobile, Tablet, Desktop)', () {
    testWidgets('ClassesHubScreen renders on Phone (390x844) with compact dropdown and no overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: ClassesHubScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header shows breadcrumb with Classes and active section title
      expect(find.text('Classes'), findsWidgets);
      expect(find.text('Class List'), findsWidgets);

      // Dropdown menu opens only when clicked
      await tester.tap(find.byType(PopupMenuButton<EdupluseNavPage>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dropdown items are now visible
      expect(find.text('Subjects'), findsWidgets);
      expect(find.text('Sections'), findsWidgets);
      expect(find.text('Curriculum'), findsWidgets);
      expect(find.text('Daily Lessons'), findsWidgets);
      expect(find.text('Timetable'), findsWidgets);
      expect(find.text('Classrooms'), findsWidgets);
      expect(find.text('Teacher Work'), findsWidgets);
    });

    testWidgets('Classes sidebar dropdown expands on click and collapses on click on Desktop (1280x800)', (tester) async {
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
            home: ClassesHubScreen(),
          ),
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
      expect(find.text('Daily Lessons'), findsWidgets);
      expect(find.text('Timetable'), findsWidgets);
      expect(find.text('Classrooms'), findsWidgets);
      expect(find.text('Teacher Work'), findsWidgets);

      // Click again to collapse
      await tester.tap(classesSidebarFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Submenu collapsed
      expect(find.text('Teacher Work'), findsNothing);
    });

    testWidgets('ClassesHubScreen renders on Tablet (800x1280) in Teacher mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserRoleProvider.overrideWith((ref) => UserRole.teacher),
          ],
          child: const MaterialApp(
            home: ClassesHubScreen(),
          ),
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

      expect(find.text('Teacher Work'), findsWidgets);
      expect(find.text('Daily Lessons'), findsWidgets);
    });

    testWidgets('ClassesHubScreen renders Teacher Work screen on desktop and mobile without ParentDataWidget errors', (tester) async {
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

      // Verifies 'Academic Tasks' header and filters render cleanly without ParentDataWidget assertions
      expect(find.text('Academic Tasks'), findsOneWidget);
      expect(find.text('Teacher Work'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);

      // Now test on mobile size (390x844)
      tester.view.physicalSize = const Size(390, 844);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Academic Tasks'), findsOneWidget);
    });
  });
}
